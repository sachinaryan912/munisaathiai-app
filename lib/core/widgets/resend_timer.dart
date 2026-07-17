import 'dart:async';
import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class ResendTimer extends StatefulWidget {
  final Future<void> Function() onResend;
  final int seconds;

  const ResendTimer({super.key, required this.onResend, this.seconds = 60});

  @override
  State<ResendTimer> createState() => _ResendTimerState();
}

class _ResendTimerState extends State<ResendTimer> {
  late int _remaining = widget.seconds;
  Timer? _timer;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  void _startTimer() {
    _timer?.cancel();
    setState(() => _remaining = widget.seconds);
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (_remaining <= 1) {
        t.cancel();
        setState(() => _remaining = 0);
      } else {
        setState(() => _remaining--);
      }
    });
  }

  Future<void> _resend() async {
    setState(() => _loading = true);
    await widget.onResend();
    if (mounted) {
      setState(() => _loading = false);
      _startTimer();
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final canResend = _remaining <= 0 && !_loading;
    return Center(
      child: TextButton(
        onPressed: canResend ? _resend : null,
        child: Text(
          _loading
              ? 'Sending...'
              : canResend
                  ? 'Resend OTP'
                  : 'Resend OTP in ${_remaining}s',
          style: TextStyle(
            fontSize: 12.5,
            fontWeight: FontWeight.w700,
            color: canResend ? AppColors.saffron600 : Colors.grey,
          ),
        ),
      ),
    );
  }
}
