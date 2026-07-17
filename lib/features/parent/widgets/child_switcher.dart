import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../selected_child_provider.dart';
import 'link_child_panel.dart';

class ChildSwitcher extends StatelessWidget {
  const ChildSwitcher({super.key});

  void _openAddSheet(BuildContext context) {
    showModalBottomSheet(
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
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(width: 40, height: 4, margin: const EdgeInsets.only(bottom: 14), alignment: Alignment.center, decoration: BoxDecoration(color: s.border, borderRadius: BorderRadius.circular(99))),
                  Text('Link a child', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: s.textPrimary)),
                  const SizedBox(height: 14),
                  const LinkChildPanel(),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = context.surface;
    final provider = context.watch<SelectedChildProvider>();

    return SizedBox(
      height: 40,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          ...provider.children.map((c) {
            final active = c['id'] == provider.selectedChildId;
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: ChoiceChip(
                label: Text(c['fullName'] as String),
                selected: active,
                onSelected: (_) => context.read<SelectedChildProvider>().select(c['id'] as int),
                selectedColor: AppColors.saffron500,
                labelStyle: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w800, color: active ? Colors.white : s.textSecondary),
                backgroundColor: s.card,
                side: BorderSide(color: active ? AppColors.saffron500 : s.border),
                avatar: active ? null : const Icon(LucideIcons.user, size: 13),
              ),
            );
          }),
          ActionChip(
            label: const Text('Add child'),
            avatar: const Icon(LucideIcons.plus, size: 14, color: AppColors.saffron600),
            onPressed: () => _openAddSheet(context),
            labelStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.saffron600),
            backgroundColor: AppColors.saffron50,
            side: BorderSide.none,
          ),
        ],
      ),
    );
  }
}
