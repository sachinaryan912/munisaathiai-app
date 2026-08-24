import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/time_ago.dart';
import '../../core/widgets/async_screen.dart';
import '../../core/widgets/empty_view.dart';
import '../../core/widgets/section_card.dart';
import '../shell/app_shell.dart';
import 'knowledge_base_editor_screen.dart';
import 'management_repository.dart';
import 'widgets/knowledge_note_form_sheet.dart';

/// Lets Management teach Vidya directly from the app — school-visit findings, curriculum
/// documents, corrections — without a developer hand-editing muni-knowledge.md and redeploying.
/// Every active note here is appended to Vidya's grounding text on every AI call.
class KnowledgeNotesScreen extends StatefulWidget {
  const KnowledgeNotesScreen({super.key});

  @override
  State<KnowledgeNotesScreen> createState() => _KnowledgeNotesScreenState();
}

class _KnowledgeNotesScreenState extends State<KnowledgeNotesScreen> {
  final _repo = ManagementRepository();

  Future<void> _create(Future<void> Function() refresh) async {
    final payload = await showCreateKnowledgeNoteSheet(context);
    if (payload == null) return;
    try {
      await _repo.addKnowledgeNote(payload['title']!, payload['content']!);
      await refresh();
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Added to Vidya's knowledge base.")));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString().replaceFirst('ApiException: ', ''))));
    }
  }

  Future<void> _edit(Map<String, dynamic> note, Future<void> Function() refresh) async {
    final payload = await showEditKnowledgeNoteSheet(context, note);
    if (payload == null) return;
    try {
      await _repo.updateKnowledgeNote(note['id'] as int, payload['title']!, payload['content']!);
      await refresh();
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString().replaceFirst('ApiException: ', ''))));
    }
  }

  Future<void> _toggleActive(Map<String, dynamic> note, Future<void> Function() refresh) async {
    final active = note['active'] as bool? ?? true;
    try {
      await _repo.setKnowledgeNoteActive(note['id'] as int, !active);
      await refresh();
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString().replaceFirst('ApiException: ', ''))));
    }
  }

  Future<void> _delete(Map<String, dynamic> note, Future<void> Function() refresh) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Remove this note?'),
        content: Text('"${note['title']}" will be permanently removed from Vidya\'s knowledge base.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(dialogContext, true), child: const Text('Remove', style: TextStyle(color: AppColors.danger))),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await _repo.deleteKnowledgeNote(note['id'] as int);
      await refresh();
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString().replaceFirst('ApiException: ', ''))));
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppShell(
      title: 'Train Vidya AI',
      showAiFab: false,
      actions: [
        IconButton(
          icon: const Icon(LucideIcons.fileText),
          tooltip: 'View & edit the full knowledge base',
          onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const KnowledgeBaseEditorScreen())),
        ),
      ],
      body: AsyncScreen<List<Map<String, dynamic>>>(
        loader: _repo.getKnowledgeNotes,
        builder: (context, notes, refresh) {
          final s = context.surface;
          return Stack(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 14, 16, 6),
                    child: SectionCard(
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(LucideIcons.brainCircuit, size: 18, color: AppColors.saffron500),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              "Add anything Vidya should know — school-visit findings, curriculum documents, "
                              "corrections to how a methodology is actually run. Active notes go live in Vidya's "
                              "answers immediately, for every role, with no app update.",
                              style: TextStyle(fontSize: 11.5, color: s.textSecondary, height: 1.4),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Expanded(
                    child: notes.isEmpty
                        ? const EmptyView(
                            title: 'No training notes yet',
                            subtitle: "Tap + to teach Vidya something that isn't in the knowledge base yet.",
                            icon: LucideIcons.brainCircuit,
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.fromLTRB(16, 6, 16, 100),
                            itemCount: notes.length,
                            itemBuilder: (context, i) {
                              final note = notes[i];
                              final active = note['active'] as bool? ?? true;
                              final updatedAt = DateTime.tryParse(note['updatedAt'] as String? ?? '');
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 10),
                                child: Opacity(
                                  opacity: active ? 1 : 0.55,
                                  child: SectionCard(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Expanded(
                                              child: Text(note['title'] as String? ?? '',
                                                  style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13.5, color: s.textPrimary)),
                                            ),
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                              decoration: BoxDecoration(
                                                color: (active ? AppColors.success : s.textMuted).withValues(alpha: 0.14),
                                                borderRadius: BorderRadius.circular(99),
                                              ),
                                              child: Text(active ? 'Live' : 'Off',
                                                  style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.w800, color: active ? AppColors.success : s.textMuted)),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 6),
                                        Text(
                                          note['content'] as String? ?? '',
                                          maxLines: 3,
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(fontSize: 12, color: s.textSecondary, height: 1.4),
                                        ),
                                        const SizedBox(height: 8),
                                        Text(
                                          'by ${note['addedByName'] ?? 'Management'} · ${timeAgo(updatedAt)}',
                                          style: TextStyle(fontSize: 10.5, color: s.textMuted),
                                        ),
                                        const SizedBox(height: 8),
                                        Row(
                                          children: [
                                            _ActionBtn(icon: LucideIcons.pencil, label: 'Edit', onTap: () => _edit(note, refresh)),
                                            _ActionBtn(
                                              icon: active ? LucideIcons.eyeOff : LucideIcons.eye,
                                              label: active ? 'Turn off' : 'Turn on',
                                              onTap: () => _toggleActive(note, refresh),
                                            ),
                                            _ActionBtn(icon: LucideIcons.trash2, label: 'Remove', color: AppColors.danger, onTap: () => _delete(note, refresh)),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ).animate(delay: (i * 40).ms).fadeIn(duration: 280.ms).slideY(begin: 0.06, end: 0, curve: Curves.easeOutCubic);
                            },
                          ),
                  ),
                ],
              ),
              Positioned(
                right: 16,
                bottom: 16,
                child: FloatingActionButton(
                  heroTag: 'create_knowledge_note',
                  backgroundColor: AppColors.saffron500,
                  onPressed: () => _create(refresh),
                  child: const Icon(Icons.add, color: Colors.white),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _ActionBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color? color;
  final VoidCallback onTap;
  const _ActionBtn({required this.icon, required this.label, required this.onTap, this.color});

  @override
  Widget build(BuildContext context) {
    final s = context.surface;
    final c = color ?? s.textSecondary;
    return Expanded(
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Column(children: [Icon(icon, size: 15, color: c), const SizedBox(height: 3), Text(label, style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.w700, color: c))]),
        ),
      ),
    );
  }
}
