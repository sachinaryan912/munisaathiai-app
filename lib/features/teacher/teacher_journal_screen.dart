import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/app_text_field.dart';
import '../../core/widgets/async_screen.dart';
import '../../core/widgets/empty_view.dart';
import '../../core/widgets/gradient_button.dart';
import '../../core/widgets/section_card.dart';
import '../shell/app_shell.dart';
import 'teacher_repository.dart';

const _ecceFormat = [
  'Meaning', 'Questions related to daily life', 'Sambandh (Relation)', 'Vyavastha (System)',
  'Sah-Astitav (Co-existence)', 'Application', 'Importance', 'Shram (Effort)', 'Abhyas (Practice)',
  'Samiksha (Review)', 'Moolyankan (Evaluation)',
];

const _ecceSubjects = [
  'Life Skills', 'Reasoning & Logics', 'Habits', 'Language', 'Bharat Bodh',
  'Physical Education', 'Brain Activities (Brain Mapping, Abacus, Juggling)', 'Science', 'Math',
];

class TeacherJournalScreen extends StatefulWidget {
  const TeacherJournalScreen({super.key});

  @override
  State<TeacherJournalScreen> createState() => _TeacherJournalScreenState();
}

class _TeacherJournalScreenState extends State<TeacherJournalScreen> with SingleTickerProviderStateMixin {
  late final TabController _tabController = TabController(length: 4, vsync: this);
  final _repo = TeacherRepository();

