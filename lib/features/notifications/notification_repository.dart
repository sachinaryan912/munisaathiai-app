import '../../core/network/api_client.dart';
import '../../models/app_notification.dart';

class NotificationRepository {
  final _dio = ApiClient.instance.dio;

  Future<List<AppNotification>> getAll() => apiCall(() async {
        final res = await _dio.get('/notifications');
        return (res.data as List).map((e) => AppNotification.fromJson(e as Map<String, dynamic>)).toList();
      });

  Future<void> markRead(int id) => apiCall(() async {
        await _dio.post('/notifications/$id/read');
      });

  Future<void> markAllRead() => apiCall(() async {
        await _dio.post('/notifications/read-all');
      });
}
