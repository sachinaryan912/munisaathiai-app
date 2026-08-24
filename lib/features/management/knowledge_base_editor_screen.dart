import 'package:flutter/material.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/time_ago.dart';
import '../../core/widgets/async_screen.dart';
import '../../core/widgets/gradient_button.dart';
import '../../core/widgets/section_card.dart';
import '../shell/app_shell.dart';
import 'management_repository.dart';

/// Lets Management view and directly fix the core Muni knowledge base (muni-knowledge.md) itself
/// — unlike the "Train Vidya AI" notes screen, which only ever ADDS supplementary notes, this
/// edits the source text every AI answer is grounded in. High blast radius by design, so every
/// save and reset asks for confirmation, and "Reset to Original" is always available as an undo.
class KnowledgeBaseEditorScreen extends StatelessWidget {
  const KnowledgeBaseEditorScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final repo = ManagementRepository();
    return AppShell(
      title: 'Edit Knowledge Base',
      showAiFab: false,
      body: AsyncScreen<Map<String, dynamic>>(
        loader: repo.getKnowledgeBase,
        builder: (context, data, refresh) => _Body(repo: repo, data: data, refresh: refresh),
      ),
    );
  }
}

class _Body extends StatefulWidget {
  final ManagementRepository repo;
  final Map<String, dynamic> data;
  final Future<void> Function() refresh;
  const _Body({required this.repo, required this.data, required this.refresh});

  @override
  State<_Body> createState() => _BodyState();
}

class _BodyState extends State<_Body> {
  late final _controller = TextEditingController(text: widget.data['content'] as String? ?? '');
  // Covers the confirm-dialog window too, not just the network call — without this, a fast
  // double-tap on Save (or Reset) before the dialog appears fires _save()/_resetToOriginal()
  // twice, stacking two confirmation dialogs.
  bool _busy = false;
  bool _saving = false;
  bool _resetting = false;
  String? _error;
  // Raw markdown in a monospace box reads as noise for a 1000+ line document — default to a
  // rendered preview and only drop into the raw editor when the user actually wants to type.
  bool _editing = false;
  // The preview should reflect what's on screen, including unsaved edits — but MarkdownBody
  // isn't reactive to a TextEditingController, so this is refreshed on every switch back to
  // Preview and after a successful save/reset.
  late String _previewText = _controller.text;

  bool get _customized => widget.data['isCustomized'] as bool? ?? false;
  String? get _updatedByName => widget.data['updatedByName'] as String?;
  DateTime? get _updatedAt => DateTime.tryParse(widget.data['updatedAt'] as String? ?? '');

