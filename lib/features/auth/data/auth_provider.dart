import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/storage/secure_storage.dart';
import '../../../models/user.dart';
import 'auth_repository.dart';

enum AuthStatus { unknown, authenticated, unauthenticated }

class AuthProvider extends ChangeNotifier {
  final AuthRepository _repo = AuthRepository();
  final _storage = SecureStorage.instance;

  AuthStatus status = AuthStatus.unknown;
  AppUser? user;

  /// Decoded avatar bytes, held in memory so every avatar in the app renders
  /// instantly from one fetch instead of each widget hitting the network.
  Uint8List? profileImage;

  /// Which [AppUser.profileImageUpdatedAt] the bytes above correspond to, so a
  /// photo changed on another device is refetched rather than shown stale.
  DateTime? _profileImageStamp;

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
    } on ApiException catch (e) {
      if (_isSessionRejected(e.statusCode)) {
        // The stored token is dead. This must force a logout here rather than
        // being left to the onUnauthorized interceptor: that only fires on 401,
        // and the backend used to answer an expired token with 403 (Spring's
        // default Http403ForbiddenEntryPoint). Swallowing it booted the app into
        // the dashboard on a dead token, so the first fetch on every page failed
        // and rendered "Access denied" with no way out but a manual re-login.
        //
        // Reaching here now also means the refresh token was tried and rejected
        // (ApiClient refreshes on 401 before the error ever surfaces), so the
        // session really is over. Cleared locally rather than via logout(): the
        // server has already invalidated it, and a revoke round trip would only
        // delay the redirect to login.
        await _clearSession();
        return;
      }
      // Anything else (offline, timeout, 5xx) is not a statement about the
      // session — keep the cached one so the app still opens without a network.
    } catch (_) {
      // Non-API failure (e.g. malformed payload) — same reasoning: don't punish
      // the session for it.
    }

    // Not awaited: the avatar is decoration, and blocking the splash screen on it
    // would delay the whole app for a file that may not even exist.
    unawaited(loadProfileImage());
  }

  /// /users/me is open to every authenticated role, so it can never legitimately
  /// 403 on role grounds — both codes there mean "this token isn't good anymore".
  /// 403 is accepted alongside 401 so already-installed builds recover even
  /// against a backend that hasn't picked up the 401 entry-point fix yet.
  bool _isSessionRejected(int? statusCode) => statusCode == 401 || statusCode == 403;

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

  // ── Profile photo ────────────────────────────────────────────────────────

  /// Fetches the avatar if the server says one exists and the cached bytes are
  /// stale. Silent on failure — a missing avatar falls back to initials, which is
  /// never worth an error in front of the user.
  Future<void> loadProfileImage() async {
    final stamp = user?.profileImageUpdatedAt;
    if (stamp == null) {
      if (profileImage != null) {
        profileImage = null;
        _profileImageStamp = null;
        notifyListeners();
      }
      return;
    }
    if (profileImage != null && _profileImageStamp == stamp) return;

    try {
      final bytes = await _repo.fetchProfileImage();
      if (bytes.isEmpty) return;
      profileImage = bytes;
      _profileImageStamp = stamp;
      notifyListeners();
    } catch (_) {
      // Offline, or the object went missing from the bucket. Initials still render.
    }
  }

  Future<void> uploadProfileImage(Uint8List bytes) async {
    final updated = await _repo.uploadProfileImage(bytes);
    user = updated;
    // Adopt the bytes we just sent rather than re-downloading them. They differ
    // slightly from what's stored (the server re-compresses), but not visibly, and
    // this makes the new photo appear the instant the upload returns.
    profileImage = bytes;
    _profileImageStamp = updated.profileImageUpdatedAt;
    await _persistUser(updated);
    notifyListeners();
  }

  Future<void> removeProfileImage() async {
    final updated = await _repo.deleteProfileImage();
    user = updated;
    profileImage = null;
    _profileImageStamp = null;
    await _persistUser(updated);
    notifyListeners();
  }

  /// Changing the password revokes every session on the account, so the replacement
  /// tokens the server hands back must be stored here — going through the repository
  /// directly would leave the app holding credentials the server just retired.
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    final session = await _repo.changePassword(
      currentPassword: currentPassword,
      newPassword: newPassword,
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

  /// The one thing that ends a session. Revokes the refresh token server-side first
  /// so it can't outlive the logout, then clears local state regardless of whether
  /// that call got through.
  Future<void> logout() async {
    final refreshToken = await _storage.readRefreshToken();
    if (refreshToken != null && refreshToken.isNotEmpty) {
      // Hard time limit. On a dead connection this request burns a 20s connect timeout and
      // is then retried twice by RetryInterceptor — close to a minute of the user staring at
      // a "Signing Out…" spinner after asking to leave. Signing out is a local act; the
      // revoke is a courtesy to the server, so it must never hold the user hostage. The
      // token expires on its own if the call never lands.
      await _repo
          .revokeRefreshToken(refreshToken)
          .timeout(const Duration(seconds: 4), onTimeout: () {});
    }
    await _storage.clear();
    user = null;
    profileImage = null;
    _profileImageStamp = null;
    status = AuthStatus.unauthenticated;
    notifyListeners();
  }

  /// Session ended by the server (refresh token rejected), not by the user — so
  /// there is nothing to revoke, just local state to drop.
  void _forceLogout() {
    _clearSession();
  }

  Future<void> _clearSession() async {
    await _storage.clear();
    user = null;
    // Must be dropped with the session — otherwise the next person to sign in on
    // this device briefly sees the previous user's face in the app bar.
    profileImage = null;
    _profileImageStamp = null;
    status = AuthStatus.unauthenticated;
    notifyListeners();
  }

  Future<void> _persistSession(AuthSession session) async {
    await _storage.saveToken(session.token);
    if (session.refreshToken.isNotEmpty) {
      await _storage.saveRefreshToken(session.refreshToken);
    }
    user = session.user;
    status = AuthStatus.authenticated;
    await _persistUser(session.user);
    notifyListeners();
    unawaited(loadProfileImage());
  }

  Future<void> _persistUser(AppUser u) => _storage.saveUserJson(jsonEncode(u.toJson()));
}
