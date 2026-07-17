import 'dart:io';
import 'package:dio/dio.dart';
import '../../core/network/api_client.dart';

class TeacherRepository {
  final _dio = ApiClient.instance.dio;

  Future<List<Map<String, dynamic>>> getClass() => apiCall(() async {
        final res = await _dio.get('/teacher/class');
        return (res.data as List).cast<Map<String, dynamic>>();
      });

  Future<void> markAttendance({required int studentId, String? date, required bool present}) => apiCall(() async {
        await _dio.post('/teacher/attendance', data: {'studentId': studentId, 'date': ?date, 'present': present});
      });

  Future<List<Map<String, dynamic>>> getNotes(int studentId) => apiCall(() async {
        final res = await _dio.get('/teacher/notes/$studentId');
        return (res.data as List).cast<Map<String, dynamic>>();
      });

  Future<Map<String, dynamic>> addNote({required int studentId, required String content}) => apiCall(() async {
        final res = await _dio.post('/teacher/notes', data: {'studentId': studentId.toString(), 'content': content});
        return res.data as Map<String, dynamic>;
      });

  Future<void> assignBuddy({required int studentAId, required int studentBId}) => apiCall(() async {
        await _dio.post('/teacher/buddy/assign', data: {'studentAId': studentAId, 'studentBId': studentBId});
      });

  Future<void> unassignBuddy(int studentId) => apiCall(() async {
        await _dio.post('/teacher/buddy/unassign/$studentId');
      });

  Future<Map<String, dynamic>> getDashboard() => apiCall(() async {
        final res = await _dio.get('/teacher/dashboard');
        return res.data as Map<String, dynamic>;
      });

  Future<Map<String, dynamic>> generateDailyReport() => apiCall(() async {
        final res = await _dio.post('/teacher/daily-report');
        return res.data as Map<String, dynamic>;
      });

  Future<List<Map<String, dynamic>>> getMethodology({String? date}) => apiCall(() async {
        final res = await _dio.get('/teacher/methodology', queryParameters: {'date': ?date});
        return (res.data as List).cast<Map<String, dynamic>>();
      });

  Future<Map<String, dynamic>> setMethodology({required String methodology, String? date, bool? implemented, String? remarks}) => apiCall(() async {
        final res = await _dio.post('/teacher/methodology', data: {
          'methodology': methodology,
          'date': ?date,
          'implemented': ?implemented,
          'remarks': ?remarks,
        });
        return res.data as Map<String, dynamic>;
      });

  Future<List<Map<String, dynamic>>> getEvidence() => apiCall(() async {
        final res = await _dio.get('/teacher/evidence');
        return (res.data as List).cast<Map<String, dynamic>>();
      });

  Future<Map<String, dynamic>> uploadEvidence({required String methodology, required File file}) => apiCall(() async {
        final form = FormData.fromMap({
          'methodology': methodology,
          'file': await MultipartFile.fromFile(file.path, filename: file.path.split(Platform.pathSeparator).last),
        });
        final res = await _dio.post('/teacher/evidence', data: form);
        return res.data as Map<String, dynamic>;
      });

  Future<Map<String, dynamic>> analyzeEvidence(int id) => apiCall(() async {
        final res = await _dio.post('/teacher/evidence/$id/analyze');
        return res.data as Map<String, dynamic>;
      });

  Future<List<int>> getEvidenceFile(int id) => apiCall(() async {
        final res = await _dio.get<List<int>>('/teacher/evidence/$id/file', options: Options(responseType: ResponseType.bytes));
        return res.data!;
      });

  Future<List<Map<String, dynamic>>> getLessonPlans() => apiCall(() async {
        final res = await _dio.get('/teacher/lesson-plans');
        return (res.data as List).cast<Map<String, dynamic>>();
      });

  Future<Map<String, dynamic>> createLessonPlan({
    required String subject,
    required String topic,
    String? objectives,
    required String date,
    int durationMinutes = 40,
    List<String> linkedMethodologies = const [],
  }) =>
      apiCall(() async {
        final res = await _dio.post('/teacher/lesson-plans', data: {
          'subject': subject,
          'topic': topic,
          'objectives': ?objectives,
          'date': date,
          'durationMinutes': durationMinutes,
          'linkedMethodologies': linkedMethodologies,
        });
        return res.data as Map<String, dynamic>;
      });

  Future<Map<String, dynamic>> setLessonPlanStatus(int id, String status) => apiCall(() async {
        final res = await _dio.post('/teacher/lesson-plans/$id/status', data: {'status': status});
        return res.data as Map<String, dynamic>;
      });

  Future<void> deleteLessonPlan(int id) => apiCall(() async {
        await _dio.delete('/teacher/lesson-plans/$id');
      });

  Future<Map<String, dynamic>> getReflection(String weekStartDate) => apiCall(() async {
        final res = await _dio.get('/teacher/reflection', queryParameters: {'weekStartDate': weekStartDate});
        return res.data as Map<String, dynamic>;
      });

  Future<List<Map<String, dynamic>>> getReflections() => apiCall(() async {
        final res = await _dio.get('/teacher/reflections');
        return (res.data as List).cast<Map<String, dynamic>>();
      });

  Future<Map<String, dynamic>> saveReflection({required String weekStartDate, required String content}) => apiCall(() async {
        final res = await _dio.post('/teacher/reflection', data: {'weekStartDate': weekStartDate, 'content': content});
        return res.data as Map<String, dynamic>;
      });

  // ── Child Parliament Module ──────────────────────────────────────────────

  Future<List<Map<String, dynamic>>> getParliamentMeetings() => apiCall(() async {
        final res = await _dio.get('/teacher/parliament/meetings');
        return (res.data as List).cast<Map<String, dynamic>>();
      });

  Future<Map<String, dynamic>> logParliamentMeeting({String? date, required String agenda, String? minutes}) => apiCall(() async {
        final res = await _dio.post('/teacher/parliament/meetings', data: {
          'date': ?date,
          'agenda': agenda,
          'minutes': ?minutes,
        });
        return res.data as Map<String, dynamic>;
      });

  Future<List<Map<String, dynamic>>> getParliamentActivities() => apiCall(() async {
        final res = await _dio.get('/teacher/parliament/activities');
        return (res.data as List).cast<Map<String, dynamic>>();
      });

  Future<Map<String, dynamic>> logParliamentActivity({int? studentId, required String description, String? date}) => apiCall(() async {
        final res = await _dio.post('/teacher/parliament/activities', data: {
          'studentId': ?studentId,
          'description': description,
          'date': ?date,
        });
        return res.data as Map<String, dynamic>;
      });
}
