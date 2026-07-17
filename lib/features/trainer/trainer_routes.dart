import 'package:go_router/go_router.dart';
import 'alerts_screen.dart';
import 'dashboard_screen.dart';
import 'reports_screen.dart';
import 'schools_screen.dart';
import 'teachers_screen.dart';
import 'training_screen.dart';

List<StatefulShellBranch> trainerBranches() => [
      StatefulShellBranch(routes: [GoRoute(path: '/trainer', builder: (context, state) => const TrainerDashboardScreen())]),
      StatefulShellBranch(routes: [GoRoute(path: '/trainer/schools', builder: (context, state) => const TrainerSchoolsScreen())]),
      StatefulShellBranch(routes: [GoRoute(path: '/trainer/teachers', builder: (context, state) => const TrainerTeachersScreen())]),
      StatefulShellBranch(routes: [GoRoute(path: '/trainer/training', builder: (context, state) => const TrainerTrainingScreen())]),
      StatefulShellBranch(routes: [GoRoute(path: '/trainer/reports', builder: (context, state) => const TrainerReportsScreen())]),
      StatefulShellBranch(routes: [GoRoute(path: '/trainer/alerts', builder: (context, state) => const TrainerAlertsScreen())]),
    ];
