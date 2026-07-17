/// Mirrors the backend `Notification` entity. Named `AppNotification` to
/// avoid clashing with Flutter's own `Notification` widget-tree class.
class AppNotification {
  final int id;
  final String title;
  final String body;
  final String icon;
  final bool read;
  final DateTime? createdAt;

  AppNotification({
    required this.id,
    required this.title,
    required this.body,
    required this.icon,
    required this.read,
    required this.createdAt,
  });

  factory AppNotification.fromJson(Map<String, dynamic> json) {
    return AppNotification(
      id: (json['id'] as num).toInt(),
      title: json['title'] as String? ?? '',
      body: json['body'] as String? ?? '',
      icon: json['icon'] as String? ?? 'Bell',
      read: json['read'] as bool? ?? false,
      createdAt: DateTime.tryParse(json['createdAt'] as String? ?? ''),
    );
  }

  AppNotification copyWith({bool? read}) {
    return AppNotification(
      id: id,
      title: title,
      body: body,
      icon: icon,
      read: read ?? this.read,
      createdAt: createdAt,
    );
  }
}
