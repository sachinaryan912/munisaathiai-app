import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/system_ui.dart';
import 'core/theme/theme_provider.dart';
import 'features/auth/data/auth_provider.dart';
import 'features/notifications/notifications_provider.dart';
import 'features/parent/selected_child_provider.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemUi.enableEdgeToEdge();
  SystemUi.applyOnSaffron();
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

  @override
  void initState() {
    super.initState();
    _authProvider.bootstrap();
    _themeProvider.bootstrap();
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
