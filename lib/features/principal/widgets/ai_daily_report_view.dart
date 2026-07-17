import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';

const _urgencyColors = {'high': AppColors.danger, 'medium': AppColors.warning};

/// Renders `POST /api/principal/daily-report`'s response shape.
class AiDailyReportView extends StatelessWidget {
  final Map<String, dynamic> report;
  const AiDailyReportView({super.key, required this.report});

  @override
  Widget build(BuildContext context) {
    final s = context.surface;
    final alerts = (report['alerts'] as List? ?? []).cast<Map<String, dynamic>>();
    final gaps = (report['teacherGaps'] as List? ?? []).cast<Map<String, dynamic>>();
    final suggestions = (report['meetingSuggestions'] as List? ?? []).cast<String>();
    final teacherCount = report['teacherCount'] as int? ?? 0;
    final teachersActiveToday = report['teachersActiveToday'] as num? ?? 0;
    final evidenceToday = report['evidenceToday'] as num? ?? 0;
    final avgStudentScore = report['avgStudentScore'] as int? ?? 0;
    final amIAbleScore = report['amIAbleScore'] as int?;
    final buddyScore = report['buddyScore'] as int?;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(color: AppColors.success.withValues(alpha: 0.14), borderRadius: BorderRadius.circular(16)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Text('🏫 Daily School Health Report', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: AppColors.success)),
                  const Spacer(),
                  Text('$teachersActiveToday/$teacherCount active', style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w700, color: AppColors.success)),
                ],
              ),
              const SizedBox(height: 8),
              Text(report['healthSummary'] as String? ?? '', style: TextStyle(fontSize: 12.5, color: s.textPrimary, height: 1.5)),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(child: _MiniStat(value: '$teachersActiveToday/$teacherCount', label: 'Teachers Active')),
                  Expanded(child: _MiniStat(value: '$evidenceToday', label: 'Evidence Today')),
                  Expanded(child: _MiniStat(value: '$avgStudentScore%', label: 'Avg Score')),
                ],
              ),
            ],
          ),
        ),
        if (alerts.isNotEmpty) ...[
          const SizedBox(height: 16),
          Text('🚨 Non-Implementation Alerts', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: AppColors.danger)),
          const SizedBox(height: 8),
          ...alerts.map((a) => Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(color: (_urgencyColors[a['urgency']] ?? AppColors.warning).withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(LucideIcons.triangleAlert, size: 14, color: _urgencyColors[a['urgency']] ?? AppColors.warning),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(a['subject'] as String, style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w800, color: s.textPrimary)),
                            Text(a['issue'] as String, style: TextStyle(fontSize: 11, color: s.textSecondary)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              )),
        ],
        if (gaps.isNotEmpty) ...[
          const SizedBox(height: 16),
          Text('📊 Teacher Gap Analysis', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: s.textPrimary)),
          const SizedBox(height: 8),
          ...gaps.map((t) {
            final score = t['score'] as int? ?? 0;
            final color = score >= 70 ? AppColors.success : score >= 40 ? AppColors.warning : AppColors.danger;
            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: s.bg, borderRadius: BorderRadius.circular(14)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    Expanded(child: Text(t['name'] as String, style: TextStyle(fontWeight: FontWeight.w800, fontSize: 12.5, color: s.textPrimary))),
                    Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3), decoration: BoxDecoration(color: color.withValues(alpha: 0.14), borderRadius: BorderRadius.circular(99)), child: Text('Score: $score', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: color))),
                  ]),
                  const SizedBox(height: 6),
                  Text('✓ Strong: ${t['strength']}', style: const TextStyle(fontSize: 11, color: AppColors.success)),
                  Text('✗ Gap: ${t['gap']}', style: const TextStyle(fontSize: 11, color: AppColors.danger)),
                ],
              ),
            );
          }),
        ],
        if (suggestions.isNotEmpty) ...[
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: AppColors.info.withValues(alpha: 0.14), borderRadius: BorderRadius.circular(14)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('📅 Corrective Meeting Suggestions', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: AppColors.info)),
                const SizedBox(height: 6),
                ...suggestions.map((sug) => Padding(padding: const EdgeInsets.only(bottom: 3), child: Text('• $sug', style: TextStyle(fontSize: 12, color: s.textPrimary)))),
              ],
            ),
          ),
        ],
        if (amIAbleScore != null || buddyScore != null) ...[
          const SizedBox(height: 16),
          Row(
            children: [
              if (amIAbleScore != null) Expanded(child: _MiniStat(value: '$amIAbleScore%', label: 'Am I Able')),
              if (buddyScore != null) Expanded(child: _MiniStat(value: '$buddyScore%', label: 'Buddy System')),
            ],
          ),
        ],
      ],
    );
  }
}

class _MiniStat extends StatelessWidget {
  final String value;
  final String label;
  const _MiniStat({required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    final s = context.surface;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 3),
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(color: s.card, borderRadius: BorderRadius.circular(12)),
      child: Column(
        children: [
          Text(value, style: TextStyle(fontWeight: FontWeight.w900, fontSize: 15, color: s.textPrimary)),
          Text(label, style: TextStyle(fontSize: 9.5, color: s.textMuted)),
        ],
      ),
    );
  }
}
