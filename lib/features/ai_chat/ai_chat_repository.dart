import 'dart:io';
import 'package:dio/dio.dart';
import '../../core/network/api_client.dart';
import '../../models/ai_chat_message.dart';
import '../../models/ai_conversation.dart';

class AiChatRepository {
  final _dio = ApiClient.instance.dio;

  Future<List<AiConversation>> getConversations() => apiCall(() async {
        final res = await _dio.get('/ai/conversations');
        return (res.data as List).map((e) => AiConversation.fromJson(e as Map<String, dynamic>)).toList();
      });

  Future<AiConversation> createConversation() => apiCall(() async {
        final res = await _dio.post('/ai/conversations');
        return AiConversation.fromJson(res.data as Map<String, dynamic>);
      });

  Future<List<AiChatMessage>> getConversationMessages(int conversationId) => apiCall(() async {
        final res = await _dio.get('/ai/conversations/$conversationId/messages');
        return (res.data as List).map((e) => AiChatMessage.fromJson(e as Map<String, dynamic>)).toList();
      });

  Future<AiChatMessage> sendMessage(int conversationId, {String? content, File? file}) => apiCall(() async {
        final form = FormData.fromMap({
          if (content != null && content.isNotEmpty) 'content': content,
          if (file != null) 'file': await MultipartFile.fromFile(file.path, filename: file.path.split(Platform.pathSeparator).last),
        });
        final res = await _dio.post('/ai/conversations/$conversationId/messages', data: form);
        return AiChatMessage.fromJson(res.data as Map<String, dynamic>);
      });
}
