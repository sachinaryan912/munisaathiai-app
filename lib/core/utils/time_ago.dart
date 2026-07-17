import 'package:intl/intl.dart';

String timeAgo(DateTime? dt) {
  if (dt == null) return '';
  final diff = DateTime.now().difference(dt);
  final mins = diff.inMinutes;
  if (mins < 1) return 'just now';
  if (mins < 60) return '${mins}m ago';
  final hours = diff.inHours;
  if (hours < 24) return '${hours}h ago';
  final days = diff.inDays;
  if (days < 7) return '${days}d ago';
  return DateFormat('d MMM').format(dt);
}
