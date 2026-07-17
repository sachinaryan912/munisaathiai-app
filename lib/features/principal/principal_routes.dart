import 'package:go_router/go_router.dart';
import 'attendance_report_screen.dart';
import 'classes_screen.dart';
import 'dashboard_screen.dart';
import 'methodology_screen.dart';
import 'observations_screen.dart';
import 'parliament_screen.dart';
import 'reports_screen.dart';
import 'teachers_screen.dart';

List<StatefulShellBranch> principalBranches() => [
      StatefulShellBranch(routes: [GoRoute(path: '/principal', builder: (context, state) => const PrincipalDashboardScreen())]),
      StatefulShellBranch(routes: [GoRoute(path: '/principal/teachers', builder: (context, state) => const PrincipalTeachersScreen())]),
      StatefulShellBranch(routes: [GoRoute(path: '/principal/classes', builder: (context, state) => const PrincipalClassesScreen())]),
      StatefulShellBranch(routes: [GoRoute(path: '/principal/observations', builder: (context, state) => const PrincipalObservationsScreen())]),
      StatefulShellBranch(routes: [GoRoute(path: '/principal/methodology', builder: (context, state) => const PrincipalMethodologyScreen())]),
      StatefulShellBranch(routes: [GoRoute(path: '/principal/reports', builder: (context, state) => const PrincipalReportsScreen())]),
      StatefulShellBranch(routes: [GoRoute(path: '/principal/attendance', builder: (context, state) => const PrincipalAttendanceReportScreen())]),
      StatefulShellBranch(routes: [GoRoute(path: '/principal/parliament', builder: (context, state) => const PrincipalParliamentScreen())]),
    ];
