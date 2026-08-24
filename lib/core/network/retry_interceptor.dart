import 'package:dio/dio.dart';

/// Prepares [options] to be sent a second time.
///
/// A [FormData] body (evidence/assignment uploads) is a one-shot stream — resending
/// the same instance would transmit an empty body, turning a retriable network blip
/// into a silently corrupt upload. `clone()` gives each attempt its own copy.
RequestOptions prepareForReplay(RequestOptions options) {
  final data = options.data;
  if (data is FormData) options.data = data.clone();
  return options;
}

/// Retries a request when the backend simply wasn't reachable.
///
/// Motivated by Cloud Run cold starts: when the service has scaled to zero, the first
/// request after an idle period can fail outright before the container is up, which the
/// user experiences as a random "cannot reach the server" on an app that works fine a
/// moment later.
///
/// Total attempts are capped at [maxAttempts] (3 = the original try plus 2 retries).
class RetryInterceptor extends Interceptor {
  RetryInterceptor({this.maxAttempts = 3});

  final int maxAttempts;

  /// Attempt counter, carried on the request so a retry that re-enters this
  /// interceptor continues the count instead of restarting it.
  static const _attemptKey = 'muni_retry_attempt';

  static const _backoff = <Duration>[
    Duration(milliseconds: 500),
    Duration(milliseconds: 1500),
  ];

  final Dio _retryDio = Dio();

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    final attempt = err.requestOptions.extra[_attemptKey] as int? ?? 1;

    if (attempt >= maxAttempts || !_isRetriable(err)) {
      handler.next(err);
      return;
    }

    await Future<void>.delayed(_backoff[(attempt - 1).clamp(0, _backoff.length - 1)]);

    final options = err.requestOptions;
    options.extra[_attemptKey] = attempt + 1;

    try {
      // Sent through a bare Dio rather than re-entering the owning client, so a
      // retry replays exactly this request instead of re-running interceptors that
      // have already done their work (token attach, refresh-on-401) for it.
      handler.resolve(await _retryDio.fetch<dynamic>(prepareForReplay(options)));
    } on DioException catch (e) {
      handler.next(e);
    }
  }

  bool _isRetriable(DioException err) {
    switch (err.type) {
      case DioExceptionType.connectionError:
      case DioExceptionType.connectionTimeout:
        // No connection was established, so the request provably never ran on the
        // server. Safe to repeat regardless of HTTP method.
        return true;
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
      case DioExceptionType.badResponse:
        // Here the server may well have processed the request — only repeat it if
        // doing so twice is harmless. Notably this keeps POSTs out: retrying
        // /auth/forgot-password on the backend's 503 would fire duplicate OTP emails,
        // and retrying /auth/register could create a second account.
        return _isIdempotent(err.requestOptions.method) && _isTransientStatus(err);
      default:
        return false;
    }
  }

  bool _isIdempotent(String method) {
    final m = method.toUpperCase();
    return m == 'GET' || m == 'HEAD';
  }

  bool _isTransientStatus(DioException err) {
    if (err.type != DioExceptionType.badResponse) return true; // a GET timeout
    final code = err.response?.statusCode ?? 0;
    return code == 502 || code == 503 || code == 504;
  }
}
