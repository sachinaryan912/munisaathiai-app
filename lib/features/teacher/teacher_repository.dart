import 'dart:io';
import 'package:dio/dio.dart';
import '../../core/network/api_client.dart';

class TeacherRepository {
  final _dio = ApiClient.instance.dio;

  Future<List<Map<String, dynamic>>> getClass({String? date}) => apiCall(() async {
        final res = await _dio.get('/teacher/class', queryParameters: {'date': ?date});
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

  Future<List<Map<String, dynamic>>> getBuddyGroups() => apiCall(() async {
        final res = await _dio.get('/teacher/buddy-groups');
        return (res.data as List).cast<Map<String, dynamic>>();
      });

  Future<Map<String, dynamic>> createBuddyGroup(List<int> studentIds) => apiCall(() async {
        final res = await _dio.post('/teacher/buddy-groups', data: {'studentIds': studentIds});
        return res.data as Map<String, dynamic>;
      });

  Future<Map<String, dynamic>> addToBuddyGroup({required int groupId, required int studentId}) => apiCall(() async {
        final res = await _dio.post('/teacher/buddy-groups/$groupId/members', data: {'studentId': studentId});
        return res.data as Map<String, dynamic>;
      });

  Future<void> removeFromBuddyGroup({required int groupId, required int studentId}) => apiCall(() async {
        await _dio.delete('/teacher/buddy-groups/$groupId/members/$studentId');
      });

  Future<List<Map<String, dynamic>>> getPeerTeachingForReview() => apiCall(() async {
        final res = await _dio.get('/teacher/peer-teaching');
        return (res.data as List).cast<Map<String, dynamic>>();
      });

  Future<Map<String, dynamic>> reviewPeerTeaching({required int id, required String feedback, required int stars}) => apiCall(() async {
        final res = await _dio.post('/teacher/peer-teaching/$id/review', data: {'feedback': feedback, 'stars': stars});
        return res.data as Map<String, dynamic>;
      });

  Future<Map<String, dynamic>> getDashboard() => apiCall(() async {
        final res = await _dio.get('/teacher/dashboard');
        return res.data as Map<String, dynamic>;
      });

  Future<Map<String, dynamic>> generateDailyReport() => apiCall(() async {
        final res = await _dio.post('/teacher/daily-report');
        return res.data as Map<String, dynamic>;
      });

  Future<Map<String, dynamic>> getDailyReport({String? date}) => apiCall(() async {
        final res = await _dio.get('/teacher/daily-report', queryParameters: {'date': ?date});
        return res.data as Map<String, dynamic>;
      });

  Future<List<Map<String, dynamic>>> getDailyReportHistory() => apiCall(() async {
        final res = await _dio.get('/teacher/daily-reports');
        return (res.data as List).cast<Map<String, dynamic>>();
      });

  Future<List<String>> getMethodologies() => apiCall(() async {
        final res = await _dio.get('/teacher/methodologies');
        return (res.data as List).cast<String>();
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

  Future<List<Map<String, dynamic>>> getCommunityAssessmentVisits() => apiCall(() async {
        final res = await _dio.get('/teacher/community-assessment');
        return (res.data as List).cast<Map<String, dynamic>>();
      });

  Future<void> logCommunityAssessmentVisit({required int studentId, String? habitsNotes, String? understandingNotes, String? otherNotes}) => apiCall(() async {
        await _dio.post('/teacher/community-assessment', data: {
          'studentId': studentId,
          'habitsNotes': ?habitsNotes,
          'understandingNotes': ?understandingNotes,
          'otherNotes': ?otherNotes,
        });
      });

  Future<List<Map<String, dynamic>>> getCenterWorkEntries() => apiCall(() async {
        final res = await _dio.get('/teacher/center-work');
        return (res.data as List).cast<Map<String, dynamic>>();
      });

  Future<void> logCenterWork({
    required String topic,
    String? researchCreativityNotes,
    String? constructionNotes,
    String? mathScienceNotes,
    String? rolePlayNotes,
    String? abcLanguageNotes,
  }) =>
      apiCall(() async {
        await _dio.post('/teacher/center-work', data: {
          'topic': topic,
          'researchCreativityNotes': ?researchCreativityNotes,
          'constructionNotes': ?constructionNotes,
          'mathScienceNotes': ?mathScienceNotes,
          'rolePlayNotes': ?rolePlayNotes,
          'abcLanguageNotes': ?abcLanguageNotes,
        });
      });

  Future<List<Map<String, dynamic>>> getValuesDiscussionLogs() => apiCall(() async {
        final res = await _dio.get('/teacher/values-discussion');
        return (res.data as List).cast<Map<String, dynamic>>();
      });

  Future<void> logValuesDiscussion({required String valueTopic, String? notes}) => apiCall(() async {
        await _dio.post('/teacher/values-discussion', data: {'valueTopic': valueTopic, 'notes': ?notes});
      });

  Future<List<Map<String, dynamic>>> getOathRecords() => apiCall(() async {
        final res = await _dio.get('/teacher/oath');
        return (res.data as List).cast<Map<String, dynamic>>();
      });

  Future<void> markOathRecited() => apiCall(() async {
        await _dio.post('/teacher/oath/recite');
      });

  Future<List<Map<String, dynamic>>> getPeerExamEvaluations() => apiCall(() async {
        final res = await _dio.get('/teacher/peer-exam-evaluations');
        return (res.data as List).cast<Map<String, dynamic>>();
      });

  Future<void> logPeerExamEvaluation({required int studentId, required String examName, required String pattern, required double avgScore}) => apiCall(() async {
        await _dio.post('/teacher/peer-exam-evaluations', data: {'studentId': studentId, 'examName': examName, 'pattern': pattern, 'avgScore': avgScore});
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
    String? sambandh,
    String? vyavastha,
    String? sahAstitva,
  }) =>
      apiCall(() async {
        final res = await _dio.post('/teacher/lesson-plans', data: {
          'subject': subject,
          'topic': topic,
          'objectives': ?objectives,
          'date': date,
          'durationMinutes': durationMinutes,
          'linkedMethodologies': linkedMethodologies,
          'sambandh': ?sambandh,
          'vyavastha': ?vyavastha,
          'sahAstitva': ?sahAstitva,
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
