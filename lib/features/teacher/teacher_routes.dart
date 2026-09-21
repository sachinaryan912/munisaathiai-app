import 'package:go_router/go_router.dart';
import 'class_screen.dart';
import 'dashboard_screen.dart';
import 'evidence_screen.dart';
import 'lesson_plans_screen.dart';
import 'methodology_screen.dart';
import 'parliament_screen.dart';
import 'reflection_screen.dart';
import '../shell/app_shell.dart';
import '../video_gallery/video_gallery_screen.dart';

/// One branch per `kNavByRole['TEACHER']` entry, in the same order, so tab index N always
/// corresponds to nav item N - reorder the two together or the tabs open the wrong screens.
List<StatefulShellBranch> teacherBranches() => [
      StatefulShellBranch(routes: [GoRoute(path: '/teacher', builder: (context, state) => const TeacherDashboardScreen())]),
      StatefulShellBranch(routes: [GoRoute(path: '/teacher/class', builder: (context, state) => const TeacherClassScreen())]),
      StatefulShellBranch(routes: [GoRoute(path: '/teacher/methodology', builder: (context, state) => const TeacherMethodologyScreen())]),
      StatefulShellBranch(routes: [GoRoute(path: '/teacher/videos', builder: (context, state) => const AppShell(title: 'Video Gallery', showAiFab: false, body: VideoGalleryScreen()))]),
      StatefulShellBranch(routes: [GoRoute(path: '/teacher/lesson', builder: (context, state) => const TeacherLessonPlansScreen())]),
      StatefulShellBranch(routes: [GoRoute(path: '/teacher/reflection', builder: (context, state) => const TeacherReflectionScreen())]),
      StatefulShellBranch(routes: [GoRoute(path: '/teacher/parliament', builder: (context, state) => const TeacherParliamentScreen())]),
      StatefulShellBranch(routes: [GoRoute(path: '/teacher/evidence', builder: (context, state) => const TeacherEvidenceScreen())]),
    ];
