import 'dart:async';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:provider/provider.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/video_fullscreen_scope.dart';
import '../../core/widgets/app_text_field.dart';
import '../../core/widgets/async_screen.dart';
import '../../core/widgets/empty_view.dart';
import '../../core/widgets/gradient_button.dart';
import '../auth/data/auth_provider.dart';
import 'video_gallery_repository.dart';

const _methodologies = [
  'GRS', 'Buddy System', 'UPLC', 'HADS', 'Child Parliament', 'Growth Habits',
  'Ghar Ek Pathshala', 'Am I Able', 'Situation Creation', 'Bharat Bodh',
  'Vedic Math', 'English Language (LLT)',
];

/// The Video Gallery — deliberately separate from Training Management's video learning
/// resources (VideoResourceService/VideoResourceScreen): its own backend table, its own API.
/// Management picks an actual video file here; the untouched original goes straight to Cloud
/// Storage (Cloud Run's 32MiB request cap rules out sending it through our backend), and the
/// backend then pushes it to YouTube as unlisted. Every role can
/// browse and watch, filtered by methodology.
class VideoGalleryScreen extends StatelessWidget {
  const VideoGalleryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final repo = VideoGalleryRepository();
    return AsyncScreen<List<Map<String, dynamic>>>(
      loader: () => repo.getVideos(),
      builder: (context, videos, refresh) => _Body(videos: videos, repo: repo, refresh: refresh),
    );
  }
}

class _Body extends StatefulWidget {
  final List<Map<String, dynamic>> videos;
  final VideoGalleryRepository repo;
  final Future<void> Function() refresh;
  const _Body({required this.videos, required this.repo, required this.refresh});

  @override
  State<_Body> createState() => _BodyState();
}

class _BodyState extends State<_Body> {
  final Set<int> _analyzingIds = {};

  // A local copy of the list so it can be refreshed in the background while YouTube is still
  // processing a video — going through widget.refresh would swap the whole screen for a loading
  // spinner (and lose the scroll position) every few seconds.
  late List<Map<String, dynamic>> _videos = widget.videos;
  Timer? _poller;

  @override
  void initState() {
    super.initState();
    _syncPoller();
  }

  @override
  void didUpdateWidget(covariant _Body oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Only when the parent actually fetched a new list — a plain rebuild would otherwise
    // clobber a fresher background result with the older one it's still holding.
    if (!identical(oldWidget.videos, widget.videos)) {
      _videos = widget.videos;
      _syncPoller();
    }
  }

  @override
  void dispose() {
    _poller?.cancel();
    super.dispose();
  }

  bool get _anyBusy => _videos.any((v) => v['processingStatus'] == 'PROCESSING' || v['processingStatus'] == 'UPLOADING');
  bool get _anyQueued => _videos.any((v) => v['processingStatus'] == 'QUEUED');
  var _pollTick = 0;

  /// Polls only while something is still on its way, and stops as soon as nothing is. A video
  /// actively moving (uploading, or processing on YouTube) is checked every 15 seconds; one just
  /// waiting in the queue — possibly for hours, until YouTube's daily quota resets — only every
  /// minute.
  void _syncPoller() {
    if (_anyBusy || _anyQueued) {
      _poller ??= Timer.periodic(const Duration(seconds: 15), (_) {
        _pollTick++;
        if (_anyBusy || _pollTick % 4 == 0) _silentRefresh();
      });
    } else {
      _poller?.cancel();
      _poller = null;
    }
  }

  Future<void> _silentRefresh() async {
    try {
      final next = await widget.repo.getVideos();
      if (!mounted) return;
      setState(() => _videos = next);
      _syncPoller();
    } catch (_) {
      // A missed poll is harmless — the next one tries again.
    }
  }

