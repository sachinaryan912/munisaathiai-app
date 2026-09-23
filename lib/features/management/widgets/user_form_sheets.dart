import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_text_field.dart';
import '../../../core/widgets/gradient_button.dart';
import '../../../core/widgets/searchable_field.dart';
import '../../auth/data/auth_repository.dart';
import '../management_repository.dart';

const _roleOptions = ['MANAGEMENT', 'TRAINER', 'PRINCIPAL', 'TEACHER', 'STUDENT', 'PARENT'];

Future<bool?> showCreateUserSheet(BuildContext context) {
  return showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (sheetContext) => const _UserFormSheet(),
  );
}

Future<bool?> showEditUserSheet(BuildContext context, Map<String, dynamic> user) {
  return showModalBottomSheet<bool>(
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
  final _formKey = GlobalKey<FormState>();
  final _authRepo = AuthRepository();
  final _managementRepo = ManagementRepository();

  late final _fullName = TextEditingController(text: widget.existing?['fullName'] as String? ?? '');
  late final _username = TextEditingController(text: widget.existing?['username'] as String? ?? '');
  late final _email = TextEditingController(text: widget.existing?['email'] as String? ?? '');
  late final _password = TextEditingController();
  late final _phone = TextEditingController(text: widget.existing?['phone'] as String? ?? '');
  late final _schoolName = TextEditingController(text: widget.existing?['schoolName'] as String? ?? '');
  late final _className = TextEditingController(text: widget.existing?['className'] as String? ?? '');
  late final _section = TextEditingController(text: widget.existing?['section'] as String? ?? '');
  late final _designation = TextEditingController(text: widget.existing?['designation'] as String? ?? '');
  late String _role = widget.existing?['role'] as String? ?? 'TEACHER';

  String? _error;
  bool _submitted = false;
  bool _saving = false;
  List<String> _schools = [];
  bool _schoolsLoading = false;

  @override
  void initState() {
    super.initState();
    _loadSchools();
  }

  @override
  void dispose() {
    _fullName.dispose();
    _username.dispose();
    _email.dispose();
    _password.dispose();
    _phone.dispose();
    _schoolName.dispose();
    _className.dispose();
    _section.dispose();
    _designation.dispose();
    super.dispose();
  }

  Future<void> _loadSchools() async {
    setState(() => _schoolsLoading = true);
    try {
      _schools = await _authRepo.lookupSchools();
    } catch (_) {
      _schools = [];
    } finally {
      if (mounted) setState(() => _schoolsLoading = false);
    }
  }

  Future<void> _save() async {
    setState(() {
      _submitted = true;
      _error = null;
    });

    if (!_formKey.currentState!.validate()) {
      return;
    }

    final isEdit = widget.existing != null;
    setState(() => _saving = true);

    try {
      if (isEdit) {
        final payload = {
          'fullName': _fullName.text.trim(),
          'username': _username.text.trim(),
          'phone': _phone.text.trim(),
          'schoolName': _schoolName.text.trim().isEmpty ? null : _schoolName.text.trim(),
          'className': _className.text.trim().isEmpty ? null : _className.text.trim(),
          'section': _section.text.trim().isEmpty ? null : _section.text.trim(),
          'designation': _designation.text.trim().isEmpty ? null : _designation.text.trim(),
          'role': _role,
        };
        await _managementRepo.updateUser(widget.existing!['id'] as int, payload);
      } else {
        final payload = {
          'fullName': _fullName.text.trim(),
          'username': _username.text.trim(),
          'email': _email.text.trim(),
          'password': _password.text.trim(),
          'phone': _phone.text.trim(),
          'role': _role,
          'schoolName': _schoolName.text.trim().isEmpty ? null : _schoolName.text.trim(),
          'className': _className.text.trim().isEmpty ? null : _className.text.trim(),
          'section': _section.text.trim().isEmpty ? null : _section.text.trim(),
          'designation': _designation.text.trim().isEmpty ? null : _designation.text.trim(),
        };
        await _managementRepo.createUser(payload);
      }

      if (mounted) {
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString().replaceFirst('ApiException: ', '');
          _saving = false;
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
        constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.88),
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
                  isEdit ? 'Edit User' : 'Create User',
                  style: TextStyle(fontWeight: FontWeight.w900, fontSize: 17, color: s.textPrimary),
                ),
                const SizedBox(height: 16),

                // Full Name (Mandatory)
                AppTextField(
                  label: 'Full Name',
                  isRequired: true,
                  controller: _fullName,
                  hint: 'e.g. Rahul Sharma',
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return 'Full name is required';
                    if (v.trim().length < 2) return 'Full name must be at least 2 characters';
                    return null;
                  },
                ),
                const SizedBox(height: 14),

                // Username (Mandatory)
                AppTextField(
                  label: 'Username',
                  isRequired: true,
                  controller: _username,
                  hint: 'e.g. rahul_sharma',
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return 'Username is required';
                    if (!RegExp(r'^[a-zA-Z0-9_.]{3,30}$').hasMatch(v.trim())) {
                      return '3-30 characters: letters, numbers, underscore, dot';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 14),

                // Email (Mandatory on Create, Read-only on Edit)
                AppTextField(
                  label: 'Email',
                  isRequired: !isEdit,
                  controller: _email,
                  enabled: !isEdit,
                  hint: 'e.g. rahul@school.org',
                  keyboardType: TextInputType.emailAddress,
                  validator: (v) {
                    if (!isEdit) {
                      if (v == null || v.trim().isEmpty) return 'Email is required';
                      if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(v.trim())) {
                        return 'Enter a valid email address';
                      }
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 14),

                // Password (Mandatory on Create)
                if (!isEdit) ...[
                  AppTextField(
                    label: 'Password',
                    isRequired: true,
                    controller: _password,
                    obscure: true,
                    hint: 'Minimum 6 characters',
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) return 'Password is required';
                      if (v.trim().length < 6) return 'Password must be at least 6 characters';
                      return null;
                    },
                  ),
                  const SizedBox(height: 14),
                ],

                // Phone (Mandatory)
                AppTextField(
                  label: 'Phone',
                  isRequired: true,
                  controller: _phone,
                  hint: 'e.g. +91 9876543210',
                  keyboardType: TextInputType.phone,
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return 'Phone number is required';
                    final cleaned = v.trim().replaceAll(RegExp(r'[\s\-]'), '');
                    if (!RegExp(r'^\+?[0-9]{10,15}$').hasMatch(cleaned)) {
                      return 'Enter a valid phone number (10-15 digits)';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 14),

                // Role (Mandatory)
                Padding(
                  padding: const EdgeInsets.only(left: 4, bottom: 6),
                  child: RichText(
                    text: TextSpan(
                      text: 'Role',
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
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _roleOptions.map((r) {
                    final active = r == _role;
                    return ChoiceChip(
                      label: Text(r, style: const TextStyle(fontSize: 11)),
                      selected: active,
                      onSelected: (_) => setState(() => _role = r),
                      selectedColor: AppColors.saffron500,
                      labelStyle: TextStyle(color: active ? Colors.white : s.textSecondary, fontWeight: FontWeight.w700),
                      backgroundColor: s.border.withValues(alpha: 0.4),
                      side: BorderSide.none,
                    );
                  }).toList(),
                ),
                const SizedBox(height: 14),

                // School (Optional)
                SearchableField(
                  label: 'School (optional)',
                  value: _schoolName.text,
                  onChanged: (v) => _schoolName.text = v,
                  options: _schools,
                  loading: _schoolsLoading,
                ),
                const SizedBox(height: 14),

                // Class & Section (Optional)
                Row(
                  children: [
                    Expanded(child: AppTextField(label: 'Class (optional)', controller: _className)),
                    const SizedBox(width: 10),
                    Expanded(child: AppTextField(label: 'Section (optional)', controller: _section)),
                  ],
                ),
                const SizedBox(height: 14),

                // Designation (Optional)
                AppTextField(label: 'Designation (optional)', controller: _designation),

                // Inline Server / Validation Error Alert
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

                const SizedBox(height: 20),
                GradientButton(
                  label: isEdit ? 'Save Changes' : 'Create User',
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
}

Future<String?> showResetPasswordSheet(BuildContext context) {
  return showModalBottomSheet<String>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (sheetContext) => const _ResetPasswordSheet(),
  );
}

class _ResetPasswordSheet extends StatefulWidget {
  const _ResetPasswordSheet();

  @override
  State<_ResetPasswordSheet> createState() => _ResetPasswordSheetState();
}

class _ResetPasswordSheetState extends State<_ResetPasswordSheet> {
  final _formKey = GlobalKey<FormState>();
  final _ctrl = TextEditingController();
  bool _submitted = false;

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _submit() {
    setState(() => _submitted = true);
    if (!_formKey.currentState!.validate()) return;
    Navigator.pop(context, _ctrl.text.trim());
  }

  @override
  Widget build(BuildContext context) {
    final s = context.surface;
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 28),
        decoration: BoxDecoration(color: s.card, borderRadius: const BorderRadius.vertical(top: Radius.circular(28))),
        child: Form(
          key: _formKey,
          autovalidateMode: _submitted ? AutovalidateMode.onUserInteraction : AutovalidateMode.disabled,
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
              Text('Reset Password', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 17, color: s.textPrimary)),
              const SizedBox(height: 16),
              AppTextField(
                label: 'New Password',
                isRequired: true,
                controller: _ctrl,
                obscure: true,
                hint: 'Minimum 6 characters',
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'New password is required';
                  if (v.trim().length < 6) return 'Password must be at least 6 characters';
                  return null;
                },
              ),
              const SizedBox(height: 18),
              GradientButton(
                label: 'Reset Password',
                onPressed: _submit,
                height: 48,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
