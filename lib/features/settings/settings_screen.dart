import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';
import '../../core/nav/nav_items.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_shadows.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/gradient_button.dart';
import '../auth/data/auth_provider.dart';
import '../auth/data/auth_repository.dart';
import '../management/thresholds_screen.dart';

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

  Widget _buildGroup(List<Widget> children) {
    final s = context.surface;
    final dark = Theme.of(context).brightness == Brightness.dark;
    final items = <Widget>[];
    for (int i = 0; i < children.length; i++) {
      items.add(children[i]);
      if (i < children.length - 1) {
        items.add(Divider(height: 1, thickness: 0.5, color: s.border, indent: 58));
      }
    }
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: s.card,
        borderRadius: BorderRadius.circular(16),
        border: dark ? null : Border.all(color: s.border),
        boxShadow: AppShadows.soft(dark),
      ),
      child: Column(
        children: items,
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    final s = context.surface;
    return Padding(
      padding: const EdgeInsets.only(left: 16, bottom: 8, top: 8),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: s.textMuted,
          letterSpacing: 0.8,
        ),
      ),
    );
  }

  Widget _buildEditableRow({
    required IconData icon,
    required Color iconBgColor,
    required String label,
    required TextEditingController controller,
    TextInputType? keyboardType,
  }) {
    final s = context.surface;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              color: iconBgColor,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: Colors.white, size: 16),
          ),
          const SizedBox(width: 12),
          Text(
            label,
            style: TextStyle(
              fontSize: 14.5,
              fontWeight: FontWeight.w600,
              color: s.textPrimary,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: TextField(
              controller: controller,
              keyboardType: keyboardType,
              textAlign: TextAlign.right,
              style: TextStyle(
                fontSize: 14.5,
                fontWeight: FontWeight.w500,
                color: s.textSecondary,
              ),
              decoration: const InputDecoration(
                border: InputBorder.none,
                focusedBorder: InputBorder.none,
                enabledBorder: InputBorder.none,
                contentPadding: EdgeInsets.zero,
                isDense: true,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildValueRow({
    required IconData icon,
    required Color iconBgColor,
    required String label,
    required String value,
  }) {
    final s = context.surface;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              color: iconBgColor,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: Colors.white, size: 16),
          ),
          const SizedBox(width: 12),
          Text(
            label,
            style: TextStyle(
              fontSize: 14.5,
              fontWeight: FontWeight.w600,
              color: s.textPrimary,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: TextStyle(
                fontSize: 14.5,
                fontWeight: FontWeight.w500,
                color: s.textMuted,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = context.surface;
    final dark = Theme.of(context).brightness == Brightness.dark;
    final user = context.watch<AuthProvider>().user;
    final role = user?.role ?? 'STUDENT';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 40),
        children: [
          // Profile Header Section
          Column(
            children: [
              const SizedBox(height: 10),
              Center(
                child: Stack(
                  children: [
                    Container(
                      width: 88,
                      height: 88,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          colors: AppColors.roleGradient(role),
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        border: Border.all(color: s.bg, width: 3),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.roleColor(role).withValues(alpha: 0.3),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        user?.initials ?? 'U',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 28,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1,
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        padding: const EdgeInsets.all(5),
                        decoration: BoxDecoration(
                          color: AppColors.saffron500,
                          shape: BoxShape.circle,
                          border: Border.all(color: s.bg, width: 2),
                        ),
                        child: const Icon(LucideIcons.camera, color: Colors.white, size: 12),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Text(
                user?.fullName ?? '',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: s.textPrimary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                user?.email ?? '',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: s.textMuted,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.roleColor(role).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: AppColors.roleColor(role).withValues(alpha: 0.25),
                    width: 1,
                  ),
                ),
                child: Text(
                  kRoleLabels[role] ?? role,
                  style: TextStyle(
                    color: AppColors.roleColor(role),
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),

          // Section: Personal Information
          _buildSectionHeader('Personal Information'),
          _buildGroup([
            _buildEditableRow(
              icon: LucideIcons.user,
              iconBgColor: AppColors.saffron500,
              label: 'Full Name',
              controller: _fullName,
            ),
            _buildEditableRow(
              icon: LucideIcons.phone,
              iconBgColor: const Color(0xFF3B82F6),
              label: 'Phone',
              controller: _phone,
              keyboardType: TextInputType.phone,
            ),
          ]),
          if (_profileErr != null) ...[
            Padding(
              padding: const EdgeInsets.only(left: 4, bottom: 8),
              child: Text(_profileErr!, style: const TextStyle(color: AppColors.danger, fontSize: 12.5, fontWeight: FontWeight.w700)),
            ),
          ],
          if (_profileMsg != null) ...[
            Padding(
              padding: const EdgeInsets.only(left: 4, bottom: 8),
              child: Text(_profileMsg!, style: const TextStyle(color: AppColors.success, fontSize: 12.5, fontWeight: FontWeight.w700)),
            ),
          ],
          Padding(
            padding: const EdgeInsets.only(bottom: 24),
            child: GradientButton(
              label: 'Save Changes',
              loading: _savingProfile,
              onPressed: _saveProfile,
              height: 44,
            ),
          ),

          // Section: Academic Profile
          _buildSectionHeader('Details'),
          _buildGroup([
            _buildValueRow(
              icon: LucideIcons.mail,
              iconBgColor: const Color(0xFF6B7280),
              label: 'Email',
              value: user?.email ?? '',
            ),
            _buildValueRow(
              icon: LucideIcons.shieldAlert,
              iconBgColor: AppColors.roleColor(role),
              label: 'Role',
              value: kRoleLabels[role] ?? role,
            ),
            if (user?.schoolName != null)
              _buildValueRow(
                icon: LucideIcons.school,
                iconBgColor: const Color(0xFF8B5CF6),
                label: 'School',
                value: user!.schoolName!,
              ),
            if (user?.className != null)
              _buildValueRow(
                icon: LucideIcons.graduationCap,
                iconBgColor: const Color(0xFF10B981),
                label: 'Class',
                value: user!.className!,
              ),
          ]),
          const SizedBox(height: 12),

          // Section: Security
          _buildSectionHeader('Security'),
          _buildGroup([
            _PasswordRow(
              icon: LucideIcons.key,
              iconBgColor: const Color(0xFFF59E0B),
              label: 'Current Password',
              controller: _currentPassword,
            ),
            _PasswordRow(
              icon: LucideIcons.lock,
              iconBgColor: const Color(0xFF10B981),
              label: 'New Password',
              controller: _newPassword,
            ),
            _PasswordRow(
              icon: LucideIcons.checkSquare,
              iconBgColor: const Color(0xFFEC4899),
              label: 'Confirm Password',
              controller: _confirmPassword,
            ),
          ]),
          if (_passwordErr != null) ...[
            Padding(
              padding: const EdgeInsets.only(left: 4, bottom: 8),
              child: Text(_passwordErr!, style: const TextStyle(color: AppColors.danger, fontSize: 12.5, fontWeight: FontWeight.w700)),
            ),
          ],
          if (_passwordMsg != null) ...[
            Padding(
              padding: const EdgeInsets.only(left: 4, bottom: 8),
              child: Text(_passwordMsg!, style: const TextStyle(color: AppColors.success, fontSize: 12.5, fontWeight: FontWeight.w700)),
            ),
          ],
          Padding(
            padding: const EdgeInsets.only(bottom: 28),
            child: GradientButton(
              label: 'Update Password',
              loading: _savingPassword,
              onPressed: _changePassword,
              height: 44,
            ),
          ),

          // Section: Management-only tools
          if (role == 'MANAGEMENT') ...[
            _buildSectionHeader('Administration'),
            GestureDetector(
              onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const ThresholdsScreen())),
              child: _buildGroup([
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Row(
                    children: [
                      Container(
                        width: 30,
                        height: 30,
                        decoration: BoxDecoration(color: AppColors.saffron500, borderRadius: BorderRadius.circular(8)),
                        child: const Icon(LucideIcons.slidersHorizontal, color: Colors.white, size: 16),
                      ),
                      const SizedBox(width: 12),
                      Expanded(child: Text('MII & Alert Thresholds', style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.w600, color: s.textPrimary))),
                      Icon(LucideIcons.chevronRight, size: 16, color: s.textMuted),
                    ],
                  ),
                ),
              ]),
            ),
            const SizedBox(height: 12),
          ],

          // Section: Account Actions
          GestureDetector(
            onTap: _logout,
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 14),
              decoration: BoxDecoration(
                color: s.card,
                borderRadius: BorderRadius.circular(16),
                border: dark ? null : Border.all(color: s.border),
                boxShadow: AppShadows.soft(dark),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(LucideIcons.logOut, color: AppColors.danger, size: 18),
                  SizedBox(width: 8),
                  Text(
                    'Sign Out',
                    style: TextStyle(
                      color: AppColors.danger,
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}

class _PasswordRow extends StatefulWidget {
  final IconData icon;
  final Color iconBgColor;
  final String label;
  final TextEditingController controller;

  const _PasswordRow({
    required this.icon,
    required this.iconBgColor,
    required this.label,
    required this.controller,
  });

  @override
  State<_PasswordRow> createState() => _PasswordRowState();
}

class _PasswordRowState extends State<_PasswordRow> {
  bool _obscured = true;

  @override
  Widget build(BuildContext context) {
    final s = context.surface;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              color: widget.iconBgColor,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(widget.icon, color: Colors.white, size: 16),
          ),
          const SizedBox(width: 12),
          Text(
            widget.label,
            style: TextStyle(
              fontSize: 14.5,
              fontWeight: FontWeight.w600,
              color: s.textPrimary,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: TextField(
              controller: widget.controller,
              obscureText: _obscured,
              textAlign: TextAlign.right,
              style: TextStyle(
                fontSize: 14.5,
                fontWeight: FontWeight.w500,
                color: s.textSecondary,
              ),
              decoration: const InputDecoration(
                border: InputBorder.none,
                focusedBorder: InputBorder.none,
                enabledBorder: InputBorder.none,
                contentPadding: EdgeInsets.zero,
                isDense: true,
              ),
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: () => setState(() => _obscured = !_obscured),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Icon(
                _obscured ? Icons.visibility_off_rounded : Icons.visibility_rounded,
                size: 18,
                color: s.textMuted,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
