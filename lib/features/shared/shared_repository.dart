import '../../core/network/api_client.dart';

class SharedRepository {
  final _dio = ApiClient.instance.dio;

  Future<List<Map<String, dynamic>>> getWakeupCallBoard() => apiCall(() async {
        final res = await _dio.get('/shared/wakeup-call-board');
        return (res.data as List).cast<Map<String, dynamic>>();
      });

  Future<void> postWakeupCallItem({required String title, String? content, String? category}) => apiCall(() async {
        await _dio.post('/shared/wakeup-call-board', data: {'title': title, 'content': ?content, 'category': ?category});
      });

  Future<List<Map<String, dynamic>>> getRevivalDayEvents() => apiCall(() async {
        final res = await _dio.get('/shared/revival-day-events');
        return (res.data as List).cast<Map<String, dynamic>>();
      });

  Future<void> logRevivalDayEvent({required String type, required String description, String? className}) => apiCall(() async {
        await _dio.post('/shared/revival-day-events', data: {'type': type, 'description': description, 'className': ?className});
      });

  Future<List<Map<String, dynamic>>> getSkillWorkshops() => apiCall(() async {
        final res = await _dio.get('/shared/skill-workshops');
        return (res.data as List).cast<Map<String, dynamic>>();
      });

  Future<void> logSkillWorkshop({required String workshopName, required String category, String? notes, int? attendeeCount, bool certified = false}) => apiCall(() async {
        await _dio.post('/shared/skill-workshops', data: {
          'workshopName': workshopName,
          'category': category,
          'notes': ?notes,
          'attendeeCount': ?attendeeCount,
          'certified': certified,
        });
      });

  Future<List<Map<String, dynamic>>> getActivityClubs() => apiCall(() async {
        final res = await _dio.get('/shared/activity-clubs');
        return (res.data as List).cast<Map<String, dynamic>>();
      });

  Future<void> createActivityClub(String name) => apiCall(() async {
        await _dio.post('/shared/activity-clubs', data: {'name': name});
      });

  Future<void> assignStudentToClub({required int studentId, required int clubId, required String termLabel}) => apiCall(() async {
        await _dio.post('/shared/activity-clubs/assign', data: {'studentId': studentId, 'clubId': clubId, 'termLabel': termLabel});
      });

  Future<Map<String, dynamic>> getMyClub() => apiCall(() async {
        final res = await _dio.get('/shared/activity-clubs/mine');
        return res.data as Map<String, dynamic>;
      });
}
