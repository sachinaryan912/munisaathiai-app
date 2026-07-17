import 'package:dio/dio.dart';

import '../../core/network/api_client.dart';

class TrainerRepository {
  final _dio = ApiClient.instance.dio;

  Future<List<Map<String, dynamic>>> getSchools() => apiCall(() async {
        final res = await _dio.get('/trainer/schools');
        return (res.data as List).cast<Map<String, dynamic>>();
      });

  Future<Map<String, dynamic>> getDashboard() => apiCall(() async {
        final res = await _dio.get('/trainer/dashboard');
        return res.data as Map<String, dynamic>;
      });

  Future<List<Map<String, dynamic>>> getTeachers({int? schoolId}) => apiCall(() async {
        final res = await _dio.get('/trainer/teachers', queryParameters: {'schoolId': ?schoolId});
        return (res.data as List).cast<Map<String, dynamic>>();
      });

  Future<List<Map<String, dynamic>>> getMethodology({int? schoolId}) => apiCall(() async {
        final res = await _dio.get('/trainer/methodology', queryParameters: {'schoolId': ?schoolId});
        return (res.data as List).cast<Map<String, dynamic>>();
      });

  Future<List<Map<String, dynamic>>> getAlerts() => apiCall(() async {
        final res = await _dio.get('/trainer/alerts');
        return (res.data as List).cast<Map<String, dynamic>>();
      });

  Future<List<Map<String, dynamic>>> getObservations() => apiCall(() async {
        final res = await _dio.get('/trainer/observations');
        return (res.data as List).cast<Map<String, dynamic>>();
      });

  Future<Map<String, dynamic>> createObservation({
    required int teacherId,
    required int schoolId,
    String? className,
    String? section,
    String? date,
    String? notes,
    required Map<String, bool> checklist,
  }) =>
      apiCall(() async {
        final res = await _dio.post('/trainer/observations', data: {
          'teacherId': teacherId,
          'schoolId': schoolId,
          'className': ?className,
          'section': ?section,
          'date': ?date,
          'notes': ?notes,
          'checklist': checklist,
        });
        return res.data as Map<String, dynamic>;
      });

  Future<List<Map<String, dynamic>>> getEvidenceQueue() => apiCall(() async {
        final res = await _dio.get('/trainer/evidence');
        return (res.data as List).cast<Map<String, dynamic>>();
      });

  Future<Map<String, dynamic>> verifyEvidence(int id, bool verified) => apiCall(() async {
        final res = await _dio.post('/trainer/evidence/$id/verify', data: {'verified': verified});
        return res.data as Map<String, dynamic>;
      });

  Future<List<Map<String, dynamic>>> getSessions() => apiCall(() async {
        final res = await _dio.get('/trainer/training-sessions');
        return (res.data as List).cast<Map<String, dynamic>>();
      });

  Future<Map<String, dynamic>> createSession({
    required int schoolId,
    required String topic,
    String? date,
    String? venue,
    String mode = 'On-site',
    String? notes,
  }) =>
      apiCall(() async {
        final res = await _dio.post('/trainer/training-sessions', data: {
          'schoolId': schoolId,
          'topic': topic,
          'date': ?date,
          'venue': ?venue,
          'mode': mode,
          'notes': ?notes,
        });
        return res.data as Map<String, dynamic>;
      });

  Future<Map<String, dynamic>> getSessionDetail(int id) => apiCall(() async {
        final res = await _dio.get('/trainer/training-sessions/$id');
        return res.data as Map<String, dynamic>;
      });

  Future<Map<String, dynamic>> recordAttendance({
    required int sessionId,
    required int teacherId,
    bool? attended,
    int? preTestScore,
    int? postTestScore,
    bool? certified,
    String? feedback,
    int? rating,
  }) =>
      apiCall(() async {
        final res = await _dio.post('/trainer/training-sessions/$sessionId/attendance', data: {
          'teacherId': teacherId,
          'attended': ?attended,
          'preTestScore': ?preTestScore,
          'postTestScore': ?postTestScore,
          'certified': ?certified,
          'feedback': ?feedback,
          'rating': ?rating,
        });
        return res.data as Map<String, dynamic>;
      });

  Future<Map<String, dynamic>> getReportsSummary() => apiCall(() async {
        final res = await _dio.get('/trainer/reports/summary');
        return res.data as Map<String, dynamic>;
      });

  Future<Map<String, dynamic>> generateTrainingPlan() => apiCall(() async {
        final res = await _dio.post('/trainer/ai/training-plan');
        return res.data as Map<String, dynamic>;
      });

  Future<Map<String, dynamic>> generateTeacherFeedback(int teacherId) => apiCall(() async {
        final res = await _dio.post('/trainer/ai/teacher-feedback/$teacherId');
        return res.data as Map<String, dynamic>;
      });

  Future<Map<String, dynamic>> generateWhatsappReminder(int sessionId) => apiCall(() async {
        final res = await _dio.post('/trainer/ai/whatsapp-reminder/$sessionId');
        return res.data as Map<String, dynamic>;
      });

  Future<Map<String, dynamic>> generateMonthlyReport() => apiCall(() async {
        final res = await _dio.post('/trainer/ai/monthly-report');
        return res.data as Map<String, dynamic>;
      });

  Future<List<int>> downloadMonthlyReportPdf() => apiCall(() async {
        final res = await _dio.post('/trainer/ai/monthly-report/pdf',
            options: Options(responseType: ResponseType.bytes));
        return res.data as List<int>;
      });
}
