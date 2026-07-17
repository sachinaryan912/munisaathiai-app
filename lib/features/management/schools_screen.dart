import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/async_screen.dart';
import '../../core/widgets/empty_view.dart';
import '../../core/widgets/section_card.dart';
import '../shell/app_shell.dart';
import 'management_repository.dart';
import 'widgets/school_form_sheet.dart';
import 'widgets/school_status_widgets.dart';

class ManagementSchoolsScreen extends StatefulWidget {
  const ManagementSchoolsScreen({super.key});

  @override
  State<ManagementSchoolsScreen> createState() => _ManagementSchoolsScreenState();
}

class _ManagementSchoolsScreenState extends State<ManagementSchoolsScreen> {
  final _repo = ManagementRepository();

  Future<void> _openAdd(Future<void> Function() refresh) async {
    final payload = await showSchoolFormSheet(context);
    if (payload == null) return;
    try {
      await _repo.addSchool(payload);
      await refresh();
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString().replaceFirst('ApiException: ', ''))));
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppShell(
      title: 'Schools',
      showAiFab: false,
      body: AsyncScreen<Map<String, dynamic>>(
        loader: _repo.getOverview,
        builder: (context, data, refresh) {
          final s = context.surface;
          final schools = (data['schools'] as List? ?? []).cast<Map<String, dynamic>>();
          return Stack(
            children: [
              schools.isEmpty
                  ? ListView(children: const [SizedBox(height: 120), EmptyView(title: 'No schools yet', subtitle: 'Tap + to add your first school.', icon: LucideIcons.school)])
                  : ListView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                      itemCount: schools.length,
                      itemBuilder: (context, i) {
                        final sc = schools[i];
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: SectionCard(
                            onTap: () => context.push('/management/schools/${sc['id']}'),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(sc['name'] as String, style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: s.textPrimary)),
                                      const SizedBox(height: 3),
                                      Text('${sc['district']} · Trainer: ${sc['trainer']}', style: TextStyle(fontSize: 11, color: s.textMuted)),
                                      const SizedBox(height: 4),
                                      Text('${sc['teacherCount']} teachers · ${sc['studentCount']} students', style: TextStyle(fontSize: 10.5, color: s.textMuted)),
                                    ],
                                  ),
                                ),
                                SchoolStatusBadge(mii: sc['miiScore'] as int? ?? 0, status: sc['status'] as String?),
                              ],
                            ),
                          ),
                        ).animate(delay: (i * 40).ms).fadeIn(duration: 280.ms).slideY(begin: 0.06, end: 0, curve: Curves.easeOutCubic);
                      },
                    ),
              Positioned(right: 16, bottom: 16, child: FloatingActionButton(heroTag: 'add_school', backgroundColor: AppColors.saffron500, onPressed: () => _openAdd(refresh), child: const Icon(Icons.add, color: Colors.white))),
            ],
          );
        },
      ),
    );
  }
}