  Future<void> _analyze(int id, {bool replace = false}) async {
    setState(() => _analyzingIds.add(id));
    try {
      await widget.repo.analyzeVideo(id, replace: replace);
      // A re-analysis is refreshed quietly: the video is already on screen, and going through
      // widget.refresh would blank the whole list behind a spinner.
      if (replace) {
        await _silentRefresh();
      } else {
        await widget.refresh();
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(replace ? "Re-analyzed — Vidya's memory of this video is updated." : "Analyzed — added to Vidya's knowledge base."),
        ));
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString().replaceFirst('ApiException: ', ''))));
    } finally {
      if (mounted) setState(() => _analyzingIds.remove(id));
    }
  }

  /// Re-analysis overwrites the existing AI analysis (and what Vidya remembers), so it always asks.
  Future<void> _reanalyze(int id) async {
    if (!await _confirmReanalyze(context) || !mounted) return;
    await _analyze(id, replace: true);
  }

  /// A small rounded button in the style of the list's AI chips.
  Widget _pill({required Widget leading, required String label, required VoidCallback? onTap}) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return InkWell(
      borderRadius: BorderRadius.circular(99),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: dark ? AppColors.saffron500.withValues(alpha: 0.18) : AppColors.saffron50,
          borderRadius: BorderRadius.circular(99),
          border: Border.all(
            color: dark ? AppColors.saffron500.withValues(alpha: 0.3) : AppColors.saffron200,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            leading,
            const SizedBox(width: 6),
            Text(label, style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w800, color: dark ? AppColors.saffron400 : AppColors.saffron600)),
          ],
        ),
      ),
    );
  }

  void _viewAnalysis(Map<String, dynamic> video) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        final s = sheetContext.surface;
        return Container(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 28),
          decoration: BoxDecoration(color: s.card, borderRadius: const BorderRadius.vertical(top: Radius.circular(28))),
          constraints: BoxConstraints(maxHeight: MediaQuery.of(sheetContext).size.height * 0.75),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(width: 40, height: 4, margin: const EdgeInsets.only(bottom: 14), alignment: Alignment.center, decoration: BoxDecoration(color: s.border, borderRadius: BorderRadius.circular(99))),
                Row(
                  children: [
                    const HugeIcon(icon: HugeIcons.strokeRoundedSparkles, size: 18, color: AppColors.saffron500),
                    const SizedBox(width: 8),
                    Expanded(child: Text('AI Analysis', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: s.textPrimary))),
                  ],
                ),
                const SizedBox(height: 4),
                Text("Already added to Vidya AI's knowledge base.", style: TextStyle(fontSize: 11.5, color: s.textMuted)),
                const SizedBox(height: 14),
                Text(video['aiAnalysis'] as String, style: TextStyle(fontSize: 13, color: s.textSecondary, height: 1.5)),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _openAdd() async {
    File? pickedFile;
    final titleCtrl = TextEditingController();
    final descriptionCtrl = TextEditingController();
    String? methodology;
    // Set once the file is safely in storage, so a failed hand-off to YouTube can be retried
    // without sending the whole video again.
    String? uploadedKey;
    var submitting = false;
    String? error;
    String? statusLabel;
    double? progress;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      isDismissible: false,
      enableDrag: false,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return StatefulBuilder(builder: (sheetContext, setSheetState) {
          final s = sheetContext.surface;
          // Back would dismiss the sheet mid-upload and leave the transfer running unseen.
          return PopScope(
            canPop: !submitting,
            child: Padding(
            padding: EdgeInsets.only(bottom: MediaQuery.of(sheetContext).viewInsets.bottom),
            child: Container(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 28),
              decoration: BoxDecoration(color: s.card, borderRadius: const BorderRadius.vertical(top: Radius.circular(28))),
              constraints: BoxConstraints(maxHeight: MediaQuery.of(sheetContext).size.height * 0.88),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Container(width: 40, height: 4, margin: const EdgeInsets.only(bottom: 14), alignment: Alignment.center, decoration: BoxDecoration(color: s.border, borderRadius: BorderRadius.circular(99))),
                    Text('Add Video', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: s.textPrimary)),
                    const SizedBox(height: 16),
                    AppTextField(label: 'Title', controller: titleCtrl, enabled: !submitting),
                    const SizedBox(height: 12),
                    AppTextField(label: 'Description (optional)', controller: descriptionCtrl, maxLines: 3, enabled: !submitting),
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
                          onSelected: submitting ? null : (_) => setSheetState(() => methodology = active ? null : m),
                          selectedColor: AppColors.saffron500,
                          labelStyle: TextStyle(color: active ? Colors.white : s.textSecondary, fontWeight: FontWeight.w700),
                          backgroundColor: s.border.withValues(alpha: 0.4),
                          side: BorderSide.none,
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 16),
                    InkWell(
                      borderRadius: BorderRadius.circular(16),
                      onTap: submitting
                          ? null
                          : () async {
                              final result = await FilePicker.platform.pickFiles(type: FileType.video);
                              final path = result?.files.single.path;
                              if (path == null) return;
                              setSheetState(() {
                                pickedFile = File(path);
                                uploadedKey = null;
                                error = null;
                              });
                            },
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(color: Theme.of(sheetContext).inputDecorationTheme.fillColor, borderRadius: BorderRadius.circular(16)),
                        child: Row(
                          children: [
                            HugeIcon(icon: pickedFile != null ? HugeIcons.strokeRoundedFileCheck : HugeIcons.strokeRoundedUpload01, color: AppColors.saffron600, size: 20),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                pickedFile != null ? pickedFile!.path.split(Platform.pathSeparator).last : 'Choose a video from this device',
                                style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: s.textPrimary),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    if (statusLabel != null) ...[
                      const SizedBox(height: 14),
                      Text(statusLabel!, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: s.textSecondary)),
                      const SizedBox(height: 2),
                      Text('Keep the app open until this finishes.', style: TextStyle(fontSize: 11, color: s.textMuted)),
                      const SizedBox(height: 6),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(99),
                        child: LinearProgressIndicator(value: progress, backgroundColor: s.border, color: AppColors.saffron500, minHeight: 6),
                      ),
                    ],
                    if (error != null) ...[const SizedBox(height: 10), Text(error!, style: const TextStyle(color: AppColors.danger, fontSize: 12))],
                    const SizedBox(height: 18),
                    GradientButton(
                      label: submitting ? (statusLabel ?? 'Uploading...') : 'Upload Video',
                      loading: submitting,
                      onPressed: () async {
                        if (titleCtrl.text.trim().isEmpty) {
                          setSheetState(() => error = 'Please enter a title.');
                          return;
                        }
                        if (pickedFile == null) {
                          setSheetState(() => error = 'Please choose a video file.');
                          return;
                        }
                        setSheetState(() {
                          submitting = true;
                          error = null;
                        });

                        try {
                          // A locked phone can stall the transfer, so keep the screen awake.
                          await WakelockPlus.enable();

                          if (uploadedKey == null) {
                            setSheetState(() {
                              statusLabel = 'Uploading video...';
                              progress = 0;
                            });
                            // Dio reports per ~64KB chunk - thousands of callbacks for one video -
                            // so only rebuild the sheet when the visible percentage moves.
                            var lastPercent = -1;
                            uploadedKey = await widget.repo.uploadVideoFile(
                              file: pickedFile!,
                              onSendProgress: (sent, total) {
                                if (total <= 0) return;
                                final percent = sent * 100 ~/ total;
                                if (percent == lastPercent) return;
                                lastPercent = percent;
                                setSheetState(() {
                                  statusLabel = 'Uploading video...';
                                  progress = sent / total;
                                });
                              },
                              onRetrying: () => setSheetState(() => statusLabel = 'Connection lost - retrying...'),
                            );
                          }

                          // Indeterminate: the backend gives no progress for its push to YouTube.
                          setSheetState(() {
                            statusLabel = 'Sending to YouTube... this can take a few minutes.';
                            progress = null;
                          });
                          final added = await widget.repo.publishUploadedVideo(
                            objectKey: uploadedKey!,
                            title: titleCtrl.text.trim(),
                            description: descriptionCtrl.text.trim(),
                            methodology: methodology,
                          );
                          if (sheetContext.mounted) Navigator.pop(sheetContext);
                          if (mounted) {
                            // The file is safe either way; QUEUED just means YouTube isn't
                            // taking uploads right now (its daily quota is used up).
                            final queued = added['processingStatus'] == 'QUEUED';
                            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                              content: Text(queued
                                  ? 'Saved. YouTube is not accepting uploads right now, so this video is queued and will be sent automatically.'
                                  : 'Uploaded. YouTube is processing it - it will appear for everyone once it is ready.'),
                            ));
                          }
                          await widget.refresh();
                        } catch (e) {
                          var message = e.toString().replaceFirst('ApiException: ', '');
                          // These mean the backend no longer holds a usable file for that key, so
                          // the next tap has to send it again rather than retry the hand-off.
                          if (message.contains("didn't finish uploading") || message.contains("isn't a video") || message.contains('too large')) {
                            uploadedKey = null;
                          } else if (uploadedKey != null) {
                            message = '$message\nYour video is already uploaded - tap Upload Video to try again.';
                          }
                          setSheetState(() {
                            submitting = false;
                            statusLabel = null;
                            progress = null;
                            error = message;
                          });
                        } finally {
                          await WakelockPlus.disable();
                        }
                      },
                    ),
                  ],
                ),
              ),
            ),
          ));
        });
      },
    );
  }

  Future<void> _openEdit(Map<String, dynamic> existing) async {
    final titleCtrl = TextEditingController(text: existing['title'] as String? ?? '');
    final descriptionCtrl = TextEditingController(text: existing['description'] as String? ?? '');
    String? methodology = existing['methodology'] as String?;
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
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Container(width: 40, height: 4, margin: const EdgeInsets.only(bottom: 14), alignment: Alignment.center, decoration: BoxDecoration(color: s.border, borderRadius: BorderRadius.circular(99))),
                    Text('Edit Video', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: s.textPrimary)),
                    const SizedBox(height: 16),
                    AppTextField(label: 'Title', controller: titleCtrl),
                    const SizedBox(height: 12),
                    AppTextField(label: 'Description (optional)', controller: descriptionCtrl, maxLines: 3),
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
                      label: 'Save Changes',
                      loading: submitting,
                      onPressed: () async {
                        if (titleCtrl.text.trim().isEmpty) {
                          setSheetState(() => error = 'Please enter a title.');
                          return;
                        }
                        setSheetState(() {
                          submitting = true;
                          error = null;
                        });
                        try {
                          await widget.repo.updateVideo(
                            id: existing['id'] as int,
                            title: titleCtrl.text.trim(),
                            description: descriptionCtrl.text.trim(),
                            methodology: methodology,
                          );
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
          );
        });
      },
    );
  }

  /// A card's 16:9 YouTube thumbnail with a play badge on top. A video that isn't watchable yet
  /// gets a dark scrim instead, carrying what's holding it back: a progress ring while YouTube
  /// is still transcoding it, or a warning icon.
  Widget _thumbnail(Map<String, dynamic> v) {
    final status = v['processingStatus'] as String? ?? 'READY';
    final url = v['thumbnailUrl'] as String?;

    // Shown while the image loads, if it fails (offline), or for a video YouTube has no
    // thumbnail for yet.
    const placeholder = ColoredBox(
      color: Color(0xFF1B1B1F),
      child: Center(child: HugeIcon(icon: HugeIcons.strokeRoundedClapperboard, color: Colors.white38, size: 28)),
    );

    final Widget badge;
    switch (status) {
      case 'PROCESSING':
        final percent = v['processingPercent'] as int?;
        badge = SizedBox(
          width: 34,
          height: 34,
          child: CircularProgressIndicator(strokeWidth: 3, value: percent == null ? null : percent / 100, color: Colors.white),
        );
      case 'UPLOADING':
        badge = const SizedBox(width: 34, height: 34, child: CircularProgressIndicator(strokeWidth: 3, color: Colors.white));
      case 'QUEUED':
        badge = const Icon(Icons.schedule, size: 34, color: Colors.white);
      case 'FAILED':
        badge = const Icon(Icons.error_outline, size: 34, color: Colors.white);
      case 'PRIVATE_LOCKED':
        badge = const Icon(Icons.lock_outline, size: 30, color: Colors.white);
      default:
        badge = Container(
          width: 48,
          height: 48,
          decoration: const BoxDecoration(color: Colors.black54, shape: BoxShape.circle),
          child: const Icon(Icons.play_arrow_rounded, color: Colors.white, size: 30),
        );
    }

    // Full width with square corners - there's no card around it. (ClipRect only trims the
    // cover-fitted image to the box.)
    return ClipRect(
      child: AspectRatio(
        aspectRatio: 16 / 9,
        child: Stack(
          fit: StackFit.expand,
          children: [
            // YouTube's hqdefault is 4:3 with black bars above and below the picture; cover-fitting
            // it into a 16:9 box crops exactly those bars away.
            if (url != null)
              Image.network(
                url,
                fit: BoxFit.cover,
                cacheWidth: 720,
                errorBuilder: (_, _, _) => placeholder,
                loadingBuilder: (_, child, progress) => progress == null ? child : placeholder,
              )
            else
              placeholder,
            if (status != 'READY') const ColoredBox(color: Colors.black54),
            Center(child: badge),
          ],
        ),
      ),
    );
  }

  String _statusNote(Map<String, dynamic> v) {
    switch (v['processingStatus']) {
      case 'PROCESSING':
        final percent = v['processingPercent'] as int?;
        return percent == null ? 'Processing on YouTube - only you can see this until it is ready' : 'Processing on YouTube - $percent%';
      case 'UPLOADING':
        return 'Sending to YouTube...';
      case 'QUEUED':
        // The backend says why it's waiting; the reset time it gives is UTC, so show it in the
        // viewer's own clock.
        final reason = (v['processingMessage'] as String?) ?? 'Waiting to be sent to YouTube.';
        final retryAt = DateTime.tryParse((v['uploadRetryAt'] as String?) ?? '')?.toLocal();
        return retryAt == null
            ? '$reason It will be sent automatically.'
            : '$reason It will be sent automatically after ${DateFormat('d MMM, h:mm a').format(retryAt)}.';
      default:
        return (v['processingMessage'] as String?) ?? 'This video is not available yet.';
    }
  }

  void _explainUnfinished(Map<String, dynamic> v) {
    final text = v['processingStatus'] == 'PROCESSING'
        ? 'YouTube is still processing this video. Until it finishes it would play as a blurry low-quality stream, so it stays hidden from everyone else and will appear here automatically.'
        : _statusNote(v);
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }

  Future<void> _play(Map<String, dynamic> video) async {
    final videoId = video['youtubeVideoId'] as String?;
    if (videoId == null) return;
    // Root navigator: pushed onto the tab's own navigator the page would open *inside*
    // RootTabShell, leaving the bottom nav bar showing around a fullscreen video.
    await Navigator.of(context, rootNavigator: true).push(MaterialPageRoute(builder: (_) => _GalleryVideoPlayerPage(video: video)));
    // The page counted this open and Management may have analyzed the video there — pick up
    // the new view count and analysis for the list.
    if (mounted) await _silentRefresh();
  }

  Future<void> _delete(Map<String, dynamic> video) async {
    if (!await _confirmDelete(context, video) || !mounted) return;
    try {
      await widget.repo.deleteVideo(video['id'] as int);
      await widget.refresh();
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString().replaceFirst('ApiException: ', ''))));
    }
  }

  /// Flattens videos into a [_MethodologyHeader] + video sequence, grouped in canonical
  /// methodology order with an untagged "General" group last — so the list reads as
  /// sections rather than one long undifferentiated feed.
  List<Object> _groupedEntries() {
    final byMethodology = <String, List<Map<String, dynamic>>>{};
    final general = <Map<String, dynamic>>[];
    for (final v in _videos) {
      final m = v['methodology'] as String?;
      if (m == null || m.isEmpty) {
        general.add(v);
      } else {
        byMethodology.putIfAbsent(m, () => []).add(v);
      }
    }
    final entries = <Object>[];
    for (final m in _methodologies) {
      final group = byMethodology[m];
      if (group != null && group.isNotEmpty) {
        entries.add(_MethodologyHeader(m, group.length));
        entries.addAll(group);
      }
    }
    if (general.isNotEmpty) {
      entries.add(_MethodologyHeader('General', general.length));
      entries.addAll(general);
    }
    return entries;
  }

  @override
  Widget build(BuildContext context) {
    final s = context.surface;
    final dark = Theme.of(context).brightness == Brightness.dark;
    final role = context.watch<AuthProvider>().user?.role;
    final canManage = role == 'MANAGEMENT';
    final entries = _groupedEntries();

    return Stack(
      children: [
        _videos.isEmpty
            ? ListView(children: const [SizedBox(height: 120), EmptyView(title: 'No videos yet', subtitle: 'Management can upload videos here.', icon: HugeIcons.strokeRoundedClapperboard)])
            : ListView.builder(
                // No side padding on the list itself: the thumbnails go edge to edge, and the
                // text and section headers add their own 16px inset.
                padding: EdgeInsets.fromLTRB(0, 12, 0, canManage ? 100 : 24),
                itemCount: entries.length,
                itemBuilder: (context, i) {
                  final entry = entries[i];
                  if (entry is _MethodologyHeader) {
                    return Padding(
                      padding: EdgeInsets.fromLTRB(16, i == 0 ? 4 : 10, 16, 12),
                      child: Row(
                        children: [
                          Container(width: 4, height: 15, decoration: BoxDecoration(color: AppColors.saffron500, borderRadius: BorderRadius.circular(2))),
                          const SizedBox(width: 8),
                          Text(entry.title, style: TextStyle(fontWeight: FontWeight.w900, fontSize: 14, color: s.textPrimary)),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: dark ? AppColors.saffron500.withValues(alpha: 0.18) : AppColors.saffron50,
                              borderRadius: BorderRadius.circular(99),
                              border: Border.all(
                                color: dark ? AppColors.saffron500.withValues(alpha: 0.3) : AppColors.saffron200,
                              ),
                            ),
                            child: Text(
                              '${entry.count}',
                              style: TextStyle(
                                fontSize: 10.5,
                                fontWeight: FontWeight.w800,
                                color: dark ? AppColors.saffron400 : AppColors.saffron600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }
                  final v = entry as Map<String, dynamic>;
                  final description = v['description'] as String?;
                  final id = v['id'] as int;
                  final analyzed = v['aiAnalysis'] != null;
                  final canAnalyze = v['canAnalyze'] == true;
                  final analyzing = _analyzingIds.contains(id);
                  final status = v['processingStatus'] as String? ?? 'READY';
                  final ready = status == 'READY';
                  // No card: the thumbnail runs edge to edge and the details sit straight on the
                  // page below it, inset to line up with the section headers.
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 24),
                    child: InkWell(
                      onTap: ready ? () => _play(v) : () => _explainUnfinished(v),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _thumbnail(v),
                          Padding(
                            padding: const EdgeInsets.fromLTRB(16, 12, 8, 0),
                            child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(v['title'] as String, style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14.5, color: s.textPrimary)),
                                if (description != null && description.isNotEmpty) ...[
                                  const SizedBox(height: 2),
                                  Text(description, maxLines: 2, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 11.5, color: s.textSecondary)),
                                ],
                                const SizedBox(height: 2),
                                Text('Uploaded by ${v['uploadedByName']} · ${_viewsLabel(v)}', style: TextStyle(fontSize: 11, color: s.textMuted)),
                                if (!ready) ...[
                                  const SizedBox(height: 6),
                                  Text(
                                    _statusNote(v),
                                    style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: status == 'FAILED' ? AppColors.danger : AppColors.saffron600),
                                  ),
                                ],
                                if (analyzed || (canManage && (canAnalyze || v['canReanalyze'] == true))) ...[
                                  const SizedBox(height: 8),
                                  Wrap(
                                    spacing: 8,
                                    runSpacing: 6,
                                    children: [
                                      if (analyzed || (canManage && canAnalyze))
                                        _pill(
                                          leading: analyzing && !analyzed
                                              ? const SizedBox(width: 12, height: 12, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.saffron600))
                                              : HugeIcon(icon: analyzed ? HugeIcons.strokeRoundedSparkles : HugeIcons.strokeRoundedAiBrain01, size: 12, color: AppColors.saffron600),
                                          label: analyzing && !analyzed ? 'Analyzing...' : (analyzed ? 'View AI Analysis' : 'Analyze with AI'),
                                          onTap: analyzed ? () => _viewAnalysis(v) : (analyzing ? null : () => _analyze(id)),
                                        ),
                                      // Management only, and only while the original file is still stored.
                                      if (canManage && v['canReanalyze'] == true)
                                        _pill(
                                          leading: analyzing
                                              ? const SizedBox(width: 12, height: 12, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.saffron600))
                                              : const HugeIcon(icon: HugeIcons.strokeRoundedRefresh, size: 12, color: AppColors.saffron600),
                                          label: analyzing ? 'Re-analyzing...' : 'Re-analyze',
                                          onTap: analyzing ? null : () => _reanalyze(id),
                                        ),
                                    ],
                                  ),
                                ],
                              ],
                            ),
                          ),
                          if (canManage) ...[
                            IconButton(icon: HugeIcon(icon: HugeIcons.strokeRoundedPencilEdit02, size: 16, color: s.textMuted), onPressed: () => _openEdit(v)),
                            IconButton(icon: HugeIcon(icon: HugeIcons.strokeRoundedDelete02, size: 16, color: s.textMuted), onPressed: () => _delete(v)),
                          ],
                            ],
                          ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
        if (canManage)
          Positioned(right: 16, bottom: 16, child: FloatingActionButton(heroTag: 'add_gallery_video', backgroundColor: AppColors.saffron500, onPressed: _openAdd, child: const Icon(Icons.add, color: Colors.white))),
      ],
    );
  }
}

