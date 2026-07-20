import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/app_text_field.dart';
import '../../core/widgets/empty_view.dart';
import '../../core/widgets/gradient_button.dart';
import '../../core/widgets/list_search_field.dart';
import '../../core/widgets/section_card.dart';
import '../shell/app_shell.dart';
import 'session_detail_screen.dart';
import 'trainer_repository.dart';
import 'widgets/observations_tab.dart';
import '../videos/video_screen.dart';

class TrainerTrainingScreen extends StatefulWidget {
  const TrainerTrainingScreen({super.key});

  @override
  State<TrainerTrainingScreen> createState() => _TrainerTrainingScreenState();
}

class _TrainerTrainingScreenState extends State<TrainerTrainingScreen> with SingleTickerProviderStateMixin {
  final _repo = TrainerRepository();
  late final TabController _tabController = TabController(length: 4, vsync: this)..addListener(() => setState(() {}));
  List<Map<String, dynamic>>? _sessions;
  List<Map<String, dynamic>>? _evidence;
  List<Map<String, dynamic>> _schools = [];
  bool _loading = true;
  String? _error;
  final _searchCtrl = TextEditingController();
  String _query = '';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final results = await Future.wait([_repo.getSessions(), _repo.getEvidenceQueue(), _repo.getSchools()]);
      _sessions = results[0];
      _evidence = results[1];
      _schools = results[2];
      _error = null;
    } catch (e) {
      _error = e.toString().replaceFirst('ApiException: ', '');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _openCreateSession() async {
    if (_schools.isEmpty) return;
    int schoolId = _schools.first['id'] as int;
    final topicCtrl = TextEditingController();
    final venueCtrl = TextEditingController();
    var mode = 'On-site';
    var date = DateTime.now();
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
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Container(width: 40, height: 4, margin: const EdgeInsets.only(bottom: 14), alignment: Alignment.center, decoration: BoxDecoration(color: s.border, borderRadius: BorderRadius.circular(99))),
                    Text('New Training Session', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 17, color: s.textPrimary)),
                    const SizedBox(height: 16),
                    Text('School', style: Theme.of(sheetContext).inputDecorationTheme.labelStyle),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      decoration: BoxDecoration(color: Theme.of(sheetContext).inputDecorationTheme.fillColor, borderRadius: BorderRadius.circular(16)),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<int>(
                          value: schoolId,
                          isExpanded: true,
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          items: _schools.map((sc) => DropdownMenuItem(value: sc['id'] as int, child: Text(sc['name'] as String))).toList(),
                          onChanged: (v) => setSheetState(() => schoolId = v!),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    AppTextField(label: 'Topic', controller: topicCtrl),
                    const SizedBox(height: 14),
                    InkWell(
                      onTap: () async {
                        final picked = await showDatePicker(context: sheetContext, initialDate: date, firstDate: DateTime(2024), lastDate: DateTime(2030));
                        if (picked != null) setSheetState(() => date = picked);
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
                        decoration: BoxDecoration(color: Theme.of(sheetContext).inputDecorationTheme.fillColor, borderRadius: BorderRadius.circular(16)),
                        child: Row(children: [const Icon(LucideIcons.calendar, size: 16, color: AppColors.saffron600), const SizedBox(width: 8), Text(DateFormat('d MMM yyyy').format(date), style: TextStyle(fontWeight: FontWeight.w700, color: s.textPrimary))]),
                      ),
                    ),
                    const SizedBox(height: 14),
                    AppTextField(label: 'Venue (optional)', controller: venueCtrl),
                    const SizedBox(height: 14),
                    Wrap(spacing: 8, children: ['On-site', 'Online'].map((m) {
                      final active = m == mode;
                      return ChoiceChip(label: Text(m), selected: active, onSelected: (_) => setSheetState(() => mode = m), selectedColor: AppColors.saffron500, labelStyle: TextStyle(color: active ? Colors.white : s.textSecondary, fontWeight: FontWeight.w700), backgroundColor: s.border.withValues(alpha: 0.4), side: BorderSide.none);
                    }).toList()),
                    if (error != null) ...[const SizedBox(height: 10), Text(error!, style: const TextStyle(color: AppColors.danger, fontSize: 12))],
                    const SizedBox(height: 18),
                    GradientButton(
                      label: 'Create Session',
                      loading: submitting,
                      onPressed: () async {
                        if (topicCtrl.text.trim().isEmpty) {
                          setSheetState(() => error = 'Topic is required.');
                          return;
                        }
                        setSheetState(() => submitting = true);
                        try {
                          await _repo.createSession(schoolId: schoolId, topic: topicCtrl.text.trim(), date: DateFormat('yyyy-MM-dd').format(date), venue: venueCtrl.text.trim().isEmpty ? null : venueCtrl.text.trim(), mode: mode);
                          if (sheetContext.mounted) Navigator.pop(sheetContext);
                          await _load();
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

  Future<void> _verify(int id, bool verified) async {
    await _repo.verifyEvidence(id, verified);
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    final s = context.surface;
    return AppShell(
      title: 'Training',
      showAiFab: false,
      body: Column(
        children: [
          TabBar(
            controller: _tabController,
            labelColor: AppColors.saffron600,
            unselectedLabelColor: s.textMuted,
            indicatorColor: AppColors.saffron500,
            labelStyle: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w800),
            isScrollable: true,
            tabs: const [Tab(text: 'Sessions'), Tab(text: 'Evidence Review'), Tab(text: 'Observations'), Tab(text: 'Videos')],
          ),
          if (!_loading && _error == null && _tabController.index < 2 && ((_sessions?.isNotEmpty ?? false) || (_evidence?.isNotEmpty ?? false)))
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
              child: ListSearchField(
                controller: _searchCtrl,
                hint: _tabController.index == 0 ? 'Search by topic or school' : 'Search by methodology, teacher or school',
                onChanged: (v) => setState(() => _query = v),
              ),
            ),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _error != null
                    ? Center(child: Text(_error!, style: const TextStyle(color: AppColors.danger)))
                    : TabBarView(
                        controller: _tabController,
                        children: [
                          _buildSessionsTab(s),
                          _buildEvidenceTab(s),
                          const ObservationsTab(),
                          const VideoResourcesScreen(),
                        ],
                      ),
          ),
        ],
      ),
      floatingActionButton: _tabController.index == 0
          ? FloatingActionButton(heroTag: 'create_session', backgroundColor: AppColors.saffron500, onPressed: _openCreateSession, child: const Icon(Icons.add, color: Colors.white))
          : null,
    );
  }

  Widget _buildSessionsTab(MuniSurface s) {
    final q = _query.trim().toLowerCase();
    final sessions = q.isEmpty
        ? _sessions!
        : _sessions!.where((sess) {
            return (sess['topic'] as String? ?? '').toLowerCase().contains(q) ||
                (sess['schoolName'] as String? ?? '').toLowerCase().contains(q);
          }).toList();
    if (sessions.isEmpty) {
      return ListView(children: [
        const SizedBox(height: 80),
        EmptyView(title: _sessions!.isEmpty ? 'No training sessions yet' : 'No sessions match your search', icon: LucideIcons.bookOpen),
      ]);
    }
    return ListView.builder(
                                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
                                  itemCount: sessions.length,
                                  itemBuilder: (context, i) {
                                    final sess = sessions[i];
                                    return Padding(
                                      padding: const EdgeInsets.only(bottom: 10),
                                      child: SectionCard(
                                        onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => SessionDetailScreen(sessionId: sess['id'] as int))).then((_) => _load()),
                                        child: Row(
                                          children: [
                                            Container(width: 40, height: 40, decoration: BoxDecoration(color: AppColors.saffron50, borderRadius: BorderRadius.circular(13)), child: const Icon(LucideIcons.bookOpen, size: 18, color: AppColors.saffron600)),
                                            const SizedBox(width: 12),
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Text(sess['topic'] as String, style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13.5, color: s.textPrimary)),
                                                  Text('${sess['schoolName']} · ${sess['date']} · ${sess['mode']}', style: TextStyle(fontSize: 11, color: s.textMuted)),
                                                ],
                                              ),
                                            ),
                                            Text('${sess['attendedCount']}/${sess['attendeeCount']}', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w800, color: s.textPrimary)),
                                          ],
                                        ),
                                      ),
                                    ).animate(delay: (i * 40).ms).fadeIn(duration: 280.ms).slideY(begin: 0.06, end: 0, curve: Curves.easeOutCubic);
                                  },
                                );
  }

  Widget _buildEvidenceTab(MuniSurface s) {
    final q = _query.trim().toLowerCase();
    final evidence = q.isEmpty
        ? _evidence!
        : _evidence!.where((e) {
            return (e['methodology'] as String? ?? '').toLowerCase().contains(q) ||
                (e['teacherName'] as String? ?? '').toLowerCase().contains(q) ||
                (e['schoolName'] as String? ?? '').toLowerCase().contains(q);
          }).toList();
    if (evidence.isEmpty) {
      return ListView(children: [
        const SizedBox(height: 80),
        EmptyView(title: _evidence!.isEmpty ? 'No evidence pending review' : 'No evidence matches your search', icon: LucideIcons.circleCheck),
      ]);
    }
    return ListView.builder(
                                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 40),
                                  itemCount: evidence.length,
                                  itemBuilder: (context, i) {
                                    final e = evidence[i];
                                    final verified = e['trainerVerified'] as bool? ?? false;
                                    return Padding(
                                      padding: const EdgeInsets.only(bottom: 10),
                                      child: SectionCard(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Row(children: [
                                              Expanded(
                                                child: Column(
                                                  crossAxisAlignment: CrossAxisAlignment.start,
                                                  children: [
                                                    Text('${e['methodology']} — ${e['teacherName']}', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: s.textPrimary)),
                                                    Text('${e['schoolName']} · ${e['fileName']}', style: TextStyle(fontSize: 10.5, color: s.textMuted), overflow: TextOverflow.ellipsis),
                                                  ],
                                                ),
                                              ),
                                            ]),
                                            if (e['aiScore'] != null)
                                              Padding(padding: const EdgeInsets.only(top: 6), child: Text('AI: ${e['aiScore']}/${e['aiMaxScore']} — ${e['aiVerdict'] ?? ''}', style: TextStyle(fontSize: 11, color: s.textSecondary))),
                                            const SizedBox(height: 10),
                                            if (verified)
                                              const Row(children: [Icon(LucideIcons.circleCheck, size: 15, color: AppColors.success), SizedBox(width: 6), Text('Verified', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.success))])
                                            else
                                              Row(children: [
                                                Expanded(child: OutlinedButton(onPressed: () => _verify(e['id'] as int, true), style: OutlinedButton.styleFrom(foregroundColor: AppColors.success, padding: const EdgeInsets.symmetric(vertical: 9)), child: const Text('Verify', style: TextStyle(fontSize: 12)))),
                                                const SizedBox(width: 8),
                                                Expanded(child: OutlinedButton(onPressed: () => _verify(e['id'] as int, false), style: OutlinedButton.styleFrom(foregroundColor: AppColors.danger, padding: const EdgeInsets.symmetric(vertical: 9)), child: const Text('Reject', style: TextStyle(fontSize: 12)))),
                                              ]),
                                          ],
                                        ),
                                      ),
                                    ).animate(delay: (i * 40).ms).fadeIn(duration: 280.ms).slideY(begin: 0.06, end: 0, curve: Curves.easeOutCubic);
                                  },
                                );
  }
}
