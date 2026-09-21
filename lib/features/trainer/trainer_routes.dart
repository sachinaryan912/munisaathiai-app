import 'package:go_router/go_router.dart';
import 'alerts_screen.dart';
import 'dashboard_screen.dart';
import 'reports_screen.dart';
import 'schools_screen.dart';
import 'teachers_screen.dart';
import 'training_screen.dart';
import '../shell/app_shell.dart';
import '../video_gallery/video_gallery_screen.dart';

/// One branch per `kNavByRole['TRAINER']` entry, in the same order, so tab index N always
/// corresponds to nav item N - reorder the two together or the tabs open the wrong screens.
List<StatefulShellBranch> trainerBranches() => [
      StatefulShellBranch(routes: [GoRoute(path: '/trainer', builder: (context, state) => const TrainerDashboardScreen())]),
      StatefulShellBranch(routes: [GoRoute(path: '/trainer/schools', builder: (context, state) => const TrainerSchoolsScreen())]),
      StatefulShellBranch(routes: [GoRoute(path: '/trainer/teachers', builder: (context, state) => const TrainerTeachersScreen())]),
      StatefulShellBranch(routes: [GoRoute(path: '/trainer/videos', builder: (context, state) => const AppShell(title: 'Video Gallery', showAiFab: false, body: VideoGalleryScreen()))]),
      StatefulShellBranch(routes: [GoRoute(path: '/trainer/reports', builder: (context, state) => const TrainerReportsScreen())]),
      StatefulShellBranch(routes: [GoRoute(path: '/trainer/alerts', builder: (context, state) => const TrainerAlertsScreen())]),
      StatefulShellBranch(routes: [GoRoute(path: '/trainer/training', builder: (context, state) => const TrainerTrainingScreen())]),
    ];
