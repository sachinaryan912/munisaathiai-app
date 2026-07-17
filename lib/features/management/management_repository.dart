import 'package:dio/dio.dart';

import '../../core/network/api_client.dart';

class ManagementRepository {
  final _dio = ApiClient.instance.dio;

  // ── Overview ─────────────────────────────────────────────────────────────
  Future<Map<String, dynamic>> getOverview() => apiCall(() async {
        final res = await _dio.get('/management/overview');
        return res.data as Map<String, dynamic>;
      });

  // ── Schools ──────────────────────────────────────────────────────────────
  Future<Map<String, dynamic>> getSchool(int id) => apiCall(() async {
        final res = await _dio.get('/management/schools/$id');
        return res.data as Map<String, dynamic>;
      });

  Future<Map<String, dynamic>> addSchool(Map<String, dynamic> payload) => apiCall(() async {
        final res = await _dio.post('/management/schools', data: payload);
        return res.data as Map<String, dynamic>;
      });

  Future<Map<String, dynamic>> updateSchool(int id, Map<String, dynamic> payload) => apiCall(() async {
        final res = await _dio.put('/management/schools/$id', data: payload);
        return res.data as Map<String, dynamic>;
      });

  Future<void> deleteSchool(int id) => apiCall(() async {
        await _dio.delete('/management/schools/$id');
      });

  Future<Map<String, dynamic>> assignTrainer(int schoolId, int trainerId) => apiCall(() async {
        final res = await _dio.post('/management/schools/$schoolId/assign-trainer', data: {'trainerId': trainerId});
        return res.data as Map<String, dynamic>;
      });

  Future<Map<String, dynamic>> recomputeMii(int schoolId) => apiCall(() async {
        final res = await _dio.post('/management/schools/$schoolId/recompute-mii');
        return res.data as Map<String, dynamic>;
      });

  Future<List<Map<String, dynamic>>> getMiiHistory(int schoolId) => apiCall(() async {
        final res = await _dio.get('/management/schools/$schoolId/mii-history');
        return (res.data as List).cast<Map<String, dynamic>>();
      });

  Future<List<Map<String, dynamic>>> getSchoolTrainingSessions(int schoolId) => apiCall(() async {
        final res = await _dio.get('/management/schools/$schoolId/training-sessions');
        return (res.data as List).cast<Map<String, dynamic>>();
      });

  // ── Trainers / training / certifications ────────────────────────────────
  Future<List<Map<String, dynamic>>> getTrainerRoster() => apiCall(() async {
        final res = await _dio.get('/management/trainers');
        return (res.data as List).cast<Map<String, dynamic>>();
      });

  Future<List<Map<String, dynamic>>> getNetworkTrainingSessions() => apiCall(() async {
        final res = await _dio.get('/management/training-sessions');
        return (res.data as List).cast<Map<String, dynamic>>();
      });

  Future<List<Map<String, dynamic>>> getCertifications() => apiCall(() async {
        final res = await _dio.get('/management/certifications');
        return (res.data as List).cast<Map<String, dynamic>>();
      });

  // ── AI ───────────────────────────────────────────────────────────────────
  Future<Map<String, dynamic>> generateMonitoringInsights() => apiCall(() async {
        final res = await _dio.post('/management/ai/monitoring-insights');
        return res.data as Map<String, dynamic>;
      });

  Future<Map<String, dynamic>> generateNetworkReport() => apiCall(() async {
        final res = await _dio.post('/management/ai/network-report');
        return res.data as Map<String, dynamic>;
      });

  Future<List<int>> downloadMonitoringInsightsPdf() => apiCall(() async {
        final res = await _dio.post('/management/ai/monitoring-insights/pdf',
            options: Options(responseType: ResponseType.bytes));
        return res.data as List<int>;
      });

  Future<List<int>> downloadNetworkReportPdf() => apiCall(() async {
        final res = await _dio.post('/management/ai/network-report/pdf',
            options: Options(responseType: ResponseType.bytes));
        return res.data as List<int>;
      });

  // ── Users ────────────────────────────────────────────────────────────────
  Future<List<Map<String, dynamic>>> getUsers() => apiCall(() async {
        final res = await _dio.get('/management/users');
        return (res.data as List).cast<Map<String, dynamic>>();
      });

  Future<Map<String, dynamic>> blockUser(int id) => apiCall(() async {
        final res = await _dio.post('/management/users/$id/block');
        return res.data as Map<String, dynamic>;
      });

  Future<Map<String, dynamic>> unblockUser(int id) => apiCall(() async {
        final res = await _dio.post('/management/users/$id/unblock');
        return res.data as Map<String, dynamic>;
      });

  Future<Map<String, dynamic>> updateUser(int id, Map<String, dynamic> patch) => apiCall(() async {
        final res = await _dio.put('/management/users/$id', data: patch);
        return res.data as Map<String, dynamic>;
      });

  Future<Map<String, dynamic>> resetPassword(int id, String newPassword) => apiCall(() async {
        final res = await _dio.post('/management/users/$id/reset-password', data: {'newPassword': newPassword});
        return res.data as Map<String, dynamic>;
      });

  Future<Map<String, dynamic>> createUser(Map<String, dynamic> payload) => apiCall(() async {
        final res = await _dio.post('/management/users', data: payload);
        return res.data as Map<String, dynamic>;
      });
}
