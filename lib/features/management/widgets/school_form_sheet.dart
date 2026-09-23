import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_text_field.dart';
import '../../../core/widgets/gradient_button.dart';
import '../management_repository.dart';

/// Add/edit form for `AddSchoolRequest` — handles saving and validation internally,
/// returns true on success, or null if cancelled. [existing] pre-fills every field when editing.
Future<bool?> showSchoolFormSheet(BuildContext context, {Map<String, dynamic>? existing}) {
  return showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (sheetContext) => _SchoolFormSheet(existing: existing),
  );
}

class _SchoolFormSheet extends StatefulWidget {
  final Map<String, dynamic>? existing;
  const _SchoolFormSheet({this.existing});

  @override
  State<_SchoolFormSheet> createState() => _SchoolFormSheetState();
}

class _SchoolFormSheetState extends State<_SchoolFormSheet> {
  final _formKey = GlobalKey<FormState>();
  final _repo = ManagementRepository();
  late final _name = TextEditingController(text: widget.existing?['name'] as String? ?? '');
  late final _district = TextEditingController(text: widget.existing?['district'] as String? ?? '');
  late final _location = TextEditingController(text: widget.existing?['location'] as String? ?? '');
  late final _phase = TextEditingController(text: widget.existing?['phase'] as String? ?? 'Phase 1');
  late final _trainingScore = TextEditingController(text: '${widget.existing?['trainingScore'] ?? 0}');
  late final _classroomScore = TextEditingController(text: '${widget.existing?['classroomScore'] ?? 0}');
  late final _evidenceScore = TextEditingController(text: '${widget.existing?['evidenceScore'] ?? 0}');
  late final _participationScore = TextEditingController(text: '${widget.existing?['participationScore'] ?? 0}');
  late final _buddyGrsScore = TextEditingController(text: '${widget.existing?['buddyGrsScore'] ?? 0}');
  late final _parentScore = TextEditingController(text: '${widget.existing?['parentScore'] ?? 0}');
  late final _academicScore = TextEditingController(text: '${widget.existing?['academicScore'] ?? 0}');
  late final _reportingScore = TextEditingController(text: '${widget.existing?['reportingScore'] ?? 0}');
  late final _principal = TextEditingController(text: widget.existing?['principal'] as String? ?? '');
  late final _contactPhone = TextEditingController(text: widget.existing?['contactPhone'] as String? ?? '');
  late final _contactEmail = TextEditingController(text: widget.existing?['contactEmail'] as String? ?? '');
  late final _establishedYear = TextEditingController(text: '${widget.existing?['establishedYear'] ?? ''}');
  late final _board = TextEditingController(text: widget.existing?['board'] as String? ?? '');

