import 'package:go_router/go_router.dart';
import 'activities_screen.dart';
import 'dashboard_screen.dart';
import 'home_learning_screen.dart';
import 'progress_screen.dart';

List<StatefulShellBranch> parentBranches() => [
      StatefulShellBranch(routes: [GoRoute(path: '/parent', builder: (context, state) => const ParentDashboardScreen())]),
      StatefulShellBranch(routes: [GoRoute(path: '/parent/progress', builder: (context, state) => const ParentProgressScreen())]),
      StatefulShellBranch(routes: [GoRoute(path: '/parent/home-learning', builder: (context, state) => const ParentHomeLearningScreen())]),
      StatefulShellBranch(routes: [GoRoute(path: '/parent/activities', builder: (context, state) => const ParentActivitiesScreen())]),
    ];
