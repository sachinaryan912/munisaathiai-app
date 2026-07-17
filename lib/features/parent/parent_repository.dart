import '../../core/network/api_client.dart';

class ParentRepository {
  final _dio = ApiClient.instance.dio;

  Future<List<Map<String, dynamic>>> getChildren() => apiCall(() async {
        final res = await _dio.get('/parent/children');
        return (res.data as List).cast<Map<String, dynamic>>();
      });

  Future<List<Map<String, dynamic>>> searchChildren(String query) => apiCall(() async {
        final res = await _dio.get('/parent/children/search', queryParameters: {'query': query});
        return (res.data as List).cast<Map<String, dynamic>>();
      });

  Future<List<Map<String, dynamic>>> linkChild(int childId) => apiCall(() async {
        final res = await _dio.post('/parent/children/link', data: {'childId': childId});
        return (res.data as List).cast<Map<String, dynamic>>();
      });

  Future<Map<String, dynamic>> getDashboard(int? childId) => apiCall(() async {
        final res = await _dio.get('/parent/dashboard', queryParameters: {'childId': ?childId});
        return res.data as Map<String, dynamic>;
      });

  Future<Map<String, dynamic>> getProgress(int? childId) => apiCall(() async {
        final res = await _dio.get('/parent/progress', queryParameters: {'childId': ?childId});
        return res.data as Map<String, dynamic>;
      });

  Future<Map<String, dynamic>> getHomeLearning(int? childId) => apiCall(() async {
        final res = await _dio.get('/parent/home-learning', queryParameters: {'childId': ?childId});
        return res.data as Map<String, dynamic>;
      });

  Future<void> toggleHomeLearning(int id) => apiCall(() async {
        await _dio.post('/parent/home-learning/toggle/$id');
      });

  Future<List<Map<String, dynamic>>> getFeedback(int? childId) => apiCall(() async {
        final res = await _dio.get('/parent/feedback', queryParameters: {'childId': ?childId});
        return (res.data as List).cast<Map<String, dynamic>>();
      });

  Future<Map<String, dynamic>> submitFeedback({int? childId, String category = 'general', required String content, int rating = 5}) => apiCall(() async {
        final res = await _dio.post('/parent/feedback', data: {
          'childId': ?childId,
          'category': category,
          'content': content,
          'rating': rating,
        });
        return res.data as Map<String, dynamic>;
      });
}
