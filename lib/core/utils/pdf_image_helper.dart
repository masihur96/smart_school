import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class PdfImageHelper {
  /// Fetches an image from the network using flutter_cache_manager.
  /// This ensures the image is downloaded once and saved to disk,
  /// preventing excessive egress when generating PDFs multiple times.
  static Future<pw.ImageProvider> getCachedImageProvider(String url) async {
    if (url.isEmpty) {
      throw Exception('URL is empty');
    }
    try {
      final fileInfo = await DefaultCacheManager().downloadFile(url);
      final bytes = await fileInfo.file.readAsBytes();
      return pw.MemoryImage(bytes);
    } catch (e) {
      // Fallback to the default printing networkImage if caching fails
      return await networkImage(url);
    }
  }
}
