import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/app_text_field.dart';
import '../../core/widgets/async_screen.dart';
import '../../core/widgets/gradient_button.dart';
import '../../core/widgets/section_card.dart';
import 'trainer_repository.dart';

class SessionDetailScreen extends StatelessWidget {
  final int sessionId;
  const SessionDetailScreen({super.key, required this.sessionId});

  @override
  Widget build(BuildContext context) {
    final repo = TrainerRepository();
    return Scaffold(
      appBar: AppBar(title: const Text('Training Session')),
      body: AsyncScreen<Map<String, dynamic>>(
        loader: () => repo.getSessionDetail(sessionId),
        builder: (context, session, refresh) {
          final s = context.surface;
          final roster = (session['roster'] as List? ?? []).cast<Map<String, dynamic>>();
          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
            children: [
              SectionCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(child: Text(session['topic'] as String, style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: s.textPrimary))),
                        IconButton(
                          icon: const Icon(LucideIcons.messageCircle, color: AppColors.success),
                          tooltip: 'WhatsApp Reminder',
                          onPressed: () => _showWhatsappReminder(context, repo, sessionId),
                        ),
                      ],
                    ),
                    Text('${session['schoolName']} · ${session['date']} · ${session['mode']}', style: TextStyle(fontSize: 12, color: s.textMuted)),
                    if (session['venue'] != null) Text('${session['venue']}', style: TextStyle(fontSize: 11.5, color: s.textMuted)),
                    if ((session['notes'] as String?)?.isNotEmpty == true) Padding(padding: const EdgeInsets.only(top: 8), child: Text(session['notes'] as String, style: TextStyle(fontSize: 12, color: s.textSecondary))),
                  ],
                ),
              ),
              const SizedBox(height: 22),
              Text('Attendance & Assessment', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 15, color: s.textPrimary)),
              const SizedBox(height: 10),
              ...roster.map((r) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: _AttendanceRow(record: r, sessionId: sessionId, repo: repo, refresh: refresh),
                  )),
            ],
          );
        },
      ),
    );
  }

  Future<void> _showWhatsappReminder(BuildContext context, TrainerRepository repo, int sessionId) async {
    showDialog(
      context: context,
      builder: (dialogContext) => const AlertDialog(
        content: SizedBox(height: 60, child: Center(child: CircularProgressIndicator(strokeWidth: 2))),
      ),
    );
    try {
      final result = await repo.generateWhatsappReminder(sessionId);
      if (!context.mounted) return;
      Navigator.pop(context);
      showDialog(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: const Text('WhatsApp Reminder'),
          content: SelectableText(result['message'] as String? ?? ''),
          actions: [
            TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Close')),
            TextButton(
              onPressed: () {
                Clipboard.setData(ClipboardData(text: result['message'] as String? ?? ''));
                Navigator.pop(dialogContext);
              },
              child: const Text('Copy'),
            ),
          ],
        ),
      );
    } catch (e) {
      if (!context.mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString().replaceFirst('ApiException: ', ''))));
    }
  }
}

class _AttendanceRow extends StatefulWidget {
  final Map<String, dynamic> record;
  final int sessionId;
  final TrainerRepository repo;
  final Future<void> Function() refresh;
  const _AttendanceRow({required this.record, required this.sessionId, required this.repo, required this.refresh});

  @override
  State<_AttendanceRow> createState() => _AttendanceRowState();
}

class _AttendanceRowState extends State<_AttendanceRow> {
  bool _expanded = false;
  late bool _attended = widget.record['attended'] as bool? ?? false;
  late bool _certified = widget.record['certified'] as bool? ?? false;
  late final _preCtrl = TextEditingController(text: widget.record['preTestScore']?.toString() ?? '');
  late final _postCtrl = TextEditingController(text: widget.record['postTestScore']?.toString() ?? '');
  late final _feedbackCtrl = TextEditingController(text: widget.record['feedback'] as String? ?? '');
  int _rating = 0;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _rating = widget.record['rating'] as int? ?? 0;
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      await widget.repo.recordAttendance(
        sessionId: widget.sessionId,
        teacherId: widget.record['teacherId'] as int,
        attended: _attended,
        preTestScore: _preCtrl.text.trim().isEmpty ? null : int.tryParse(_preCtrl.text.trim()),
        postTestScore: _postCtrl.text.trim().isEmpty ? null : int.tryParse(_postCtrl.text.trim()),
        certified: _certified,
        feedback: _feedbackCtrl.text.trim().isEmpty ? null : _feedbackCtrl.text.trim(),
        rating: _rating == 0 ? null : _rating,
      );
      await widget.refresh();
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = context.surface;
    return SectionCard(
      onTap: () => setState(() => _expanded = !_expanded),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: Text(widget.record['teacherName'] as String, style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: s.textPrimary))),
              Switch(value: _attended, activeThumbColor: AppColors.saffron500, onChanged: (v) => setState(() => _attended = v)),
              Icon(_expanded ? LucideIcons.chevronUp : LucideIcons.chevronDown, size: 16, color: s.textMuted),
            ],
          ),
          if (_expanded) ...[
            const SizedBox(height: 8),
            Row(children: [
              Expanded(child: AppTextField(label: 'Pre-test', controller: _preCtrl, keyboardType: TextInputType.number)),
              const SizedBox(width: 10),
              Expanded(child: AppTextField(label: 'Post-test', controller: _postCtrl, keyboardType: TextInputType.number)),
            ]),
            const SizedBox(height: 10),
            AppTextField(label: 'Feedback', controller: _feedbackCtrl, maxLines: 2),
            const SizedBox(height: 8),
            Row(
              children: [
                Text('Certified', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: s.textPrimary)),
                Switch(value: _certified, activeThumbColor: AppColors.success, onChanged: (v) => setState(() => _certified = v)),
                const Spacer(),
                ...List.generate(5, (i) => IconButton(padding: EdgeInsets.zero, constraints: const BoxConstraints(), onPressed: () => setState(() => _rating = i + 1), icon: Icon(i < _rating ? Icons.star_rounded : Icons.star_border_rounded, size: 18, color: AppColors.saffron500))),
              ],
            ),
            const SizedBox(height: 8),
            GradientButton(label: 'Save', loading: _saving, onPressed: _save, height: 40),
          ],
        ],
      ),
    );
  }
}