class _MethodologyHeader {
  final String title;
  final int count;
  const _MethodologyHeader(this.title, this.count);
}

/// A branded, in-app video page rather than a raw YouTube-style popup: the surrounding
/// chrome (app bar, title, description, methodology tag) is entirely ours, the progress
/// bar and controls are re-themed to the app's saffron palette instead of YouTube red, and
/// this pushes as a full page (not a dialog) so it reads as part of the app, not an embed.
/// Independent of Training Management's video player by design — shares no code with
/// VideoResourceScreen, only the same third-party player widget under the hood.
class _GalleryVideoPlayerPage extends StatefulWidget {
  final Map<String, dynamic> video;
  const _GalleryVideoPlayerPage({required this.video});

  @override
  State<_GalleryVideoPlayerPage> createState() => _GalleryVideoPlayerPageState();
}

class _GalleryVideoPlayerPageState extends State<_GalleryVideoPlayerPage> {
  late final YoutubePlayerController _controller = YoutubePlayerController(
    initialVideoId: widget.video['youtubeVideoId'] as String,
    flags: const YoutubePlayerFlags(autoPlay: true, controlsVisibleAtStart: true),
  );

  final _repo = VideoGalleryRepository();

  // A local copy, because this page changes it: the view count arrives after opening, and
  // Management can run the AI analysis from here.
  late Map<String, dynamic> _video = Map.of(widget.video);
  var _analyzing = false;
  String? _analyzeError;

