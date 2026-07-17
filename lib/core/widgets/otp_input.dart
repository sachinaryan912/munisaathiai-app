import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';

class OtpInput extends StatefulWidget {
  final ValueChanged<String> onChanged;
  final String? error;
  final int length;

  const OtpInput({super.key, required this.onChanged, this.error, this.length = 6});

  @override
  State<OtpInput> createState() => OtpInputState();
}

class OtpInputState extends State<OtpInput> {
  late final List<TextEditingController> _controllers = List.generate(widget.length, (_) => TextEditingController());
  late final List<FocusNode> _nodes = List.generate(widget.length, (_) => FocusNode());

  void clear() {
    for (final c in _controllers) {
      c.clear();
    }
    _nodes.first.requestFocus();
    widget.onChanged('');
  }

  @override
  void dispose() {
    for (final c in _controllers) {
      c.dispose();
    }
    for (final n in _nodes) {
      n.dispose();
    }
    super.dispose();
  }

  void _emit() {
    widget.onChanged(_controllers.map((c) => c.text).join());
  }

  void _onChanged(int i, String v) {
    if (v.length > 1) {
      // Handles pasting the full code into one box.
      final digits = v.replaceAll(RegExp(r'\D'), '').split('');
      for (var j = 0; j < _controllers.length; j++) {
        _controllers[j].text = j < digits.length ? digits[j] : '';
      }
      final lastIndex = digits.length.clamp(0, widget.length) - 1;
      if (lastIndex >= 0) _nodes[lastIndex.clamp(0, widget.length - 1)].requestFocus();
      _emit();
      return;
    }
    if (v.isNotEmpty && i < widget.length - 1) _nodes[i + 1].requestFocus();
    _emit();
  }

  @override
  Widget build(BuildContext context) {
    final s = context.surface;
    final hasError = widget.error != null && widget.error!.isNotEmpty;
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: List.generate(widget.length, (i) {
            return SizedBox(
              width: 44,
              height: 52,
              child: KeyboardListener(
                focusNode: FocusNode(skipTraversal: true),
                onKeyEvent: (event) {
                  if (event is KeyDownEvent && event.logicalKey == LogicalKeyboardKey.backspace && _controllers[i].text.isEmpty && i > 0) {
                    _nodes[i - 1].requestFocus();
                  }
                },
                child: TextField(
                  controller: _controllers[i],
                  focusNode: _nodes[i],
                  textAlign: TextAlign.center,
                  keyboardType: TextInputType.number,
                  maxLength: widget.length,
                  style: TextStyle(fontSize: 19, fontWeight: FontWeight.w800, color: s.textPrimary),
                  decoration: InputDecoration(
                    counterText: '',
                    filled: true,
                    fillColor: Theme.of(context).inputDecorationTheme.fillColor,
                    contentPadding: EdgeInsets.zero,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: hasError ? const BorderSide(color: AppColors.danger, width: 1.4) : BorderSide.none,
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(color: AppColors.saffron400, width: 1.8),
                    ),
                  ),
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  onChanged: (v) => _onChanged(i, v),
                ),
              ),
            );
          }),
        ),
        if (hasError)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(widget.error!, style: const TextStyle(color: AppColors.danger, fontSize: 12, fontWeight: FontWeight.w600)),
          ),
      ],
    );
  }
}
