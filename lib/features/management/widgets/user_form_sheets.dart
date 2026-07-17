import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_text_field.dart';
import '../../../core/widgets/gradient_button.dart';
import '../../../core/widgets/searchable_field.dart';

const _roleOptions = ['MANAGEMENT', 'TRAINER', 'PRINCIPAL', 'TEACHER', 'STUDENT', 'PARENT'];

Future<Map<String, dynamic>?> showCreateUserSheet(BuildContext context) {
  return showModalBottomSheet<Map<String, dynamic>>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (sheetContext) => const _UserFormSheet(),
  );
}

Future<Map<String, dynamic>?> showEditUserSheet(BuildContext context, Map<String, dynamic> user) {
  return showModalBottomSheet<Map<String, dynamic>>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (sheetContext) => _UserFormSheet(existing: user),
  );
}

class _UserFormSheet extends StatefulWidget {
  final Map<String, dynamic>? existing;
  const _UserFormSheet({this.existing});

  @override
  State<_UserFormSheet> createState() => _UserFormSheetState();
}

class _UserFormSheetState extends State<_UserFormSheet> {
  late final _fullName = TextEditingController(text: widget.existing?['fullName'] as String? ?? '');
  late final _email = TextEditingController(text: widget.existing?['email'] as String? ?? '');
  late final _password = TextEditingController();
  late final _phone = TextEditingController(text: widget.existing?['phone'] as String? ?? '');
  late final _schoolName = TextEditingController(text: widget.existing?['schoolName'] as String? ?? '');
  late final _className = TextEditingController(text: widget.existing?['className'] as String? ?? '');
  late final _section = TextEditingController(text: widget.existing?['section'] as String? ?? '');
  late final _designation = TextEditingController(text: widget.existing?['designation'] as String? ?? '');
  late String _role = widget.existing?['role'] as String? ?? 'TEACHER';
  String? _error;

  void _save() {
    final isEdit = widget.existing != null;
    if (_fullName.text.trim().isEmpty || (!isEdit && _email.text.trim().isEmpty)) {
      setState(() => _error = 'Please fill in the required fields.');
      return;
    }
    if (isEdit) {
      Navigator.pop(context, {
        'fullName': _fullName.text.trim(),
        'phone': _phone.text.trim(),
        'schoolName': _schoolName.text.trim(),
        'className': _className.text.trim(),
        'section': _section.text.trim(),
        'designation': _designation.text.trim(),
        'role': _role,
      });
    } else {
      if (_password.text.trim().length < 6) {
        setState(() => _error = 'Password must be at least 6 characters.');
        return;
      }
      Navigator.pop(context, {
        'fullName': _fullName.text.trim(),
        'email': _email.text.trim(),
        'password': _password.text.trim(),
        'phone': _phone.text.trim(),
        'role': _role,
        'schoolName': _schoolName.text.trim(),
        'className': _className.text.trim(),
        'section': _section.text.trim(),
        'designation': _designation.text.trim(),
      });
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
        constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.88),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(width: 40, height: 4, margin: const EdgeInsets.only(bottom: 14), alignment: Alignment.center, decoration: BoxDecoration(color: s.border, borderRadius: BorderRadius.circular(99))),
              Text(isEdit ? 'Edit User' : 'Create User', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 17, color: s.textPrimary)),
              const SizedBox(height: 16),
              AppTextField(label: 'Full Name', controller: _fullName),
              const SizedBox(height: 14),
              AppTextField(label: 'Email', controller: _email, enabled: !isEdit, keyboardType: TextInputType.emailAddress),
              if (!isEdit) ...[const SizedBox(height: 14), AppTextField(label: 'Password', controller: _password, obscure: true)],
              const SizedBox(height: 14),
              AppTextField(label: 'Phone', controller: _phone, keyboardType: TextInputType.phone),
              const SizedBox(height: 14),
              Text('Role', style: Theme.of(context).inputDecorationTheme.labelStyle),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _roleOptions.map((r) {
                  final active = r == _role;
                  return ChoiceChip(label: Text(r, style: const TextStyle(fontSize: 11)), selected: active, onSelected: (_) => setState(() => _role = r), selectedColor: AppColors.saffron500, labelStyle: TextStyle(color: active ? Colors.white : s.textSecondary, fontWeight: FontWeight.w700), backgroundColor: s.border.withValues(alpha: 0.4), side: BorderSide.none);
                }).toList(),
              ),
              const SizedBox(height: 14),
              SearchableField(label: 'School (optional)', value: _schoolName.text, onChanged: (v) => _schoolName.text = v, options: const []),
              const SizedBox(height: 14),
              Row(children: [
                Expanded(child: AppTextField(label: 'Class (optional)', controller: _className)),
                const SizedBox(width: 10),
                Expanded(child: AppTextField(label: 'Section (optional)', controller: _section)),
              ]),
              const SizedBox(height: 14),
              AppTextField(label: 'Designation (optional)', controller: _designation),
              if (_error != null) ...[const SizedBox(height: 10), Text(_error!, style: const TextStyle(color: AppColors.danger, fontSize: 12))],
              const SizedBox(height: 18),
              GradientButton(label: isEdit ? 'Save Changes' : 'Create User', onPressed: _save, height: 48),
            ],
          ),
        ),
      ),
    );
  }
}

Future<String?> showResetPasswordSheet(BuildContext context) {
  final ctrl = TextEditingController();
  return showModalBottomSheet<String>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (sheetContext) {
      final s = sheetContext.surface;
      return Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(sheetContext).viewInsets.bottom),
        child: Container(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 28),
          decoration: BoxDecoration(color: s.card, borderRadius: const BorderRadius.vertical(top: Radius.circular(28))),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(width: 40, height: 4, margin: const EdgeInsets.only(bottom: 14), alignment: Alignment.center, decoration: BoxDecoration(color: s.border, borderRadius: BorderRadius.circular(99))),
              Text('Reset Password', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 17, color: s.textPrimary)),
              const SizedBox(height: 16),
              AppTextField(label: 'New Password', controller: ctrl, obscure: true),
              const SizedBox(height: 18),
              GradientButton(
                label: 'Reset Password',
                onPressed: () {
                  if (ctrl.text.trim().length < 6) return;
                  Navigator.pop(sheetContext, ctrl.text.trim());
                },
                height: 48,
              ),
            ],
          ),
        ),
      );
    },
  );
}
