import 'package:hugeicons/hugeicons.dart';

class NavItem {
  final String label;
  final String path;
  final dynamic icon;
  final bool aiHighlight;

  const NavItem({required this.label, required this.path, required this.icon, this.aiHighlight = false});
}

/// Role-scoped navigation destinations. The first 4 render in the bottom bar;
/// the remainder surface in the "More" sheet. Paths are relative to the
/// role's root, e.g. "schools" -> "/management/schools".
const Map<String, List<NavItem>> kNavByRole = {
  'MANAGEMENT': [
    NavItem(label: 'Dashboard', path: '', icon: HugeIcons.strokeRoundedDashboardSquare01),
    NavItem(label: 'Schools', path: 'schools', icon: HugeIcons.strokeRoundedSchool),
    NavItem(label: 'MII Scores', path: 'mii', icon: HugeIcons.strokeRoundedTask01),
    NavItem(label: 'Video Gallery', path: 'videos', icon: HugeIcons.strokeRoundedVideo01),
    NavItem(label: 'Trainers', path: 'trainers', icon: HugeIcons.strokeRoundedUserGroup),
    NavItem(label: 'Users', path: 'users', icon: HugeIcons.strokeRoundedUserSettings01),
    NavItem(label: 'Training', path: 'training', icon: HugeIcons.strokeRoundedBookOpen01),
    NavItem(label: 'Train Vidya AI', path: 'train-ai', icon: HugeIcons.strokeRoundedAiBrain01),
    NavItem(label: 'Alerts', path: 'alerts', icon: HugeIcons.strokeRoundedNotification03),
    NavItem(label: 'Reports', path: 'reports', icon: HugeIcons.strokeRoundedBarChart),
  ],
  'TRAINER': [
    NavItem(label: 'Dashboard', path: '', icon: HugeIcons.strokeRoundedDashboardSquare01),
    NavItem(label: 'My Schools', path: 'schools', icon: HugeIcons.strokeRoundedSchool),
    NavItem(label: 'Teachers', path: 'teachers', icon: HugeIcons.strokeRoundedUserGroup),
    NavItem(label: 'Video Gallery', path: 'videos', icon: HugeIcons.strokeRoundedVideo01),
    NavItem(label: 'Reports', path: 'reports', icon: HugeIcons.strokeRoundedBarChart),
    NavItem(label: 'Alerts', path: 'alerts', icon: HugeIcons.strokeRoundedNotification03),
    NavItem(label: 'Training', path: 'training', icon: HugeIcons.strokeRoundedBookOpen01),
  ],
  'PRINCIPAL': [
    NavItem(label: 'Dashboard', path: '', icon: HugeIcons.strokeRoundedDashboardSquare01),
    NavItem(label: 'Teachers', path: 'teachers', icon: HugeIcons.strokeRoundedUserGroup),
    NavItem(label: 'Classes', path: 'classes', icon: HugeIcons.strokeRoundedSchool),
    NavItem(label: 'Video Gallery', path: 'videos', icon: HugeIcons.strokeRoundedVideo01),
    NavItem(label: 'Methodology', path: 'methodology', icon: HugeIcons.strokeRoundedTask01),
    NavItem(label: 'Reports', path: 'reports', icon: HugeIcons.strokeRoundedBarChart),
    NavItem(label: 'Attendance', path: 'attendance', icon: HugeIcons.strokeRoundedCalendarCheck01),
    NavItem(label: 'Parliament', path: 'parliament', icon: HugeIcons.strokeRoundedBuilding01),
    NavItem(label: 'Observations', path: 'observations', icon: HugeIcons.strokeRoundedDocumentValidation),
  ],
  'TEACHER': [
    NavItem(label: 'Dashboard', path: '', icon: HugeIcons.strokeRoundedDashboardSquare01),
    NavItem(label: 'My Class', path: 'class', icon: HugeIcons.strokeRoundedSchool),
    NavItem(label: 'Methodology', path: 'methodology', icon: HugeIcons.strokeRoundedTask01),
    NavItem(label: 'Video Gallery', path: 'videos', icon: HugeIcons.strokeRoundedVideo01),
    NavItem(label: 'Lesson Plans', path: 'lesson', icon: HugeIcons.strokeRoundedNoteEdit),
    NavItem(label: 'Reflection', path: 'reflection', icon: HugeIcons.strokeRoundedNoteEdit),
    NavItem(label: 'Parliament', path: 'parliament', icon: HugeIcons.strokeRoundedBuilding01),
    NavItem(label: 'Evidence', path: 'evidence', icon: HugeIcons.strokeRoundedBookOpen01),
  ],
  'STUDENT': [
    NavItem(label: 'Dashboard', path: '', icon: HugeIcons.strokeRoundedDashboardSquare01),
    NavItem(label: 'Progress', path: 'progress', icon: HugeIcons.strokeRoundedTask01),
    NavItem(label: 'Video Gallery', path: 'videos', icon: HugeIcons.strokeRoundedVideo01),
    NavItem(label: 'Vidya AI', path: 'ai', icon: HugeIcons.strokeRoundedAiChat01, aiHighlight: true),
    NavItem(label: 'My Group', path: 'buddy', icon: HugeIcons.strokeRoundedUserGroup),
    NavItem(label: 'Self Study', path: 'study', icon: HugeIcons.strokeRoundedBookOpen01),
    NavItem(label: 'Peer Teaching', path: 'peer-teaching', icon: HugeIcons.strokeRoundedMortarboard01),
    NavItem(label: 'Feedback', path: 'feedback', icon: HugeIcons.strokeRoundedFavourite),
    NavItem(label: 'Parliament', path: 'parliament', icon: HugeIcons.strokeRoundedBuilding01),
    NavItem(label: 'Assignments', path: 'assignments', icon: HugeIcons.strokeRoundedDocumentValidation),
  ],
  'PARENT': [
    NavItem(label: 'Dashboard', path: '', icon: HugeIcons.strokeRoundedDashboardSquare01),
    NavItem(label: "Child's Progress", path: 'progress', icon: HugeIcons.strokeRoundedBarChart),
    NavItem(label: 'Ghar Ek Pathshala', path: 'home-learning', icon: HugeIcons.strokeRoundedBookOpen01),
    NavItem(label: 'Activities', path: 'activities', icon: HugeIcons.strokeRoundedTask01),
    NavItem(label: 'Video Gallery', path: 'videos', icon: HugeIcons.strokeRoundedVideo01),
  ],
};

const Map<String, String> kRoleLabels = {
  'MANAGEMENT': 'Management',
  'TRAINER': 'Trainer',
  'PRINCIPAL': 'Principal',
  'TEACHER': 'Teacher',
  'STUDENT': 'Student',
  'PARENT': 'Parent',
};

String roleBasePath(String role) => '/${role.toLowerCase()}';
