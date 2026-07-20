import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/app_text_field.dart';
import '../../core/widgets/async_screen.dart';
import '../../core/widgets/gradient_button.dart';
import '../../core/widgets/section_card.dart';
import '../shell/app_shell.dart';
import 'management_repository.dart';

class ThresholdsScreen extends StatelessWidget {
  const ThresholdsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final repo = ManagementRepository();
    return AppShell(
      title: 'MII & Alert Thresholds',
      showAiFab: false,
      body: AsyncScreen<Map<String, dynamic>>(
        loader: repo.getThresholds,
        builder: (context, thresholds, refresh) => _Body(repo: repo, thresholds: thresholds, refresh: refresh),
      ),
    );
  }
}

class _Body extends StatefulWidget {
  final ManagementRepository repo;
  final Map<String, dynamic> thresholds;
  final Future<void> Function() refresh;
  const _Body({required this.repo, required this.thresholds, required this.refresh});

  @override
  State<_Body> createState() => _BodyState();
}

class _BodyState extends State<_Body> {
  late final _excellentMin = TextEditingController(text: '${widget.thresholds['excellentMin']}');
  late final _needsSupportMin = TextEditingController(text: '${widget.thresholds['needsSupportMin']}');
  late final _weakMin = TextEditingController(text: '${widget.thresholds['weakMin']}');
  late final _evidenceAlertMax = TextEditingController(text: '${widget.thresholds['evidenceAlertMax']}');
  late final _buddyGrsAlertMax = TextEditingController(text: '${widget.thresholds['buddyGrsAlertMax']}');
  late final _parentAlertMax = TextEditingController(text: '${widget.thresholds['parentAlertMax']}');
  late final _reportingAlertMax = TextEditingController(text: '${widget.thresholds['reportingAlertMax']}');
  late final _trendDropAlert = TextEditingController(text: '${widget.thresholds['trendDropAlert']}');

  bool _saving = false;
  String? _error;

  Future<void> _save() async {
    final excellentMin = int.tryParse(_excellentMin.text);
    final needsSupportMin = int.tryParse(_needsSupportMin.text);
    final weakMin = int.tryParse(_weakMin.text);
    if (excellentMin == null || needsSupportMin == null || weakMin == null) {
      setState(() => _error = 'Enter a valid number for every band.');
      return;
    }
    if (!(excellentMin > needsSupportMin && needsSupportMin > weakMin)) {
      setState(() => _error = 'Bands must be in order: Excellent > Needs Support > Weak.');
      return;
    }

    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await widget.repo.updateThresholds({
        'excellentMin': excellentMin,
        'needsSupportMin': needsSupportMin,
        'weakMin': weakMin,
        'evidenceAlertMax': int.parse(_evidenceAlertMax.text),
        'buddyGrsAlertMax': int.parse(_buddyGrsAlertMax.text),
        'parentAlertMax': int.parse(_parentAlertMax.text),
        'reportingAlertMax': int.parse(_reportingAlertMax.text),
        'trendDropAlert': int.parse(_trendDropAlert.text),
      });
      await widget.refresh();
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Thresholds updated successfully.')));
    } catch (e) {
      setState(() => _error = e.toString().replaceFirst('ApiException: ', ''));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = context.surface;
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
      children: [
        Text('MII Score Bands', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 15, color: s.textPrimary)),
        const SizedBox(height: 4),
        Text('Schools scoring at or above each threshold fall into that band. Below Weak = Urgent.', style: TextStyle(fontSize: 11.5, color: s.textMuted)),
        const SizedBox(height: 12),
        SectionCard(
          child: Column(
            children: [
              AppTextField(label: 'Excellent (min score)', controller: _excellentMin, keyboardType: TextInputType.number),
              const SizedBox(height: 12),
              AppTextField(label: 'Needs Support (min score)', controller: _needsSupportMin, keyboardType: TextInputType.number),
              const SizedBox(height: 12),
              AppTextField(label: 'Weak (min score)', controller: _weakMin, keyboardType: TextInputType.number),
            ],
          ),
        ),
        const SizedBox(height: 22),
        Text('Alert Triggers', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 15, color: s.textPrimary)),
        const SizedBox(height: 4),
        Text('A school triggers an alert when its score for that area falls below these values.', style: TextStyle(fontSize: 11.5, color: s.textMuted)),
        const SizedBox(height: 12),
        SectionCard(
          child: Column(
            children: [
              AppTextField(label: 'Evidence score alert (below, out of 10)', controller: _evidenceAlertMax, keyboardType: TextInputType.number),
              const SizedBox(height: 12),
              AppTextField(label: 'Buddy/GRS score alert (below, out of 10)', controller: _buddyGrsAlertMax, keyboardType: TextInputType.number),
              const SizedBox(height: 12),
              AppTextField(label: 'Parent involvement alert (below, out of 10)', controller: _parentAlertMax, keyboardType: TextInputType.number),
              const SizedBox(height: 12),
              AppTextField(label: 'Reporting discipline alert (below, out of 5)', controller: _reportingAlertMax, keyboardType: TextInputType.number),
              const SizedBox(height: 12),
              AppTextField(label: 'MII drop alert (points this month)', controller: _trendDropAlert, keyboardType: TextInputType.number),
            ],
          ),
        ),
        if (_error != null) ...[
          const SizedBox(height: 12),
          Text(_error!, style: const TextStyle(color: AppColors.danger, fontSize: 12)),
        ],
        const SizedBox(height: 20),
        GradientButton(label: 'Save Thresholds', loading: _saving, onPressed: _save),
      ],
    );
  }
}
