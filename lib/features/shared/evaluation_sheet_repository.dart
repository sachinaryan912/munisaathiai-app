import '../../core/network/api_client.dart';

class EvaluationSheetRepository {
  final _dio = ApiClient.instance.dio;

  Future<List<String>> getCriteria() => apiCall(() async {
        final res = await _dio.get('/evaluation-sheet/criteria');
        return (res.data as List).cast<String>();
      });

  Future<Map<String, dynamic>> getEvaluationSheet({int? studentId, required String termLabel}) => apiCall(() async {
        final res = await _dio.get('/evaluation-sheet', queryParameters: {'studentId': ?studentId, 'termLabel': termLabel});
        return res.data as Map<String, dynamic>;
      });

  Future<List<String>> getTermLabels() => apiCall(() async {
        final res = await _dio.get('/evaluation-sheet/terms');
        return (res.data as List).cast<String>();
      });

  Future<void> submitRating({
    required int studentId,
    required String termLabel,
    required String criterion,
    required String raterRole,
    String? raterName,
    required int score,
  }) =>
      apiCall(() async {
        await _dio.post('/evaluation-sheet/rate', data: {
          'studentId': studentId,
          'termLabel': termLabel,
          'criterion': criterion,
          'raterRole': raterRole,
          'raterName': ?raterName,
          'score': score,
        });
      });
}
