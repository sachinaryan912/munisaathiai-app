import 'dart:developer';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:provider/provider.dart';

import '../../features/notifications/notification_repository.dart';
import '../../features/notifications/notification_panel.dart';
import '../../features/notifications/notifications_provider.dart';
import '../router/app_router.dart';

const _defaultChannel = AndroidNotificationChannel(
  'muni_saathi_default_channel',
  'Muni Saathi AI Notifications',
  description: 'Updates, alerts and reminders from Muni Saathi AI.',
  importance: Importance.high,
);

/// Top-level background handler — required by firebase_messaging to run in its own isolate
/// when a push arrives while the app is backgrounded/killed. Android shows the system
/// notification itself (via the manifest's default channel/icon meta-data); this only runs for
/// any additional data-only processing, so it's intentionally minimal.
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  log('FCM background message received: ${message.messageId}');
}

/// Owns the whole push-notification lifecycle: permission request, token capture/refresh +
/// backend registration, foreground display (Android hides system notifications while the app
/// is in the foreground, so we show one ourselves), and tap-to-open handling for background/
/// killed-state taps.
class FcmService {
  FcmService._();
  static final FcmService instance = FcmService._();

  final _repo = NotificationRepository();
  final _localNotifications = FlutterLocalNotificationsPlugin();
  String? _lastRegisteredToken;
  bool _initialized = false;

  Future<void> initialize() async {
    if (_initialized) return;
    _initialized = true;

    await _localNotifications.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(_defaultChannel);
    await _localNotifications.initialize(
      const InitializationSettings(android: AndroidInitializationSettings('@mipmap/ic_launcher')),
      onDidReceiveNotificationResponse: (_) => _openNotificationPanel(),
    );

    await FirebaseMessaging.instance.requestPermission(alert: true, badge: true, sound: true);

    FirebaseMessaging.onMessage.listen(_showForegroundNotification);
    FirebaseMessaging.onMessageOpenedApp.listen((_) => _openNotificationPanel());
    FirebaseMessaging.instance.onTokenRefresh.listen((token) => _registerToken(token));

    // App was fully killed and got opened by tapping the notification.
    final initialMessage = await FirebaseMessaging.instance.getInitialMessage();
    if (initialMessage != null) _openNotificationPanel();
  }

  /// Call once the user is known to be authenticated (right after login, and on app start if a
  /// session is already cached) — the backend endpoint needs a valid JWT to attribute the token.
  Future<void> registerCurrentToken() async {
    try {
      final token = await FirebaseMessaging.instance.getToken();
      if (token != null) await _registerToken(token);
    } catch (e) {
      log('FCM: could not fetch/register token: $e');
    }
  }

  Future<void> _registerToken(String token) async {
    if (token == _lastRegisteredToken) return;
    try {
      await _repo.registerDeviceToken(token);
      _lastRegisteredToken = token;
    } catch (e) {
      log('FCM: token registration failed: $e');
    }
  }

  /// Call on logout so this device stops receiving pushes meant for the account that just
  /// signed out (the next user to log in on this device will register their own token).
  Future<void> unregisterCurrentToken() async {
    final token = _lastRegisteredToken;
    if (token == null) return;
    _lastRegisteredToken = null;
    try {
      await _repo.unregisterDeviceToken(token);
    } catch (e) {
      log('FCM: token unregistration failed: $e');
    }
  }

  Future<void> _showForegroundNotification(RemoteMessage message) async {
    final notification = message.notification;
    if (notification == null) return;
    await _localNotifications.show(
      message.hashCode,
      notification.title,
      notification.body,
      NotificationDetails(android: AndroidNotificationDetails(_defaultChannel.id, _defaultChannel.name, channelDescription: _defaultChannel.description, importance: Importance.high, priority: Priority.high)),
    );
  }

  void _openNotificationPanel() {
    final context = rootNavigatorKey.currentContext;
    if (context == null) return;
    context.read<NotificationsProvider>().load();
    showNotificationPanel(context);
  }
}
