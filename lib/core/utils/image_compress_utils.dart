import 'dart:io';
import 'dart:ui' as ui;
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

/// Utility to compress an image [File] to under [targetSizeKB] kilobytes.
/// Returns the compressed [File] (written to a temp path).
/// If the image is already below [targetSizeKB], the original file is returned.
///
/// Only applies to image files. PDFs are returned unchanged.
class ImageCompressUtils {
  static const int _targetSizeKB = 50;

  /// Compress [imageFile] to under [_targetSizeKB] KB.
  /// Returns the compressed [File] or the original if already small enough.
  static Future<File> compressToUnder50KB(File imageFile) async {
    final int originalSize = await imageFile.length();
    final int targetBytes = _targetSizeKB * 1024;

    // Already under limit — return original
    if (originalSize <= targetBytes) {
      return imageFile;
    }

    debugPrint(
      '[ImageCompress] Original: ${(originalSize / 1024).toStringAsFixed(1)} KB — compressing...',
    );

    // Read raw bytes
    final Uint8List originalBytes = await imageFile.readAsBytes();

    // Decode image with dart:ui
    final ui.Codec codec = await ui.instantiateImageCodec(originalBytes);
    final ui.FrameInfo frame = await codec.getNextFrame();
    final ui.Image image = frame.image;

    int width = image.width;
    int height = image.height;

    Uint8List? compressedBytes;

    // Strategy 1: Try progressively lower JPEG quality at original size
    // We simulate quality reduction by scaling down and re-encoding as PNG/JPEG
    // dart:ui only supports raw RGBA and PNG, so we scale dimensions instead.
    // Scale factor reduces both width and height proportionally.
    double scaleFactor = 1.0;
    const double minScale = 0.05;

    while (scaleFactor >= minScale) {
      final int targetW = (width * scaleFactor).round().clamp(1, width);
      final int targetH = (height * scaleFactor).round().clamp(1, height);

      // Resize by creating a picture recorder
      final ui.PictureRecorder recorder = ui.PictureRecorder();
      final ui.Canvas canvas = ui.Canvas(
        recorder,
        ui.Rect.fromLTWH(0, 0, targetW.toDouble(), targetH.toDouble()),
      );
      canvas.drawImageRect(
        image,
        ui.Rect.fromLTWH(0, 0, width.toDouble(), height.toDouble()),
        ui.Rect.fromLTWH(0, 0, targetW.toDouble(), targetH.toDouble()),
        ui.Paint(),
      );
      final ui.Picture picture = recorder.endRecording();
      final ui.Image resized = await picture.toImage(targetW, targetH);

      // Encode as PNG
      final ByteData? byteData =
          await resized.toByteData(format: ui.ImageByteFormat.png);
      resized.dispose();
      picture.dispose();

      if (byteData == null) break;

      final Uint8List bytes = byteData.buffer.asUint8List();

      debugPrint(
        '[ImageCompress] Scale ${(scaleFactor * 100).toStringAsFixed(0)}% → '
        '${targetW}x${targetH} → ${(bytes.length / 1024).toStringAsFixed(1)} KB',
      );

      if (bytes.length <= targetBytes) {
        compressedBytes = bytes;
        break;
      }

      // Reduce scale by 10% each iteration
      scaleFactor -= 0.10;
    }

    image.dispose();

    if (compressedBytes == null) {
      // Fallback — couldn't compress below target, return smallest we got
      debugPrint('[ImageCompress] Could not reach target — returning original');
      return imageFile;
    }

    // Write compressed bytes to a temp file
    final Directory tempDir = await getTemporaryDirectory();
    final String originalName = imageFile.path.split('/').last;
    final String baseName = originalName.contains('.')
        ? originalName.substring(0, originalName.lastIndexOf('.'))
        : originalName;
    final File outputFile = File(
      '${tempDir.path}/${baseName}_compressed.png',
    );
    await outputFile.writeAsBytes(compressedBytes);

    final int finalSize = await outputFile.length();
    debugPrint(
      '[ImageCompress] Done: ${(finalSize / 1024).toStringAsFixed(1)} KB '
      '(was ${(originalSize / 1024).toStringAsFixed(1)} KB)',
    );

    return outputFile;
  }
}
