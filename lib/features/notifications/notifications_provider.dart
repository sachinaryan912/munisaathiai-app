import 'package:flutter/foundation.dart';
import '../../models/app_notification.dart';
import 'notification_repository.dart';

class NotificationsProvider extends ChangeNotifier {
  final _repo = NotificationRepository();
  List<AppNotification> items = [];
  bool loading = true;

  int get unreadCount => items.where((n) => !n.read).length;

  Future<void> load() async {
    try {
      items = await _repo.getAll();
    } catch (_) {
      // Silent — the bell just stays empty; not worth blocking the shell for.
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  Future<void> markRead(AppNotification n) async {
    if (n.read) return;
    final idx = items.indexWhere((x) => x.id == n.id);
    if (idx == -1) return;
    items[idx] = n.copyWith(read: true);
    notifyListeners();
    try {
      await _repo.markRead(n.id);
    } catch (_) {
      // optimistic update stands regardless
    }
  }

  Future<void> markAllRead() async {
    items = items.map((n) => n.copyWith(read: true)).toList();
    notifyListeners();
    try {
      await _repo.markAllRead();
    } catch (_) {}
  }
}
