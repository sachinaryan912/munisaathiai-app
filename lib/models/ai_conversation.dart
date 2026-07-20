class AiConversation {
  final int id;
  final String title;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  AiConversation({
    required this.id,
    required this.title,
    this.createdAt,
    this.updatedAt,
  });

  factory AiConversation.fromJson(Map<String, dynamic> json) {
    return AiConversation(
      id: (json['id'] as num).toInt(),
      title: json['title'] as String? ?? 'New chat',
      createdAt: DateTime.tryParse(json['createdAt'] as String? ?? ''),
      updatedAt: DateTime.tryParse(json['updatedAt'] as String? ?? ''),
    );
  }
}