  @override
  void initState() {
    super.initState();
    _recordView();
  }

  /// Counts this open. Fire-and-forget: a failed count must never get in the way of watching.
  Future<void> _recordView() async {
    try {
      final count = await _repo.recordView(_video['id'] as int);
      if (mounted) setState(() => _video = {..._video, 'viewCount': count});
    } catch (_) {}
  }

  /// Replacing an existing analysis (and Vidya's memory of the video) is destructive, so ask first.
  Future<void> _reanalyze() async {
    if (!await _confirmReanalyze(context) || !mounted) return;
    await _analyze(replace: true);
  }

  Future<void> _analyze({bool replace = false}) async {
    setState(() {
      _analyzing = true;
      _analyzeError = null;
    });
    try {
      final updated = await _repo.analyzeVideo(_video['id'] as int, replace: replace);
      if (!mounted) return;
      setState(() {
        _video = updated;
        _analyzing = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _analyzing = false;
        _analyzeError = e.toString().replaceFirst('ApiException: ', '');
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  /// The app is portrait-only; the one exception is this player's fullscreen mode, which
  /// YoutubePlayerBuilder switches to landscape and back (the fullscreen button alone only
  /// requests the orientation — it's the builder that re-lays the page out around the player).
  @override
  Widget build(BuildContext context) {
    return VideoFullscreenScope(
      child: Material(
      color: Colors.black,
      child: YoutubePlayerBuilder(
        player: YoutubePlayer(
          controller: _controller,
          showVideoProgressIndicator: false,
          progressColors: const ProgressBarColors(
            playedColor: AppColors.saffron500,
            handleColor: AppColors.saffron400,
            bufferedColor: Colors.white24,
            backgroundColor: Colors.white12,
          ),
          bottomActions: const [
            SizedBox(width: 12),
            CurrentPosition(),
            SizedBox(width: 8),
            Expanded(child: ProgressBar(isExpanded: true, colors: ProgressBarColors(playedColor: AppColors.saffron500, handleColor: AppColors.saffron400, bufferedColor: Colors.white24, backgroundColor: Colors.white12))),
            RemainingDuration(),
            SizedBox(width: 6),
            FullScreenButton(),
          ],
        ),
        builder: (context, player) => _buildPage(context, player),
      ),
    ));
  }

  Widget _buildPage(BuildContext context, Widget player) {
    final s = context.surface;
    final dark = Theme.of(context).brightness == Brightness.dark;
    final title = _video['title'] as String;
    final description = _video['description'] as String?;
    final methodology = _video['methodology'] as String?;
    final canManage = context.watch<AuthProvider>().user?.role == 'MANAGEMENT';

    return Scaffold(
      backgroundColor: s.bg,
      appBar: AppBar(
        backgroundColor: s.card,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        foregroundColor: s.textPrimary,
        title: Text('Video Gallery', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: s.textPrimary)),
      ),
      body: ListView(
        children: [
          ColoredBox(color: Colors.black, child: player),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: TextStyle(fontWeight: FontWeight.w900, fontSize: 17, color: s.textPrimary)),
                const SizedBox(height: 10),
                Row(
                  children: [
                    if (methodology != null) ...[
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: dark ? AppColors.saffron500.withValues(alpha: 0.18) : AppColors.saffron50,
                          borderRadius: BorderRadius.circular(99),
                          border: Border.all(
                            color: dark ? AppColors.saffron500.withValues(alpha: 0.3) : AppColors.saffron200,
                          ),
                        ),
                        child: Text(
                          methodology,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            color: dark ? AppColors.saffron400 : AppColors.saffron600,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                    ],
                    Expanded(child: Text('Uploaded by ${_video['uploadedByName']}', style: TextStyle(fontSize: 11.5, color: s.textMuted), overflow: TextOverflow.ellipsis)),
                    const SizedBox(width: 8),
                    HugeIcon(icon: HugeIcons.strokeRoundedView, size: 13, color: s.textMuted),
                    const SizedBox(width: 4),
                    Text(_viewsLabel(_video), style: TextStyle(fontSize: 11.5, color: s.textMuted)),
                  ],
                ),
                if (description != null && description.isNotEmpty) ...[
                  const SizedBox(height: 14),
                  Text(description, style: TextStyle(fontSize: 13, color: s.textSecondary, height: 1.5)),
                ],
                const SizedBox(height: 18),
                _analysisCard(context, canManage),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// One collapsible block of the analysis (the transcript can run long, so it can be folded away).
  /// Selectable so any of it can be copied out.
  Widget _analysisSection(BuildContext context, String title, String text) {
    final s = context.surface;
    final dark = Theme.of(context).brightness == Brightness.dark;
    final saffronColor = dark ? AppColors.saffron400 : AppColors.saffron600;
    return Theme(
      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
      child: ExpansionTile(
        initiallyExpanded: true,
        tilePadding: EdgeInsets.zero,
        childrenPadding: const EdgeInsets.only(bottom: 6),
        expandedAlignment: Alignment.centerLeft,
        expandedCrossAxisAlignment: CrossAxisAlignment.start,
        iconColor: saffronColor,
        collapsedIconColor: saffronColor,
        title: Text(title, style: TextStyle(fontWeight: FontWeight.w800, fontSize: 12.5, color: s.textPrimary)),
        children: [
          SelectableText(text, style: TextStyle(fontSize: 13, color: s.textSecondary, height: 1.6)),
        ],
      ),
    );
  }

  /// The AI's account of the video. Always shown, so the space under the player is never just
  /// empty: the analysis itself when there is one, otherwise a button for Management to run it,
  /// otherwise a note that there isn't one.
  Widget _analysisCard(BuildContext context, bool canManage) {
    final s = context.surface;
    final dark = Theme.of(context).brightness == Brightness.dark;
    final raw = _video['aiAnalysis'] as String?;
    final canAnalyze = canManage && _video['canAnalyze'] == true;

    final Widget body;
    if (raw != null) {
      final parsed = _parseAnalysis(raw);
      body = Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (parsed.overview.isNotEmpty)
            Text(parsed.overview, style: TextStyle(fontSize: 13, color: s.textSecondary, height: 1.55)),
          if (parsed.explanation.isNotEmpty) _analysisSection(context, 'Detailed explanation', parsed.explanation),
          if (parsed.points.isNotEmpty) ...[
            const SizedBox(height: 14),
            Text('Key points', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 12.5, color: s.textPrimary)),
            const SizedBox(height: 8),
            for (final point in parsed.points)
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(top: 7),
                      child: Container(
                        width: 5,
                        height: 5,
                        decoration: BoxDecoration(
                          color: dark ? AppColors.saffron400 : AppColors.saffron600,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(child: Text(point, style: TextStyle(fontSize: 13, color: s.textSecondary, height: 1.5))),
                  ],
                ),
              ),
          ],
          // Management only, and only while the original file is still stored (the backend says).
          if (canManage && _video['canReanalyze'] == true) ...[
            const SizedBox(height: 14),
            if (_analyzeError != null) ...[
              Text(_analyzeError!, style: const TextStyle(color: AppColors.danger, fontSize: 12)),
              const SizedBox(height: 8),
            ],
            OutlinedButton.icon(
              onPressed: _analyzing ? null : _reanalyze,
              icon: _analyzing
                  ? SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: dark ? AppColors.saffron400 : AppColors.saffron600))
                  : HugeIcon(icon: HugeIcons.strokeRoundedRefresh, size: 14, color: dark ? AppColors.saffron400 : AppColors.saffron600),
              label: Text(_analyzing ? 'Re-analyzing...' : 'Re-analyze'),
              style: OutlinedButton.styleFrom(
                foregroundColor: dark ? AppColors.saffron400 : AppColors.saffron600,
                side: BorderSide(color: (dark ? AppColors.saffron400 : AppColors.saffron600).withValues(alpha: 0.5)),
                shape: const StadiumBorder(),
                textStyle: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w800),
              ),
            ),
          ],
        ],
      );
    } else if (canAnalyze) {
      body = Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Let AI watch this video and explain everything said and shown in it, in detail. It's also added to Vidya AI's memory, so she can answer questions about this video in chat.",
            style: TextStyle(fontSize: 13, color: s.textSecondary, height: 1.5),
          ),
          if (_analyzeError != null) ...[
            const SizedBox(height: 10),
            Text(_analyzeError!, style: const TextStyle(color: AppColors.danger, fontSize: 12)),
          ],
          const SizedBox(height: 14),
          GradientButton(
            label: _analyzeError != null ? 'Try again' : 'Analyze with AI',
            icon: HugeIcons.strokeRoundedAiBrain01,
            loading: _analyzing,
            height: 46,
            onPressed: _analyze,
          ),
        ],
      );
    } else {
      body = Text(
        "There's no AI analysis for this video yet.",
        style: TextStyle(fontSize: 13, color: s.textMuted, height: 1.5),
      );
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: dark ? s.card : AppColors.saffron50,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: dark ? s.border : AppColors.saffron200,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              HugeIcon(
                icon: HugeIcons.strokeRoundedSparkles,
                size: 16,
                color: dark ? AppColors.saffron400 : AppColors.saffron600,
              ),
              const SizedBox(width: 6),
              Text(
                'AI Analysis',
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 13.5,
                  color: dark ? AppColors.saffron400 : AppColors.saffron700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          body,
        ],
      ),
    );
  }
}

