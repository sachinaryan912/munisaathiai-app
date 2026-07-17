import 'package:go_router/go_router.dart';
import '../../features/management/management_routes.dart';
import '../../features/parent/parent_routes.dart';
import '../../features/principal/principal_routes.dart';
import '../../features/shell/root_tab_shell.dart';
import '../../features/student/student_routes.dart';
import '../../features/teacher/teacher_routes.dart';
import '../../features/trainer/trainer_routes.dart';
import '../nav/nav_items.dart';

/// One `StatefulShellRoute.indexedStack` per role — each branch's Navigator
/// (and therefore its page state, scroll position, in-flight requests) stays
/// alive underneath, so tapping between tabs never rebuilds a page from
/// scratch the way separate top-level GoRoutes did.
StatefulShellRoute _roleShellRoute(String role, List<StatefulShellBranch> branches) {
  return StatefulShellRoute.indexedStack(
    builder: (context, state, navigationShell) => RootTabShell(navigationShell: navigationShell, items: kNavByRole[role]!),
    branches: branches,
  );
}

List<RouteBase> buildRoleRoutes() => [
      _roleShellRoute('STUDENT', studentBranches()),
      _roleShellRoute('PARENT', parentBranches()),
      _roleShellRoute('TEACHER', teacherBranches()),
      _roleShellRoute('PRINCIPAL', principalBranches()),
      _roleShellRoute('TRAINER', trainerBranches()),
      _roleShellRoute('MANAGEMENT', managementBranches()),
    ];
