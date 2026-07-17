import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_text_field.dart';
import '../../../core/widgets/gradient_button.dart';
import '../student_repository.dart';

const _categories = ['general', 'buddy', 'study', 'teacher'];

/// Compact "Send Feedback" sheet for the Dashboard's quick-action speed
/// dial — the Feedback screen itself keeps its fuller inline form.
Future<void> showQuickFeedbackSheet(BuildContext context, StudentRepository repo, Future<void> Function() onSuccess) {
  final contentCtrl = TextEditingController();
  var category = 'general';
  var rating = 5;
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
                  Text('Share Feedback', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 17, color: s.textPrimary)),
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 8,
                    children: _categories.map((c) {
                      final active = c == category;
                      return ChoiceChip(
                        label: Text(c[0].toUpperCase() + c.substring(1)),
                        selected: active,
                        onSelected: (_) => setSheetState(() => category = c),
                        selectedColor: AppColors.saffron100,
                        labelStyle: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: active ? AppColors.saffron700 : s.textSecondary),
                        backgroundColor: s.border.withValues(alpha: 0.4),
                        side: BorderSide.none,
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(5, (i) {
                      final filled = i < rating;
                      return IconButton(
                        onPressed: () => setSheetState(() => rating = i + 1),
                        icon: Icon(filled ? Icons.star_rounded : Icons.star_border_rounded, color: AppColors.saffron500, size: 28),
                      );
                    }),
                  ),
                  AppTextField(label: 'Your thoughts', controller: contentCtrl, maxLines: 4, hint: 'Tell us what you think...'),
                  if (error != null) ...[const SizedBox(height: 10), Text(error!, style: const TextStyle(color: AppColors.danger, fontSize: 12))],
                  const SizedBox(height: 18),
                  GradientButton(
                    label: 'Send Feedback',
                    icon: Icons.send_rounded,
                    loading: submitting,
                    onPressed: () async {
                      if (contentCtrl.text.trim().isEmpty) {
                        setSheetState(() => error = 'Please write your feedback first.');
                        return;
                      }
                      setSheetState(() {
                        submitting = true;
                        error = null;
                      });
                      try {
                        await repo.submitFeedback(category: category, content: contentCtrl.text.trim(), rating: rating);
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