/// Asks before deleting a video, spelling out what goes with it: the YouTube copy (or the pending
/// upload, for a video still queued) and, if it was analyzed, what Vidya learned from it. True
/// only if Management confirms.
Future<bool> _confirmDelete(BuildContext context, Map<String, dynamic> video) async {
  final title = video['title'] as String? ?? 'This video';
  final onYouTube = video['youtubeVideoId'] != null;
  final analyzed = video['aiAnalysis'] != null;
  final message = StringBuffer('"$title" will be removed from the gallery');
  message.write(onYouTube ? ' and from YouTube.' : ', and its pending upload to YouTube will be cancelled.');
  if (analyzed) message.write(' Vidya will also forget what she learned from it.');
  message.write(" This can't be undone.");

  final confirmed = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: const Text('Delete this video?'),
      content: Text(message.toString()),
      actions: [
        TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: const Text('Cancel')),
        TextButton(
          onPressed: () => Navigator.pop(dialogContext, true),
          child: const Text('Delete', style: TextStyle(color: AppColors.danger, fontWeight: FontWeight.w800)),
        ),
      ],
    ),
  );
  return confirmed == true;
}

/// Asks before a re-analysis, since it overwrites the video's existing AI analysis and what
/// Vidya remembers about the video. True only if Management confirms.
Future<bool> _confirmReanalyze(BuildContext context) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: const Text('Re-analyze this video?'),
      content: const Text(
        'The AI will watch the video again and write a new analysis. It will replace the current AI '
        'analysis and what Vidya remembers about this video. This can take a couple of minutes.',
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: const Text('Cancel')),
        TextButton(
          onPressed: () => Navigator.pop(dialogContext, true),
          child: const Text('Re-analyze', style: TextStyle(color: AppColors.saffron600, fontWeight: FontWeight.w800)),
        ),
      ],
    ),
  );
  return confirmed == true;
}

