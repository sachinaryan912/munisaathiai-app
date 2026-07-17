import 'package:go_router/go_router.dart';
import 'assignments_screen.dart';
import 'buddy_screen.dart';
import 'dashboard_screen.dart';
import 'feedback_screen.dart';
import 'parliament_screen.dart';
import 'peer_teaching_screen.dart';
import 'progress_screen.dart';
import 'self_study_screen.dart';
import '../ai_chat/ai_chat_screen.dart';
import '../shell/app_shell.dart';

/// One branch per `kNavByRole['STUDENT']` entry, in the same order, so tab
/// index N always corresponds to nav item N.
List<StatefulShellBranch> studentBranches() => [
      StatefulShellBranch(routes: [GoRoute(path: '/student', builder: (context, state) => const StudentDashboardScreen())]),
      StatefulShellBranch(routes: [GoRoute(path: '/student/progress', builder: (context, state) => const StudentProgressScreen())]),
      StatefulShellBranch(routes: [GoRoute(path: '/student/assignments', builder: (context, state) => const StudentAssignmentsScreen())]),
      StatefulShellBranch(routes: [GoRoute(path: '/student/ai', builder: (context, state) => const AppShell(title: 'Vidya AI', showAiFab: false, body: AiChatBody()))]),
      StatefulShellBranch(routes: [GoRoute(path: '/student/buddy', builder: (context, state) => const StudentBuddyScreen())]),
      StatefulShellBranch(routes: [GoRoute(path: '/student/study', builder: (context, state) => const StudentSelfStudyScreen())]),
      StatefulShellBranch(routes: [GoRoute(path: '/student/peer-teaching', builder: (context, state) => const StudentPeerTeachingScreen())]),
      StatefulShellBranch(routes: [GoRoute(path: '/student/feedback', builder: (context, state) => const StudentFeedbackScreen())]),
      StatefulShellBranch(routes: [GoRoute(path: '/student/parliament', builder: (context, state) => const StudentParliamentScreen())]),
    ];
