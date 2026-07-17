import 'package:dio/dio.dart';
import '../storage/secure_storage.dart';
import 'api_exception.dart';

/// Default points at the same Cloud Run backend the web app's Capacitor build
/// uses (muni-saathi-ai-frontend/.env.capacitor) — override at build time with
/// `--dart-define=API_BASE_URL=...` for local backend testing against an
/// emulator (`http://10.0.2.2:8080/api`).
const _defaultBaseUrl = 'https://munisaathiai-backend-201037794520.asia-south1.run.app/api';
const _apiBaseUrl = String.fromEnvironment('API_BASE_URL', defaultValue: _defaultBaseUrl);

const _statusMessages = <int, String>{
  400: 'Invalid request. Please check your details.',
  401: 'Session expired. Please sign in again.',
  403: 'Access denied.',
  404: 'Resource not found.',
  500: 'Server error. Please try again later.',
};

class ApiClient {
  ApiClient._();
  static final ApiClient instance = ApiClient._();

  /// Set by AuthProvider at startup so a 401 anywhere can force a clean logout
  /// + redirect to login, without this layer depending on app-level state.
  void Function()? onUnauthorized;

  late final Dio dio = _build();

  Dio _build() {
    final d = Dio(BaseOptions(
      baseUrl: _apiBaseUrl,
      connectTimeout: const Duration(seconds: 20),
      receiveTimeout: const Duration(seconds: 25),
      sendTimeout: const Duration(seconds: 30),
    ));

    d.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        final token = await SecureStorage.instance.readToken();
        if (token != null && token.isNotEmpty) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        handler.next(options);
      },
      onError: (error, handler) {
        if (error.response?.statusCode == 401) {
          onUnauthorized?.call();
        }
        handler.next(error);
      },
    ));

    return d;
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
