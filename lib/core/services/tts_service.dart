import 'dart:io';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_edge_tts/flutter_edge_tts.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:path_provider/path_provider.dart';

/// Speaks AI chat responses aloud using Microsoft Edge's neural voices (via
/// flutter_edge_tts) for natural Hindi/Indian-English speech — this hits an
/// unofficial, unsupported Microsoft endpoint with no uptime guarantee, so
/// every failure (network, endpoint change, rate limit) silently degrades to
/// the on-device engine rather than going silent.
class TtsService {
  TtsService._() {
    _fallback.setLanguage('en-US');
    _fallback.setPitch(1.0);
    _fallback.setSpeechRate(0.48);
    _fallback.awaitSpeakCompletion(true);
  }

  static final TtsService instance = TtsService._();

  // Indian-English female neural voice — matches "Vidya"'s persona and the
  // Indian-accent requirement without needing per-message language detection.
  static const _voice = 'en-IN-NeerjaNeural';

  final FlutterTts _fallback = FlutterTts();
  final AudioPlayer _player = AudioPlayer();

  // speak() awaits a network round-trip (synthesis) before it ever touches
  // the player — a stop() tapped during that window would otherwise have
  // nothing to stop yet, and playback would start anyway once synthesis
  // finishes. Each speak() call is stamped with the generation at its start;
  // stop() bumps it, and every await-point below re-checks it before
  // proceeding, so a superseded call just quietly gives up.
  int _generation = 0;

  /// [messageId] keys a per-message cache file, so replaying the same
  /// response is instant on the second tap onward instead of re-paying the
  /// network round-trip to Microsoft's endpoint every time. [onPlaybackStart]
  /// fires right before audio actually starts (on either engine), so callers
  /// can show a loading state during the synthesis wait and know when to
  /// switch it off — otherwise that wait looks identical to "actively
  /// speaking" and reads as broken/unresponsive.
  Future<void> speak(
    int messageId,
    String rawText, {
    VoidCallback? onPlaybackStart,
  }) async {
    final text = _stripMarkdown(rawText);
    if (text.isEmpty) return;
    final myGeneration = ++_generation;
    try {
      final dir = await getTemporaryDirectory();
      if (myGeneration != _generation) return;
      final path = '${dir.path}/vidya_tts_$messageId.mp3';
      if (!await File(path).exists()) {
        final edgeTts = FlutterEdgeTts(voice: _voice);
        await edgeTts.synthesizeToFile(text, audioFilePath: path);
      }
      if (myGeneration != _generation) return;
      onPlaybackStart?.call();
      await _player.play(DeviceFileSource(path));
    } catch (_) {
      if (myGeneration != _generation) return;
      onPlaybackStart?.call();
      await _fallback.speak(text);
    }
  }

  Future<void> stop() async {
    _generation++;
    await _player.stop();
    await _fallback.stop();
  }

  /// Chat messages are Markdown (the same string `MarkdownBody` renders for
  /// the bubble) — without this, the TTS engine reads out literal `**`, `#`,
  /// `-`, link syntax, etc. instead of speaking naturally.
  String _stripMarkdown(String markdown) {
    var text = markdown;
    text = text.replaceAll(RegExp(r'```[\s\S]*?```'), ' ');
    text = text.replaceAllMapped(RegExp(r'`([^`]*)`'), (m) => m.group(1) ?? '');
    text = text.replaceAllMapped(
      RegExp(r'\[([^\]]*)\]\([^)]*\)'),
      (m) => m.group(1) ?? '',
    );
    text = text.replaceAll(RegExp(r'(\*\*\*|\*\*|\*|___|__|_|~~)'), '');
    text = text.replaceAll(RegExp(r'^\s{0,3}#{1,6}\s*', multiLine: true), '');
    text = text.replaceAll(RegExp(r'^\s*[-*+]\s+', multiLine: true), '');
    text = text.replaceAll(RegExp(r'^\s*\d+\.\s+', multiLine: true), '');
    text = text.replaceAll(RegExp(r'^\s*>\s?', multiLine: true), '');
    text = text.replaceAll(
      RegExp(
        '[\\p{Extended_Pictographic}\\u200D\\uFE0F\\u{1F3FB}-\\u{1F3FF}]',
        unicode: true,
      ),
      '',
    );
    text = text.replaceAll(RegExp(r'\n+'), '. ');
    return text.replaceAll(RegExp(r'\s{2,}'), ' ').trim();
  }
}
