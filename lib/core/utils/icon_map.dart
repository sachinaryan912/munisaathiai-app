import 'package:hugeicons/hugeicons.dart';

/// Maps icon name strings sent by the backend (badges, stat
/// cards, recent-activity feeds, notifications) to HugeIcons
/// equivalents. Falls back to a generic circle icon for anything unmapped.
dynamic lucideByName(String? name) {
  switch (name) {
    case 'Users':
      return HugeIcons.strokeRoundedUserGroup;
    case 'BookOpen':
      return HugeIcons.strokeRoundedBookOpen01;
    case 'TrendingUp':
      return HugeIcons.strokeRoundedTradeUp;
    case 'Star':
      return HugeIcons.strokeRoundedStar;
    case 'FileCheck':
      return HugeIcons.strokeRoundedFileCheck;
    case 'GraduationCap':
      return HugeIcons.strokeRoundedGraduationScroll;
    case 'Heart':
      return HugeIcons.strokeRoundedFavourite;
    case 'MessageSquareText':
      return HugeIcons.strokeRoundedComment01;
    case 'CalendarCheck':
      return HugeIcons.strokeRoundedCalendarCheck01;
    case 'AlertTriangle':
      return HugeIcons.strokeRoundedAlertCircle;
    case 'CheckCircle':
      return HugeIcons.strokeRoundedCheckmarkCircle02;
    case 'School':
      return HugeIcons.strokeRoundedSchool;
    case 'ClipboardList':
      return HugeIcons.strokeRoundedClipboardCheck;
    case 'BarChart3':
      return HugeIcons.strokeRoundedAnalytics01;
    case 'Sparkles':
      return HugeIcons.strokeRoundedSparkles;
    case 'Bell':
      return HugeIcons.strokeRoundedNotification02;
    case 'Award':
      return HugeIcons.strokeRoundedAward01;
    case 'Download':
      return HugeIcons.strokeRoundedDownload01;
    case 'Eye':
      return HugeIcons.strokeRoundedView;
    case 'Zap':
      return HugeIcons.strokeRoundedEnergy;
    default:
      return HugeIcons.strokeRoundedCircle;
  }
}
