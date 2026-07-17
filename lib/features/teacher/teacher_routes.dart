import 'package:go_router/go_router.dart';
import 'class_screen.dart';
import 'dashboard_screen.dart';
import 'evidence_screen.dart';
import 'lesson_plans_screen.dart';
import 'methodology_screen.dart';
import 'parliament_screen.dart';
import 'reflection_screen.dart';

List<StatefulShellBranch> teacherBranches() => [
      StatefulShellBranch(routes: [GoRoute(path: '/teacher', builder: (context, state) => const TeacherDashboardScreen())]),
      StatefulShellBranch(routes: [GoRoute(path: '/teacher/class', builder: (context, state) => const TeacherClassScreen())]),
      StatefulShellBranch(routes: [GoRoute(path: '/teacher/methodology', builder: (context, state) => const TeacherMethodologyScreen())]),
      StatefulShellBranch(routes: [GoRoute(path: '/teacher/evidence', builder: (context, state) => const TeacherEvidenceScreen())]),
      StatefulShellBranch(routes: [GoRoute(path: '/teacher/lesson', builder: (context, state) => const TeacherLessonPlansScreen())]),
      StatefulShellBranch(routes: [GoRoute(path: '/teacher/reflection', builder: (context, state) => const TeacherReflectionScreen())]),
      StatefulShellBranch(routes: [GoRoute(path: '/teacher/parliament', builder: (context, state) => const TeacherParliamentScreen())]),
    ];
