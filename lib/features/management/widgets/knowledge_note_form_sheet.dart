import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_text_field.dart';
import '../../../core/widgets/gradient_button.dart';

Future<Map<String, String>?> showCreateKnowledgeNoteSheet(BuildContext context) {
  return showModalBottomSheet<Map<String, String>>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (sheetContext) => const _KnowledgeNoteFormSheet(),
  );
}

Future<Map<String, String>?> showEditKnowledgeNoteSheet(BuildContext context, Map<String, dynamic> note) {
  return showModalBottomSheet<Map<String, String>>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (sheetContext) => _KnowledgeNoteFormSheet(existing: note),
  );
}

class _KnowledgeNoteFormSheet extends StatefulWidget {
  final Map<String, dynamic>? existing;
  const _KnowledgeNoteFormSheet({this.existing});

  @override
  State<_KnowledgeNoteFormSheet> createState() => _KnowledgeNoteFormSheetState();
}

class _KnowledgeNoteFormSheetState extends State<_KnowledgeNoteFormSheet> {
  late final _title = TextEditingController(text: widget.existing?['title'] as String? ?? '');
  late final _content = TextEditingController(text: widget.existing?['content'] as String? ?? '');
  String? _error;

  void _save() {
    if (_title.text.trim().isEmpty || _content.text.trim().isEmpty) {
      setState(() => _error = 'Please fill in both the title and the content.');
      return;
    }
    Navigator.pop(context, {'title': _title.text.trim(), 'content': _content.text.trim()});
  }

  @override
  Widget build(BuildContext context) {
    final s = context.surface;
    final isEdit = widget.existing != null;
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 28),
        decoration: BoxDecoration(color: s.card, borderRadius: const BorderRadius.vertical(top: Radius.circular(28))),
        constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.88),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(width: 40, height: 4, margin: const EdgeInsets.only(bottom: 14), alignment: Alignment.center, decoration: BoxDecoration(color: s.border, borderRadius: BorderRadius.circular(99))),
              Text(isEdit ? 'Edit Training Note' : 'Add Training Note', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 17, color: s.textPrimary)),
              const SizedBox(height: 4),
              Text(
                'Vidya reads every active note here on top of the Muni knowledge base — no app '
                'update needed. Write it the way you would explain it to a new teacher.',
                style: TextStyle(fontSize: 11.5, color: s.textMuted),
              ),
              const SizedBox(height: 16),
              AppTextField(label: 'Title', hint: 'e.g. Ghar Ek Pathshala — how our schools actually run it', controller: _title),
              const SizedBox(height: 14),
              AppTextField(label: 'Content', hint: 'Write in as much detail as you would want Vidya to know...', controller: _content, maxLines: 10),
              if (_error != null) ...[const SizedBox(height: 10), Text(_error!, style: const TextStyle(color: AppColors.danger, fontSize: 12))],
              const SizedBox(height: 18),
              GradientButton(label: isEdit ? 'Save Changes' : 'Add to Vidya\'s Knowledge', onPressed: _save, height: 48),
            ],
          ),
        ),
      ),
    );
  }
}
