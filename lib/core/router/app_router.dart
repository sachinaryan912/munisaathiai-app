import 'package:go_router/go_router.dart';
import '../../features/ai_chat/ai_chat_page.dart';
import '../../features/auth/data/auth_provider.dart';
import '../../features/auth/ui/forgot_password_screen.dart';
import '../../features/auth/ui/login_screen.dart';
import '../../features/auth/ui/register_screen.dart';
import '../../features/auth/ui/splash_screen.dart';
import '../../features/auth/ui/verify_email_screen.dart';
import '../../features/settings/settings_screen.dart';
import '../nav/nav_items.dart';
import 'role_routes.dart';

const _authRoutePaths = {'/login', '/register', '/forgot-password'};

GoRouter buildRouter(AuthProvider auth) {
  return GoRouter(
    initialLocation: '/splash',
    refreshListenable: auth,
    redirect: (context, state) {
      final loc = state.uri.toString();

      if (auth.status == AuthStatus.unknown) {
        return loc == '/splash' ? null : '/splash';
      }

      if (auth.status == AuthStatus.unauthenticated) {
        if (loc == '/splash') return '/login';
        if (_authRoutePaths.any((p) => loc.startsWith(p))) return null;
        return '/login';
      }

      // authenticated
      final role = auth.user!.role;
      final home = roleBasePath(role);

      if (loc == '/splash' || _authRoutePaths.any((p) => loc.startsWith(p))) {
        return auth.user!.emailVerified ? home : '/verify-email';
      }
      if (!auth.user!.emailVerified) {
        return loc == '/verify-email' ? null : '/verify-email';
      }
      if (loc == '/verify-email') return home;

      return null;
    },
    routes: [
      GoRoute(path: '/splash', builder: (context, state) => const SplashScreen()),
      GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
      GoRoute(path: '/register', builder: (context, state) => const RegisterScreen()),
      GoRoute(path: '/forgot-password', builder: (context, state) => const ForgotPasswordScreen()),
      GoRoute(path: '/verify-email', builder: (context, state) => const VerifyEmailScreen()),
      GoRoute(path: '/settings', builder: (context, state) => const SettingsScreen()),
      GoRoute(path: '/ai-chat', builder: (context, state) => const AiChatPage()),
      ...buildRoleRoutes(),
    ],
  );
}
