/// A user-facing error message extracted from a failed API call — mirrors the
/// message-normalization logic in the web app's `src/utils/api.js` interceptor.
class ApiException implements Exception {
  final String message;
  final int? statusCode;

  ApiException(this.message, {this.statusCode});

  @override
  String toString() => message;
}
