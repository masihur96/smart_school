import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import 'package:url_launcher/url_launcher.dart';

class PdfViewerScreen extends StatefulWidget {
  final String pdfUrl;
  final String title;

  const PdfViewerScreen({
    super.key,
    required this.pdfUrl,
    required this.title,
  });

  @override
  State<PdfViewerScreen> createState() => _PdfViewerScreenState();
}

class _PdfViewerScreenState extends State<PdfViewerScreen> {
  final PdfViewerController _pdfViewerController = PdfViewerController();
  final GlobalKey<SfPdfViewerState> _pdfViewerKey = GlobalKey();

  bool _isVertical = false;

  Future<void> _openInBrowser() async {
    final uri = Uri.parse(widget.pdfUrl);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE5E7EB),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A3C6E),
        foregroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.title,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            Text(
              _isVertical ? 'Continuous Scroll Mode' : 'Book Reading Mode',
              style: const TextStyle(
                fontSize: 10,
                color: Colors.white60,
                fontWeight: FontWeight.w400,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(
              _isVertical
                  ? Icons.menu_book_rounded
                  : Icons.swap_vert_rounded,
              size: 20,
            ),
            tooltip: _isVertical ? 'Switch to Book Mode' : 'Switch to Continuous Scroll',
            onPressed: () {
              setState(() {
                _isVertical = !_isVertical;
              });
            },
          ),
          IconButton(
            icon: const Icon(Icons.zoom_in_rounded, size: 20),
            tooltip: 'Zoom In',
            onPressed: () {
              _pdfViewerController.zoomLevel =
                  _pdfViewerController.zoomLevel + 0.5;
            },
          ),
          IconButton(
            icon: const Icon(Icons.open_in_browser_rounded, size: 20),
            tooltip: 'Open in Browser',
            onPressed: _openInBrowser,
          ),
        ],
      ),
      body: SfPdfViewer.network(
        widget.pdfUrl,
        key: _pdfViewerKey,
        controller: _pdfViewerController,
        canShowScrollHead: false,
        canShowScrollStatus: true,
        // Using single page layout makes it transition like a book
        pageLayoutMode: _isVertical
            ? PdfPageLayoutMode.continuous
            : PdfPageLayoutMode.single,
        // Set horizontal scroll direction for book-like flipping
        scrollDirection: _isVertical
            ? PdfScrollDirection.vertical
            : PdfScrollDirection.horizontal,
        enableTextSelection: true, // Enables marking/selecting text
        enableDocumentLinkAnnotation: true,
      ),
    );
  }
}
