import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_text_field.dart';
import '../../../core/widgets/gradient_button.dart';
import '../student_repository.dart';

/// Shared "Log Buddy Session" sheet — used by the Buddy screen's own button
/// and the Dashboard's quick-action speed dial.
Future<void> showLogBuddySessionSheet(BuildContext context, StudentRepository repo, Future<void> Function() onSuccess) {
  final topicCtrl = TextEditingController();
  final reflectionCtrl = TextEditingController();
  var duration = 30;
  var helped = true;
  var rating = 5;
  var submitting = false;

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
                  Text('Log Buddy Session', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 17, color: s.textPrimary)),
                  const SizedBox(height: 16),
                  AppTextField(label: 'Topic', controller: topicCtrl, hint: 'What did you study together?'),
                  const SizedBox(height: 14),
                  Text('Duration (minutes)', style: Theme.of(sheetContext).inputDecorationTheme.labelStyle),
                  Slider(value: duration.toDouble(), min: 5, max: 90, divisions: 17, label: '$duration min', activeColor: AppColors.saffron500, onChanged: (v) => setSheetState(() => duration = v.round())),
                  Row(
                    children: [
                      Expanded(
                        child: SwitchListTile(
                          contentPadding: EdgeInsets.zero,
                          title: const Text('I helped my buddy', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700)),
                          value: helped,
                          activeThumbColor: AppColors.saffron500,
                          onChanged: (v) => setSheetState(() => helped = v),
                        ),
                      ),
                    ],
                  ),
                  Text('Your rating of this session', style: Theme.of(sheetContext).inputDecorationTheme.labelStyle),
                  const SizedBox(height: 6),
                  Row(
                    children: List.generate(5, (i) {
                      final filled = i < rating;
                      return IconButton(
                        onPressed: () => setSheetState(() => rating = i + 1),
                        icon: Icon(filled ? Icons.star_rounded : Icons.star_border_rounded, color: AppColors.saffron500, size: 26),
                      );
                    }),
                  ),
                  AppTextField(label: 'Reflection (optional)', controller: reflectionCtrl, maxLines: 3, hint: 'How did it go?'),
                  const SizedBox(height: 18),
                  GradientButton(
                    label: 'Save Session',
                    loading: submitting,
                    onPressed: () async {
                      if (topicCtrl.text.trim().isEmpty) return;
                      setSheetState(() => submitting = true);
                      try {
                        await repo.logBuddySession(
                          topic: topicCtrl.text.trim(),
                          duration: duration,
                          helped: helped,
                          peerReflection: reflectionCtrl.text.trim().isEmpty ? null : reflectionCtrl.text.trim(),
                          buddyRating: rating,
                        );
                        if (sheetContext.mounted) Navigator.pop(sheetContext);
                        await onSuccess();
                      } catch (_) {
                        setSheetState(() => submitting = false);
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
