import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';
import 'package:dio/dio.dart';
import '../../core/network/api_client.dart';
import '../../core/network/api_exception.dart';

class VideoGalleryRepository {
  final _dio = ApiClient.instance.dio;

  /// Cloud Storage takes the file straight from the phone, so this deliberately isn't the shared
  /// [ApiClient] Dio: that one attaches our Bearer token (which storage would reject), retries
  /// on failure (a half-sent file stream can't be replayed), and caps sends at 30s. No send
  /// timeout — a large video on a slow connection legitimately takes minutes.
  final _storageDio = Dio(BaseOptions(
    connectTimeout: const Duration(seconds: 20),
    receiveTimeout: const Duration(minutes: 2),
    // 308 is how storage says "got that chunk, send the rest" — not a redirect.
    followRedirects: false,
  ));

  /// Storage requires every chunk but the last to be a multiple of 256 KiB.
  static const _chunkBytes = 8 * 1024 * 1024;
  static const _maxChunkFailures = 6;

  Future<List<Map<String, dynamic>>> getVideos({String? methodology}) => apiCall(() async {
        final res = await _dio.get('/video-gallery', queryParameters: {'methodology': ?methodology});
        return (res.data as List).cast<Map<String, dynamic>>();
      });

  /// Step 1 of a gallery upload: sends the original, uncompressed file directly to Cloud Storage
  /// (bypassing the backend, whose Cloud Run host rejects request bodies over 32 MiB). It goes up
  /// in chunks over a resumable session, so a dropped connection carries on from where storage
  /// last got to instead of starting the whole video again. Returns the storage object key to
  /// hand to [publishUploadedVideo].
  Future<String> uploadVideoFile({
    required File file,
    void Function(int sent, int total)? onSendProgress,
    void Function()? onRetrying,
  }) =>
      apiCall(() async {
        final contentType = _videoContentType(file.path);
        final res = await _dio.post('/video-gallery/upload-url', data: {'contentType': contentType});
        final target = res.data as Map<String, dynamic>;

        final sessionUri = await _startSession(target['uploadUrl'] as String, target['contentType'] as String);
        await _sendChunks(sessionUri, file, onSendProgress, onRetrying);
        return target['objectKey'] as String;
      });

  /// Opens the resumable session. The URL is signed against this exact header set, so the
  /// Content-Type and `x-goog-resumable` must be sent precisely as-is.
  Future<String> _startSession(String signedUrl, String contentType) async {
    try {
      final res = await _storageDio.post<dynamic>(
        signedUrl,
        data: Uint8List(0),
        options: Options(contentType: contentType, headers: {'x-goog-resumable': 'start'}),
      );
      final location = res.headers.value('location');
      if (location == null || location.isEmpty) {
        throw ApiException('The upload could not be started. Please try again.');
      }
      return location;
    } on DioException catch (e) {
      throw _storageFailure(e);
    }
  }

  Future<void> _sendChunks(
    String sessionUri,
    File file,
    void Function(int sent, int total)? onSendProgress,
    void Function()? onRetrying,
  ) async {
    final total = await file.length();
    if (total == 0) throw ApiException('That video file is empty.');

    var offset = 0;
    var failures = 0;
    while (offset < total) {
      final end = math.min(offset + _chunkBytes, total); // exclusive
      final chunkStart = offset;
      try {
        final res = await _storageDio.put<dynamic>(
          sessionUri,
          data: file.openRead(chunkStart, end),
          options: Options(
            headers: {
              Headers.contentLengthHeader: end - chunkStart,
              'Content-Range': 'bytes $chunkStart-${end - 1}/$total',
            },
            validateStatus: (s) => s == 200 || s == 201 || s == 308,
          ),
          onSendProgress: (sent, _) => onSendProgress?.call(chunkStart + sent, total),
        );
        final next = res.statusCode == 308 ? _persistedBytes(res) : total;
        if (next <= chunkStart) {
          // Storage acknowledged but kept nothing new — don't spin on it forever.
          if (++failures > _maxChunkFailures) {
            throw ApiException('The upload is not making progress. Please check your connection and try again.');
          }
        } else {
          failures = 0;
        }
        offset = next;
      } on DioException catch (e) {
        if (!_isTransient(e) || ++failures > _maxChunkFailures) throw _storageFailure(e);
        onRetrying?.call();
        await Future<void>.delayed(Duration(seconds: math.min(2 * failures, 10)));
        // Storage may have kept part or all of that chunk before the connection dropped —
        // ask it rather than guess, so we neither skip bytes nor resend what it already has.
        offset = await _askPersistedBytes(sessionUri, total);
      }
    }
    onSendProgress?.call(total, total);
  }

  /// How many bytes storage has durably stored, according to a 308's `Range: bytes=0-N`.
  /// No Range header at all means it has nothing yet.
  int _persistedBytes(Response<dynamic> res) {
    final range = res.headers.value('range');
    final match = range == null ? null : RegExp(r'bytes=0-(\d+)').firstMatch(range);
    return match == null ? 0 : int.parse(match.group(1)!) + 1;
  }

