import 'dart:io';
import 'package:dio/dio.dart';
import '../../core/network/api_client.dart';

class StudentRepository {
  final _dio = ApiClient.instance.dio;

  Future<Map<String, dynamic>> getDashboard() => apiCall(() async {
        final res = await _dio.get('/student/dashboard');
        return res.data as Map<String, dynamic>;
      });

  Future<Map<String, dynamic>> getProgress() => apiCall(() async {
        final res = await _dio.get('/student/progress');
        return res.data as Map<String, dynamic>;
      });

  Future<Map<String, dynamic>> getBuddy() => apiCall(() async {
        final res = await _dio.get('/student/buddy');
        return res.data as Map<String, dynamic>;
      });

  Future<Map<String, dynamic>> logBuddySession({required String topic, int duration = 30, bool helped = true, String? peerReflection, int? buddyRating}) =>
      apiCall(() async {
        final res = await _dio.post('/student/buddy/session', data: {
          'topic': topic,
          'duration': duration,
          'helped': helped,
          'peerReflection': ?peerReflection,
          'buddyRating': ?buddyRating,
        });
        return res.data as Map<String, dynamic>;
      });

  Future<Map<String, dynamic>> toggleActivity(int id) => apiCall(() async {
        final res = await _dio.post('/student/buddy/activity/toggle/$id');
        return res.data as Map<String, dynamic>;
      });

  Future<List<Map<String, dynamic>>> getStudyModules() => apiCall(() async {
        final res = await _dio.get('/student/study');
        return (res.data as List).cast<Map<String, dynamic>>();
      });

  Future<Map<String, dynamic>> updateStudyProgress({required int moduleId, required int done}) => apiCall(() async {
        final res = await _dio.post('/student/study/progress', data: {'moduleId': moduleId, 'done': done});
        return res.data as Map<String, dynamic>;
      });

  Future<List<Map<String, dynamic>>> getPeerTeaching() => apiCall(() async {
        final res = await _dio.get('/student/peer-teaching');
        return (res.data as List).cast<Map<String, dynamic>>();
      });

  Future<Map<String, dynamic>> logPeerTeaching({required String topic, int studentCount = 1, String? reflection}) => apiCall(() async {
        final res = await _dio.post('/student/peer-teaching', data: {
          'topic': topic,
          'studentCount': studentCount,
          'reflection': ?reflection,
        });
        return res.data as Map<String, dynamic>;
      });

  Future<List<Map<String, dynamic>>> getFeedback() => apiCall(() async {
        final res = await _dio.get('/student/feedback');
        return (res.data as List).cast<Map<String, dynamic>>();
      });

  Future<Map<String, dynamic>> submitFeedback({String category = 'general', required String content, int rating = 5}) => apiCall(() async {
        final res = await _dio.post('/student/feedback', data: {'category': category, 'content': content, 'rating': rating});
        return res.data as Map<String, dynamic>;
      });

  Future<List<Map<String, dynamic>>> getAssignments() => apiCall(() async {
        final res = await _dio.get('/student/assignments');
        return (res.data as List).cast<Map<String, dynamic>>();
      });

  Future<Map<String, dynamic>> submitAssignment({required File file, required String subject, String title = 'Untitled Assignment'}) => apiCall(() async {
        final form = FormData.fromMap({
          'subject': subject,
          'title': title,
          'file': await MultipartFile.fromFile(file.path, filename: file.path.split(Platform.pathSeparator).last),
        });
        final res = await _dio.post('/student/assignments', data: form);
        return res.data as Map<String, dynamic>;
      });

  Future<Map<String, dynamic>> getMyParliamentRole() => apiCall(() async {
        final res = await _dio.get('/student/parliament/my-role');
        return res.data as Map<String, dynamic>;
      });
}
