import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:provider/provider.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/app_text_field.dart';
import '../../core/widgets/async_screen.dart';
import '../../core/widgets/empty_view.dart';
import '../../core/widgets/gradient_button.dart';
import '../../core/widgets/section_card.dart';
import '../../core/widgets/video_fullscreen_scope.dart';
import '../auth/data/auth_provider.dart';
import 'video_repository.dart';

const _methodologies = [
  'GRS', 'Buddy System', 'UPLC', 'HADS', 'Child Parliament', 'Growth Habits',
  'Ghar Ek Pathshala', 'Am I Able', 'Situation Creation', 'Bharat Bodh',
  'Vedic Math', 'English Language (LLT)',
];

/// Training Management's "video learning resources" — reused as a tab/section
/// by both Trainer and Management, and viewable read-only by any role.
class VideoResourcesScreen extends StatelessWidget {
  const VideoResourcesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final repo = VideoRepository();
    return AsyncScreen<List<Map<String, dynamic>>>(
      loader: () => repo.getVideos(),
      builder: (context, videos, refresh) => _Body(videos: videos, repo: repo, refresh: refresh),
    );
  }
}

class _Body extends StatefulWidget {
  final List<Map<String, dynamic>> videos;
  final VideoRepository repo;
  final Future<void> Function() refresh;
  const _Body({required this.videos, required this.repo, required this.refresh});

  @override
  State<_Body> createState() => _BodyState();
}

class _BodyState extends State<_Body> {
  Future<void> _openAdd() async {
    final formKey = GlobalKey<FormState>();
    var submitted = false;
    final titleCtrl = TextEditingController();
    final urlCtrl = TextEditingController();
    String? methodology;
    var submitting = false;
    String? error;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return StatefulBuilder(builder: (sheetContext, setSheetState) {
          final s = sheetContext.surface;
          return Padding(
            padding: EdgeInsets.only(bottom: MediaQuery.of(sheetContext).viewInsets.bottom),
            child: Container(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 28),
              decoration: BoxDecoration(color: s.card, borderRadius: const BorderRadius.vertical(top: Radius.circular(28))),
              constraints: BoxConstraints(maxHeight: MediaQuery.of(sheetContext).size.height * 0.85),
              child: Form(
                key: formKey,
                autovalidateMode: submitted ? AutovalidateMode.onUserInteraction : AutovalidateMode.disabled,
                child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Container(width: 40, height: 4, margin: const EdgeInsets.only(bottom: 14), alignment: Alignment.center, decoration: BoxDecoration(color: s.border, borderRadius: BorderRadius.circular(99))),
                    Text('Add Training Video', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: s.textPrimary)),
                    const SizedBox(height: 16),
                    AppTextField(
                      label: 'Title',
                      isRequired: true,
                      controller: titleCtrl,
                      validator: (v) => (v == null || v.trim().isEmpty) ? 'Title is required' : null,
                    ),
                    const SizedBox(height: 12),
                    AppTextField(
                      label: 'YouTube URL',
                      isRequired: true,
                      controller: urlCtrl,
                      hint: 'https://youtu.be/...',
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) return 'YouTube URL is required';
                        if (YoutubePlayer.convertUrlToId(v.trim()) == null) return 'Please enter a valid YouTube URL';
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    Text('Methodology (optional)', style: Theme.of(sheetContext).inputDecorationTheme.labelStyle),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _methodologies.map((m) {
                        final active = m == methodology;
                        return ChoiceChip(
                          label: Text(m, style: const TextStyle(fontSize: 11)),
                          selected: active,
                          onSelected: (_) => setSheetState(() => methodology = active ? null : m),
                          selectedColor: AppColors.saffron500,
                          labelStyle: TextStyle(color: active ? Colors.white : s.textSecondary, fontWeight: FontWeight.w700),
                          backgroundColor: s.border.withValues(alpha: 0.4),
                          side: BorderSide.none,
                        );
                      }).toList(),
                    ),
                    if (error != null) ...[const SizedBox(height: 10), Text(error!, style: const TextStyle(color: AppColors.danger, fontSize: 12))],
                    const SizedBox(height: 18),
                    GradientButton(
                      label: 'Add Video',
                      loading: submitting,
                      onPressed: () async {
                        setSheetState(() => submitted = true);
                        if (!formKey.currentState!.validate()) return;
                        setSheetState(() {
                          submitting = true;
                          error = null;
                        });
                        try {
                          await widget.repo.addVideo(title: titleCtrl.text.trim(), youtubeUrl: urlCtrl.text.trim(), methodology: methodology);
                          if (sheetContext.mounted) Navigator.pop(sheetContext);
                          await widget.refresh();
                        } catch (e) {
                          setSheetState(() {
                            submitting = false;
                            error = e.toString().replaceFirst('ApiException: ', '');
                          });
                        }
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
        });
      },
    );
  }

