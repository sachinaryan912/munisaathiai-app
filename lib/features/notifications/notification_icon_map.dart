import 'package:flutter/material.dart';
import '../../core/utils/icon_map.dart';

/// Backend sends lucide-react icon names (e.g. "MessageSquareText") as a
/// plain string — delegate to the shared icon-name map used across the app.
IconData notificationIcon(String name) => lucideByName(name);
