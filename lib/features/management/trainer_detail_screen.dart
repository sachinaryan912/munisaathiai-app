import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/async_screen.dart';
import '../../core/widgets/empty_view.dart';
import '../../core/widgets/section_card.dart';
import 'management_repository.dart';

class TrainerDetailScreen extends StatelessWidget {
  final int trainerId;
  const TrainerDetailScreen({super.key, required this.trainerId});

  @override
  Widget build(BuildContext context) {
    final repo = ManagementRepository();
    return AsyncScreen<Map<String, dynamic>>(
      loader: () => repo.getTrainerDetail(trainerId),
      builder: (context, trainer, refresh) {
        final s = context.surface;
        final schools = (trainer['schools'] as List? ?? []).cast<Map<String, dynamic>>();
        final sessions = (trainer['sessions'] as List? ?? []).cast<Map<String, dynamic>>();
        final certifications = (trainer['certifications'] as List? ?? []).cast<Map<String, dynamic>>();
        return Scaffold(
          appBar: AppBar(title: Text(trainer['fullName'] as String)),
          body: ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
            children: [
              SectionCard(
                child: Row(
                  children: [
                    CircleAvatar(radius: 22, backgroundColor: AppColors.roleColor('TRAINER'), child: Text((trainer['fullName'] as String).isNotEmpty ? (trainer['fullName'] as String)[0].toUpperCase() : '?', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 16))),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(trainer['email'] as String, style: TextStyle(fontSize: 12, color: s.textMuted)),
                          Text(trainer['phone'] as String? ?? '', style: TextStyle(fontSize: 12, color: s.textMuted)),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text('${trainer['avgMii']}', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: s.textPrimary)),
                        Text('avg MII', style: TextStyle(fontSize: 9, color: s.textMuted)),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 22),
              Text('Schools (${trainer['schoolCount']})', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 15, color: s.textPrimary)),
              const SizedBox(height: 10),
              schools.isEmpty
                  ? SectionCard(child: Text('No schools assigned yet.', style: TextStyle(fontSize: 12, color: s.textMuted)))
                  : SectionCard(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Column(
                        children: schools.map((sc) => ListTile(
                              contentPadding: const EdgeInsets.symmetric(horizontal: 6),
                              title: Text(sc['name'] as String, style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: s.textPrimary)),
                              subtitle: Text('${sc['district']} · ${sc['status']}', style: TextStyle(fontSize: 10.5, color: s.textMuted)),
                              trailing: Text('${sc['miiScore']}', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: s.textPrimary)),
                            )).toList(),
                      ),
                    ),
              const SizedBox(height: 22),
              Text('Training Sessions (${sessions.length})', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 15, color: s.textPrimary)),
              const SizedBox(height: 10),
              sessions.isEmpty
                  ? SectionCard(child: Text('No training sessions run yet.', style: TextStyle(fontSize: 12, color: s.textMuted)))
                  : SectionCard(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Column(
                        children: sessions.map((sess) => ListTile(
                              contentPadding: const EdgeInsets.symmetric(horizontal: 6),
                              title: Text(sess['topic'] as String, style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: s.textPrimary)),
                              subtitle: Text('${sess['schoolName']} · ${sess['date']}', style: TextStyle(fontSize: 10.5, color: s.textMuted)),
                              trailing: Text('${sess['attendedCount']}/${sess['attendeeCount']}', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w800, color: s.textPrimary)),
                            )).toList(),
                      ),
                    ),
              const SizedBox(height: 22),
              Text('Certifications Issued (${certifications.length})', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 15, color: s.textPrimary)),
              const SizedBox(height: 10),
              certifications.isEmpty
                  ? const EmptyView(title: 'No certifications issued yet', icon: LucideIcons.award)
                  : SectionCard(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Column(
                        children: certifications.map((c) => ListTile(
                              contentPadding: const EdgeInsets.symmetric(horizontal: 6),
                              title: Text(c['teacherName'] as String, style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: s.textPrimary)),
                              subtitle: Text('${c['schoolName']} · ${c['topic']}', style: TextStyle(fontSize: 10.5, color: s.textMuted)),
                              trailing: c['postTestScore'] != null ? Text('${c['postTestScore']}%', style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w900, color: AppColors.success)) : null,
                            )).toList(),
                      ),
                    ),
            ],
          ),
        );
      },
    );
  }
}
