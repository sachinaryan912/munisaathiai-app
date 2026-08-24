import 'package:flutter/foundation.dart';
import 'package:in_app_update/in_app_update.dart';

/// Asks Google Play directly whether a newer version of this app has been
/// published, using the Play Core "in-app update" API — there is no backend
/// endpoint to maintain, Play Store is already the source of truth for
/// "is there a newer build than the one installed".
///
/// Only meaningful on a release build actually installed from Play, so every
/// failure mode (dev build, sideloaded APK, no Play Store on the device, no
/// network) is swallowed rather than surfaced — an update nudge must never
/// be able to break app startup.
class AppUpdateService {
  AppUpdateService._();
  static final instance = AppUpdateService._();

  bool _checkedThisSession = false;

  /// Returns update info once a newer version is confirmed available, or
  /// null otherwise. Only ever returns non-null once per app process.
  Future<AppUpdateInfo?> checkForUpdate() async {
    if (!kReleaseMode || _checkedThisSession) return null;
    _checkedThisSession = true;
    try {
      final info = await InAppUpdate.checkForUpdate();
      if (info.updateAvailability == UpdateAvailability.updateAvailable) {
        return info;
      }
    } catch (_) {
      // Not a Play-installed build, no Play Store, offline, etc.
    }
    return null;
  }

  /// Hands off to Play's own full-screen update UI, which downloads,
  /// installs, and restarts the app on completion. If the user backs out of
  /// that flow, the promise just resolves — there is nothing else to do.
  Future<void> performImmediateUpdate() async {
    try {
      await InAppUpdate.performImmediateUpdate();
    } catch (_) {
      // User cancelled the Play UI, or the flow isn't available right now.
    }
  }
}
