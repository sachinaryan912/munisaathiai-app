import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/async_screen.dart';
import '../../core/widgets/section_card.dart';
import '../shell/app_shell.dart';
import 'principal_repository.dart';

const _statusColors = {
  'Implemented': Color(0xFF10B981),
  'Partial': Color(0xFF3B82F6),
  'Not Done': Color(0xFFEF4444),
};

class PrincipalMethodologyScreen extends StatelessWidget {
  const PrincipalMethodologyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final repo = PrincipalRepository();
    return AppShell(
      title: 'Methodology',
      body: AsyncScreen<List<Map<String, dynamic>>>(
        loader: repo.getMethodology,
        builder: (context, list, refresh) {
          final s = context.surface;
          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
            itemCount: list.length,
            itemBuilder: (context, i) {
              final m = list[i];
              final score = m['score'] as int? ?? 0;
              final status = m['status'] as String? ?? 'Not Done';
              final color = _statusColors[status] ?? s.textMuted;
              final evidenceUploaded = m['evidenceUploaded'] as bool? ?? false;
              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: SectionCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(child: Text(m['name'] as String, style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13.5, color: s.textPrimary))),
                          Container(padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4), decoration: BoxDecoration(color: color.withValues(alpha: 0.14), borderRadius: BorderRadius.circular(99)), child: Text(status, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: color))),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(children: [
                        Expanded(child: ClipRRect(borderRadius: BorderRadius.circular(99), child: LinearProgressIndicator(value: score / 100, minHeight: 7, backgroundColor: s.border, valueColor: AlwaysStoppedAnimation(color)))),
                        const SizedBox(width: 8),
                        Text('$score', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 12.5, color: s.textPrimary)),
                      ]),
                      if (!evidenceUploaded) Padding(padding: const EdgeInsets.only(top: 6), child: Row(children: [Icon(LucideIcons.circleAlert, size: 12, color: AppColors.warning), const SizedBox(width: 4), const Text('No evidence uploaded', style: TextStyle(fontSize: 10.5, color: AppColors.warning, fontWeight: FontWeight.w700))])),
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
