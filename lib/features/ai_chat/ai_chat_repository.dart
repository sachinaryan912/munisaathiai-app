import 'dart:io';
import 'package:dio/dio.dart';
import '../../core/network/api_client.dart';
import '../../models/ai_chat_message.dart';

class AiChatRepository {
  final _dio = ApiClient.instance.dio;

  Future<List<AiChatMessage>> getHistory() => apiCall(() async {
        final res = await _dio.get('/ai/chat');
        return (res.data as List).map((e) => AiChatMessage.fromJson(e as Map<String, dynamic>)).toList();
      });

  Future<AiChatMessage> send({String? content, File? file}) => apiCall(() async {
        final form = FormData.fromMap({
          if (content != null && content.isNotEmpty) 'content': content,
          if (file != null) 'file': await MultipartFile.fromFile(file.path, filename: file.path.split(Platform.pathSeparator).last),
        });
        final res = await _dio.post('/ai/chat', data: form);
        return AiChatMessage.fromJson(res.data as Map<String, dynamic>);
      });
}
