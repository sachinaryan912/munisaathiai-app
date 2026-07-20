import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../student_repository.dart';
import 'log_buddy_session_sheet.dart';
import 'log_peer_teaching_sheet.dart';
import 'quick_feedback_sheet.dart';
import 'upload_assignment_sheet.dart';

class _SpeedDialAction {
  final String label;
  final IconData icon;
  final Color color;
  final Future<void> Function(BuildContext context, StudentRepository repo, Future<void> Function() onSuccess) show;
  const _SpeedDialAction(this.label, this.icon, this.color, this.show);
}

const _actions = [
  _SpeedDialAction('Assignment', LucideIcons.fileCheck, Color(0xFF10B981), showUploadAssignmentSheet),
  _SpeedDialAction('Buddy Session', LucideIcons.users, AppColors.saffron500, showLogBuddySessionSheet),
  _SpeedDialAction('Peer Teaching', LucideIcons.graduationCap, Color(0xFFF43F5E), showLogPeerTeachingSheet),
  _SpeedDialAction('Feedback', LucideIcons.heart, Color(0xFFEC4899), showQuickFeedbackSheet),
];

/// Quick-create speed dial for the Student Dashboard — the fastest path to
/// "submit an assignment" / "log a buddy session" / etc. without drilling
/// into each sub-page first.
class StudentSpeedDial extends StatefulWidget {
  final StudentRepository repo;
  final Future<void> Function() onDone;

  const StudentSpeedDial({super.key, required this.repo, required this.onDone});

  @override
  State<StudentSpeedDial> createState() => _StudentSpeedDialState();
}

class _StudentSpeedDialState extends State<StudentSpeedDial> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 260));
  bool _open = false;

  void _toggle() {
    HapticFeedback.selectionClick();
    setState(() => _open = !_open);
    if (_open) {
      _controller.forward();
    } else {
      _controller.reverse();
    }
  }

  Future<void> _runAction(_SpeedDialAction action) async {
    _toggle();
    await action.show(context, widget.repo, widget.onDone);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        ...List.generate(_actions.length, (i) {
          final action = _actions[i];
          final interval = Interval((i / _actions.length) * 0.5, 1.0, curve: Curves.easeOutCubic);
          final anim = CurvedAnimation(parent: _controller, curve: interval);
          return _SpeedDialItem(action: action, animation: anim, onTap: () => _runAction(action));
        }).toList().reversed,
        const SizedBox(height: 14),
        _MainFab(open: _open, onTap: _toggle),
      ],
    );
  }
}

class _MainFab extends StatelessWidget {
  final bool open;
  final VoidCallback onTap;
  const _MainFab({required this.open, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      shape: const CircleBorder(),
      // Material's own elevation shadow (clipped via PhysicalShape to `shape:`) instead of a
      // manual BoxShadow — BoxShadow on a BoxShape.circle decoration can render as a square
      // behind the circle on some renderers, since it isn't clipped to the shape.
      elevation: 8,
      shadowColor: AppColors.saffron500.withValues(alpha: 0.6),
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: Ink(
          width: 58,
          height: 58,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(colors: [AppColors.saffron500, AppColors.saffron400]),
          ),
          child: Center(
            child: AnimatedRotation(
              turns: open ? 0.125 : 0,
              duration: const Duration(milliseconds: 260),
              curve: Curves.easeOutBack,
              child: const Icon(Icons.add_rounded, color: Colors.white, size: 28),
            ),
          ),
        ),
      ),
    );
  }
}

class _SpeedDialItem extends StatelessWidget {
  final _SpeedDialAction action;
  final Animation<double> animation;
  final VoidCallback onTap;

  const _SpeedDialItem({required this.action, required this.animation, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final s = context.surface;
    // SizeTransition collapses the row to zero height (and blocks taps) when
    // closed, instead of just fading it out and leaving dead space behind.
    return SizeTransition(
      sizeFactor: animation,
      axis: Axis.vertical,
      axisAlignment: -1,
      child: FadeTransition(
        opacity: animation,
        child: Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: s.card,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.12), blurRadius: 10, offset: const Offset(0, 3))],
                ),
                child: Text(action.label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: s.textPrimary)),
              ),
              const SizedBox(width: 10),
              Material(
                color: Colors.transparent,
                shape: const CircleBorder(),
                elevation: 6,
                shadowColor: action.color.withValues(alpha: 0.6),
                child: InkWell(
                  onTap: onTap,
                  customBorder: const CircleBorder(),
                  child: Ink(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      color: action.color,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(action.icon, color: Colors.white, size: 20),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
