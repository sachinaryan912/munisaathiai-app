import 'package:go_router/go_router.dart';
import 'alerts_screen.dart';
import 'dashboard_screen.dart';
import 'knowledge_notes_screen.dart';
import 'mii_screen.dart';
import 'reports_screen.dart';
import 'school_detail_screen.dart';
import 'schools_screen.dart';
import 'trainers_screen.dart';
import 'training_screen.dart';
import 'users_screen.dart';
import '../shell/app_shell.dart';
import '../video_gallery/video_gallery_screen.dart';

/// One branch per `kNavByRole['MANAGEMENT']` entry, in the same order, so tab index N always
/// corresponds to nav item N — reorder the two together or the tabs open the wrong screens.
List<StatefulShellBranch> managementBranches() => [
      StatefulShellBranch(routes: [GoRoute(path: '/management', builder: (context, state) => const ManagementDashboardScreen())]),
      StatefulShellBranch(routes: [
        GoRoute(
          path: '/management/schools',
          builder: (context, state) => const ManagementSchoolsScreen(),
          routes: [
            GoRoute(
              path: ':id',
              builder: (context, state) => SchoolDetailScreen(schoolId: int.parse(state.pathParameters['id']!)),
            ),
          ],
        ),
      ]),
      StatefulShellBranch(routes: [GoRoute(path: '/management/mii', builder: (context, state) => const ManagementMiiScreen())]),
      StatefulShellBranch(routes: [GoRoute(path: '/management/videos', builder: (context, state) => const AppShell(title: 'Video Gallery', showAiFab: false, body: VideoGalleryScreen()))]),
      StatefulShellBranch(routes: [GoRoute(path: '/management/trainers', builder: (context, state) => const ManagementTrainersScreen())]),
      StatefulShellBranch(routes: [GoRoute(path: '/management/users', builder: (context, state) => const ManagementUsersScreen())]),
      StatefulShellBranch(routes: [GoRoute(path: '/management/training', builder: (context, state) => const ManagementTrainingScreen())]),
      StatefulShellBranch(routes: [GoRoute(path: '/management/train-ai', builder: (context, state) => const KnowledgeNotesScreen())]),
      StatefulShellBranch(routes: [GoRoute(path: '/management/alerts', builder: (context, state) => const ManagementAlertsScreen())]),
      StatefulShellBranch(routes: [GoRoute(path: '/management/reports', builder: (context, state) => const ManagementReportsScreen())]),
    ];
