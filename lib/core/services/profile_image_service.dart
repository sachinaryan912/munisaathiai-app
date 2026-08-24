import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:image_picker/image_picker.dart';

/// Where the user wants to get their profile photo from.
enum ImageSourceChoice { camera, gallery }

/// Picks a profile photo and compresses it hard before it goes anywhere near the network.
///
/// A modern phone camera produces 3–8 MB per shot. An avatar is drawn at ~88 logical pixels.
/// Uploading the original would be pointless on a school's mobile connection, so this shrinks
/// it by roughly two orders of magnitude first — the backend compresses again as a guarantee,
/// but doing it here is what actually saves the user's data and time.
class ProfileImageService {
  ProfileImageService._();
  static final ProfileImageService instance = ProfileImageService._();

  final ImagePicker _picker = ImagePicker();

  /// Long edge of the stored avatar. 512 stays crisp on 3x-density screens at avatar sizes.
  static const int _maxDimension = 512;

  /// 70 sits just below where JPEG artefacts become visible at this size.
  static const int _quality = 70;

  /// Refuse to upload anything still absurd after compression — a defensive stop, not an
  /// expected path, since compression normally lands well under 100 KB.
  static const int _maxBytes = 2 * 1024 * 1024;

  /// Returns null if the user backed out of the picker.
  ///
  /// Throws [ProfileImageException] with a message fit to show directly if something failed.
  Future<PickedAvatar?> pickAndCompress(ImageSourceChoice choice) async {
    final XFile? picked;
    try {
      picked = await _picker.pickImage(
        source: choice == ImageSourceChoice.camera ? ImageSource.camera : ImageSource.gallery,
        // A first pass in the picker itself: decoding an 8 MP image only to throw most of it
        // away is what makes low-end devices stutter here.
        maxWidth: 1280,
        maxHeight: 1280,
        imageQuality: 90,
      );
    } on Exception {
      // Most often a denied camera/photos permission.
      throw ProfileImageException(
        choice == ImageSourceChoice.camera
            ? "Couldn't open the camera. Please allow camera access in your device settings."
            : "Couldn't open your photos. Please allow photo access in your device settings.",
      );
    }

    if (picked == null) return null;

    final bytes = await _compress(File(picked.path));
    if (bytes.lengthInBytes > _maxBytes) {
      throw ProfileImageException('That image is too large to upload. Please try another photo.');
    }
    return PickedAvatar(bytes: bytes, originalPath: picked.path);
  }

  Future<Uint8List> _compress(File file) async {
    final result = await FlutterImageCompress.compressWithFile(
      file.absolute.path,
      minWidth: _maxDimension,
      minHeight: _maxDimension,
      quality: _quality,
      // Always JPEG: the backend accepts JPG/PNG and normalises to JPEG anyway, and JPEG is
      // dramatically smaller than PNG for photographic content.
      format: CompressFormat.jpeg,
      // Undo the EXIF orientation flag rather than carrying it — the flag is stripped during
      // re-encoding, so without this a portrait photo would come back rotated.
      autoCorrectionAngle: true,
      keepExif: false,
    );

    if (result == null) {
      throw ProfileImageException("Couldn't process that image. Please try another photo.");
    }
    return result;
  }
}

class PickedAvatar {
  final Uint8List bytes;
  final String originalPath;

  const PickedAvatar({required this.bytes, required this.originalPath});

  double get kilobytes => bytes.lengthInBytes / 1024;
}

class ProfileImageException implements Exception {
  final String message;
  ProfileImageException(this.message);

  @override
  String toString() => message;
}
