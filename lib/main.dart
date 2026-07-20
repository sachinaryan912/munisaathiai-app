import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'core/notifications/fcm_service.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/system_ui.dart';
import 'core/theme/theme_provider.dart';
import 'features/auth/data/auth_provider.dart';
import 'features/notifications/notifications_provider.dart';
import 'features/parent/selected_child_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemUi.enableEdgeToEdge();
  SystemUi.applyOnSaffron();

  // Push notifications — failures here (e.g. no Firebase config on a dev build) must never
  // block the app from starting, so every step is best-effort.
  try {
    await Firebase.initializeApp();
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
    await FcmService.instance.initialize();
  } catch (_) {
    // Push just won't work on this build/device — everything else still does.
  }

  runApp(const MuniApp());
}

class MuniApp extends StatefulWidget {
  const MuniApp({super.key});

  @override
  State<MuniApp> createState() => _MuniAppState();
}

class _MuniAppState extends State<MuniApp> {
  late final AuthProvider _authProvider = AuthProvider();
  late final ThemeProvider _themeProvider = ThemeProvider();
  late final NotificationsProvider _notificationsProvider = NotificationsProvider();
  late final SelectedChildProvider _selectedChildProvider = SelectedChildProvider();
  late final _router = buildRouter(_authProvider);
  AuthStatus? _lastAuthStatus;

  @override
  void initState() {
    super.initState();
    _authProvider.addListener(_onAuthChanged);
    _authProvider.bootstrap();
    _themeProvider.bootstrap();
  }

  @override
  void dispose() {
    _authProvider.removeListener(_onAuthChanged);
    super.dispose();
  }

  // Registers/unregisters this device's FCM token whenever the session actually transitions
  // in or out of being authenticated — bootstrap's later re-sync keeps status unchanged, so
  // this only fires on real login/logout, not on every notifyListeners() call.
  void _onAuthChanged() {
    final status = _authProvider.status;
    if (status == _lastAuthStatus) return;
    final previous = _lastAuthStatus;
    _lastAuthStatus = status;
    if (status == AuthStatus.authenticated) {
      FcmService.instance.registerCurrentToken();
    } else if (status == AuthStatus.unauthenticated && previous == AuthStatus.authenticated) {
      FcmService.instance.unregisterCurrentToken();
    }
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: _authProvider),
        ChangeNotifierProvider.value(value: _themeProvider),
        ChangeNotifierProvider.value(value: _notificationsProvider),
        ChangeNotifierProvider.value(value: _selectedChildProvider),
      ],
      child: Consumer2<ThemeProvider, AuthProvider>(
        builder: (context, theme, auth, _) {
          // Keep the splash screen's solid saffron nav/status bar until the
          // auth bootstrap resolves — only then does a real page (with a
          // light/dark background) take over, so only then should the
          // system bars switch to match the light/dark theme.
          if (auth.status == AuthStatus.unknown) {
            SystemUi.applyOnSaffron();
          } else {
            SystemUi.apply(dark: theme.isDark);
          }
          return MaterialApp.router(
            title: 'Muni Saathi AI',
            debugShowCheckedModeBanner: false,
            themeMode: theme.mode,
            theme: AppTheme.light(),
            darkTheme: AppTheme.dark(),
            routerConfig: _router,
          );
        },
      ),
    );
  }
}
