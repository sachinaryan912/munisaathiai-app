import '../../core/utils/icon_map.dart';

/// Backend sends icon names (e.g. "MessageSquareText") as a
/// plain string — delegate to the shared icon-name map used across the app.
dynamic notificationIcon(String name) => lucideByName(name);
