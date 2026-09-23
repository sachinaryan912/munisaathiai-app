import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/app_text_field.dart';
import '../../core/widgets/async_screen.dart';
import '../../core/widgets/empty_view.dart';
import '../../core/widgets/gradient_button.dart';
import '../../core/widgets/section_card.dart';
import '../auth/data/auth_provider.dart';
import '../shell/app_shell.dart';
import 'shared_repository.dart';

const _revivalTypeLabels = {'REVIVAL_DAY': 'Revival Day', 'GYAN_MELA': 'Gyan Mela', 'BHARAT_BODH': 'Bharat Bodh'};
const _workshopCategoryLabels = {'HEALTH': 'Health Plan', 'SKILL': 'Skill', 'KITCHEN_GARDEN': 'Kitchen Garden'};

class CommunityHubScreen extends StatefulWidget {
  const CommunityHubScreen({super.key});

  @override
  State<CommunityHubScreen> createState() => _CommunityHubScreenState();
}

class _CommunityHubScreenState extends State<CommunityHubScreen> with SingleTickerProviderStateMixin {
  late final TabController _tabController = TabController(length: 4, vsync: this);
  final _repo = SharedRepository();

  @override
  Widget build(BuildContext context) {
    final s = context.surface;
    final role = context.watch<AuthProvider>().user?.role;
    final canPublish = role == 'TRAINER' || role == 'MANAGEMENT';
    return AppShell(
      title: 'Community Hub',
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
            tabs: const [Tab(text: 'Wakeup Board'), Tab(text: 'Revival Day'), Tab(text: 'Workshops'), Tab(text: 'Activity Clubs')],
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _WakeupBoardTab(repo: _repo, canPublish: canPublish),
                _RevivalDayTab(repo: _repo, canPublish: canPublish),
                _WorkshopsTab(repo: _repo, canPublish: canPublish),
                _ActivityClubsTab(repo: _repo, canPublish: canPublish),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Wakeup Call Board ────────────────────────────────────────────────────────
class _WakeupBoardTab extends StatelessWidget {
  final SharedRepository repo;
  final bool canPublish;
  const _WakeupBoardTab({required this.repo, required this.canPublish});

  Future<void> _openAdd(BuildContext context, Future<void> Function() refresh) async {
    final titleCtrl = TextEditingController();
    final contentCtrl = TextEditingController();
    var category = 'Society';
    final formKey = GlobalKey<FormState>();
    var submitted = false;
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
              child: Form(
                key: formKey,
                autovalidateMode: submitted ? AutovalidateMode.onUserInteraction : AutovalidateMode.disabled,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Container(width: 40, height: 4, margin: const EdgeInsets.only(bottom: 14), alignment: Alignment.center, decoration: BoxDecoration(color: s.border, borderRadius: BorderRadius.circular(99))),
                    Text('Post to Wakeup Board', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: s.textPrimary)),
                    const SizedBox(height: 14),
                    Wrap(spacing: 8, children: ['Society', 'Country', 'World'].map((c) {
                      final active = c == category;
                      return ChoiceChip(label: Text(c, style: const TextStyle(fontSize: 11.5)), selected: active, onSelected: (_) => setSheetState(() => category = c), selectedColor: AppColors.saffron500, labelStyle: TextStyle(color: active ? Colors.white : s.textSecondary, fontWeight: FontWeight.w700));
                    }).toList()),
                    const SizedBox(height: 12),
                    AppTextField(
                      label: 'Title',
                      isRequired: true,
                      controller: titleCtrl,
                      validator: (v) => (v == null || v.trim().isEmpty) ? 'Title is required' : null,
                    ),
                    const SizedBox(height: 12),
                    AppTextField(label: 'Content', controller: contentCtrl, maxLines: 3),
                    if (error != null) ...[const SizedBox(height: 10), Text(error!, style: const TextStyle(color: AppColors.danger, fontSize: 12))],
                    const SizedBox(height: 18),
                    GradientButton(
                      label: 'Post',
                      loading: submitting,
                      onPressed: () async {
                        setSheetState(() => submitted = true);
                        if (!formKey.currentState!.validate()) return;
                        setSheetState(() {
                          submitting = true;
                          error = null;
                        });
                        try {
                          await repo.postWakeupCallItem(title: titleCtrl.text.trim(), content: contentCtrl.text.trim(), category: category);
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
      loader: repo.getWakeupCallBoard,
      builder: (context, items, refresh) {
        final s = context.surface;
        return Stack(
          children: [
            items.isEmpty
                ? ListView(children: const [SizedBox(height: 120), EmptyView(title: 'No posts yet', subtitle: 'Current events from society, country and world.', icon: HugeIcons.strokeRoundedNewspaper)])
                : ListView.builder(
                    padding: EdgeInsets.fromLTRB(16, 16, 16, canPublish ? 100 : 24),
                    itemCount: items.length,
                    itemBuilder: (context, i) {
                      final item = items[i];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: SectionCard(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(children: [
                                Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3), decoration: BoxDecoration(color: AppColors.saffron500.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(99)), child: Text(item['category'] as String, style: const TextStyle(fontSize: 9.5, fontWeight: FontWeight.w800, color: AppColors.saffron600))),
                              ]),
                              const SizedBox(height: 6),
                              Text(item['title'] as String, style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13.5, color: s.textPrimary)),
                              if ((item['content'] as String?)?.isNotEmpty ?? false) ...[const SizedBox(height: 4), Text(item['content'] as String, style: TextStyle(fontSize: 12, color: s.textSecondary))],
                            ],
                          ),
                        ),
                      );
                    },
                  ),
            if (canPublish)
              Positioned(right: 16, bottom: 16, child: FloatingActionButton(heroTag: 'add_wakeup', backgroundColor: AppColors.saffron500, onPressed: () => _openAdd(context, refresh), child: const HugeIcon(icon: HugeIcons.strokeRoundedAdd01, color: Colors.white))),
          ],
        );
      },
    );
  }
}

