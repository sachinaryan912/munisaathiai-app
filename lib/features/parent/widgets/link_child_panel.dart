import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../parent_repository.dart';
import '../selected_child_provider.dart';

class LinkChildPanel extends StatefulWidget {
  const LinkChildPanel({super.key});

  @override
  State<LinkChildPanel> createState() => _LinkChildPanelState();
}

class _LinkChildPanelState extends State<LinkChildPanel> {
  final _repo = ParentRepository();
  final _queryCtrl = TextEditingController();
  List<Map<String, dynamic>> _results = [];
  bool _searching = false;
  int? _linkingId;
  String? _error;

  Future<void> _search(String query) async {
    if (query.trim().length < 2) {
      setState(() => _results = []);
      return;
    }
    setState(() => _searching = true);
    try {
      _results = await _repo.searchChildren(query.trim());
    } catch (_) {
      _results = [];
    } finally {
      if (mounted) setState(() => _searching = false);
    }
  }

  Future<void> _link(int childId) async {
    setState(() {
      _linkingId = childId;
      _error = null;
    });
    try {
      await context.read<SelectedChildProvider>().linkChild(childId);
    } catch (e) {
      setState(() => _error = e.toString().replaceFirst('ApiException: ', ''));
    } finally {
      if (mounted) setState(() => _linkingId = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = context.surface;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          controller: _queryCtrl,
          onChanged: _search,
          decoration: InputDecoration(
            hintText: "Search your child's name",
            prefixIcon: const Icon(Icons.search_rounded, size: 20),
            suffixIcon: _searching ? const Padding(padding: EdgeInsets.all(14), child: SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2))) : null,
          ),
        ),
        if (_error != null) Padding(padding: const EdgeInsets.only(top: 8), child: Text(_error!, style: const TextStyle(color: AppColors.danger, fontSize: 12))),
        if (_results.isNotEmpty) ...[
          const SizedBox(height: 12),
          ..._results.map((c) {
            final id = c['id'] as int;
            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(color: s.card, borderRadius: BorderRadius.circular(14), border: Border.all(color: s.border)),
              child: Row(
                children: [
                  CircleAvatar(radius: 16, backgroundColor: AppColors.roleColor('STUDENT'), child: Text((c['fullName'] as String).isNotEmpty ? (c['fullName'] as String)[0].toUpperCase() : '?', style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w800))),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(c['fullName'] as String, style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: s.textPrimary)),
                        Text('${c['className'] ?? ''} ${c['section'] ?? ''} · ${c['schoolName'] ?? ''}', style: TextStyle(fontSize: 10.5, color: s.textMuted)),
                      ],
                    ),
                  ),
                  _linkingId == id
                      ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                      : TextButton(onPressed: () => _link(id), child: const Text('Link', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800))),
                ],
              ),
            );
          }),
        ] else if (_queryCtrl.text.trim().length >= 2 && !_searching)
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Text('No matching students found.', style: TextStyle(fontSize: 12, color: s.textMuted)),
          ),
      ],
    );
  }
}

class NotLinkedState extends StatelessWidget {
  final String message;
  const NotLinkedState({super.key, this.message = 'Link your child to continue'});

  @override
  Widget build(BuildContext context) {
    final s = context.surface;
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 40, 24, 24),
      child: Column(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(color: AppColors.saffron50, borderRadius: BorderRadius.circular(18)),
            child: const Icon(LucideIcons.users, color: AppColors.saffron500, size: 26),
          ),
          const SizedBox(height: 14),
          Text(message, textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: s.textPrimary)),
          const SizedBox(height: 20),
          const LinkChildPanel(),
        ],
      ),
    );
  }
}
