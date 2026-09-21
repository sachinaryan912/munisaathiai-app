import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import 'app_icon.dart';

class AppTextField extends StatefulWidget {
  final String label;
  final String? hint;
  final TextEditingController controller;
  final bool obscure;
  final TextInputType? keyboardType;
  final dynamic prefixIcon;
  final String? Function(String?)? validator;
  final int maxLines;
  final bool enabled;
  final ValueChanged<String>? onChanged;
  final Widget? suffix;

  const AppTextField({
    super.key,
    required this.label,
    required this.controller,
    this.hint,
    this.obscure = false,
    this.keyboardType,
    this.prefixIcon,
    this.validator,
    this.maxLines = 1,
    this.enabled = true,
    this.onChanged,
    this.suffix,
  });

  @override
  State<AppTextField> createState() => _AppTextFieldState();
}

class _AppTextFieldState extends State<AppTextField> {
  late bool _obscured = widget.obscure;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 6),
          child: Text(widget.label, style: Theme.of(context).inputDecorationTheme.labelStyle),
        ),
        TextFormField(
          controller: widget.controller,
          obscureText: _obscured,
          keyboardType: widget.keyboardType,
          maxLines: widget.obscure ? 1 : widget.maxLines,
          enabled: widget.enabled,
          validator: widget.validator,
          onChanged: widget.onChanged,
          decoration: InputDecoration(
            hintText: widget.hint,
            prefixIcon: widget.prefixIcon != null
                ? Padding(
                    padding: const EdgeInsets.only(left: 12, right: 8),
                    child: AppIcon(
                      widget.prefixIcon,
                      size: 19,
                      color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.55),
                    ),
                  )
                : null,
            prefixIconConstraints: const BoxConstraints(minWidth: 40, minHeight: 40),
            suffixIcon: widget.obscure
                ? IconButton(
                    icon: HugeIcon(
                      icon: _obscured ? HugeIcons.strokeRoundedViewOffSlash : HugeIcons.strokeRoundedView,
                      size: 19,
                      color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.55),
                    ),
                    onPressed: () => setState(() => _obscured = !_obscured),
                  )
                : widget.suffix,
          ),
        ),
      ],
    );
  }
}
