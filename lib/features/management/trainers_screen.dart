import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/async_screen.dart';
import '../../core/widgets/empty_view.dart';
import '../../core/widgets/section_card.dart';
import '../shell/app_shell.dart';
import 'management_repository.dart';

class ManagementTrainersScreen extends StatelessWidget {
  const ManagementTrainersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final repo = ManagementRepository();
    return AppShell(
      title: 'Trainers',
      body: AsyncScreen<List<Map<String, dynamic>>>(
        loader: repo.getTrainerRoster,
        builder: (context, trainers, refresh) {
          final s = context.surface;
          if (trainers.isEmpty) {
            return ListView(children: const [SizedBox(height: 120), EmptyView(title: 'No trainers yet', icon: LucideIcons.users)]);
          }
          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
            itemCount: trainers.length,
            itemBuilder: (context, i) {
              final t = trainers[i];
              final schools = (t['schools'] as List? ?? []).cast<Map<String, dynamic>>();
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: SectionCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          CircleAvatar(radius: 20, backgroundColor: AppColors.roleColor('TRAINER'), child: Text((t['fullName'] as String).isNotEmpty ? (t['fullName'] as String)[0].toUpperCase() : '?', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800))),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(t['fullName'] as String, style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: s.textPrimary)),
                                Text(t['email'] as String, style: TextStyle(fontSize: 11, color: s.textMuted)),
                              ],
                            ),
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text('${t['avgMii']}', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: s.textPrimary)),
                              Text('avg MII', style: TextStyle(fontSize: 9, color: s.textMuted)),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Text('${t['schoolCount']} school${t['schoolCount'] == 1 ? '' : 's'} assigned', style: TextStyle(fontSize: 11, color: s.textSecondary, fontWeight: FontWeight.w700)),
                      if (schools.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          children: schools.map((sc) => Container(padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5), decoration: BoxDecoration(color: s.bg, borderRadius: BorderRadius.circular(10)), child: Text('${sc['name']} (${sc['miiScore']})', style: TextStyle(fontSize: 10.5, color: s.textSecondary, fontWeight: FontWeight.w700)))).toList(),
                        ),
                      ],
                    ],
                  ),
                ),
              ).animate(delay: (i * 40).ms).fadeIn(duration: 280.ms).slideY(begin: 0.06, end: 0, curve: Curves.easeOutCubic);
            },
          );
        },
      ),
    );
  }
}
