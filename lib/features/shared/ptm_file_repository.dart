import 'package:dio/dio.dart';
import '../../core/network/api_client.dart';

class PtmFileRepository {
  final _dio = ApiClient.instance.dio;

  Future<Map<String, dynamic>> getPtmFile(int studentId) => apiCall(() async {
        final res = await _dio.get('/ptm-file/$studentId');
        return res.data as Map<String, dynamic>;
      });

  Future<List<int>> downloadPtmFilePdf(int studentId) => apiCall(() async {
        final res = await _dio.get('/ptm-file/$studentId/pdf', options: Options(responseType: ResponseType.bytes));
        return res.data as List<int>;
      });
}
