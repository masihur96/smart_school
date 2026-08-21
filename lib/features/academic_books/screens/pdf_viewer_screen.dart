import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:smart_school/core/theme/app_colors.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import 'package:url_launcher/url_launcher.dart';

class PdfViewerScreen extends StatefulWidget {
  final String pdfUrl;
  final String title;
  final String comeFrom;

  const PdfViewerScreen({
    super.key,
    required this.pdfUrl,
    required this.title,
    required this.comeFrom,
  });

  @override
  State<PdfViewerScreen> createState() => _PdfViewerScreenState();
}

class _PdfViewerScreenState extends State<PdfViewerScreen> {
  final PdfViewerController _pdfViewerController = PdfViewerController();
  final GlobalKey<SfPdfViewerState> _pdfViewerKey = GlobalKey();
  late PdfTextSearchResult _searchResult;
  final TextEditingController _searchController = TextEditingController();

  bool _isVertical = false; // Default: Book Reading Mode (Horizontal single-page, ultra smooth)
  bool _isSelectionMode = false; // Default: Pan mode for fast scrolling
  bool _isSearching = false;

  bool _isLoading = true;
  double _downloadProgress = 0.0;
  String? _localPath;
  String? _errorMessage;

  int _currentPage = 1;
  int _totalPages = 0;

  @override
  void initState() {
    super.initState();
    _searchResult = PdfTextSearchResult();
    _initPdfFile();
  }

