import 'package:dio/dio.dart';

import '../../core/network/api_client.dart';

class PrincipalRepository {
  final _dio = ApiClient.instance.dio;

  Future<Map<String, dynamic>> getDashboard() => apiCall(() async {
        final res = await _dio.get('/principal/dashboard');
        return res.data as Map<String, dynamic>;
      });

  Future<List<Map<String, dynamic>>> getTeachers() => apiCall(() async {
        final res = await _dio.get('/principal/teachers');
        return (res.data as List).cast<Map<String, dynamic>>();
      });

  Future<List<Map<String, dynamic>>> getClasses() => apiCall(() async {
        final res = await _dio.get('/principal/classes');
        return (res.data as List).cast<Map<String, dynamic>>();
      });

  Future<List<Map<String, dynamic>>> getMethodology() => apiCall(() async {
        final res = await _dio.get('/principal/methodology');
        return (res.data as List).cast<Map<String, dynamic>>();
      });

  Future<Map<String, dynamic>> getAttendanceReport({
    required String className,
    String? section,
    required DateTime start,
    required DateTime end,
  }) =>
      apiCall(() async {
        final res = await _dio.get('/principal/attendance-report', queryParameters: {
          'className': className,
          'section': ?section,
          'start': _fmt(start),
          'end': _fmt(end),
        });
        return res.data as Map<String, dynamic>;
      });

  Future<List<int>> downloadAttendanceReportPdf({
    required String className,
    String? section,
    required DateTime start,
    required DateTime end,
  }) =>
      apiCall(() async {
        final res = await _dio.get('/principal/attendance-report/pdf', queryParameters: {
          'className': className,
          'section': ?section,
          'start': _fmt(start),
          'end': _fmt(end),
        }, options: Options(responseType: ResponseType.bytes));
        return res.data as List<int>;
      });

  String _fmt(DateTime d) => '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  Future<Map<String, dynamic>> generateDailyReport() => apiCall(() async {
        final res = await _dio.post('/principal/daily-report');
        return res.data as Map<String, dynamic>;
      });

  Future<List<int>> downloadDailyReportPdf() => apiCall(() async {
        final res = await _dio.post('/principal/daily-report/pdf',
            options: Options(responseType: ResponseType.bytes));
        return res.data as List<int>;
      });

  Future<List<Map<String, dynamic>>> getObservations() => apiCall(() async {
        final res = await _dio.get('/principal/observations');
        return (res.data as List).cast<Map<String, dynamic>>();
      });

  Future<Map<String, dynamic>> createObservation({
    required int teacherId,
    String? className,
    String? section,
    String? date,
    String? notes,
    required Map<String, bool> checklist,
  }) =>
      apiCall(() async {
        final res = await _dio.post('/principal/observations', data: {
          'teacherId': teacherId,
          'className': ?className,
          'section': ?section,
          'date': ?date,
          'notes': ?notes,
          'checklist': checklist,
        });
        return res.data as Map<String, dynamic>;
      });

  // ── Child Parliament Module ──────────────────────────────────────────────

  Future<List<Map<String, dynamic>>> getParliamentTerms() => apiCall(() async {
        final res = await _dio.get('/principal/parliament/terms');
        return (res.data as List).cast<Map<String, dynamic>>();
      });

  Future<Map<String, dynamic>> createParliamentTerm({required String className, String? section, String? monthStart}) => apiCall(() async {
        final res = await _dio.post('/principal/parliament/terms', data: {
          'className': className,
          'section': ?section,
          'monthStart': ?monthStart,
        });
        return res.data as Map<String, dynamic>;
      });

  Future<Map<String, dynamic>> getParliamentTerm(int id) => apiCall(() async {
        final res = await _dio.get('/principal/parliament/terms/$id');
        return res.data as Map<String, dynamic>;
      });

  Future<Map<String, dynamic>> assignParliamentRole({required int termId, required int studentId, required String roleType, String? ministry}) =>
      apiCall(() async {
        final res = await _dio.post('/principal/parliament/terms/$termId/roles', data: {
          'studentId': studentId,
          'roleType': roleType,
          'ministry': ?ministry,
        });
        return res.data as Map<String, dynamic>;
      });

  Future<Map<String, dynamic>> getParliamentSummaryReport() => apiCall(() async {
        final res = await _dio.get('/principal/parliament/summary-report');
        return res.data as Map<String, dynamic>;
      });

  Future<List<int>> downloadParliamentSummaryReportPdf() => apiCall(() async {
        final res = await _dio.get('/principal/parliament/summary-report/pdf', options: Options(responseType: ResponseType.bytes));
        return res.data as List<int>;
      });
}