  List<Map<String, dynamic>> _trainers = [];
  bool _trainersLoading = true;
  int? _trainerId;
  String? _error;
  bool _submitted = false;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _trainerId = widget.existing?['trainerId'] as int?;
    _loadTrainers();
  }

  @override
  void dispose() {
    _name.dispose();
    _district.dispose();
    _location.dispose();
    _phase.dispose();
    _trainingScore.dispose();
    _classroomScore.dispose();
    _evidenceScore.dispose();
    _participationScore.dispose();
    _buddyGrsScore.dispose();
    _parentScore.dispose();
    _academicScore.dispose();
    _reportingScore.dispose();
    _principal.dispose();
    _contactPhone.dispose();
    _contactEmail.dispose();
    _establishedYear.dispose();
    _board.dispose();
    super.dispose();
  }

  Future<void> _loadTrainers() async {
    setState(() => _trainersLoading = true);
    try {
      final roster = await _repo.getTrainerRoster();
      _trainers = roster.where((t) => t['enabled'] as bool? ?? true).toList();
      if (_trainerId != null && !_trainers.any((t) => t['id'] == _trainerId)) _trainerId = null;
    } catch (_) {
      _trainers = [];
    } finally {
      if (mounted) setState(() => _trainersLoading = false);
    }
  }

  int _int(TextEditingController c) => int.tryParse(c.text.trim()) ?? 0;

  Future<void> _save() async {
    setState(() {
      _submitted = true;
      _error = null;
    });

    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_trainerId == null) {
      setState(() => _error = 'Please select an assigned trainer.');
      return;
    }

    final isEdit = widget.existing != null;
    setState(() => _saving = true);

    final payload = {
      'name': _name.text.trim(),
      'district': _district.text.trim(),
      'location': _location.text.trim().isEmpty ? null : _location.text.trim(),
      'trainerId': _trainerId,
      'phase': _phase.text.trim(),
      'trainingScore': _int(_trainingScore).clamp(0, 15),
      'classroomScore': _int(_classroomScore).clamp(0, 25),
      'evidenceScore': _int(_evidenceScore).clamp(0, 10),
      'participationScore': _int(_participationScore).clamp(0, 15),
      'buddyGrsScore': _int(_buddyGrsScore).clamp(0, 10),
      'parentScore': _int(_parentScore).clamp(0, 10),
      'academicScore': _int(_academicScore).clamp(0, 10),
      'reportingScore': _int(_reportingScore).clamp(0, 5),
      'principal': _principal.text.trim().isEmpty ? null : _principal.text.trim(),
      'contactPhone': _contactPhone.text.trim().isEmpty ? null : _contactPhone.text.trim(),
      'contactEmail': _contactEmail.text.trim().isEmpty ? null : _contactEmail.text.trim(),
      'establishedYear': int.tryParse(_establishedYear.text.trim()),
      'board': _board.text.trim().isEmpty ? null : _board.text.trim(),
    };

    try {
      if (isEdit) {
        await _repo.updateSchool(widget.existing!['id'] as int, payload);
      } else {
        await _repo.addSchool(payload);
      }
      if (mounted) {
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _saving = false;
          _error = e.toString().replaceFirst('ApiException: ', '');
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = context.surface;
    final isEdit = widget.existing != null;
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 28),
        decoration: BoxDecoration(color: s.card, borderRadius: const BorderRadius.vertical(top: Radius.circular(28))),
        constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.9),
        child: Form(
          key: _formKey,
          autovalidateMode: _submitted ? AutovalidateMode.onUserInteraction : AutovalidateMode.disabled,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 14),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(color: s.border, borderRadius: BorderRadius.circular(99)),
                ),
                Text(
                  isEdit ? 'Edit School' : 'Add School',
                  style: TextStyle(fontWeight: FontWeight.w900, fontSize: 17, color: s.textPrimary),
                ),
                const SizedBox(height: 16),
                AppTextField(
                  label: 'School Name',
                  isRequired: true,
                  controller: _name,
                  hint: 'e.g. Model Secondary School',
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return 'School name is required';
                    return null;
                  },
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: AppTextField(
                        label: 'District',
                        isRequired: true,
                        controller: _district,
                        hint: 'e.g. Pune',
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) return 'District is required';
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(child: AppTextField(label: 'Location (optional)', controller: _location)),
                  ],
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(child: _trainerDropdown(s)),
                    const SizedBox(width: 10),
                    Expanded(child: AppTextField(label: 'Phase', controller: _phase)),
                  ],
                ),
                const SizedBox(height: 18),
                Text('MII Component Scores', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: s.textPrimary)),
                const SizedBox(height: 4),
                Text('These can also be auto-computed via "Recompute MII" from real activity.', style: TextStyle(fontSize: 10.5, color: s.textMuted)),
                const SizedBox(height: 12),
                _scoreGrid(),
                const SizedBox(height: 18),
                Text('School Profile (optional)', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: s.textPrimary)),
                const SizedBox(height: 12),
                AppTextField(label: 'Principal', controller: _principal),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(child: AppTextField(label: 'Contact Phone', controller: _contactPhone, keyboardType: TextInputType.phone)),
                    const SizedBox(width: 10),
                    Expanded(child: AppTextField(label: 'Contact Email', controller: _contactEmail, keyboardType: TextInputType.emailAddress)),
                  ],
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(child: AppTextField(label: 'Established Year', controller: _establishedYear, keyboardType: TextInputType.number)),
                    const SizedBox(width: 10),
                    Expanded(child: AppTextField(label: 'Board', controller: _board)),
                  ],
                ),
                if (_error != null) ...[
                  const SizedBox(height: 14),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: AppColors.danger.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.danger.withValues(alpha: 0.4)),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Padding(
                          padding: EdgeInsets.only(top: 1),
                          child: Icon(Icons.error_outline_rounded, color: AppColors.danger, size: 17),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _error!,
                            style: const TextStyle(color: AppColors.danger, fontSize: 12, fontWeight: FontWeight.w600),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 18),
                GradientButton(
                  label: isEdit ? 'Save Changes' : 'Add School',
                  loading: _saving,
                  onPressed: _saving ? null : _save,
                  height: 48,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _trainerDropdown(MuniSurface s) {
    final hasTrainerError = _submitted && _trainerId == null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 6),
          child: RichText(
            text: TextSpan(
              text: 'Assigned Trainer',
              style: Theme.of(context).inputDecorationTheme.labelStyle,
              children: const [
                TextSpan(
                  text: ' *',
                  style: TextStyle(color: AppColors.danger, fontWeight: FontWeight.bold, fontSize: 14),
                ),
              ],
            ),
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          decoration: BoxDecoration(
            color: Theme.of(context).inputDecorationTheme.fillColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: hasTrainerError ? AppColors.danger : Colors.transparent,
              width: 1.4,
            ),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<int>(
              value: _trainerId,
              isExpanded: true,
              hint: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Text(
                  _trainersLoading ? 'Loading trainers...' : (_trainers.isEmpty ? 'No trainers available' : 'Select a trainer'),
                  style: TextStyle(fontSize: 13, color: s.textMuted),
                ),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 12),
              items: _trainers.map((t) => DropdownMenuItem(value: t['id'] as int, child: Text(t['fullName'] as String))).toList(),
              onChanged: _trainersLoading || _trainers.isEmpty
                  ? null
                  : (v) => setState(() {
                        _trainerId = v;
                        _error = null;
                      }),
            ),
          ),
        ),
        if (hasTrainerError)
          const Padding(
            padding: EdgeInsets.only(top: 4, left: 4),
            child: Text('Trainer is required', style: TextStyle(color: AppColors.danger, fontSize: 11.5, fontWeight: FontWeight.w600)),
          ),
        if (!_trainersLoading && _trainers.isEmpty)
          const Padding(
            padding: EdgeInsets.only(top: 6, left: 4),
            child: Text(
              'No trainer accounts yet — create one from the Users tab first.',
              style: TextStyle(fontSize: 11, color: AppColors.danger),
            ),
          ),
      ],
    );
  }

  Widget _scoreGrid() {
    final fields = [
      ('Training /15', _trainingScore),
      ('Classroom /25', _classroomScore),
      ('Evidence /10', _evidenceScore),
      ('Participation /15', _participationScore),
      ('Buddy/GRS /10', _buddyGrsScore),
      ('Parent /10', _parentScore),
      ('Academic /10', _academicScore),
      ('Reporting /5', _reportingScore),
    ];
    return Wrap(
      spacing: 10,
      runSpacing: 12,
      children: fields
          .map((f) => SizedBox(
                width: 150,
                child: AppTextField(label: f.$1, controller: f.$2, keyboardType: TextInputType.number),
              ))
          .toList(),
    );
  }
}