  Future<void> _save() async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: const Text('Save changes to the knowledge base?'),
          content: const Text(
            'Every answer Vidya gives, to every role, is grounded in this text. Saving replaces it '
            'immediately for everyone — no review step. Make sure the change is correct.',
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: const Text('Cancel')),
            TextButton(onPressed: () => Navigator.pop(dialogContext, true), child: const Text('Save')),
          ],
        ),
      );
      if (confirmed != true) return;

      setState(() {
        _saving = true;
        _error = null;
      });
      await widget.repo.updateKnowledgeBase(_controller.text);
      await widget.refresh();
      _previewText = _controller.text;
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Knowledge base updated. Vidya is using it now.')));
    } catch (e) {
      setState(() => _error = e.toString().replaceFirst('ApiException: ', ''));
    } finally {
      if (mounted) {
        setState(() {
          _saving = false;
          _busy = false;
        });
      }
    }
  }

  Future<void> _resetToOriginal() async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: const Text('Reset to the original file?'),
          content: const Text(
            'This discards every edit Management has made and restores the factory-default '
            'muni-knowledge.md. This cannot be undone.',
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: const Text('Cancel')),
            TextButton(onPressed: () => Navigator.pop(dialogContext, true), child: const Text('Reset', style: TextStyle(color: AppColors.danger))),
          ],
        ),
      );
      if (confirmed != true) return;

      setState(() => _resetting = true);
      final result = await widget.repo.resetKnowledgeBase();
      _controller.text = result['content'] as String? ?? '';
      _previewText = _controller.text;
      await widget.refresh();
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Restored to the original knowledge base.')));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString().replaceFirst('ApiException: ', ''))));
    } finally {
      if (mounted) {
        setState(() {
          _resetting = false;
          _busy = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = context.surface;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 6),
          child: SectionCard(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(_customized ? LucideIcons.pencilLine : LucideIcons.fileText, size: 18, color: AppColors.saffron500),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _customized ? 'Customized by Management' : 'Original file — never edited',
                        style: TextStyle(fontWeight: FontWeight.w800, fontSize: 12.5, color: s.textPrimary),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _customized && _updatedByName != null
                            ? 'Last edited by $_updatedByName · ${timeAgo(_updatedAt)}'
                            : 'This is the exact text every AI answer is grounded in — edit carefully.',
                        style: TextStyle(fontSize: 11, color: s.textMuted),
                      ),
                    ],
                  ),
                ),
                if (_customized)
                  TextButton.icon(
                    onPressed: _resetting ? null : _resetToOriginal,
                    icon: _resetting
                        ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2))
                        : const Icon(LucideIcons.rotateCcw, size: 14),
                    label: const Text('Reset', style: TextStyle(fontSize: 11.5)),
                    style: TextButton.styleFrom(foregroundColor: AppColors.danger),
                  ),
              ],
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 6, 16, 6),
          child: Row(
            children: [
              _ModeChip(label: 'Preview', icon: LucideIcons.eye, selected: !_editing, onTap: () {
                setState(() {
                  _previewText = _controller.text;
                  _editing = false;
                });
              }),
              const SizedBox(width: 8),
              _ModeChip(label: 'Edit', icon: LucideIcons.pencilLine, selected: _editing, onTap: () => setState(() => _editing = true)),
            ],
          ),
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Container(
              decoration: BoxDecoration(color: s.card, borderRadius: BorderRadius.circular(16), border: Border.all(color: s.border)),
              padding: const EdgeInsets.all(14),
              child: _editing
                  ? TextField(
                      controller: _controller,
                      maxLines: null,
                      expands: true,
                      textAlignVertical: TextAlignVertical.top,
                      style: TextStyle(fontSize: 12.5, height: 1.5, color: s.textPrimary, fontFamily: 'monospace'),
                      decoration: const InputDecoration(border: InputBorder.none, isCollapsed: true),
                    )
                  : Scrollbar(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.only(right: 4),
                        child: MarkdownBody(
                          data: _previewText,
                          styleSheet: _markdownStyleSheet(s),
                        ),
                      ),
                    ),
            ),
          ),
        ),
        if (_editing)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (_error != null) ...[
                  Text(_error!, style: const TextStyle(color: AppColors.danger, fontSize: 12)),
                  const SizedBox(height: 10),
                ],
                GradientButton(label: 'Save', loading: _saving, onPressed: _save, height: 48),
              ],
            ),
          )
        else
          const SizedBox(height: 20),
      ],
    );
  }

  MarkdownStyleSheet _markdownStyleSheet(MuniSurface s) {
    return MarkdownStyleSheet(
      p: TextStyle(color: s.textPrimary, fontSize: 13, height: 1.55),
      h1: TextStyle(color: s.textPrimary, fontSize: 20, fontWeight: FontWeight.w900, height: 2),
      h2: TextStyle(color: s.textPrimary, fontSize: 17, fontWeight: FontWeight.w900, height: 2),
      h3: TextStyle(color: s.textPrimary, fontSize: 15, fontWeight: FontWeight.w800, height: 1.8),
      h4: TextStyle(color: AppColors.saffron600, fontSize: 13.5, fontWeight: FontWeight.w800, height: 1.8),
      strong: TextStyle(color: s.textPrimary, fontWeight: FontWeight.w800),
      em: TextStyle(color: s.textSecondary, fontStyle: FontStyle.italic),
      listBullet: TextStyle(color: s.textSecondary, fontSize: 13),
      blockquote: TextStyle(color: s.textSecondary, fontSize: 13, fontStyle: FontStyle.italic),
      blockquoteDecoration: BoxDecoration(
        color: s.surfaceVariant,
        border: Border(left: BorderSide(color: AppColors.saffron500, width: 3)),
        borderRadius: const BorderRadius.horizontal(right: Radius.circular(6)),
      ),
      blockquotePadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      code: TextStyle(color: AppColors.saffron600, fontSize: 12, fontFamily: 'monospace', backgroundColor: s.surfaceVariant),
      codeblockDecoration: BoxDecoration(color: s.surfaceVariant, borderRadius: BorderRadius.circular(8)),
      codeblockPadding: const EdgeInsets.all(10),
      horizontalRuleDecoration: BoxDecoration(border: Border(top: BorderSide(color: s.border))),
      tableHead: TextStyle(color: s.textPrimary, fontWeight: FontWeight.w800, fontSize: 12),
      tableBody: TextStyle(color: s.textSecondary, fontSize: 12),
      tableBorder: TableBorder.all(color: s.border, width: 0.6),
      tableCellsPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      tableColumnWidth: const IntrinsicColumnWidth(),
      a: const TextStyle(color: Color(0xFF7C4DFF), decoration: TextDecoration.underline),
    );
  }
}

class _ModeChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;
  const _ModeChip({required this.label, required this.icon, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final s = context.surface;
    return InkWell(
      borderRadius: BorderRadius.circular(99),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? AppColors.saffron500 : s.card,
          borderRadius: BorderRadius.circular(99),
          border: Border.all(color: selected ? AppColors.saffron500 : s.border),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: selected ? Colors.white : s.textSecondary),
            const SizedBox(width: 6),
            Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: selected ? Colors.white : s.textSecondary)),
          ],
        ),
      ),
    );
  }
}
