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

  Future<List<Map<String, dynamic>>> getSchoolClasses(int schoolId) => apiCall(() async {
        final res = await _dio.get('/management/schools/$schoolId/classes');
        return (res.data as List).cast<Map<String, dynamic>>();
      });

  Future<List<Map<String, dynamic>>> getSchoolTeachersDrillDown(int schoolId) => apiCall(() async {
        final res = await _dio.get('/management/schools/$schoolId/teachers');
        return (res.data as List).cast<Map<String, dynamic>>();
      });

  // ── Class/Section Catalog ────────────────────────────────────────────────

  Future<List<Map<String, dynamic>>> getClassCatalog(int schoolId) => apiCall(() async {
        final res = await _dio.get('/management/schools/$schoolId/class-catalog');
        return (res.data as List).cast<Map<String, dynamic>>();
      });

  Future<Map<String, dynamic>> addClassCatalogEntry(int schoolId, {required String className, String? section}) => apiCall(() async {
        final res = await _dio.post('/management/schools/$schoolId/class-catalog', data: {
          'className': className,
          'section': ?section,
        });
        return res.data as Map<String, dynamic>;
      });

  Future<void> deleteClassCatalogEntry(int schoolId, int entryId) => apiCall(() async {
        await _dio.delete('/management/schools/$schoolId/class-catalog/$entryId');
      });

  Future<Map<String, dynamic>> getTrainerDetail(int trainerId) => apiCall(() async {
        final res = await _dio.get('/management/trainers/$trainerId');
        return res.data as Map<String, dynamic>;
      });

  Future<List<Map<String, dynamic>>> getAuditLog() => apiCall(() async {
        final res = await _dio.get('/management/audit-log');
        return (res.data as List).cast<Map<String, dynamic>>();
      });

  Future<Map<String, dynamic>> getThresholds() => apiCall(() async {
        final res = await _dio.get('/management/settings/thresholds');
        return res.data as Map<String, dynamic>;
      });

  Future<Map<String, dynamic>> updateThresholds(Map<String, dynamic> patch) => apiCall(() async {
        final res = await _dio.put('/management/settings/thresholds', data: patch);
        return res.data as Map<String, dynamic>;
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

  Future<Map<String, dynamic>> getWeeklyTrainerReport() => apiCall(() async {
        final res = await _dio.get('/management/reports/weekly-trainer');
        return res.data as Map<String, dynamic>;
      });

  Future<List<int>> downloadWeeklyTrainerReportPdf() => apiCall(() async {
        final res = await _dio.get('/management/reports/weekly-trainer/pdf', options: Options(responseType: ResponseType.bytes));
        return res.data as List<int>;
      });

  Future<Map<String, dynamic>> getMonthlySchoolReport() => apiCall(() async {
        final res = await _dio.get('/management/reports/monthly-school');
        return res.data as Map<String, dynamic>;
      });

  Future<List<int>> downloadMonthlySchoolReportPdf() => apiCall(() async {
        final res = await _dio.get('/management/reports/monthly-school/pdf', options: Options(responseType: ResponseType.bytes));
        return res.data as List<int>;
      });

  Future<Map<String, dynamic>> getStudentProgressReport() => apiCall(() async {
        final res = await _dio.get('/management/reports/student-progress');
        return res.data as Map<String, dynamic>;
      });

  Future<List<int>> downloadStudentProgressReportPdf() => apiCall(() async {
        final res = await _dio.get('/management/reports/student-progress/pdf', options: Options(responseType: ResponseType.bytes));
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

  // ── Vidya AI knowledge notes ─────────────────────────────────────────────
  Future<List<Map<String, dynamic>>> getKnowledgeNotes() => apiCall(() async {
        final res = await _dio.get('/management/knowledge-notes');
        return (res.data as List).cast<Map<String, dynamic>>();
      });

  Future<Map<String, dynamic>> addKnowledgeNote(String title, String content) => apiCall(() async {
        final res = await _dio.post('/management/knowledge-notes', data: {'title': title, 'content': content});
        return res.data as Map<String, dynamic>;
      });

  Future<Map<String, dynamic>> updateKnowledgeNote(int id, String title, String content) => apiCall(() async {
        final res = await _dio.put('/management/knowledge-notes/$id', data: {'title': title, 'content': content});
        return res.data as Map<String, dynamic>;
      });

  Future<Map<String, dynamic>> setKnowledgeNoteActive(int id, bool active) => apiCall(() async {
        final res = await _dio.patch('/management/knowledge-notes/$id/active', data: {'active': active});
        return res.data as Map<String, dynamic>;
      });

  Future<void> deleteKnowledgeNote(int id) => apiCall(() async {
        await _dio.delete('/management/knowledge-notes/$id');
      });

  // ── Vidya AI knowledge base — full view/edit ─────────────────────────────
  Future<Map<String, dynamic>> getKnowledgeBase() => apiCall(() async {
        final res = await _dio.get('/management/knowledge-base');
        return res.data as Map<String, dynamic>;
      });

  Future<Map<String, dynamic>> updateKnowledgeBase(String content) => apiCall(() async {
        final res = await _dio.put('/management/knowledge-base', data: {'content': content});
        return res.data as Map<String, dynamic>;
      });

  Future<Map<String, dynamic>> resetKnowledgeBase() => apiCall(() async {
        final res = await _dio.post('/management/knowledge-base/reset');
        return res.data as Map<String, dynamic>;
      });
}
