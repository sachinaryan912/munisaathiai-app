import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/async_screen.dart';
import '../../core/widgets/empty_view.dart';
import '../../core/widgets/section_card.dart';
import '../shell/app_shell.dart';
import 'student_repository.dart';

const _roleLabels = {
  'MP': 'Member of Parliament',
  'MLA': 'MLA',
  'JUDICIARY': 'Judiciary Member',
  'COUNSELOR': 'Counselor',
  'PRESIDENT': 'President',
  'PRIME_MINISTER': 'Prime Minister',
};

class StudentParliamentScreen extends StatelessWidget {
  const StudentParliamentScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final repo = StudentRepository();
    return AppShell(
      title: 'Child Parliament',
      body: AsyncScreen<Map<String, dynamic>>(loader: repo.getMyParliamentRole, builder: (context, data, refresh) => _Body(data: data)),
    );
  }
}

class _Body extends StatelessWidget {
  final Map<String, dynamic> data;
  const _Body({required this.data});

  @override
  Widget build(BuildContext context) {
    final s = context.surface;
    final hasRole = data['hasRole'] as bool? ?? false;
    final meetings = (data['meetings'] as List? ?? []).cast<Map<String, dynamic>>();
    final activities = (data['activities'] as List? ?? []).cast<Map<String, dynamic>>();

    if (data['monthStart'] == null) {
      return ListView(children: const [
        SizedBox(height: 100),
        EmptyView(title: 'No Child Parliament this month', subtitle: 'Your class hasn\'t set up a term yet.', icon: LucideIcons.landmark),
      ]);
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
      children: [
        SectionCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                Container(
                  width: 44, height: 44,
                  decoration: BoxDecoration(color: AppColors.saffron50, borderRadius: BorderRadius.circular(14)),
                  child: const Icon(LucideIcons.landmark, size: 20, color: AppColors.saffron600),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(hasRole ? (_roleLabels[data['roleType']] ?? data['roleType'] as String) : 'No role this term', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 15, color: s.textPrimary)),
                      Text('Term: ${data['monthStart']}', style: TextStyle(fontSize: 11, color: s.textMuted)),
                    ],
                  ),
                ),
              ]),
              if (hasRole && data['ministry'] != null) ...[
                const SizedBox(height: 10),
                Text('Ministry: ${data['ministry']}', style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: AppColors.saffron600)),
              ],
            ],
          ),
        ),
        const SizedBox(height: 18),
        Text('Meetings', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 15, color: s.textPrimary)),
        const SizedBox(height: 10),
        if (meetings.isEmpty)
          Text('No meetings logged yet.', style: TextStyle(fontSize: 12, color: s.textMuted))
        else
          ...meetings.map((m) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: SectionCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(children: [
                        Expanded(child: Text(m['agenda'] as String, style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: s.textPrimary))),
                        Text(m['date'] as String, style: TextStyle(fontSize: 11, color: s.textMuted)),
                      ]),
                      if ((m['minutes'] as String?)?.isNotEmpty == true) ...[
                        const SizedBox(height: 6),
                        Text(m['minutes'] as String, style: TextStyle(fontSize: 12, color: s.textSecondary)),
                      ],
                    ],
                  ),
                ),
              )),
        const SizedBox(height: 18),
        Text('Activities', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 15, color: s.textPrimary)),
        const SizedBox(height: 10),
        if (activities.isEmpty)
          Text('No activities logged yet.', style: TextStyle(fontSize: 12, color: s.textMuted))
        else
          ...activities.map((a) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: SectionCard(
                  child: Row(
                    children: [
                      Expanded(child: Text(a['description'] as String, style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: s.textPrimary))),
                      Text(a['date'] as String, style: TextStyle(fontSize: 11, color: s.textMuted)),
                    ],
                  ),
                ),
              )),
      ],
    );
  }
}