  /// Resumable-upload status check: an empty PUT with `bytes */total` returns 308 plus what's
  /// stored so far, or 200/201 if the whole file had in fact already arrived.
  Future<int> _askPersistedBytes(String sessionUri, int total) async {
    for (var attempt = 1;; attempt++) {
      try {
        final res = await _storageDio.put<dynamic>(
          sessionUri,
          data: Uint8List(0),
          options: Options(
            headers: {'Content-Range': 'bytes */$total'},
            validateStatus: (s) => s == 200 || s == 201 || s == 308,
          ),
        );
        return res.statusCode == 308 ? _persistedBytes(res) : total;
      } on DioException catch (e) {
        if (!_isTransient(e) || attempt >= _maxChunkFailures) throw _storageFailure(e);
        await Future<void>.delayed(Duration(seconds: math.min(2 * attempt, 10)));
      }
    }
  }

  /// A dropped or stalled connection, or storage itself having a bad moment — worth retrying.
  /// Anything else (403 expired signature, 404/410 session gone, 400) won't fix itself.
  bool _isTransient(DioException e) {
    switch (e.type) {
      case DioExceptionType.connectionError:
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return true;
      case DioExceptionType.unknown:
        return e.error is SocketException || e.error is HttpException;
      case DioExceptionType.badResponse:
        final code = e.response?.statusCode ?? 0;
        return code == 500 || code == 502 || code == 503 || code == 504;
      default:
        return false;
    }
  }

  /// Storage answers with XML errors, not our {message} JSON, so the generic status mapping
  /// ("Access denied." etc.) would say nothing useful about what failed.
  ApiException _storageFailure(DioException e) {
    if (e.response != null) {
      final code = e.response?.statusCode;
      if (code == 403 || code == 404 || code == 410) {
        return ApiException('The upload session expired. Please choose the video and try again.');
      }
      return ApiException('The video could not be uploaded (error $code). Please try again.');
    }
    return ApiClient.toApiException(e);
  }

  /// Step 2: the file is in storage — the backend streams it on to YouTube and adds it to the
  /// gallery. That hand-off is server to server but still takes a while for a large video, so
  /// this gets its own long receive timeout instead of the app's default 25s. Safe to repeat
  /// with the same [objectKey]: the backend returns the existing video rather than uploading a
  /// duplicate.
  Future<Map<String, dynamic>> publishUploadedVideo({
    required String objectKey,
    required String title,
    String? description,
    String? methodology,
  }) =>
      apiCall(() async {
        final res = await _dio.post(
          '/video-gallery/from-upload',
          data: {
            'objectKey': objectKey,
            'title': title,
            'description': ?description,
            'methodology': ?methodology,
          },
          options: Options(receiveTimeout: const Duration(minutes: 10)),
        );
        return res.data as Map<String, dynamic>;
      });

  /// The signed upload is tied to this exact value, so it must be a real video/* type — the
  /// backend rejects anything else.
  static String _videoContentType(String path) {
    final dot = path.lastIndexOf('.');
    final ext = dot == -1 ? '' : path.substring(dot + 1).toLowerCase();
    return switch (ext) {
      'mov' => 'video/quicktime',
      'm4v' => 'video/x-m4v',
      'webm' => 'video/webm',
      'mkv' => 'video/x-matroska',
      '3gp' => 'video/3gpp',
      'avi' => 'video/x-msvideo',
      _ => 'video/mp4',
    };
  }

  Future<Map<String, dynamic>> updateVideo({required int id, required String title, String? description, String? methodology}) => apiCall(() async {
        final res = await _dio.put('/video-gallery/$id', data: {
          'title': title,
          'description': ?description,
          'methodology': ?methodology,
        });
        return res.data as Map<String, dynamic>;
      });

  /// Counts one open of the video and returns the new total view count.
  Future<int> recordView(int id) => apiCall(() async {
        final res = await _dio.post('/video-gallery/$id/view');
        return (res.data as Map<String, dynamic>)['viewCount'] as int;
      });

  Future<void> deleteVideo(int id) => apiCall(() async {
        await _dio.delete('/video-gallery/$id');
      });

  /// Gemini watches the whole video (frames + audio) and writes a detailed explanation of it
  /// before replying, which takes well past the app's default 25s receive timeout — this call gets
  /// its own, much longer one. With [replace] it re-analyzes a video that already has an
  /// analysis, and the new one replaces the old (on the video and in Vidya's memory).
  Future<Map<String, dynamic>> analyzeVideo(int id, {bool replace = false}) => apiCall(() async {
        final res = await _dio.post(
          '/video-gallery/$id/analyze',
          queryParameters: {if (replace) 'replace': true},
          options: Options(sendTimeout: const Duration(minutes: 8), receiveTimeout: const Duration(minutes: 8)),
        );
        return res.data as Map<String, dynamic>;
      });
}
