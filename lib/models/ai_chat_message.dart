class AiChatMessage {
  final int id;
  final String role; // "user" | "assistant"
  final String content;
  final String? attachmentName;
  final String? attachmentType;
  final DateTime? timestamp;

  AiChatMessage({
    required this.id,
    required this.role,
    required this.content,
    this.attachmentName,
    this.attachmentType,
    this.timestamp,
  });

  bool get isUser => role == 'user';

  factory AiChatMessage.fromJson(Map<String, dynamic> json) {
    return AiChatMessage(
      id: (json['id'] as num?)?.toInt() ?? 0,
      role: json['role'] as String? ?? 'assistant',
      content: json['content'] as String? ?? '',
      attachmentName: json['attachmentName'] as String?,
      attachmentType: json['attachmentType'] as String?,
      timestamp: DateTime.tryParse(json['timestamp'] as String? ?? ''),
    );
  }
}
