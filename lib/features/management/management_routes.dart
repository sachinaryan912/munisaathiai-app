import 'package:go_router/go_router.dart';
import 'alerts_screen.dart';
import 'dashboard_screen.dart';
import 'mii_screen.dart';
import 'reports_screen.dart';
import 'school_detail_screen.dart';
import 'schools_screen.dart';
import 'trainers_screen.dart';
import 'training_screen.dart';
import 'users_screen.dart';

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
      StatefulShellBranch(routes: [GoRoute(path: '/management/reports', builder: (context, state) => const ManagementReportsScreen())]),
      StatefulShellBranch(routes: [GoRoute(path: '/management/trainers', builder: (context, state) => const ManagementTrainersScreen())]),
      StatefulShellBranch(routes: [GoRoute(path: '/management/users', builder: (context, state) => const ManagementUsersScreen())]),
      StatefulShellBranch(routes: [GoRoute(path: '/management/training', builder: (context, state) => const ManagementTrainingScreen())]),
      StatefulShellBranch(routes: [GoRoute(path: '/management/alerts', builder: (context, state) => const ManagementAlertsScreen())]),
    ];
