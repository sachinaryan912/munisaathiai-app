import '../../core/network/api_client.dart';

class TimetableRepository {
  final _dio = ApiClient.instance.dio;

  Future<List<Map<String, dynamic>>> getMyTimetable() => apiCall(() async {
        final res = await _dio.get('/timetable/mine');
        return (res.data as List).cast<Map<String, dynamic>>();
      });

  Future<List<Map<String, dynamic>>> getTimetable({required String className, String? section}) => apiCall(() async {
        final res = await _dio.get('/timetable', queryParameters: {'className': className, 'section': ?section});
        return (res.data as List).cast<Map<String, dynamic>>();
      });

  Future<void> setPeriod({
    required String className,
    String? section,
    required String dayOfWeek,
    required int periodNumber,
    required String subject,
    required String startTime,
    required String endTime,
    String? teacherName,
  }) =>
      apiCall(() async {
        await _dio.post('/timetable', data: {
          'className': className,
          'section': ?section,
          'dayOfWeek': dayOfWeek,
          'periodNumber': periodNumber,
          'subject': subject,
          'startTime': startTime,
          'endTime': endTime,
          'teacherName': ?teacherName,
        });
      });

  Future<void> deletePeriod(int id) => apiCall(() async {
        await _dio.delete('/timetable/$id');
      });
}