// ── Revival Day / Gyan Mela / Bharat Bodh ────────────────────────────────────
class _RevivalDayTab extends StatelessWidget {
  final SharedRepository repo;
  final bool canPublish;
  const _RevivalDayTab({required this.repo, required this.canPublish});

  Future<void> _openAdd(BuildContext context, Future<void> Function() refresh) async {
    final descCtrl = TextEditingController();
    final classCtrl = TextEditingController();
    var type = 'REVIVAL_DAY';
    final formKey = GlobalKey<FormState>();
    var submitted = false;
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
              child: Form(
                key: formKey,
                autovalidateMode: submitted ? AutovalidateMode.onUserInteraction : AutovalidateMode.disabled,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Container(width: 40, height: 4, margin: const EdgeInsets.only(bottom: 14), alignment: Alignment.center, decoration: BoxDecoration(color: s.border, borderRadius: BorderRadius.circular(99))),
                    Text('Log Thursday Event', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: s.textPrimary)),
                    const SizedBox(height: 12),
                    Wrap(spacing: 8, children: _revivalTypeLabels.entries.map((entry) {
                      final active = type == entry.key;
                      return ChoiceChip(label: Text(entry.value, style: const TextStyle(fontSize: 11.5)), selected: active, onSelected: (_) => setSheetState(() => type = entry.key), selectedColor: AppColors.saffron500, labelStyle: TextStyle(color: active ? Colors.white : s.textSecondary, fontWeight: FontWeight.w700));
                    }).toList()),
                    const SizedBox(height: 12),
                    AppTextField(
                      label: 'Description',
                      isRequired: true,
                      controller: descCtrl,
                      maxLines: 3,
                      validator: (v) => (v == null || v.trim().isEmpty) ? 'Description is required' : null,
                    ),
                    const SizedBox(height: 12),
                    AppTextField(label: 'Class (optional — leave blank for school-wide)', controller: classCtrl),
                    if (error != null) ...[const SizedBox(height: 10), Text(error!, style: const TextStyle(color: AppColors.danger, fontSize: 12))],
                    const SizedBox(height: 18),
                    GradientButton(
                      label: 'Save',
                      loading: submitting,
                      onPressed: () async {
                        setSheetState(() => submitted = true);
                        if (!formKey.currentState!.validate()) return;
                        setSheetState(() {
                          submitting = true;
                          error = null;
                        });
                        try {
                          await repo.logRevivalDayEvent(type: type, description: descCtrl.text.trim(), className: classCtrl.text.trim().isEmpty ? null : classCtrl.text.trim());
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
      loader: repo.getRevivalDayEvents,
      builder: (context, items, refresh) {
        final s = context.surface;
        return Stack(
          children: [
            items.isEmpty
                ? ListView(children: const [SizedBox(height: 120), EmptyView(title: 'No events logged yet', subtitle: 'Revival Day, Gyan Mela and Bharat Bodh events show up here.', icon: HugeIcons.strokeRoundedCalendar03)])
                : ListView.builder(
                    padding: EdgeInsets.fromLTRB(16, 16, 16, canPublish ? 100 : 24),
                    itemCount: items.length,
                    itemBuilder: (context, i) {
                      final item = items[i];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: SectionCard(
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(_revivalTypeLabels[item['type']] ?? item['type'] as String, style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: s.textPrimary)),
                                    Text('${item['date']}${item['className'] != null ? ' · ${item['className']}' : ''}', style: TextStyle(fontSize: 10.5, color: s.textMuted)),
                                    const SizedBox(height: 4),
                                    Text(item['description'] as String, style: TextStyle(fontSize: 12, color: s.textSecondary)),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
            if (canPublish)
              Positioned(right: 16, bottom: 16, child: FloatingActionButton(heroTag: 'add_revival_day', backgroundColor: AppColors.saffron500, onPressed: () => _openAdd(context, refresh), child: const HugeIcon(icon: HugeIcons.strokeRoundedAdd01, color: Colors.white))),
          ],
        );
      },
    );
  }
}

// ── Skill & Wellness Workshops ────────────────────────────────────────────────
class _WorkshopsTab extends StatelessWidget {
  final SharedRepository repo;
  final bool canPublish;
  const _WorkshopsTab({required this.repo, required this.canPublish});

  Future<void> _openAdd(BuildContext context, Future<void> Function() refresh) async {
    final formKey = GlobalKey<FormState>();
    var submitted = false;
    final nameCtrl = TextEditingController();
    final notesCtrl = TextEditingController();
    final attendeeCtrl = TextEditingController();
    var category = 'SKILL';
    var certified = false;
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
              child: Form(
                key: formKey,
                autovalidateMode: submitted ? AutovalidateMode.onUserInteraction : AutovalidateMode.disabled,
                child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(width: 40, height: 4, margin: const EdgeInsets.only(bottom: 14), alignment: Alignment.center, decoration: BoxDecoration(color: s.border, borderRadius: BorderRadius.circular(99))),
                  Text('Log Workshop', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: s.textPrimary)),
                  const SizedBox(height: 12),
                  Wrap(spacing: 8, children: _workshopCategoryLabels.entries.map((entry) {
                    final active = category == entry.key;
                    return ChoiceChip(label: Text(entry.value, style: const TextStyle(fontSize: 11.5)), selected: active, onSelected: (_) => setSheetState(() => category = entry.key), selectedColor: AppColors.saffron500, labelStyle: TextStyle(color: active ? Colors.white : s.textSecondary, fontWeight: FontWeight.w700));
                  }).toList()),
                  const SizedBox(height: 12),
                  AppTextField(
                    label: 'Workshop name',
                    isRequired: true,
                    controller: nameCtrl,
                    hint: 'e.g. CPR Training, Robotics, Kitchen Garden',
                    validator: (v) => (v == null || v.trim().isEmpty) ? 'Workshop name is required' : null,
                  ),
                  const SizedBox(height: 12),
                  AppTextField(label: 'Attendee count (optional)', controller: attendeeCtrl, keyboardType: TextInputType.number),
                  const SizedBox(height: 12),
                  AppTextField(label: 'Notes (optional)', controller: notesCtrl, maxLines: 2),
                  const SizedBox(height: 6),
                  CheckboxListTile(contentPadding: EdgeInsets.zero, value: certified, onChanged: (v) => setSheetState(() => certified = v ?? false), title: Text('Certificates issued', style: TextStyle(fontSize: 12.5, color: s.textPrimary)), controlAffinity: ListTileControlAffinity.leading),
                  if (error != null) ...[Text(error!, style: const TextStyle(color: AppColors.danger, fontSize: 12)), const SizedBox(height: 10)],
                  GradientButton(
                    label: 'Save',
                    loading: submitting,
                    onPressed: () async {
                      setSheetState(() => submitted = true);
                      if (!formKey.currentState!.validate()) return;
                      setSheetState(() {
                        submitting = true;
                        error = null;
                      });
                      try {
                        await repo.logSkillWorkshop(
                          workshopName: nameCtrl.text.trim(),
                          category: category,
                          notes: notesCtrl.text.trim().isEmpty ? null : notesCtrl.text.trim(),
                          attendeeCount: int.tryParse(attendeeCtrl.text.trim()),
                          certified: certified,
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
      loader: repo.getSkillWorkshops,
      builder: (context, items, refresh) {
        final s = context.surface;
        return Stack(
          children: [
            items.isEmpty
                ? const EmptyView(title: 'No skill workshops logged yet', icon: HugeIcons.strokeRoundedPaintBoard)
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
                    itemCount: items.length,
                    itemBuilder: (context, i) {
                      final item = items[i];
                      final cat = item['category'] as String?;
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: SectionCard(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(color: AppColors.saffron500.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(6)),
                                    child: Text(_workshopCategoryLabels[cat] ?? (cat ?? 'Workshop'), style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w700, color: AppColors.saffron600)),
                                  ),
                                  const Spacer(),
                                  Text(DateFormat('d MMM yyyy').format(DateTime.parse(item['date'] as String)), style: TextStyle(fontSize: 11, color: s.textMuted)),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(item['workshopName'] as String, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: s.textPrimary)),
                              if (item['attendeeCount'] != null) ...[
                                const SizedBox(height: 4),
                                Text('${item['attendeeCount']} attendees${(item['certified'] as bool? ?? false) ? ' · Certificates issued' : ''}', style: TextStyle(fontSize: 11.5, color: s.textSecondary)),
                              ],
                              if ((item['notes'] as String?)?.isNotEmpty ?? false) ...[
                                const SizedBox(height: 6),
                                Text(item['notes'] as String, style: TextStyle(fontSize: 12, color: s.textMuted)),
                              ],
                            ],
                          ),
                        ),
                      );
                    },
                  ),
            if (canPublish)
              Positioned(
                right: 16,
                bottom: 16,
                child: FloatingActionButton.extended(
                  heroTag: 'fab_workshop',
                  onPressed: () => _openAdd(context, refresh),
                  backgroundColor: AppColors.saffron500,
                  foregroundColor: Colors.white,
                  icon: const Icon(Icons.add),
                  label: const Text('Log Workshop', style: TextStyle(fontWeight: FontWeight.w800)),
                ),
              ),
          ],
        );
      },
    );
  }
}

