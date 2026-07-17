import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// Maps lucide-react icon name strings sent by the backend (badges, stat
/// cards, recent-activity feeds, notifications) to lucide_icons_flutter
/// equivalents. Falls back to a generic dot icon for anything unmapped.
IconData lucideByName(String? name) {
  switch (name) {
    case 'Users':
      return LucideIcons.users;
    case 'BookOpen':
      return LucideIcons.bookOpen;
    case 'TrendingUp':
      return LucideIcons.trendingUp;
    case 'Star':
      return LucideIcons.star;
    case 'FileCheck':
      return LucideIcons.fileCheck;
    case 'GraduationCap':
      return LucideIcons.graduationCap;
    case 'Heart':
      return LucideIcons.heart;
    case 'MessageSquareText':
      return LucideIcons.messageSquareText;
    case 'CalendarCheck':
      return LucideIcons.calendarCheck;
    case 'AlertTriangle':
      return LucideIcons.triangleAlert;
    case 'CheckCircle':
      return LucideIcons.circleCheck;
    case 'School':
      return LucideIcons.school;
    case 'ClipboardList':
      return LucideIcons.clipboardList;
    case 'BarChart3':
      return LucideIcons.barChart3;
    case 'Sparkles':
      return LucideIcons.sparkles;
    case 'Bell':
      return LucideIcons.bell;
    case 'Award':
      return LucideIcons.award;
    case 'Download':
      return LucideIcons.download;
    case 'Eye':
      return LucideIcons.eye;
    case 'Zap':
      return LucideIcons.zap;
    default:
      return LucideIcons.circle;
  }
}
