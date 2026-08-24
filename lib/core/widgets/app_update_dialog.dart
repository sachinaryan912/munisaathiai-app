import 'package:flutter/material.dart';
import 'package:in_app_update/in_app_update.dart';
import '../services/app_update_service.dart';
import '../theme/app_colors.dart';

/// Shown once per app launch when [AppUpdateService] confirms Play Store has
/// a newer published version. "Update Now" hands off to Play's own
/// full-screen update UI; "Later" just dismisses — there's no repeated
/// nagging within the same session since the check only ever fires once.
Future<void> showAppUpdateDialog(BuildContext context, AppUpdateInfo info) {
  return showDialog<void>(
    context: context,
    barrierDismissible: !info.immediateUpdateAllowed,
    builder: (dialogContext) => AlertDialog(
      icon: const Icon(Icons.system_update_rounded, color: AppColors.primary, size: 32),
      title: const Text('Update Available'),
      content: const Text(
        'A new version of Muni Saathi AI is ready. Update now for the latest '
        'features and fixes.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(dialogContext),
          child: const Text('Later'),
        ),
        FilledButton(
          onPressed: () {
            Navigator.pop(dialogContext);
            AppUpdateService.instance.performImmediateUpdate();
          },
          child: const Text('Update Now'),
        ),
      ],
    ),
  );
}
