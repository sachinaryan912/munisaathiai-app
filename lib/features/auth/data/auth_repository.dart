import 'dart:typed_data';

import 'package:dio/dio.dart';

import '../../../core/network/api_client.dart';
import '../../../models/user.dart';

class AuthRepository {
  final _dio = ApiClient.instance.dio;

  Future<AuthSession> login(String email, String password) => apiCall(() async {
        final res = await _dio.post('/auth/login', data: {'email': email, 'password': password});
        return AuthSession.fromJson(res.data as Map<String, dynamic>);
      });

  Future<AuthSession> register({
    required String fullName,
    required String email,
    required String password,
    required String phone,
    required String role,
    String? schoolName,
    String? className,
    String? section,
    String? designation,
  }) =>
      apiCall(() async {
        final res = await _dio.post('/auth/register', data: {
          'fullName': fullName,
          'email': email,
          'password': password,
          'phone': phone,
          'role': role,
          if (schoolName != null && schoolName.isNotEmpty) 'schoolName': schoolName,
          if (className != null && className.isNotEmpty) 'className': className,
          if (section != null && section.isNotEmpty) 'section': section,
          if (designation != null && designation.isNotEmpty) 'designation': designation,
        });
        return AuthSession.fromJson(res.data as Map<String, dynamic>);
      });

  /// Best-effort server-side revocation of [refreshToken]. Never throws: the local
  /// session is being torn down either way, and a network failure must not leave the
  /// user stuck on a screen they asked to leave.
  Future<void> revokeRefreshToken(String refreshToken) async {
    try {
      await _dio.post('/auth/logout', data: {'refreshToken': refreshToken});
    } catch (_) {
      // Token still expires on its own; nothing useful to tell the user here.
    }
  }

  Future<String> forgotPassword(String email) => apiCall(() async {
        final res = await _dio.post('/auth/forgot-password', data: {'email': email});
        return (res.data as Map<String, dynamic>)['message'] as String? ?? 'OTP sent.';
      });

  Future<String> resetPassword({required String email, required String otp, required String newPassword}) =>
      apiCall(() async {
        final res = await _dio.post('/auth/reset-password', data: {'email': email, 'otp': otp, 'newPassword': newPassword});
        return (res.data as Map<String, dynamic>)['message'] as String? ?? 'Password reset.';
      });

  Future<String> sendVerification(String email) => apiCall(() async {
        final res = await _dio.post('/auth/send-verification', data: {'email': email});
        return (res.data as Map<String, dynamic>)['message'] as String? ?? 'OTP sent.';
      });

  Future<String> verifyEmail({required String email, required String otp}) => apiCall(() async {
        final res = await _dio.post('/auth/verify-email', data: {'email': email, 'otp': otp});
        return (res.data as Map<String, dynamic>)['message'] as String? ?? 'Email verified.';
      });

  Future<List<String>> lookupSchools() => apiCall(() async {
        final res = await _dio.get('/auth/lookup/schools');
        return (res.data as List).cast<String>();
      });

  Future<List<String>> lookupClasses(String schoolName) => apiCall(() async {
        final res = await _dio.get('/auth/lookup/classes', queryParameters: {'schoolName': schoolName});
        return (res.data as List).cast<String>();
      });

  Future<List<String>> lookupSections(String schoolName, String className) => apiCall(() async {
        final res = await _dio.get('/auth/lookup/sections', queryParameters: {'schoolName': schoolName, 'className': className});
        return (res.data as List).cast<String>();
      });

  Future<AppUser> getMe() => apiCall(() async {
        final res = await _dio.get('/users/me');
        return AppUser.fromJson(res.data as Map<String, dynamic>);
      });

  Future<AppUser> updateMe({String? fullName, String? phone}) => apiCall(() async {
        final res = await _dio.put('/users/me', data: {
          'fullName': ?fullName,
          'phone': ?phone,
        });
        return AppUser.fromJson(res.data as Map<String, dynamic>);
      });

  // ── Profile photo ────────────────────────────────────────────────────────

  Future<AppUser> uploadProfileImage(Uint8List bytes) => apiCall(() async {
        final form = FormData.fromMap({
          // Compression always emits JPEG, and the backend validates the content type,
          // so both are stated explicitly rather than guessed from a file extension.
          'file': MultipartFile.fromBytes(
            bytes,
            filename: 'avatar.jpg',
            contentType: DioMediaType('image', 'jpeg'),
          ),
        });
        final res = await _dio.post('/users/me/photo', data: form);
        return AppUser.fromJson(res.data as Map<String, dynamic>);
      });

  Future<AppUser> deleteProfileImage() => apiCall(() async {
        final res = await _dio.delete('/users/me/photo');
        return AppUser.fromJson(res.data as Map<String, dynamic>);
      });

  Future<Uint8List> fetchProfileImage() => apiCall(() async {
        final res = await _dio.get<List<int>>(
          '/users/me/photo',
          options: Options(responseType: ResponseType.bytes),
        );
        return Uint8List.fromList(res.data ?? const []);
      });

  /// Returns a fresh session. Changing the password revokes every refresh token on
  /// the account (including this device's), so the new pair in the response has to
  /// replace what's in storage or the app signs itself out at the next refresh.
  Future<AuthSession> changePassword({
    required String currentPassword,
    required String newPassword,
  }) =>
      apiCall(() async {
        final res = await _dio.post('/users/me/password', data: {
          'currentPassword': currentPassword,
          'newPassword': newPassword,
        });
        return AuthSession.fromJson(res.data as Map<String, dynamic>);
      });
}
