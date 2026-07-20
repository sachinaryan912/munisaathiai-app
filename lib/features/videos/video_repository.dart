import '../../core/network/api_client.dart';

class VideoRepository {
  final _dio = ApiClient.instance.dio;

  Future<List<Map<String, dynamic>>> getVideos({String? methodology}) => apiCall(() async {
        final res = await _dio.get('/video-resources', queryParameters: {'methodology': ?methodology});
        return (res.data as List).cast<Map<String, dynamic>>();
      });

  Future<Map<String, dynamic>> addVideo({required String title, required String youtubeUrl, String? methodology}) => apiCall(() async {
        final res = await _dio.post('/video-resources', data: {
          'title': title,
          'youtubeUrl': youtubeUrl,
          'methodology': ?methodology,
        });
        return res.data as Map<String, dynamic>;
      });

  Future<void> deleteVideo(int id) => apiCall(() async {
        await _dio.delete('/video-resources/$id');
      });
}
