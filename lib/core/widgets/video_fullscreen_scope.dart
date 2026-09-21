import 'package:flutter/material.dart';
import '../theme/system_ui.dart';

/// Wraps a page that hosts a YoutubePlayerBuilder, so the app's portrait-only chrome always
/// comes back after the video's fullscreen (landscape) mode.
///
/// The player already asks for portrait itself when fullscreen is toggled off, so this only
/// handles what it doesn't: re-showing the system bars, and un-sticking the app if the page
/// is closed while still in landscape. It deliberately keys off the screen's real orientation
/// rather than YoutubePlayerBuilder's onExitFullScreen — that callback also fires for any
/// screen-metrics change while the phone is still portrait, including the moment fullscreen
/// *starts*, so forcing portrait from it bounced the video straight back out of landscape.
class VideoFullscreenScope extends StatefulWidget {
  final Widget child;
  const VideoFullscreenScope({super.key, required this.child});

  @override
  State<VideoFullscreenScope> createState() => _VideoFullscreenScopeState();
}

class _VideoFullscreenScopeState extends State<VideoFullscreenScope> {
  bool _wasLandscape = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final landscape = MediaQuery.orientationOf(context) == Orientation.landscape;
    if (_wasLandscape && !landscape) {
      SystemUi.enableEdgeToEdge();
    }
    _wasLandscape = landscape;
  }

  @override
  void dispose() {
    SystemUi.restorePortrait();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
