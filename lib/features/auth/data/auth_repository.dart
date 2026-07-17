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

  Future<void> changePassword({required String currentPassword, required String newPassword}) => apiCall(() async {
        await _dio.post('/users/me/password', data: {'currentPassword': currentPassword, 'newPassword': newPassword});
      });
}
