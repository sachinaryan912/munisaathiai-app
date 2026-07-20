import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/async_screen.dart';
import '../../core/widgets/pdf_export_button.dart';
import '../../core/widgets/section_card.dart';
import '../shell/app_shell.dart';
import 'ptm_file_repository.dart';

class PtmFileScreen extends StatelessWidget {
  final int studentId;
  const PtmFileScreen({super.key, required this.studentId});

  @override
  Widget build(BuildContext context) {
    final repo = PtmFileRepository();
    return AppShell(
      title: 'PTM File',
      showAiFab: false,
      body: AsyncScreen<Map<String, dynamic>>(
        loader: () => repo.getPtmFile(studentId),
        builder: (context, data, refresh) {
          final s = context.surface;
          final subjects = (data['subjectReports'] as List? ?? []).cast<Map<String, dynamic>>();
          final timetable = (data['timetable'] as List? ?? []).cast<Map<String, dynamic>>();

          List<String> asStringList(String key) => (data[key] as List? ?? []).cast<String>();

          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
            children: [
              SectionCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(data['studentName'] as String, style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: s.textPrimary)),
                    const SizedBox(height: 4),
                    Text('${data['schoolName']} · ${data['className'] ?? ''} ${data['section'] ?? ''}', style: TextStyle(fontSize: 11.5, color: s.textMuted)),
                    Text('${data['email']} · ${data['phone']}', style: TextStyle(fontSize: 11.5, color: s.textMuted)),
                    if (data['attendancePercent'] != null) ...[const SizedBox(height: 8), Text('Attendance: ${data['attendancePercent']}%', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12.5, color: AppColors.saffron600))],
                  ],
                ),
              ),
              const SizedBox(height: 10),
              SectionCard(child: Text(data['instructionsForParents'] as String, style: TextStyle(fontSize: 11.5, color: s.textSecondary, fontStyle: FontStyle.italic, height: 1.4))),
              const SizedBox(height: 16),
              PdfDownloadButton(fileName: 'ptm_file.pdf', download: () => repo.downloadPtmFilePdf(studentId)),
              const SizedBox(height: 20),

              _Section(title: 'Subject Reports', icon: LucideIcons.bookOpen, empty: subjects.isEmpty,
                child: Column(children: subjects.map((sub) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(children: [
                        Expanded(child: Text(sub['subject'] as String, style: TextStyle(fontSize: 12.5, color: s.textPrimary, fontWeight: FontWeight.w600))),
                        Text('${sub['score']}/${sub['target']}', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: s.textPrimary)),
                      ]),
                    )).toList())),

              _Section(title: 'Timetable', icon: LucideIcons.calendarClock, empty: timetable.isEmpty,
                child: Column(children: timetable.map((t) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 3),
                      child: Text('${t['dayOfWeek']} P${t['periodNumber']}: ${t['subject']} (${t['startTime']}–${t['endTime']})', style: TextStyle(fontSize: 11.5, color: s.textSecondary)),
                    )).toList())),

              _Section(title: 'Extracurricular', icon: LucideIcons.usersRound, empty: false,
                child: Text(data['extracurricularClub'] as String, style: TextStyle(fontSize: 12.5, color: s.textSecondary))),

              _OpinionSection(title: 'Feedback / Complaints', icon: LucideIcons.messageSquare, items: asStringList('feedbackComplaints')),
              _OpinionSection(title: "Parents' Thoughts", icon: LucideIcons.heart, items: asStringList('parentsThoughts')),
              _OpinionSection(title: 'Community Opinion', icon: LucideIcons.house, items: asStringList('communityOpinion')),
              _OpinionSection(title: 'Work Done (½ km / Define Yourself)', icon: LucideIcons.megaphone, items: asStringList('workInHalfKm')),
              _OpinionSection(title: 'Buddy Opinion', icon: LucideIcons.userCheck, items: asStringList('buddyOpinion')),
              _OpinionSection(title: "Teachers' Opinion", icon: LucideIcons.graduationCap, items: asStringList('teachersOpinion')),
            ],
          );
        },
      ),
    );
  }
}

class _Section extends StatelessWidget {
  final String title;
  final IconData icon;
  final bool empty;
  final Widget child;
  const _Section({required this.title, required this.icon, required this.empty, required this.child});

  @override
  Widget build(BuildContext context) {
    final s = context.surface;
    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [Icon(icon, size: 15, color: AppColors.saffron600), const SizedBox(width: 6), Text(title, style: TextStyle(fontWeight: FontWeight.w900, fontSize: 13.5, color: s.textPrimary))]),
          const SizedBox(height: 8),
          SectionCard(child: empty ? Text('No data yet.', style: TextStyle(fontSize: 11.5, color: s.textMuted)) : child),
        ],
      ),
    );
  }
}

class _OpinionSection extends StatelessWidget {
  final String title;
  final IconData icon;
  final List<String> items;
  const _OpinionSection({required this.title, required this.icon, required this.items});

  @override
  Widget build(BuildContext context) {
    final s = context.surface;
    return _Section(
      title: title,
      icon: icon,
      empty: items.isEmpty,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: items.map((i) => Padding(padding: const EdgeInsets.symmetric(vertical: 4), child: Text('• $i', style: TextStyle(fontSize: 11.5, color: s.textSecondary)))).toList(),
      ),
    );
  }
}
