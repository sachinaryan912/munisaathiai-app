import '../../core/network/api_client.dart';

class ActionPlanRepository {
  final _dio = ApiClient.instance.dio;

  Future<Map<String, dynamic>> create({
    required String schoolName,
    required String title,
    String? description,
    required int assignedToId,
    String? dueDate,
  }) =>
      apiCall(() async {
        final res = await _dio.post('/action-plans', data: {
          'schoolName': schoolName,
          'title': title,
          'description': ?description,
          'assignedToId': assignedToId,
          'dueDate': ?dueDate,
        });
        return res.data as Map<String, dynamic>;
      });

  Future<List<Map<String, dynamic>>> getForSchool(String schoolName) => apiCall(() async {
        final res = await _dio.get('/action-plans/school', queryParameters: {'schoolName': schoolName});
        return (res.data as List).cast<Map<String, dynamic>>();
      });

  Future<List<Map<String, dynamic>>> getMine() => apiCall(() async {
        final res = await _dio.get('/action-plans/mine');
        return (res.data as List).cast<Map<String, dynamic>>();
      });

  Future<Map<String, dynamic>> updateStatus(int id, String status) => apiCall(() async {
        final res = await _dio.post('/action-plans/$id/status', data: {'status': status});
        return res.data as Map<String, dynamic>;
      });
}