// ── Activity Clubs ────────────────────────────────────────────────────────────
class _ActivityClubsTab extends StatelessWidget {
  final SharedRepository repo;
  final bool canPublish;
  const _ActivityClubsTab({required this.repo, required this.canPublish});

  Future<void> _openAdd(BuildContext context, Future<void> Function() refresh) async {
    final formKey = GlobalKey<FormState>();
    var submitted = false;
    final nameCtrl = TextEditingController();
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
              child: Form(
                key: formKey,
                autovalidateMode: submitted ? AutovalidateMode.onUserInteraction : AutovalidateMode.disabled,
                child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(width: 40, height: 4, margin: const EdgeInsets.only(bottom: 14), alignment: Alignment.center, decoration: BoxDecoration(color: s.border, borderRadius: BorderRadius.circular(99))),
                  Text('New Activity Club', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: s.textPrimary)),
                  const SizedBox(height: 14),
                  AppTextField(
                    label: 'Club name',
                    isRequired: true,
                    controller: nameCtrl,
                    hint: 'e.g. Drama, Art & Craft, Sports, Music',
                    validator: (v) => (v == null || v.trim().isEmpty) ? 'Club name is required' : null,
                  ),
                  if (error != null) ...[const SizedBox(height: 10), Text(error!, style: const TextStyle(color: AppColors.danger, fontSize: 12))],
                  const SizedBox(height: 18),
                  GradientButton(
                    label: 'Create',
                    loading: submitting,
                    onPressed: () async {
                      setSheetState(() => submitted = true);
                      if (!formKey.currentState!.validate()) return;
                      setSheetState(() {
                        submitting = true;
                        error = null;
                      });
                      try {
                        await repo.createActivityClub(nameCtrl.text.trim());
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
      loader: repo.getActivityClubs,
      builder: (context, items, refresh) {
        final s = context.surface;
        return Stack(
          children: [
            items.isEmpty
                ? ListView(children: const [SizedBox(height: 120), EmptyView(title: 'No clubs yet', subtitle: 'Drama, art & craft, sports, music, reasoning...', icon: HugeIcons.strokeRoundedUserGroup)])
                : ListView.builder(
                    padding: EdgeInsets.fromLTRB(16, 16, 16, canPublish ? 100 : 24),
                    itemCount: items.length,
                    itemBuilder: (context, i) {
                      final item = items[i];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: SectionCard(
                          child: Row(children: [
                            Container(width: 36, height: 36, decoration: BoxDecoration(color: AppColors.saffron50, borderRadius: BorderRadius.circular(12)), child: const Center(child: HugeIcon(icon: HugeIcons.strokeRoundedUserGroup, size: 16, color: AppColors.saffron600))),
                            const SizedBox(width: 12),
                            Text(item['name'] as String, style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13.5, color: s.textPrimary)),
                          ]),
                        ),
                      );
                    },
                  ),
            if (canPublish)
              Positioned(right: 16, bottom: 16, child: FloatingActionButton(heroTag: 'add_club', backgroundColor: AppColors.saffron500, onPressed: () => _openAdd(context, refresh), child: const HugeIcon(icon: HugeIcons.strokeRoundedAdd01, color: Colors.white))),
          ],
        );
      },
    );
  }
}
