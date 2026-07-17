import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../../../core/network/api_client.dart';
import '../../../core/storage/secure_storage.dart';
import '../../../models/user.dart';
import 'auth_repository.dart';

enum AuthStatus { unknown, authenticated, unauthenticated }

class AuthProvider extends ChangeNotifier {
  final AuthRepository _repo = AuthRepository();
  final _storage = SecureStorage.instance;

  AuthStatus status = AuthStatus.unknown;
  AppUser? user;

  AuthProvider() {
    ApiClient.instance.onUnauthorized = _forceLogout;
  }

  bool get isAuthenticated => status == AuthStatus.authenticated && user != null;

  Future<void> bootstrap() async {
    String? token;
    String? cached;
    try {
      token = await _storage.readToken();
      cached = await _storage.readUserJson();
    } catch (_) {
      // Secure storage can throw after OS-level keystore invalidation
      // (e.g. lock screen removed/changed) — treat as a clean logged-out
      // state rather than stranding the app on the splash screen forever.
      try {
        await _storage.clear();
      } catch (_) {}
    }
    if (token == null || token.isEmpty || cached == null) {
      status = AuthStatus.unauthenticated;
      notifyListeners();
      return;
    }
    if (!await _storage.readRememberMe()) {
      // User was logged in but didn't check "Remember me" — the session is
      // good until the app fully restarts, then it's forgotten.
      await _storage.clear();
      status = AuthStatus.unauthenticated;
      notifyListeners();
      return;
    }
    try {
      user = AppUser.fromJson(jsonDecode(cached) as Map<String, dynamic>);
      status = AuthStatus.authenticated;
      notifyListeners();
    } catch (_) {
      status = AuthStatus.unauthenticated;
      notifyListeners();
      return;
    }

    // Re-sync against the server so emailVerified/profile fields never go
    // stale on a cached session — mirrors the web app's AuthContext.
    try {
      final fresh = await _repo.getMe();
      user = fresh;
      await _persistUser(fresh);
      notifyListeners();
    } catch (_) {
      // Offline or token invalid — keep the cached session; onUnauthorized
      // interceptor already handles a genuine 401.
    }
  }

  Future<void> login(String email, String password, {bool rememberMe = true}) async {
    final session = await _repo.login(email, password);
    await _persistSession(session);
    await _storage.saveRememberMe(rememberMe);
  }

  Future<void> register({
    required String fullName,
    required String email,
    required String password,
    required String phone,
    required String role,
    String? schoolName,
    String? className,
    String? section,
    String? designation,
  }) async {
    final session = await _repo.register(
      fullName: fullName,
      email: email,
      password: password,
      phone: phone,
      role: role,
      schoolName: schoolName,
      className: className,
      section: section,
      designation: designation,
    );
    await _persistSession(session);
  }

  void setEmailVerified(bool verified) {
    if (user == null) return;
    user = user!.copyWith(emailVerified: verified);
    _persistUser(user!);
    notifyListeners();
  }

  void applyProfilePatch({String? fullName, String? phone}) {
    if (user == null) return;
    user = user!.copyWith(fullName: fullName, phone: phone);
    _persistUser(user!);
    notifyListeners();
  }

  Future<void> logout() async {
    await _storage.clear();
    user = null;
    status = AuthStatus.unauthenticated;
    notifyListeners();
  }

  void _forceLogout() {
    _storage.clear();
    user = null;
    status = AuthStatus.unauthenticated;
    notifyListeners();
  }

  Future<void> _persistSession(AuthSession session) async {
    await _storage.saveToken(session.token);
    user = session.user;
    status = AuthStatus.authenticated;
    await _persistUser(session.user);
    notifyListeners();
  }

  Future<void> _persistUser(AppUser u) => _storage.saveUserJson(jsonEncode(u.toJson()));
}
