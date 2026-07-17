import 'dart:convert';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/async_screen.dart';
import '../../core/widgets/empty_view.dart';
import '../../core/widgets/gradient_button.dart';
import '../../core/widgets/section_card.dart';
import '../shell/app_shell.dart';
import 'teacher_repository.dart';

const _methodologies = [
  'GRS', 'Buddy System', 'UPLC', 'HADS', 'Child Parliament', 'Growth Habits',
  'Ghar Ek Pathshala', 'Am I Able', 'Situation Creation', 'Bharat Bodh',
  'Vedic Math', 'English Language (LLT)',
];

class TeacherEvidenceScreen extends StatelessWidget {
  const TeacherEvidenceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final repo = TeacherRepository();
    return AppShell(
      title: 'Evidence',
      showAiFab: false,
      body: AsyncScreen<List<Map<String, dynamic>>>(loader: repo.getEvidence, builder: (context, list, refresh) => _Body(list: list, repo: repo, refresh: refresh)),
    );
  }
}

class _Body extends StatefulWidget {
  final List<Map<String, dynamic>> list;
  final TeacherRepository repo;
  final Future<void> Function() refresh;
  const _Body({required this.list, required this.repo, required this.refresh});

  @override
  State<_Body> createState() => _BodyState();
}

class _BodyState extends State<_Body> {
  int? _analyzingId;

  Future<void> _openUpload() async {
    String methodology = _methodologies.first;
    File? file;
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
                    Text('Upload Evidence', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 17, color: s.textPrimary)),
                    const SizedBox(height: 16),
                    Text('Methodology', style: Theme.of(sheetContext).inputDecorationTheme.labelStyle),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _methodologies.map((m) {
                        final active = m == methodology;
                        return ChoiceChip(
                          label: Text(m, style: const TextStyle(fontSize: 11)),
                          selected: active,
                          onSelected: (_) => setSheetState(() => methodology = m),
                          selectedColor: AppColors.saffron500,
                          labelStyle: TextStyle(color: active ? Colors.white : s.textSecondary, fontWeight: FontWeight.w700),
                          backgroundColor: s.border.withValues(alpha: 0.4),
                          side: BorderSide.none,
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 16),
                    InkWell(
                      borderRadius: BorderRadius.circular(16),
                      onTap: () async {
                        final result = await FilePicker.platform.pickFiles(type: FileType.custom, allowedExtensions: ['jpg', 'jpeg', 'png', 'webp', 'pdf']);
                        if (result?.files.single.path != null) setSheetState(() => file = File(result!.files.single.path!));
                      },
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(color: Theme.of(sheetContext).inputDecorationTheme.fillColor, borderRadius: BorderRadius.circular(16)),
                        child: Row(
                          children: [
                            Icon(file != null ? LucideIcons.fileCheck : LucideIcons.upload, color: AppColors.saffron600, size: 20),
                            const SizedBox(width: 10),
                            Expanded(child: Text(file != null ? file!.path.split(Platform.pathSeparator).last : 'Choose a photo or PDF', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: s.textPrimary), overflow: TextOverflow.ellipsis)),
                          ],
                        ),
                      ),
                    ),
                    if (error != null) ...[const SizedBox(height: 10), Text(error!, style: const TextStyle(color: AppColors.danger, fontSize: 12))],
                    const SizedBox(height: 18),
                    GradientButton(
                      label: 'Upload',
                      loading: submitting,
                      onPressed: () async {
                        if (file == null) {
                          setSheetState(() => error = 'Please choose a file.');
                          return;
                        }
                        setSheetState(() {
                          submitting = true;
                          error = null;
                        });
                        try {
                          await widget.repo.uploadEvidence(methodology: methodology, file: file!);
                          if (sheetContext.mounted) Navigator.pop(sheetContext);
                          await widget.refresh();
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

  Future<void> _analyze(int id) async {
    setState(() => _analyzingId = id);
    try {
      await widget.repo.analyzeEvidence(id);
      await widget.refresh();
    } finally {
      if (mounted) setState(() => _analyzingId = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = context.surface;
    return Stack(
      children: [
        widget.list.isEmpty
            ? ListView(children: const [SizedBox(height: 120), EmptyView(title: 'No evidence uploaded yet', subtitle: 'Tap + to upload your first piece of evidence.', icon: LucideIcons.bookOpen)])
            : ListView.builder(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                itemCount: widget.list.length,
                itemBuilder: (context, i) {
                  final e = widget.list[i];
                  final id = e['id'] as int;
                  final aiScore = e['aiScore'] as int?;
                  final aiVerdict = e['aiVerdict'] as String?;
                  final trainerVerified = e['trainerVerified'] as bool? ?? false;
                  List<dynamic> detections = [];
                  try {
                    if (e['aiDetections'] != null) detections = jsonDecode(e['aiDetections'] as String) as List<dynamic>;
                  } catch (_) {}

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: SectionCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(width: 40, height: 40, decoration: BoxDecoration(color: AppColors.saffron50, borderRadius: BorderRadius.circular(13)), child: const Icon(LucideIcons.fileCheck, size: 18, color: AppColors.saffron600)),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(e['methodology'] as String, style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13.5, color: s.textPrimary)),
                                    Text(e['fileName'] as String, style: TextStyle(fontSize: 10.5, color: s.textMuted), overflow: TextOverflow.ellipsis),
                                  ],
                                ),
                              ),
                              if (trainerVerified)
                                const Icon(LucideIcons.circleCheck, size: 18, color: AppColors.success)
                              else
                                Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3), decoration: BoxDecoration(color: AppColors.warning.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(99)), child: const Text('Pending review', style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.w800, color: AppColors.warning))),
                            ],
                          ),
                          if (aiScore != null) ...[
                            const SizedBox(height: 10),
                            Row(children: [
                              Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3), decoration: BoxDecoration(color: const Color(0xFF6366F1).withValues(alpha: 0.12), borderRadius: BorderRadius.circular(99)), child: Text('AI Score: $aiScore/${e['aiMaxScore']}', style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w800, color: Color(0xFF6366F1)))),
                            ]),
                            if (aiVerdict != null) Padding(padding: const EdgeInsets.only(top: 6), child: Text(aiVerdict, style: TextStyle(fontSize: 11.5, color: s.textSecondary, height: 1.4))),
                            if (detections.isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(top: 6),
                                child: Wrap(
                                  spacing: 6,
                                  runSpacing: 6,
                                  children: detections.map((d) {
                                    final map = d as Map<String, dynamic>;
                                    return Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                                      decoration: BoxDecoration(color: s.border.withValues(alpha: 0.5), borderRadius: BorderRadius.circular(8)),
                                      child: Text('${map['label']}: ${map['score']}/${map['max']}', style: TextStyle(fontSize: 9.5, color: s.textSecondary, fontWeight: FontWeight.w700)),
                                    );
                                  }).toList(),
                                ),
                              ),
                          ] else ...[
                            const SizedBox(height: 10),
                            SizedBox(
                              width: double.infinity,
                              child: OutlinedButton.icon(
                                onPressed: _analyzingId == id ? null : () => _analyze(id),
                                icon: _analyzingId == id ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(LucideIcons.sparkles, size: 15),
                                label: Text(_analyzingId == id ? 'Analyzing...' : 'Analyze with AI'),
                                style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 10)),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  );
                },
              ),
        Positioned(
          right: 16,
          bottom: 16,
          child: FloatingActionButton(heroTag: 'upload_evidence', backgroundColor: AppColors.saffron500, onPressed: _openUpload, child: const Icon(Icons.add, color: Colors.white)),
        ),
      ],
    );
  }
}