  @override
  Widget build(BuildContext context) {
    final s = context.surface;
    return AppShell(
      title: 'Teaching Journal',
      showAiFab: false,
      body: Column(
        children: [
          TabBar(
            controller: _tabController,
            isScrollable: true,
            labelColor: AppColors.saffron600,
            unselectedLabelColor: s.textMuted,
            indicatorColor: AppColors.saffron500,
            labelStyle: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w800),
            tabs: const [Tab(text: 'Center Work'), Tab(text: 'Values Discussion'), Tab(text: 'Oath Tracker'), Tab(text: 'ECCE Syllabus')],
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [_CenterWorkTab(repo: _repo), _ValuesDiscussionTab(repo: _repo), _OathTrackerTab(repo: _repo), const _EcceSyllabusTab()],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Center Work ──────────────────────────────────────────────────────────────
const _centerFields = [
  ('researchCreativityNotes', 'Research & Creativity'),
  ('constructionNotes', 'Construction'),
  ('mathScienceNotes', 'Math & Science'),
  ('rolePlayNotes', 'Role Play'),
  ('abcLanguageNotes', 'ABC (Language)'),
];

class _CenterWorkTab extends StatelessWidget {
  final TeacherRepository repo;
  const _CenterWorkTab({required this.repo});

  Future<void> _openAdd(BuildContext context, Future<void> Function() refresh) async {
    final topicCtrl = TextEditingController();
    final controllers = {for (final f in _centerFields) f.$1: TextEditingController()};
    var submitting = false;
    String? error;

    await showModalBottomSheet(
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
              constraints: BoxConstraints(maxHeight: MediaQuery.of(sheetContext).size.height * 0.85),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Container(width: 40, height: 4, margin: const EdgeInsets.only(bottom: 14), alignment: Alignment.center, decoration: BoxDecoration(color: s.border, borderRadius: BorderRadius.circular(99))),
                    Text('Log Center Work', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: s.textPrimary)),
                    const SizedBox(height: 14),
                    AppTextField(label: 'Topic', controller: topicCtrl),
                    const SizedBox(height: 12),
                    for (final f in _centerFields) ...[
                      AppTextField(label: f.$2, controller: controllers[f.$1]!, maxLines: 2),
                      const SizedBox(height: 12),
                    ],
                    if (error != null) ...[Text(error!, style: const TextStyle(color: AppColors.danger, fontSize: 12)), const SizedBox(height: 10)],
                    GradientButton(
                      label: 'Save',
                      loading: submitting,
                      onPressed: () async {
                        if (topicCtrl.text.trim().isEmpty) {
                          setSheetState(() => error = 'Please enter the topic.');
                          return;
                        }
                        setSheetState(() {
                          submitting = true;
                          error = null;
                        });
                        try {
                          await repo.logCenterWork(
                            topic: topicCtrl.text.trim(),
                            researchCreativityNotes: controllers['researchCreativityNotes']!.text.trim(),
                            constructionNotes: controllers['constructionNotes']!.text.trim(),
                            mathScienceNotes: controllers['mathScienceNotes']!.text.trim(),
                            rolePlayNotes: controllers['rolePlayNotes']!.text.trim(),
                            abcLanguageNotes: controllers['abcLanguageNotes']!.text.trim(),
                          );
                          if (sheetContext.mounted) Navigator.pop(sheetContext);
                          await refresh();
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

  @override
  Widget build(BuildContext context) {
    return AsyncScreen<List<Map<String, dynamic>>>(
      loader: repo.getCenterWorkEntries,
      builder: (context, items, refresh) {
        final s = context.surface;
        return Stack(
          children: [
            items.isEmpty
                ? ListView(children: const [SizedBox(height: 120), EmptyView(title: 'No center work logged yet', subtitle: 'Research & Creativity, Construction, Math & Science, Role Play, ABC.', icon: LucideIcons.layoutGrid)])
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                    itemCount: items.length,
                    itemBuilder: (context, i) {
                      final e = items[i];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: SectionCard(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(e['topic'] as String, style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13.5, color: s.textPrimary)),
                              Text('${e['className'] ?? ''} ${e['section'] ?? ''} · ${e['date']}', style: TextStyle(fontSize: 10.5, color: s.textMuted)),
                              const SizedBox(height: 6),
                              for (final f in _centerFields)
                                if ((e[f.$1] as String?)?.isNotEmpty ?? false)
                                  Padding(padding: const EdgeInsets.only(bottom: 3), child: Text('${f.$2}: ${e[f.$1]}', style: TextStyle(fontSize: 11.5, color: s.textSecondary))),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
            Positioned(right: 16, bottom: 16, child: FloatingActionButton(heroTag: 'add_center_work', backgroundColor: AppColors.saffron500, onPressed: () => _openAdd(context, refresh), child: const Icon(Icons.add, color: Colors.white))),
          ],
        );
      },
    );
  }
}

// ── Values Discussion ────────────────────────────────────────────────────────
class _ValuesDiscussionTab extends StatelessWidget {
  final TeacherRepository repo;
  const _ValuesDiscussionTab({required this.repo});

  Future<void> _openAdd(BuildContext context, Future<void> Function() refresh) async {
    final topicCtrl = TextEditingController();
    final notesCtrl = TextEditingController();
    var submitting = false;
    String? error;

    await showModalBottomSheet(
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
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(width: 40, height: 4, margin: const EdgeInsets.only(bottom: 14), alignment: Alignment.center, decoration: BoxDecoration(color: s.border, borderRadius: BorderRadius.circular(99))),
                  Text('Log Values Discussion', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: s.textPrimary)),
                  const SizedBox(height: 14),
                  AppTextField(label: 'Value discussed', controller: topicCtrl, hint: 'e.g. Gratitude, Responsibility'),
                  const SizedBox(height: 12),
                  AppTextField(label: 'Notes (optional)', controller: notesCtrl, maxLines: 3),
                  if (error != null) ...[const SizedBox(height: 10), Text(error!, style: const TextStyle(color: AppColors.danger, fontSize: 12))],
                  const SizedBox(height: 18),
                  GradientButton(
                    label: 'Save',
                    loading: submitting,
                    onPressed: () async {
                      if (topicCtrl.text.trim().isEmpty) {
                        setSheetState(() => error = 'Please enter the value discussed.');
                        return;
                      }
                      setSheetState(() {
                        submitting = true;
                        error = null;
                      });
                      try {
                        await repo.logValuesDiscussion(valueTopic: topicCtrl.text.trim(), notes: notesCtrl.text.trim().isEmpty ? null : notesCtrl.text.trim());
                        if (sheetContext.mounted) Navigator.pop(sheetContext);
                        await refresh();
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
          );
        });
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return AsyncScreen<List<Map<String, dynamic>>>(
      loader: repo.getValuesDiscussionLogs,
      builder: (context, items, refresh) {
        final s = context.surface;
        return Stack(
          children: [
            items.isEmpty
                ? ListView(children: const [SizedBox(height: 120), EmptyView(title: 'No discussions logged yet', subtitle: 'The daily first-period values discussion.', icon: LucideIcons.handHeart)])
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                    itemCount: items.length,
                    itemBuilder: (context, i) {
                      final e = items[i];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: SectionCard(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(e['valueTopic'] as String, style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13.5, color: s.textPrimary)),
                              Text(e['date'] as String, style: TextStyle(fontSize: 10.5, color: s.textMuted)),
                              if ((e['notes'] as String?)?.isNotEmpty ?? false) ...[const SizedBox(height: 6), Text(e['notes'] as String, style: TextStyle(fontSize: 12, color: s.textSecondary))],
                            ],
                          ),
                        ),
                      );
                    },
                  ),
            Positioned(right: 16, bottom: 16, child: FloatingActionButton(heroTag: 'add_values_discussion', backgroundColor: AppColors.saffron500, onPressed: () => _openAdd(context, refresh), child: const Icon(Icons.add, color: Colors.white))),
          ],
        );
      },
    );
  }
}

// ── Oath Tracker ──────────────────────────────────────────────────────────────
class _OathTrackerTab extends StatefulWidget {
  final TeacherRepository repo;
  const _OathTrackerTab({required this.repo});

  @override
  State<_OathTrackerTab> createState() => _OathTrackerTabState();
}

class _OathTrackerTabState extends State<_OathTrackerTab> {
  bool _marking = false;

  Future<void> _mark(Future<void> Function() refresh) async {
    setState(() => _marking = true);
    try {
      await widget.repo.markOathRecited();
      await refresh();
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString().replaceFirst('ApiException: ', ''))));
    } finally {
      if (mounted) setState(() => _marking = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AsyncScreen<List<Map<String, dynamic>>>(
      loader: widget.repo.getOathRecords,
      builder: (context, items, refresh) {
        final s = context.surface;
        final today = DateTime.now().toIso8601String().substring(0, 10);
        final recitedToday = items.any((e) => e['date'] == today);
        return ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
          children: [
            SectionCard(
              child: Column(
                children: [
                  Icon(recitedToday ? LucideIcons.circleCheck : LucideIcons.circle, size: 32, color: recitedToday ? AppColors.success : s.textMuted),
                  const SizedBox(height: 10),
                  Text(recitedToday ? 'Oath recited today' : 'Oath not marked yet today', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13.5, color: s.textPrimary)),
                  const SizedBox(height: 12),
                  if (!recitedToday)
                    GradientButton(label: 'Mark as Recited', loading: _marking, onPressed: () => _mark(refresh), height: 42),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Text('History', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 14, color: s.textPrimary)),
            const SizedBox(height: 10),
            if (items.isEmpty)
              Text('No records yet.', style: TextStyle(fontSize: 12, color: s.textMuted))
            else
              SectionCard(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Column(
                  children: items.map((e) => ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 6),
                        leading: const Icon(LucideIcons.circleCheck, size: 16, color: AppColors.success),
                        title: Text(e['date'] as String, style: TextStyle(fontSize: 12.5, color: s.textPrimary)),
                      )).toList(),
                ),
              ),
          ],
        );
      },
    );
  }
}

// ── ECCE Syllabus reference ──────────────────────────────────────────────────
class _EcceSyllabusTab extends StatelessWidget {
  const _EcceSyllabusTab();

  @override
  Widget build(BuildContext context) {
    final s = context.surface;
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
      children: [
        Text('Early Child Care & Education', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 15, color: s.textPrimary)),
        const SizedBox(height: 4),
        Text('For LKG, UKG and 1st class.', style: TextStyle(fontSize: 11.5, color: s.textMuted)),
        const SizedBox(height: 14),
        Text('Lesson Format', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: s.textPrimary)),
        const SizedBox(height: 8),
        SectionCard(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Column(
            children: _ecceFormat.asMap().entries.map((e) => ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 6),
                  leading: CircleAvatar(radius: 12, backgroundColor: AppColors.saffron100, child: Text('${e.key + 1}', style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w800, color: AppColors.saffron700))),
                  title: Text(e.value, style: TextStyle(fontSize: 12.5, color: s.textPrimary)),
                )).toList(),
          ),
        ),
        const SizedBox(height: 18),
        Text('Subjects', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: s.textPrimary)),
        const SizedBox(height: 8),
        SectionCard(
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _ecceSubjects.map((subject) => Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6), decoration: BoxDecoration(color: s.bg, borderRadius: BorderRadius.circular(10)), child: Text(subject, style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: s.textSecondary)))).toList(),
          ),
        ),
      ],
    );
  }
}