  void _play(Map<String, dynamic> video) {
    final videoId = YoutubePlayer.convertUrlToId(video['youtubeUrl'] as String);
    if (videoId == null) return;
    // A full page rather than a dialog (a dialog can't take over the screen), on the root
    // navigator so it covers RootTabShell's bottom nav bar instead of opening inside it.
    Navigator.of(context, rootNavigator: true).push(MaterialPageRoute(builder: (_) => _VideoPlayerPage(videoId: videoId)));
  }

  Future<void> _delete(int id) async {
    try {
      await widget.repo.deleteVideo(id);
      await widget.refresh();
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString().replaceFirst('ApiException: ', ''))));
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = context.surface;
    final dark = Theme.of(context).brightness == Brightness.dark;
    final role = context.watch<AuthProvider>().user?.role;
    final userId = context.watch<AuthProvider>().user?.id;
    final canAdd = role == 'TRAINER' || role == 'MANAGEMENT';

    return Stack(
      children: [
        widget.videos.isEmpty
            ? ListView(children: const [SizedBox(height: 120), EmptyView(title: 'No training videos yet', subtitle: 'Trainers and Management can add YouTube links here.', icon: HugeIcons.strokeRoundedTv01)])
            : ListView.builder(
                padding: EdgeInsets.fromLTRB(16, 16, 16, canAdd ? 100 : 24),
                itemCount: widget.videos.length,
                itemBuilder: (context, i) {
                  final v = widget.videos[i];
                  final canDelete = role == 'MANAGEMENT' || (canAdd && v['addedById'] == userId);
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: SectionCard(
                      onTap: () => _play(v),
                      child: Row(
                        children: [
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: dark ? AppColors.saffron500.withValues(alpha: 0.18) : AppColors.saffron50,
                              borderRadius: BorderRadius.circular(13),
                            ),
                            child: Center(
                              child: HugeIcon(
                                icon: HugeIcons.strokeRoundedPlay,
                                size: 18,
                                color: dark ? AppColors.saffron400 : AppColors.saffron600,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(v['title'] as String, style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13.5, color: s.textPrimary)),
                                const SizedBox(height: 2),
                                Text('${v['methodology'] ?? 'General'} · added by ${v['addedByName']}', style: TextStyle(fontSize: 11, color: s.textMuted)),
                              ],
                            ),
                          ),
                          if (canDelete)
                            IconButton(icon: HugeIcon(icon: HugeIcons.strokeRoundedDelete02, size: 16, color: s.textMuted), onPressed: () => _delete(v['id'] as int)),
                        ],
                      ),
                    ),
                  );
                },
              ),
        if (canAdd)
          Positioned(right: 16, bottom: 16, child: FloatingActionButton(heroTag: 'add_video', backgroundColor: AppColors.saffron500, onPressed: _openAdd, child: const HugeIcon(icon: HugeIcons.strokeRoundedAdd01, color: Colors.white))),
      ],
    );
  }
}

/// Owns the [YoutubePlayerController] itself (rather than building one inline in a route
/// builder) so it has a dispose() hook — otherwise the controller and its underlying WebView
/// outlive the page once it's dismissed, leaving the video (and its audio) still playing in
/// the background.
///
/// The app is portrait-only; the one exception is this player's fullscreen mode, which
/// YoutubePlayerBuilder switches to landscape and back.
class _VideoPlayerPage extends StatefulWidget {
  final String videoId;
  const _VideoPlayerPage({required this.videoId});

  @override
  State<_VideoPlayerPage> createState() => _VideoPlayerPageState();
}

class _VideoPlayerPageState extends State<_VideoPlayerPage> {
  late final YoutubePlayerController _controller = YoutubePlayerController(
    initialVideoId: widget.videoId,
    flags: const YoutubePlayerFlags(autoPlay: true),
  );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return VideoFullscreenScope(
      child: Material(
        color: Colors.black,
        child: YoutubePlayerBuilder(
          player: YoutubePlayer(controller: _controller),
          builder: (context, player) => Scaffold(
            backgroundColor: Colors.black,
            appBar: AppBar(backgroundColor: Colors.black, foregroundColor: Colors.white, elevation: 0),
            body: Center(child: player),
          ),
        ),
      ),
    );
  }
}
