import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/async_screen.dart';
import '../../core/widgets/empty_view.dart';
import '../../core/widgets/section_card.dart';
import '../shell/app_shell.dart';
import 'management_repository.dart';
import 'widgets/user_form_sheets.dart';

class ManagementUsersScreen extends StatefulWidget {
  const ManagementUsersScreen({super.key});

  @override
  State<ManagementUsersScreen> createState() => _ManagementUsersScreenState();
}

class _ManagementUsersScreenState extends State<ManagementUsersScreen> {
  final _repo = ManagementRepository();
  String _roleFilter = 'ALL';

  Future<void> _create(Future<void> Function() refresh) async {
    final payload = await showCreateUserSheet(context);
    if (payload == null) return;
    try {
      await _repo.createUser(payload);
      await refresh();
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString().replaceFirst('ApiException: ', ''))));
    }
  }

  Future<void> _edit(Map<String, dynamic> user, Future<void> Function() refresh) async {
    final payload = await showEditUserSheet(context, user);
    if (payload == null) return;
    try {
      await _repo.updateUser(user['id'] as int, payload);
      await refresh();
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString().replaceFirst('ApiException: ', ''))));
    }
  }

  Future<void> _resetPassword(Map<String, dynamic> user) async {
    final newPassword = await showResetPasswordSheet(context);
    if (newPassword == null) return;
    try {
      await _repo.resetPassword(user['id'] as int, newPassword);
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Password reset successfully.')));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString().replaceFirst('ApiException: ', ''))));
    }
  }

  Future<void> _toggleBlock(Map<String, dynamic> user, Future<void> Function() refresh) async {
    final enabled = user['enabled'] as bool? ?? true;
    try {
      if (enabled) {
        await _repo.blockUser(user['id'] as int);
      } else {
        await _repo.unblockUser(user['id'] as int);
      }
      await refresh();
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString().replaceFirst('ApiException: ', ''))));
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppShell(
      title: 'Users',
      showAiFab: false,
      body: AsyncScreen<List<Map<String, dynamic>>>(
        loader: _repo.getUsers,
        builder: (context, users, refresh) {
          final s = context.surface;
          final roles = ['ALL', ...{for (final u in users) u['role'] as String}];
          final filtered = _roleFilter == 'ALL' ? users : users.where((u) => u['role'] == _roleFilter).toList();

          return Stack(
            children: [
              Column(
                children: [
                  SizedBox(
                    height: 44,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                      children: roles.map((r) {
                        final active = r == _roleFilter;
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: ChoiceChip(label: Text(r), selected: active, onSelected: (_) => setState(() => _roleFilter = r), selectedColor: AppColors.saffron500, labelStyle: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w800, color: active ? Colors.white : s.textSecondary), backgroundColor: s.card, side: BorderSide(color: active ? AppColors.saffron500 : s.border)),
                        );
                      }).toList(),
                    ),
                  ),
                  Expanded(
                    child: filtered.isEmpty
                        ? const EmptyView(title: 'No users found', icon: LucideIcons.userCog)
                        : ListView.builder(
                            padding: const EdgeInsets.fromLTRB(16, 6, 16, 100),
                            itemCount: filtered.length,
                            itemBuilder: (context, i) {
                              final u = filtered[i];
                              final enabled = u['enabled'] as bool? ?? true;
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 10),
                                child: SectionCard(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          CircleAvatar(radius: 18, backgroundColor: AppColors.roleColor(u['role'] as String? ?? ''), child: Text((u['fullName'] as String).isNotEmpty ? (u['fullName'] as String)[0].toUpperCase() : '?', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800))),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(u['fullName'] as String, style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13.5, color: s.textPrimary)),
                                                Text(u['email'] as String, style: TextStyle(fontSize: 11, color: s.textMuted)),
                                              ],
                                            ),
                                          ),
                                          Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), decoration: BoxDecoration(color: AppColors.roleColor(u['role'] as String? ?? '').withValues(alpha: 0.14), borderRadius: BorderRadius.circular(99)), child: Text(u['role'] as String, style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.w800, color: AppColors.roleColor(u['role'] as String? ?? '')))),
                                        ],
                                      ),
                                      const SizedBox(height: 10),
                                      Row(
                                        children: [
                                          _ActionBtn(icon: LucideIcons.pencil, label: 'Edit', onTap: () => _edit(u, refresh)),
                                          _ActionBtn(icon: LucideIcons.keyRound, label: 'Reset PW', onTap: () => _resetPassword(u)),
                                          _ActionBtn(icon: enabled ? LucideIcons.ban : LucideIcons.circleCheck, label: enabled ? 'Block' : 'Unblock', color: enabled ? AppColors.danger : AppColors.success, onTap: () => _toggleBlock(u, refresh)),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ).animate(delay: (i * 40).ms).fadeIn(duration: 280.ms).slideY(begin: 0.06, end: 0, curve: Curves.easeOutCubic);
                            },
                          ),
                  ),
                ],
              ),
              Positioned(right: 16, bottom: 16, child: FloatingActionButton(heroTag: 'create_user', backgroundColor: AppColors.saffron500, onPressed: () => _create(refresh), child: const Icon(Icons.add, color: Colors.white))),
            ],
          );
        },
      ),
    );
  }
}

class _ActionBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color? color;
  final VoidCallback onTap;
  const _ActionBtn({required this.icon, required this.label, required this.onTap, this.color});

  @override
  Widget build(BuildContext context) {
    final s = context.surface;
    final c = color ?? s.textSecondary;
    return Expanded(
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Column(children: [Icon(icon, size: 15, color: c), const SizedBox(height: 3), Text(label, style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.w700, color: c))]),
        ),
      ),
    );
  }
}
