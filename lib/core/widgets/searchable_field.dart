import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';

/// A text field with a suggestions dropdown sourced from [options]. By default it still
/// accepts free text (mirrors the web app's `SearchableSelect` — schools/classes/sections
/// may not exist yet, so typing a new one is valid). Set [allowCreate] to false to make it
/// pick-only: typing still filters the suggestions, but only selecting one commits a value —
/// used for Class/Section once those come from a Management-curated catalog rather than
/// whatever anyone has typed before.
class SearchableField extends StatefulWidget {
  final String label;
  final String value;
  final ValueChanged<String> onChanged;
  final List<String> options;
  final bool loading;
  final bool enabled;
  final bool allowCreate;
  final String hint;
  final IconData? prefixIcon;
  final String? error;

  const SearchableField({
    super.key,
    required this.label,
    required this.value,
    required this.onChanged,
    required this.options,
    this.loading = false,
    this.enabled = true,
    this.allowCreate = true,
    this.hint = 'Search or type',
    this.prefixIcon,
    this.error,
  });

  @override
  State<SearchableField> createState() => _SearchableFieldState();
}

class _SearchableFieldState extends State<SearchableField> {
  late final _controller = TextEditingController(text: widget.value);
  late final _focusNode = FocusNode()..addListener(_onFocusChange);

  void _onFocusChange() {
    // Pick-only mode: unmatched typed text never committed (see onChanged above) — snap the
    // visible text back to the real value once the user looks away, instead of leaving a
    // typed string on screen that doesn't match what was actually selected.
    if (!widget.allowCreate && !_focusNode.hasFocus && _controller.text != widget.value) {
      _controller.text = widget.value;
    }
  }

  @override
  void didUpdateWidget(covariant SearchableField old) {
    super.didUpdateWidget(old);
    if (widget.value != _controller.text && widget.value != old.value) {
      _controller.text = widget.value;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = context.surface;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 6),
          child: Text(widget.label, style: Theme.of(context).inputDecorationTheme.labelStyle),
        ),
        RawAutocomplete<String>(
          textEditingController: _controller,
          focusNode: _focusNode,
          optionsBuilder: (textEditingValue) {
            final options = widget.options;
            if (textEditingValue.text.isEmpty) return options;
            return options.where((o) => o.toLowerCase().contains(textEditingValue.text.toLowerCase()));
          },
          onSelected: widget.onChanged,
          fieldViewBuilder: (context, controller, focusNode, onSubmit) {
            return TextFormField(
              controller: controller,
              focusNode: focusNode,
              enabled: widget.enabled,
              onChanged: (text) {
                // Pick-only mode: typing only filters suggestions below — it doesn't commit a
                // value on its own (that only happens via onSelected). Clearing the field does
                // still clear the committed value, so downstream cascades (e.g. clearing Section
                // when Class is erased) keep working.
                if (!widget.allowCreate) {
                  if (text.isEmpty) widget.onChanged('');
                  return;
                }
                widget.onChanged(text);
              },
              decoration: InputDecoration(
                hintText: widget.enabled ? widget.hint : 'Select the previous field first',
                prefixIcon: widget.prefixIcon != null ? Icon(widget.prefixIcon, size: 20) : null,
                suffixIcon: widget.loading
                    ? const Padding(
                        padding: EdgeInsets.all(14),
                        child: SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)),
                      )
                    : null,
                errorText: widget.error,
              ),
            );
          },
          optionsViewBuilder: (context, onSelected, opts) {
            final list = opts.toList();
            if (list.isEmpty && widget.allowCreate) return const SizedBox.shrink();
            return Align(
              alignment: Alignment.topLeft,
              child: Material(
                elevation: 6,
                borderRadius: BorderRadius.circular(14),
                color: s.card,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 220, minWidth: 280),
                  child: list.isEmpty
                      ? Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                          child: Text('None set up yet — contact your school management.', style: TextStyle(fontSize: 12, color: s.textMuted)),
                        )
                      : ListView.builder(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    shrinkWrap: true,
                    itemCount: list.length,
                    itemBuilder: (context, i) {
                      final opt = list[i];
                      return InkWell(
                        onTap: () => onSelected(opt),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
                          child: Text(opt, style: TextStyle(fontSize: 13.5, color: s.textPrimary, fontWeight: FontWeight.w600)),
                        ),
                      );
                    },
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}

class RoleOption {
  final String value;
  final String label;
  final String desc;
  final IconData icon;
  const RoleOption(this.value, this.label, this.desc, this.icon);
}

Future<String?> showRolePicker(BuildContext context, List<RoleOption> roles, String? selected) {
  final s = context.surface;
  return showModalBottomSheet<String>(
    context: context,
    backgroundColor: Colors.transparent,
    builder: (sheetContext) {
      return Container(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
        decoration: BoxDecoration(color: s.card, borderRadius: const BorderRadius.vertical(top: Radius.circular(28))),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(width: 40, height: 4, decoration: BoxDecoration(color: s.border, borderRadius: BorderRadius.circular(99))),
            const SizedBox(height: 16),
            Text('Select your role', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: s.textPrimary)),
            const SizedBox(height: 10),
            ...roles.map((r) {
              final active = r.value == selected;
              return InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: () => Navigator.pop(sheetContext, r.value),
                child: Container(
                  margin: const EdgeInsets.symmetric(vertical: 4),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                  decoration: BoxDecoration(
                    color: active ? AppColors.saffron50 : Colors.transparent,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(color: active ? AppColors.saffron100 : s.border.withValues(alpha: 0.5), borderRadius: BorderRadius.circular(12)),
                        child: Icon(r.icon, size: 17, color: active ? AppColors.saffron600 : s.textSecondary),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(r.label, style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13.5, color: active ? AppColors.saffron700 : s.textPrimary)),
                            Text(r.desc, style: TextStyle(fontSize: 11.5, color: active ? AppColors.saffron500 : s.textMuted)),
                          ],
                        ),
                      ),
                      if (active) const Icon(Icons.check_circle_rounded, color: AppColors.saffron500, size: 18),
                    ],
                  ),
                ),
              );
            }),
          ],
        ),
      );
    },
  );
}