  @override
  void dispose() {
    _pdfViewerController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Color get _primaryColor {
    switch (widget.comeFrom) {
      case "admin":
        return AppColors.primaryAdmin;
      case "teacher":
        return AppColors.primaryTeacher;
      case "student":
        return AppColors.primaryStudent;
      default:
        return AppColors.primaryAdmin;
    }
  }

  Future<void> _initPdfFile() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _downloadProgress = 0.0;
    });

    try {
      final tempDir = await getTemporaryDirectory();
      final sanitizedName = widget.pdfUrl.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '_');
      final safeName = sanitizedName.length > 40
          ? sanitizedName.substring(sanitizedName.length - 40)
          : sanitizedName;
      final filePath = '${tempDir.path}/book_$safeName.pdf';
      final file = File(filePath);

      if (await file.exists() && await file.length() > 0) {
        if (mounted) {
          setState(() {
            _localPath = filePath;
            _isLoading = false;
          });
        }
        return;
      }

      final dio = Dio();
      await dio.download(
        widget.pdfUrl,
        filePath,
        onReceiveProgress: (received, total) {
          if (total > 0 && mounted) {
            setState(() {
              _downloadProgress = received / total;
            });
          }
        },
      );

      if (mounted) {
        setState(() {
          _localPath = filePath;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Failed to load PDF book. Please check your internet connection.';
        });
      }
    }
  }

  Future<void> _openInBrowser() async {
    final uri = Uri.parse(widget.pdfUrl);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  void _showJumpToPageDialog() {
    final controller = TextEditingController(text: '$_currentPage');
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Go to Page', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Enter page number (1 - $_totalPages):', style: const TextStyle(fontSize: 13, color: Colors.grey)),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              autofocus: true,
              decoration: InputDecoration(
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: _primaryColor,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () {
              final page = int.tryParse(controller.text.trim());
              if (page != null && page >= 1 && page <= _totalPages) {
                _pdfViewerController.jumpToPage(page);
                Navigator.pop(ctx);
              }
            },
            child: const Text('Go', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: _buildAppBar(),
      body: _buildBody(),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    if (_isSearching) {
      return AppBar(
        backgroundColor: _primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () {
            setState(() {
              _isSearching = false;
              _searchResult.clear();
              _searchController.clear();
            });
          },
        ),
        title: TextField(
          controller: _searchController,
          autofocus: true,
          style: const TextStyle(color: Colors.white, fontSize: 14),
          cursorColor: Colors.white,
          decoration: const InputDecoration(
            hintText: 'Search text in book…',
            hintStyle: TextStyle(color: Colors.white70, fontSize: 14),
            border: InputBorder.none,
          ),
          onSubmitted: (query) {
            if (query.trim().isNotEmpty) {
              final result = _pdfViewerController.searchText(query.trim());
              setState(() {
                _searchResult = result;
              });
            }
          },
        ),
        actions: [
          if (_searchResult.totalInstanceCount > 0)
            Center(
              child: Padding(
                padding: const EdgeInsets.only(right: 8),
                child: Text(
                  '${_searchResult.currentInstanceIndex}/${_searchResult.totalInstanceCount}',
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          IconButton(
            icon: const Icon(Icons.keyboard_arrow_up_rounded),
            onPressed: () {
              _searchResult.previousInstance();
              setState(() {});
            },
          ),
          IconButton(
            icon: const Icon(Icons.keyboard_arrow_down_rounded),
            onPressed: () {
              _searchResult.nextInstance();
              setState(() {});
            },
          ),
          IconButton(
            icon: const Icon(Icons.close_rounded),
            onPressed: () {
              setState(() {
                _searchController.clear();
                _searchResult.clear();
              });
            },
          ),
        ],
      );
    }

    return AppBar(
      backgroundColor: _primaryColor,
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
            _isVertical
                ? 'Continuous Vertical Mode (${_isSelectionMode ? "Selection" : "Smooth Pan"})'
                : 'Book Flip Mode (${_isSelectionMode ? "Selection" : "Smooth Pan"})',
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
          icon: const Icon(Icons.search_rounded, size: 20),
          tooltip: 'Search Text',
          onPressed: () {
            setState(() {
              _isSearching = true;
            });
          },
        ),
        IconButton(
          icon: Icon(
            _isSelectionMode ? Icons.touch_app_rounded : Icons.select_all_rounded,
            size: 20,
          ),
          tooltip: _isSelectionMode ? 'Switch to Pan Scroll' : 'Switch to Text Selection Mode',
          onPressed: () {
            setState(() {
              _isSelectionMode = !_isSelectionMode;
            });
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  _isSelectionMode
                      ? 'Text Selection mode active'
                      : 'Smooth Pan Scroll mode active',
                ),
                duration: const Duration(seconds: 1),
                behavior: SnackBarBehavior.floating,
              ),
            );
          },
        ),
        IconButton(
          icon: Icon(
            _isVertical ? Icons.menu_book_rounded : Icons.swap_vert_rounded,
            size: 20,
          ),
          tooltip: _isVertical
              ? 'Switch to Book Flip Mode'
              : 'Switch to Continuous Vertical Scroll',
          onPressed: () {
            setState(() {
              _isVertical = !_isVertical;
            });
          },
        ),
        IconButton(
          icon: const Icon(Icons.open_in_browser_rounded, size: 20),
          tooltip: 'Open in External App',
          onPressed: _openInBrowser,
        ),
      ],
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return Center(
        child: Container(
          width: 280,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.06),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                height: 60,
                width: 60,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    CircularProgressIndicator(
                      value: _downloadProgress > 0 ? _downloadProgress : null,
                      strokeWidth: 4,
                      valueColor: AlwaysStoppedAnimation<Color>(_primaryColor),
                      backgroundColor: _primaryColor.withValues(alpha: 0.15),
                    ),
                    Icon(Icons.picture_as_pdf_rounded, color: _primaryColor, size: 26),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Optimizing Book for Reader…',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
              ),
              const SizedBox(height: 6),
              Text(
                _downloadProgress > 0
                    ? '${(_downloadProgress * 100).toInt()}% downloaded'
                    : 'Preparing fast reader mode…',
                style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
              ),
              const SizedBox(height: 16),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
                  value: _downloadProgress > 0 ? _downloadProgress : null,
                  minHeight: 6,
                  valueColor: AlwaysStoppedAnimation<Color>(_primaryColor),
                  backgroundColor: _primaryColor.withValues(alpha: 0.12),
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.error_outline_rounded, color: Colors.red.shade600, size: 40),
              ),
              const SizedBox(height: 16),
              Text(
                _errorMessage!,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 14, color: Color(0xFF475569)),
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: _initPdfFile,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _primaryColor,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                ),
                icon: const Icon(Icons.refresh_rounded, size: 18),
                label: const Text('Try Again', style: TextStyle(fontWeight: FontWeight.w600)),
              ),
            ],
          ),
        ),
      );
    }

    return Stack(
      children: [
        SfPdfViewer.file(
          File(_localPath!),
          key: _pdfViewerKey,
          controller: _pdfViewerController,
          canShowScrollHead: false,
          canShowScrollStatus: false,
          pageLayoutMode: _isVertical
              ? PdfPageLayoutMode.continuous
              : PdfPageLayoutMode.single,
          scrollDirection: _isVertical
              ? PdfScrollDirection.vertical
              : PdfScrollDirection.horizontal,
          interactionMode: _isSelectionMode
              ? PdfInteractionMode.selection
              : PdfInteractionMode.pan,
          enableTextSelection: _isSelectionMode,
          enableDocumentLinkAnnotation: true,
          onPageChanged: (PdfPageChangedDetails details) {
            if (mounted) {
              setState(() {
                _currentPage = details.newPageNumber;
              });
            }
          },
          onDocumentLoaded: (PdfDocumentLoadedDetails details) {
            if (mounted) {
              setState(() {
                _totalPages = details.document.pages.count;
              });
            }
          },
        ),

        // ── Floating Page Counter & Controls Bar ───────────────────────────
        Positioned(
          bottom: 20,
          left: 20,
          right: 20,
          child: Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFF0F172A).withValues(alpha: 0.85),
                borderRadius: BorderRadius.circular(30),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.2),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.chevron_left_rounded, color: Colors.white, size: 22),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                    onPressed: _currentPage > 1
                        ? () => _pdfViewerController.previousPage()
                        : null,
                  ),
                  const SizedBox(width: 4),
                  InkWell(
                    onTap: _totalPages > 0 ? _showJumpToPageDialog : null,
                    borderRadius: BorderRadius.circular(12),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      child: Row(
                        children: [
                          Text(
                            '$_currentPage',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            ' / ${_totalPages > 0 ? _totalPages : "-"}',
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 13,
                            ),
                          ),
                          const SizedBox(width: 4),
                          const Icon(Icons.unfold_more_rounded, color: Colors.white70, size: 14),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 4),
                  IconButton(
                    icon: const Icon(Icons.chevron_right_rounded, color: Colors.white, size: 22),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                    onPressed: _currentPage < _totalPages
                        ? () => _pdfViewerController.nextPage()
                        : null,
                  ),
                  Container(
                    height: 16,
                    width: 1,
                    color: Colors.white24,
                    margin: const EdgeInsets.symmetric(horizontal: 6),
                  ),
                  IconButton(
                    icon: const Icon(Icons.zoom_out_rounded, color: Colors.white, size: 18),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                    onPressed: () {
                      _pdfViewerController.zoomLevel =
                          (_pdfViewerController.zoomLevel - 0.25).clamp(1.0, 3.0);
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.zoom_in_rounded, color: Colors.white, size: 18),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                    onPressed: () {
                      _pdfViewerController.zoomLevel =
                          (_pdfViewerController.zoomLevel + 0.25).clamp(1.0, 3.0);
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
