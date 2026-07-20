import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_text_field.dart';
import '../../../core/widgets/gradient_button.dart';
import '../student_repository.dart';

/// Shared "Log Peer Teaching" sheet — used by the Peer Teaching screen's own
/// FAB and the Dashboard's quick-action speed dial.
Future<void> showLogPeerTeachingSheet(BuildContext context, StudentRepository repo, Future<void> Function() onSuccess) {
  final topicCtrl = TextEditingController();
  final reflectionCtrl = TextEditingController();
  var count = 2;
  var submitting = false;
  String? error;

  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (sheetContext) {
      return StatefulBuilder(builder: (sheetContext, setSheetState) {
        final s = sheetContext.surface;
        return Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(sheetContext).viewInsets.bottom),
          child: Container(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 28),
            decoration: BoxDecoration(color: s.card, borderRadius: const BorderRadius.vertical(top: Radius.circular(28))),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(width: 40, height: 4, margin: const EdgeInsets.only(bottom: 14), alignment: Alignment.center, decoration: BoxDecoration(color: s.border, borderRadius: BorderRadius.circular(99))),
                  Text('Log Peer Teaching', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 17, color: s.textPrimary)),
                  const SizedBox(height: 16),
                  AppTextField(label: 'Topic taught', controller: topicCtrl),
                  const SizedBox(height: 14),
                  Text('How many friends did you teach?', style: Theme.of(sheetContext).inputDecorationTheme.labelStyle),
                  Row(
                    children: [
                      IconButton.filledTonal(onPressed: count > 1 ? () => setSheetState(() => count--) : null, icon: const Icon(Icons.remove)),
                      Expanded(child: Center(child: Text('$count', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: s.textPrimary)))),
                      IconButton.filledTonal(onPressed: () => setSheetState(() => count++), icon: const Icon(Icons.add)),
                    ],
                  ),
                  const SizedBox(height: 10),
                  AppTextField(label: 'Reflection (optional)', controller: reflectionCtrl, maxLines: 3),
                  if (error != null) ...[const SizedBox(height: 10), Text(error!, style: const TextStyle(color: AppColors.danger, fontSize: 12))],
                  const SizedBox(height: 18),
                  GradientButton(
                    label: 'Save',
                    loading: submitting,
                    onPressed: () async {
                      if (topicCtrl.text.trim().isEmpty) return;
                      setSheetState(() {
                        submitting = true;
                        error = null;
                      });
                      try {
                        await repo.logPeerTeaching(topic: topicCtrl.text.trim(), studentCount: count, reflection: reflectionCtrl.text.trim().isEmpty ? null : reflectionCtrl.text.trim());
                        if (sheetContext.mounted) Navigator.pop(sheetContext);
                        await onSuccess();
                      } catch (e) {
                        setSheetState(() {
                          submitting = false;
                          error = e.toString().replaceFirst('ApiException: ', '');
                        });
                      }
                    },
                  ),
                ],
              ),
            ),
          ),
        );
      });
    },
  );
}
