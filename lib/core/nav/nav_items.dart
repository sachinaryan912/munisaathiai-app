import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class NavItem {
  final String label;
  final String path;
  final IconData icon;
  final bool aiHighlight;

  const NavItem({required this.label, required this.path, required this.icon, this.aiHighlight = false});
}

/// Role-scoped navigation destinations. The first 4 render in the bottom bar;
/// the remainder surface in the "More" sheet. Paths are relative to the
/// role's root, e.g. "schools" -> "/management/schools".
const Map<String, List<NavItem>> kNavByRole = {
  'MANAGEMENT': [
    NavItem(label: 'Dashboard', path: '', icon: LucideIcons.layoutDashboard),
    NavItem(label: 'Schools', path: 'schools', icon: LucideIcons.school),
    NavItem(label: 'MII Scores', path: 'mii', icon: LucideIcons.clipboardList),
    NavItem(label: 'Reports', path: 'reports', icon: LucideIcons.barChart3),
    NavItem(label: 'Trainers', path: 'trainers', icon: LucideIcons.users),
    NavItem(label: 'Users', path: 'users', icon: LucideIcons.userCog),
    NavItem(label: 'Training', path: 'training', icon: LucideIcons.bookOpen),
    NavItem(label: 'Alerts', path: 'alerts', icon: LucideIcons.bell),
  ],
  'TRAINER': [
    NavItem(label: 'Dashboard', path: '', icon: LucideIcons.layoutDashboard),
    NavItem(label: 'My Schools', path: 'schools', icon: LucideIcons.school),
    NavItem(label: 'Teachers', path: 'teachers', icon: LucideIcons.users),
    NavItem(label: 'Training', path: 'training', icon: LucideIcons.bookOpen),
    NavItem(label: 'Reports', path: 'reports', icon: LucideIcons.barChart3),
    NavItem(label: 'Alerts', path: 'alerts', icon: LucideIcons.bell),
  ],
  'PRINCIPAL': [
    NavItem(label: 'Dashboard', path: '', icon: LucideIcons.layoutDashboard),
    NavItem(label: 'Teachers', path: 'teachers', icon: LucideIcons.users),
    NavItem(label: 'Classes', path: 'classes', icon: LucideIcons.school),
    NavItem(label: 'Observations', path: 'observations', icon: LucideIcons.fileCheck),
    NavItem(label: 'Methodology', path: 'methodology', icon: LucideIcons.clipboardList),
    NavItem(label: 'Reports', path: 'reports', icon: LucideIcons.barChart3),
    NavItem(label: 'Attendance', path: 'attendance', icon: LucideIcons.calendarCheck),
    NavItem(label: 'Parliament', path: 'parliament', icon: LucideIcons.landmark),
  ],
  'TEACHER': [
    NavItem(label: 'Dashboard', path: '', icon: LucideIcons.layoutDashboard),
    NavItem(label: 'My Class', path: 'class', icon: LucideIcons.school),
    NavItem(label: 'Methodology', path: 'methodology', icon: LucideIcons.clipboardList),
    NavItem(label: 'Evidence', path: 'evidence', icon: LucideIcons.bookOpen),
    NavItem(label: 'Lesson Plans', path: 'lesson', icon: LucideIcons.notebookPen),
    NavItem(label: 'Reflection', path: 'reflection', icon: LucideIcons.notebookPen),
    NavItem(label: 'Parliament', path: 'parliament', icon: LucideIcons.landmark),
  ],
  'STUDENT': [
    NavItem(label: 'Dashboard', path: '', icon: LucideIcons.layoutDashboard),
    NavItem(label: 'Progress', path: 'progress', icon: LucideIcons.clipboardList),
    NavItem(label: 'Assignments', path: 'assignments', icon: LucideIcons.fileCheck),
    NavItem(label: 'Vidya AI', path: 'ai', icon: LucideIcons.sparkles, aiHighlight: true),
    NavItem(label: 'My Buddy', path: 'buddy', icon: LucideIcons.users),
    NavItem(label: 'Self Study', path: 'study', icon: LucideIcons.bookOpen),
    NavItem(label: 'Peer Teaching', path: 'peer-teaching', icon: LucideIcons.graduationCap),
    NavItem(label: 'Feedback', path: 'feedback', icon: LucideIcons.heart),
    NavItem(label: 'Parliament', path: 'parliament', icon: LucideIcons.landmark),
  ],
  'PARENT': [
    NavItem(label: 'Dashboard', path: '', icon: LucideIcons.layoutDashboard),
    NavItem(label: "Child's Progress", path: 'progress', icon: LucideIcons.barChart3),
    NavItem(label: 'Ghar Ek Pathshala', path: 'home-learning', icon: LucideIcons.bookOpen),
    NavItem(label: 'Activities', path: 'activities', icon: LucideIcons.clipboardList),
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
