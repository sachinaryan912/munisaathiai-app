import 'package:dio/dio.dart';
import '../storage/secure_storage.dart';
import 'api_exception.dart';
import 'retry_interceptor.dart';

/// The live Cloud Run backend. Override at build time with
/// `--dart-define=API_BASE_URL=...` to test against a local one
/// (`http://10.0.2.2:8080/api` from an Android emulator).
///
/// Switched off the ...201037794520 service on 2026-08-02 — that one answers
/// 500/503 to every route now, so any build still pointing at it is dead.
const _defaultBaseUrl = 'https://munisaathiai-backend-1046544478759.asia-south1.run.app/api';
const _apiBaseUrl = String.fromEnvironment('API_BASE_URL', defaultValue: _defaultBaseUrl);

const _statusMessages = <int, String>{
  400: 'Invalid request. Please check your details.',
  401: 'Session expired. Please sign in again.',
  403: 'Access denied.',
  404: 'Resource not found.',
  500: 'Server error. Please try again later.',
  503: 'The server is busy right now. Please try again in a moment.',
};

/// What came of an attempt to trade the refresh token for a new access token.
enum _RefreshOutcome {
  /// New access token stored; the caller can replay its request.
  renewed,

  /// The server rejected the refresh token — the session is genuinely over.
  sessionEnded,

  /// Couldn't reach the server. Says nothing about whether the session is valid,
  /// so the session must be left alone.
  unreachable,
}

class ApiClient {
  ApiClient._();
  static final ApiClient instance = ApiClient._();

  /// Set by AuthProvider at startup so an ended session can force a clean logout
  /// + redirect to login, without this layer depending on app-level state.
  void Function()? onUnauthorized;

  late final Dio dio = _build();

  /// Refreshes go out on their own Dio: routing them through [dio] would mean a
  /// failing refresh triggering the refresh-on-401 handler that called it.
  late final Dio _authDio = Dio(_baseOptions())..interceptors.add(RetryInterceptor());

  /// In-flight refresh, shared by every request that 401s while it runs — without
  /// this, a dashboard firing six parallel calls on a stale token would kick off
  /// six refreshes, five of which present a token the first has already rotated away.
  Future<_RefreshOutcome>? _refreshInFlight;

  static BaseOptions _baseOptions() => BaseOptions(
        baseUrl: _apiBaseUrl,
        connectTimeout: const Duration(seconds: 20),
        receiveTimeout: const Duration(seconds: 25),
        sendTimeout: const Duration(seconds: 30),
      );

  /// Marks a request that has already been replayed once after a refresh, so a
  /// second 401 ends the session instead of looping.
  static const _retriedAfterRefreshKey = 'muni_retried_after_refresh';

  Dio _build() {
    final d = Dio(_baseOptions());

    d.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        final token = await SecureStorage.instance.readToken();
        if (token != null && token.isNotEmpty) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        handler.next(options);
      },
      onError: (error, handler) async {
        if (!await _handleUnauthorized(error, handler)) {
          handler.next(error);
        }
      },
    ));

    // After the auth interceptor so a 401 is resolved by refreshing rather than
    // being retried two more times against the same dead token.
    d.interceptors.add(RetryInterceptor());

    return d;
  }

  /// @return true if [handler] has been settled and the caller should stop.
  Future<bool> _handleUnauthorized(DioException error, ErrorInterceptorHandler handler) async {
    if (error.response?.statusCode != 401) return false;

    final options = error.requestOptions;

    // /api/auth/** is where sign-in lives; a 401 from there is the answer to the
    // user's action, not a stale-token problem to paper over. (Refresh itself goes
    // out on _authDio and never reaches this interceptor.)
    if (options.path.contains('/auth/')) return false;

    if (options.extra[_retriedAfterRefreshKey] == true) {
      // Already refreshed once for this request and still unauthorized.
      onUnauthorized?.call();
      return false;
    }

    final outcome = await _refreshSession();
    switch (outcome) {
      case _RefreshOutcome.sessionEnded:
        onUnauthorized?.call();
        return false;
      case _RefreshOutcome.unreachable:
        // Leave the session intact — the user is offline, not signed out.
        return false;
      case _RefreshOutcome.renewed:
        options.extra[_retriedAfterRefreshKey] = true;
        try {
          handler.resolve(await dio.fetch<dynamic>(prepareForReplay(options)));
        } on DioException catch (e) {
          handler.next(e);
        }
        return true;
    }
  }

  Future<_RefreshOutcome> _refreshSession() {
    return _refreshInFlight ??=
        _performRefresh().whenComplete(() => _refreshInFlight = null);
  }

  Future<_RefreshOutcome> _performRefresh() async {
    final storage = SecureStorage.instance;
    final refreshToken = await storage.readRefreshToken();
    if (refreshToken == null || refreshToken.isEmpty) {
      // Nothing to refresh with — e.g. a session created by a build that predates
      // refresh tokens. The access token is dead, so the session is over.
      return _RefreshOutcome.sessionEnded;
    }

    try {
      final res = await _authDio.post<dynamic>(
        '/auth/refresh',
        data: {'refreshToken': refreshToken},
      );

      final data = res.data;
      if (data is! Map) return _RefreshOutcome.sessionEnded;

      final newAccess = data['token'] as String?;
      if (newAccess == null || newAccess.isEmpty) return _RefreshOutcome.sessionEnded;
      await storage.saveToken(newAccess);

      final newRefresh = data['refreshToken'] as String?;
      if (newRefresh != null && newRefresh.isNotEmpty) {
        await storage.saveRefreshToken(newRefresh);
      }
      return _RefreshOutcome.renewed;
    } on DioException catch (e) {
      // Only an actual answer from the server is evidence about the session.
      // A timeout or dead connection must not sign anyone out.
      return e.response == null ? _RefreshOutcome.unreachable : _RefreshOutcome.sessionEnded;
    } catch (_) {
      return _RefreshOutcome.unreachable;
    }
  }

  /// Normalizes any Dio/network failure into a friendly [ApiException],
  /// mirroring the web app's axios response-interceptor message logic.
  static ApiException toApiException(Object err) {
    if (err is ApiException) return err;
    if (err is DioException) {
      if (err.type == DioExceptionType.connectionTimeout ||
          err.type == DioExceptionType.sendTimeout ||
          err.type == DioExceptionType.receiveTimeout) {
        return ApiException('The request timed out. Please check your connection and try again.');
      }
      if (err.type == DioExceptionType.connectionError || err.response == null) {
        return ApiException('Cannot reach the server. Please check your internet connection and try again.');
      }
      final status = err.response?.statusCode;
      final data = err.response?.data;
      String? serverMessage;
      if (data is Map && data['message'] is String) serverMessage = data['message'] as String;
      return ApiException(
        serverMessage ?? _statusMessages[status] ?? 'Something went wrong.',
        statusCode: status,
      );
    }
    return ApiException('Something went wrong. Please try again.');
  }
}

/// Runs [action] and rethrows any failure as a friendly [ApiException] —
/// wrap every repository call in this instead of scattering try/catch.
Future<T> apiCall<T>(Future<T> Function() action) async {
  try {
    return await action();
  } catch (err) {
    throw ApiClient.toApiException(err);
  }
}
