import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_text_field.dart';
import '../../../core/widgets/gradient_button.dart';
import '../../../core/widgets/searchable_field.dart';
import '../data/auth_provider.dart';
import '../data/auth_repository.dart';
import 'auth_scaffold.dart';

const _roles = [
  RoleOption('MANAGEMENT', 'Management', 'Muni Educare leadership', LucideIcons.barChart3),
  RoleOption('TRAINER', 'Trainer', 'School trainer / mentor', LucideIcons.users),
  RoleOption('PRINCIPAL', 'Principal', 'School principal', LucideIcons.building2),
  RoleOption('TEACHER', 'Teacher', 'Class teacher', LucideIcons.bookOpen),
  RoleOption('STUDENT', 'Student', 'Student / buddy', LucideIcons.user),
  RoleOption('PARENT', 'Parent', 'Parent / guardian', LucideIcons.heart),
];

const _needsSchool = {'PRINCIPAL', 'TEACHER', 'STUDENT', 'PARENT'};
const _needsClass = {'TEACHER', 'STUDENT'};

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _repo = AuthRepository();

  final _fullName = TextEditingController();
  final _email = TextEditingController();
  final _phone = TextEditingController();
  final _password = TextEditingController();
  final _confirm = TextEditingController();

  String? _role;
  String _schoolName = '';
  String _className = '';
  String _section = '';

  List<String> _schools = [];
  List<String> _classes = [];
  List<String> _sections = [];
  bool _schoolsLoading = false;
  bool _classesLoading = false;
  bool _sectionsLoading = false;

  bool _loading = false;
  String? _error;
  String? _roleError;

  bool get _needsSchoolField => _needsSchool.contains(_role);
  bool get _needsClassField => _needsClass.contains(_role);

  @override
  void initState() {
    super.initState();
    _loadSchools();
  }

  Future<void> _loadSchools() async {
    setState(() => _schoolsLoading = true);
    try {
      _schools = await _repo.lookupSchools();
    } catch (_) {
      _schools = [];
    } finally {
      if (mounted) setState(() => _schoolsLoading = false);
    }
  }

  Future<void> _loadClasses(String school) async {
    if (school.isEmpty) {
      setState(() => _classes = []);
      return;
    }
    setState(() => _classesLoading = true);
    try {
      _classes = await _repo.lookupClasses(school);
    } catch (_) {
      _classes = [];
    } finally {
      if (mounted) setState(() => _classesLoading = false);
    }
  }

  Future<void> _loadSections(String school, String className) async {
    if (school.isEmpty || className.isEmpty) {
      setState(() => _sections = []);
      return;
    }
    setState(() => _sectionsLoading = true);
    try {
      _sections = await _repo.lookupSections(school, className);
    } catch (_) {
      _sections = [];
    } finally {
      if (mounted) setState(() => _sectionsLoading = false);
    }
  }

  void _onSchoolChanged(String v) {
    setState(() {
      _schoolName = v;
      _className = '';
      _section = '';
      _sections = [];
    });
    _loadClasses(v);
  }

  void _onClassChanged(String v) {
    setState(() {
      _className = v;
      _section = '';
    });
    _loadSections(_schoolName, v);
  }

  Future<void> _pickRole() async {
    final picked = await showRolePicker(context, _roles, _role);
    if (picked != null) {
      setState(() {
        _role = picked;
        _roleError = null;
      });
    }
  }

  Future<void> _submit() async {
    setState(() => _roleError = _role == null ? 'Please select your role' : null);
    if (!_formKey.currentState!.validate() || _role == null) return;
    if (_password.text != _confirm.text) {
      setState(() => _error = "Passwords don't match");
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await context.read<AuthProvider>().register(
            fullName: _fullName.text.trim(),
            email: _email.text.trim(),
            password: _password.text,
            phone: _phone.text.trim(),
            role: _role!,
            schoolName: _needsSchoolField ? _schoolName : null,
            className: _needsClassField ? _className : null,
            section: _needsClassField ? _section : null,
          );
    } catch (e) {
      setState(() => _error = e.toString().replaceFirst('ApiException: ', ''));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = context.surface;
    final selectedRole = _roles.where((r) => r.value == _role).firstOrNull;

    return AuthScaffold(
      title: 'Create account',
      subtitle: 'Fill in your details to get started',
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (_error != null)
              Container(
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(color: const Color(0xFFFEF2F2), borderRadius: BorderRadius.circular(14)),
                child: Text(_error!, style: const TextStyle(color: Color(0xFFB91C1C), fontSize: 12.5, fontWeight: FontWeight.w600)),
              ),

            Padding(
              padding: const EdgeInsets.only(left: 4, bottom: 6),
              child: Text('Select your role', style: Theme.of(context).inputDecorationTheme.labelStyle),
            ),
            InkWell(
              onTap: _pickRole,
              borderRadius: BorderRadius.circular(16),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                decoration: BoxDecoration(
                  color: Theme.of(context).inputDecorationTheme.fillColor,
                  borderRadius: BorderRadius.circular(16),
                  border: _roleError != null ? Border.all(color: AppColors.danger, width: 1.2) : null,
                ),
                child: Row(
                  children: [
                    if (selectedRole != null) ...[
                      Icon(selectedRole.icon, size: 17, color: AppColors.saffron600),
                      const SizedBox(width: 10),
                      Text(selectedRole.label, style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: s.textPrimary)),
                      const SizedBox(width: 6),
                      Expanded(child: Text(selectedRole.desc, style: TextStyle(fontSize: 12, color: s.textMuted), overflow: TextOverflow.ellipsis)),
                    ] else
                      Expanded(child: Text('— Choose your role —', style: TextStyle(color: s.textMuted, fontSize: 14))),
                    Icon(LucideIcons.chevronDown, size: 18, color: s.textMuted),
                  ],
                ),
              ),
            ),
            if (_roleError != null)
              Padding(
                padding: const EdgeInsets.only(top: 5, left: 4),
                child: Text(_roleError!, style: const TextStyle(color: AppColors.danger, fontSize: 11.5)),
              ),
            const SizedBox(height: 16),
            Divider(color: s.border),
            const SizedBox(height: 16),

            AppTextField(label: 'Full name', controller: _fullName, hint: 'Your full name', prefixIcon: Icons.person_outline_rounded, validator: (v) => (v == null || v.trim().length < 2) ? 'Enter your full name' : null),
            const SizedBox(height: 16),
            AppTextField(label: 'Email address', controller: _email, hint: 'you@example.com', keyboardType: TextInputType.emailAddress, prefixIcon: Icons.mail_outline_rounded, validator: (v) => (v == null || !v.contains('@')) ? 'Enter a valid email' : null),
            const SizedBox(height: 16),
            AppTextField(label: 'Phone number', controller: _phone, hint: '10-digit mobile number', keyboardType: TextInputType.phone, prefixIcon: Icons.phone_outlined, validator: (v) => (v == null || v.trim().length < 10) ? 'Enter a valid phone number' : null),

            if (_needsSchoolField) ...[
              const SizedBox(height: 16),
              SearchableField(
                label: 'School name',
                value: _schoolName,
                onChanged: _onSchoolChanged,
                options: _schools,
                loading: _schoolsLoading,
                prefixIcon: LucideIcons.school,
                hint: 'Search or type your school name',
              ),
            ],
            if (_needsClassField) ...[
              const SizedBox(height: 16),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: SearchableField(
                      label: 'Class',
                      value: _className,
                      onChanged: _onClassChanged,
                      options: _classes,
                      loading: _classesLoading,
                      enabled: _schoolName.isNotEmpty,
                      prefixIcon: LucideIcons.bookOpen,
                      hint: 'Search or type class',
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: SearchableField(
                      label: 'Section',
                      value: _section,
                      onChanged: (v) => setState(() => _section = v),
                      options: _sections,
                      loading: _sectionsLoading,
                      enabled: _className.isNotEmpty,
                      prefixIcon: LucideIcons.layers,
                      hint: 'Search or type section',
                    ),
                  ),
                ],
              ),
            ],

            const SizedBox(height: 16),
            AppTextField(label: 'Password', controller: _password, hint: 'At least 6 characters', obscure: true, prefixIcon: Icons.lock_outline_rounded, validator: (v) => (v == null || v.length < 6) ? 'At least 6 characters' : null),
            const SizedBox(height: 16),
            AppTextField(label: 'Confirm password', controller: _confirm, hint: 'Re-enter your password', obscure: true, prefixIcon: Icons.lock_outline_rounded, validator: (v) => (v == null || v.isEmpty) ? 'Re-enter your password' : null),

            const SizedBox(height: 22),
            GradientButton(label: 'Create Account', icon: Icons.arrow_forward_rounded, loading: _loading, onPressed: _submit),
            const SizedBox(height: 22),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('Already have an account? ', style: TextStyle(color: s.textSecondary, fontSize: 13)),
                GestureDetector(
                  onTap: () => context.pop(),
                  child: const Text('Sign in', style: TextStyle(color: AppColors.saffron600, fontSize: 13, fontWeight: FontWeight.w800)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
