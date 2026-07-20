import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/section_card.dart';
import '../shared/evaluation_sheet_screen.dart';
import '../shell/app_shell.dart';
import 'answer_pattern_screen.dart';
import 'career_assessment_screen.dart';
import 'eklavya_screen.dart';
import 'exam_self_diagnostic_screen.dart';
import 'fortnightly_self_eval_screen.dart';
import 'learning_style_screen.dart';
import 'life_application_screen.dart';
import 'skill_practice_screen.dart';
import 'social_voice_screen.dart';

class _Tool {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final WidgetBuilder builder;
  const _Tool({required this.title, required this.subtitle, required this.icon, required this.color, required this.builder});
}

final _tools = <_Tool>[
  _Tool(title: 'Socially Strong', subtitle: 'Raise your voice against a social odd', icon: LucideIcons.megaphone, color: const Color(0xFFEF4444), builder: (_) => const SocialVoiceScreen()),
  _Tool(title: 'Eklavya System', subtitle: 'Create something new from what you learned', icon: LucideIcons.sparkles, color: const Color(0xFF8B5CF6), builder: (_) => const EklavyaScreen()),
  _Tool(title: 'Mai Shikshit Hokar', subtitle: 'Apply a chapter to health, prosperity, relations & order', icon: LucideIcons.heartHandshake, color: const Color(0xFF10B981), builder: (_) => const LifeApplicationScreen()),
  _Tool(title: 'Jeevan Kaushal', subtitle: 'Fortnightly self-evaluation questionnaire', icon: LucideIcons.compass, color: const Color(0xFF3B82F6), builder: (_) => const FortnightlySelfEvalScreen()),
  _Tool(title: 'Answer Pattern', subtitle: 'Structured 7-part chapter answer', icon: LucideIcons.fileText, color: AppColors.saffron600, builder: (_) => const AnswerPatternScreen()),
  _Tool(title: 'Exam Evaluation', subtitle: 'Diagnose why an answer went wrong', icon: LucideIcons.searchCheck, color: const Color(0xFFF59E0B), builder: (_) => const ExamSelfDiagnosticScreen()),
  _Tool(title: 'Reasoning & Brain Mapping', subtitle: 'Logic, imagination and expression practice', icon: LucideIcons.brain, color: const Color(0xFF6366F1), builder: (_) => const SkillPracticeScreen()),
  _Tool(title: 'Learning Style', subtitle: 'Find your best way to learn', icon: LucideIcons.lightbulb, color: const Color(0xFFEC4899), builder: (_) => const LearningStyleScreen()),
  _Tool(title: 'IPDS Career Assessment', subtitle: 'Discover career directions with Vidya AI', icon: LucideIcons.compass, color: const Color(0xFF14B8A6), builder: (_) => const CareerAssessmentScreen()),
  _Tool(title: 'Evaluation Sheet', subtitle: 'Your 360-degree self, buddy, teacher & parent scores', icon: LucideIcons.clipboardCheck, color: const Color(0xFF0EA5E9), builder: (_) => const EvaluationSheetScreen(studentLabel: 'My Evaluation Sheet', editableRoles: ['SELF'])),
];

class SelfGrowthHubScreen extends StatelessWidget {
  const SelfGrowthHubScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final s = context.surface;
    return AppShell(
      title: 'Self-Growth Journal',
      showAiFab: false,
      body: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
        itemCount: _tools.length,
        itemBuilder: (context, i) {
          final t = _tools[i];
          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: SectionCard(
              onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: t.builder)),
              child: Row(
                children: [
                  Container(width: 42, height: 42, decoration: BoxDecoration(color: t.color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(14)), child: Icon(t.icon, size: 19, color: t.color)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(t.title, style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13.5, color: s.textPrimary)),
                        const SizedBox(height: 2),
                        Text(t.subtitle, style: TextStyle(fontSize: 11, color: s.textMuted)),
                      ],
                    ),
                  ),
                  Icon(LucideIcons.chevronRight, size: 16, color: s.textMuted),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
