import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';
import '../../core/nav/nav_items.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/app_text_field.dart';
import '../../core/widgets/gradient_button.dart';
import '../../core/widgets/section_card.dart';
import '../auth/data/auth_provider.dart';
import '../auth/data/auth_repository.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _repo = AuthRepository();

  late final _fullName = TextEditingController(text: context.read<AuthProvider>().user?.fullName ?? '');
  late final _phone = TextEditingController(text: context.read<AuthProvider>().user?.phone ?? '');
  bool _savingProfile = false;
  String? _profileMsg;
  String? _profileErr;

  final _currentPassword = TextEditingController();
  final _newPassword = TextEditingController();
  final _confirmPassword = TextEditingController();
  bool _savingPassword = false;
  String? _passwordMsg;
  String? _passwordErr;

  Future<void> _saveProfile() async {
    setState(() {
      _savingProfile = true;
      _profileMsg = null;
      _profileErr = null;
    });
    try {
      final updated = await _repo.updateMe(fullName: _fullName.text.trim(), phone: _phone.text.trim());
      if (!mounted) return;
      context.read<AuthProvider>().applyProfilePatch(fullName: updated.fullName, phone: updated.phone);
      setState(() => _profileMsg = 'Profile updated successfully!');
    } catch (e) {
      setState(() => _profileErr = e.toString().replaceFirst('ApiException: ', ''));
    } finally {
      if (mounted) setState(() => _savingProfile = false);
    }
  }

  Future<void> _changePassword() async {
    setState(() {
      _passwordMsg = null;
      _passwordErr = null;
    });
    if (_newPassword.text != _confirmPassword.text) {
      setState(() => _passwordErr = 'New password and confirmation do not match.');
      return;
    }
    if (_newPassword.text.length < 6) {
      setState(() => _passwordErr = 'New password must be at least 6 characters.');
      return;
    }
    setState(() => _savingPassword = true);
    try {
      await _repo.changePassword(currentPassword: _currentPassword.text, newPassword: _newPassword.text);
      setState(() {
        _passwordMsg = 'Password changed successfully!';
        _currentPassword.clear();
        _newPassword.clear();
        _confirmPassword.clear();
      });
    } catch (e) {
      setState(() => _passwordErr = e.toString().replaceFirst('ApiException: ', ''));
    } finally {
      if (mounted) setState(() => _savingPassword = false);
    }
  }

  Future<void> _logout() async {
    await context.read<AuthProvider>().logout();
    if (mounted) context.go('/login');
  }

  @override
  Widget build(BuildContext context) {
    final s = context.surface;
    final user = context.watch<AuthProvider>().user;

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          SectionCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(children: [const Icon(LucideIcons.user, size: 18, color: AppColors.saffron500), const SizedBox(width: 8), Text('Profile', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 15, color: s.textPrimary))]),
                const SizedBox(height: 16),
                AppTextField(label: 'Full Name', controller: _fullName),
                const SizedBox(height: 14),
                AppTextField(label: 'Phone', controller: _phone, keyboardType: TextInputType.phone),
                const SizedBox(height: 14),
                AppTextField(label: 'Email', controller: TextEditingController(text: user?.email ?? ''), enabled: false),
                const SizedBox(height: 14),
                AppTextField(label: 'Role', controller: TextEditingController(text: kRoleLabels[user?.role] ?? user?.role ?? ''), enabled: false),
                if (user?.schoolName != null) ...[
                  const SizedBox(height: 14),
                  AppTextField(label: 'School', controller: TextEditingController(text: user!.schoolName!), enabled: false),
                ],
                if (user?.className != null) ...[
                  const SizedBox(height: 14),
                  AppTextField(label: 'Class', controller: TextEditingController(text: user!.className!), enabled: false),
                ],
                if (_profileErr != null) ...[const SizedBox(height: 10), Text(_profileErr!, style: const TextStyle(color: AppColors.danger, fontSize: 12, fontWeight: FontWeight.w700))],
                if (_profileMsg != null) ...[const SizedBox(height: 10), Text(_profileMsg!, style: const TextStyle(color: AppColors.success, fontSize: 12, fontWeight: FontWeight.w700))],
                const SizedBox(height: 16),
                GradientButton(label: 'Save Changes', loading: _savingProfile, onPressed: _saveProfile, height: 46),
              ],
            ),
          ),
          const SizedBox(height: 16),
          SectionCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(children: [const Icon(LucideIcons.lock, size: 18, color: AppColors.saffron500), const SizedBox(width: 8), Text('Change Password', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 15, color: s.textPrimary))]),
                const SizedBox(height: 16),
                AppTextField(label: 'Current Password', controller: _currentPassword, obscure: true),
                const SizedBox(height: 14),
                AppTextField(label: 'New Password', controller: _newPassword, obscure: true),
                const SizedBox(height: 14),
                AppTextField(label: 'Confirm New Password', controller: _confirmPassword, obscure: true),
                if (_passwordErr != null) ...[const SizedBox(height: 10), Text(_passwordErr!, style: const TextStyle(color: AppColors.danger, fontSize: 12, fontWeight: FontWeight.w700))],
                if (_passwordMsg != null) ...[const SizedBox(height: 10), Text(_passwordMsg!, style: const TextStyle(color: AppColors.success, fontSize: 12, fontWeight: FontWeight.w700))],
                const SizedBox(height: 16),
                GradientButton(label: 'Update Password', loading: _savingPassword, onPressed: _changePassword, height: 46),
              ],
            ),
          ),
          const SizedBox(height: 16),
          SectionCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text('Account', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 15, color: s.textPrimary)),
                const SizedBox(height: 4),
                Text('Sign out of Muni Saathi AI on this device.', style: TextStyle(fontSize: 12, color: s.textMuted, fontWeight: FontWeight.w600)),
                const SizedBox(height: 16),
                OutlinedButton.icon(
                  onPressed: _logout,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.danger,
                    side: const BorderSide(color: Color(0xFFFECACA)),
                    padding: const EdgeInsets.symmetric(vertical: 13, horizontal: 18),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  icon: const Icon(LucideIcons.logOut, size: 17),
                  label: const Text('Sign Out', style: TextStyle(fontWeight: FontWeight.w800)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