/// "12 views" / "1 view" — the video's open count from the backend (0 until anyone opens it).
String _viewsLabel(Map<String, dynamic> video) {
  final n = (video['viewCount'] as num?)?.toInt() ?? 0;
  return '$n ${n == 1 ? 'view' : 'views'}';
}

/// The sections of a stored analysis; any of them can be empty.
class _Analysis {
  final String overview;
  final String explanation;
  final List<String> points;
  const _Analysis({required this.overview, required this.explanation, required this.points});
}

/// The backend stores an analysis as one string under fixed headers - it's what people read here:
/// a `Video "title" (methodology: X):` line, then `Overview:`, `Detailed explanation:` and
/// `Key points:` (a `- ` bullet each). Splits it back into those sections. Older analyses have no
/// headers (just a summary, then `Key points:`), so text before the first header counts as the
/// overview; anything that fits neither shape is shown whole rather than lost.
_Analysis _parseAnalysis(String raw) {
  var text = raw.trim();
  final firstBreak = text.indexOf('\n');
  if (text.startsWith('Video "') && firstBreak != -1) {
    text = text.substring(firstBreak + 1).trim();
  }

  const headers = {
    'Overview:': 'overview',
    'Detailed explanation:': 'explanation',
    'Key points:': 'points',
  };
  final sections = <String, StringBuffer>{};
  var current = 'overview';
  for (final line in text.split('\n')) {
    final trimmed = line.trim();
    String? key;
    var rest = '';
    for (final entry in headers.entries) {
      if (trimmed.startsWith(entry.key)) {
        key = entry.value;
        rest = trimmed.substring(entry.key.length).trim();
        break;
      }
    }
    if (key != null) {
      current = key;
      final buffer = sections.putIfAbsent(current, StringBuffer.new);
      if (rest.isNotEmpty) buffer.writeln(rest);
    } else {
      sections.putIfAbsent(current, StringBuffer.new).writeln(line);
    }
  }

  String section(String key) => (sections[key]?.toString() ?? '').trim();
  final points = section('points')
      .split('\n')
      .map((line) => line.trim())
      .where((line) => line.startsWith('- '))
      .map((line) => line.substring(2).trim())
      .where((line) => line.isNotEmpty)
      .toList();
  return _Analysis(overview: section('overview'), explanation: section('explanation'), points: points);
}
