import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_text_field.dart';
import '../../../core/widgets/gradient_button.dart';
import '../student_repository.dart';

/// Shared "Submit Assignment" sheet — used by the Assignments screen's own
/// FAB and the Dashboard's quick-action speed dial.
Future<void> showUploadAssignmentSheet(BuildContext context, StudentRepository repo, Future<void> Function() onSuccess) {
  final subjectCtrl = TextEditingController();
  final titleCtrl = TextEditingController();
  File? file;
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
                  Text('Submit Assignment', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 17, color: s.textPrimary)),
                  const SizedBox(height: 4),
                  Text('Vidya will grade it instantly with AI feedback.', style: TextStyle(fontSize: 12, color: s.textSecondary)),
                  const SizedBox(height: 16),
                  AppTextField(label: 'Subject', controller: subjectCtrl, hint: 'e.g. Mathematics'),
                  const SizedBox(height: 14),
                  AppTextField(label: 'Title', controller: titleCtrl, hint: 'e.g. Fractions Worksheet'),
                  const SizedBox(height: 16),
                  InkWell(
                    borderRadius: BorderRadius.circular(16),
                    onTap: () async {
                      final result = await FilePicker.platform.pickFiles(type: FileType.custom, allowedExtensions: ['jpg', 'jpeg', 'png', 'webp', 'pdf']);
                      if (result?.files.single.path != null) {
                        setSheetState(() => file = File(result!.files.single.path!));
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Theme.of(sheetContext).inputDecorationTheme.fillColor,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: file != null ? AppColors.saffron400 : Colors.transparent, width: 1.4),
                      ),
                      child: Row(
                        children: [
                          Icon(file != null ? LucideIcons.fileCheck : LucideIcons.upload, color: AppColors.saffron600, size: 20),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              file != null ? file!.path.split(Platform.pathSeparator).last : 'Choose a photo or PDF of your work',
                              style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: s.textPrimary),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (error != null) ...[const SizedBox(height: 10), Text(error!, style: const TextStyle(color: AppColors.danger, fontSize: 12))],
                  const SizedBox(height: 18),
                  GradientButton(
                    label: 'Submit',
                    loading: submitting,
                    onPressed: () async {
                      if (subjectCtrl.text.trim().isEmpty || file == null) {
                        setSheetState(() => error = 'Please add a subject and a file.');
                        return;
                      }
                      setSheetState(() {
                        submitting = true;
                        error = null;
                      });
                      try {
                        await repo.submitAssignment(file: file!, subject: subjectCtrl.text.trim(), title: titleCtrl.text.trim().isEmpty ? 'Untitled Assignment' : titleCtrl.text.trim());
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
