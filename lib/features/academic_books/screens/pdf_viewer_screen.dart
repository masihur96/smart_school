import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdfx/pdfx.dart';
import 'package:smart_school/core/theme/app_colors.dart';
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
  // ── State ──────────────────────────────────────────────────────────────────
  _ViewerPhase _phase = _ViewerPhase.downloading;
  double _downloadProgress = 0.0;
  String? _errorMessage;
  String? _localPath;

  // pdfx controller — created once the file is on disk and document is opened
  PdfControllerPinch? _pdfController;

  // Page tracking without ever calling setState during scroll
  final ValueNotifier<int> _currentPageNotifier = ValueNotifier<int>(1);
  final ValueNotifier<int> _totalPagesNotifier = ValueNotifier<int>(0);

  @override
  void initState() {
    super.initState();
    _start();
  }

  @override
  void dispose() {
    _pdfController?.dispose();
    _currentPageNotifier.dispose();
    _totalPagesNotifier.dispose();
    super.dispose();
  }

  // ── Theme color ────────────────────────────────────────────────────────────

  Color get _primary {
    switch (widget.comeFrom) {
      case 'admin':
        return AppColors.primaryAdmin;
      case 'teacher':
        return AppColors.primaryTeacher;
      default:
        return AppColors.primaryStudent;
    }
  }

  // ── Two-phase initialisation: download → open document ────────────────────

  Future<void> _start() async {
    // ── Phase 1: download / use cached file ──────────────────────────────────
    _setPhase(_ViewerPhase.downloading);
    try {
      final path = await _ensureLocalFile();
      if (!mounted) return;
      _localPath = path;
    } catch (e) {
      _setError('Download failed. Please check your connection and retry.');
      return;
    }

    // ── Phase 2: open & index the document (background) ──────────────────────
    // This pre-warms the page index so the first scroll is instant.
    _setPhase(_ViewerPhase.opening);
    try {
      // Opens the document on a background isolate — no main-thread blocking.
      final document = PdfDocument.openFile(_localPath!);
      if (!mounted) return;

      _pdfController = PdfControllerPinch(
        document: document,
        initialPage: 1,
      );

      _setPhase(_ViewerPhase.ready);
    } catch (e) {
      if (kDebugMode) debugPrint('[PdfViewer] open error: $e');
      _setError('Could not open the PDF. The file may be corrupted. Tap Retry to re-download.');
    }
  }

  Future<String> _ensureLocalFile() async {
    final tempDir = await getTemporaryDirectory();
    final sanitized = widget.pdfUrl.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '_');
    final key = sanitized.length > 48
        ? sanitized.substring(sanitized.length - 48)
        : sanitized;
    final filePath = '${tempDir.path}/pdfcache_$key.pdf';
    final file = File(filePath);

    // Return cached copy if valid
    if (await file.exists() && await file.length() > 1024) return filePath;

    // Delete any corrupt partial file
    if (await file.exists()) await file.delete();

    final dio = Dio(BaseOptions(
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(minutes: 10),
    ));

    await dio.download(
      widget.pdfUrl,
      filePath,
      options: Options(responseType: ResponseType.bytes),
      onReceiveProgress: (received, total) {
        if (total > 0 && mounted) {
          final pct = received / total;
          if ((pct - _downloadProgress).abs() >= 0.015 || pct >= 1.0) {
            setState(() => _downloadProgress = pct);
          }
        }
      },
    );

    return filePath;
  }

  void _setPhase(_ViewerPhase phase) {
    if (mounted) {
      setState(() => _phase = phase);
    }
  }

  void _setError(String msg) {
    if (mounted) {
      setState(() {
        _phase = _ViewerPhase.error;
        _errorMessage = msg;
      });
    }
  }

  Future<void> _retry() async {
    // Delete corrupt/incomplete cached file so it re-downloads
    if (_localPath != null) {
      final f = File(_localPath!);
      if (await f.exists()) await f.delete();
    }
    _downloadProgress = 0.0;
    _pdfController?.dispose();
    _pdfController = null;
    _currentPageNotifier.value = 1;
    _totalPagesNotifier.value = 0;
    await _start();
  }

  Future<void> _openInBrowser() async {
    final uri = Uri.parse(widget.pdfUrl);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  void _showJumpToPage() {
    final total = _totalPagesNotifier.value;
    final current = _currentPageNotifier.value;
    if (total == 0) return;

    final ctrl = TextEditingController(text: '$current');
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Go to Page',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Page number (1 – $total)',
                style: const TextStyle(fontSize: 13, color: Colors.grey)),
            const SizedBox(height: 12),
            TextField(
              controller: ctrl,
              keyboardType: TextInputType.number,
              autofocus: true,
              decoration: InputDecoration(
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10)),
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 10),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: _primary,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () {
              final page = int.tryParse(ctrl.text.trim());
              if (page != null && page >= 1 && page <= total) {
                _pdfController?.jumpToPage(page);
                Navigator.pop(ctx);
              }
            },
            child: const Text('Go', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A2E),
      appBar: _buildAppBar(),
      body: _buildBody(),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: _primary,
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
                color: Colors.white),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          Text(
            _phaseLabel,
            style: const TextStyle(
                fontSize: 10,
                color: Colors.white60,
                fontWeight: FontWeight.w400),
          ),
        ],
      ),
      actions: [
        if (_phase == _ViewerPhase.ready)
          IconButton(
            icon: const Icon(Icons.open_in_browser_rounded, size: 20),
            tooltip: 'Open in External App',
            onPressed: _openInBrowser,
          ),
      ],
    );
  }

  String get _phaseLabel {
    switch (_phase) {
      case _ViewerPhase.downloading:
        return _downloadProgress > 0
            ? 'Downloading… ${(_downloadProgress * 100).toInt()}%'
            : 'Connecting…';
      case _ViewerPhase.opening:
        return 'Preparing reader…';
      case _ViewerPhase.ready:
        return 'Swipe to turn pages';
      case _ViewerPhase.error:
        return 'Error loading book';
    }
  }

  Widget _buildBody() {
    switch (_phase) {
      case _ViewerPhase.downloading:
      case _ViewerPhase.opening:
        return _buildPreparationScreen();
      case _ViewerPhase.error:
        return _buildErrorScreen();
      case _ViewerPhase.ready:
        return _buildReaderScreen();
    }
  }

  // ── Preparation screen (download + open) ───────────────────────────────────

  Widget _buildPreparationScreen() {
    final isOpening = _phase == _ViewerPhase.opening;
    return Container(
      color: const Color(0xFF1A1A2E),
      child: Center(
        child: Container(
          width: 300,
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: const Color(0xFF242444),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
                color: _primary.withValues(alpha: 0.3), width: 1),
            boxShadow: [
              BoxShadow(
                color: _primary.withValues(alpha: 0.15),
                blurRadius: 32,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Animated icon ring
              SizedBox(
                height: 80,
                width: 80,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    CircularProgressIndicator(
                      value: isOpening
                          ? null
                          : (_downloadProgress > 0 ? _downloadProgress : null),
                      strokeWidth: 4,
                      valueColor: AlwaysStoppedAnimation<Color>(_primary),
                      backgroundColor: _primary.withValues(alpha: 0.15),
                    ),
                    Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        color: _primary.withValues(alpha: 0.12),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        isOpening
                            ? Icons.auto_stories_rounded
                            : Icons.cloud_download_rounded,
                        color: _primary,
                        size: 26,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              Text(
                isOpening ? 'Preparing Reader' : 'Downloading Book',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 8),

              Text(
                isOpening
                    ? 'Indexing pages for smooth scrolling…'
                    : _downloadProgress > 0
                        ? '${(_downloadProgress * 100).toInt()}% of 100% complete'
                        : 'Connecting to server…',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.55),
                  fontSize: 12.5,
                ),
              ),

              const SizedBox(height: 20),

              // Progress bar
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: LinearProgressIndicator(
                  value: isOpening
                      ? null
                      : (_downloadProgress > 0 ? _downloadProgress : null),
                  minHeight: 5,
                  valueColor: AlwaysStoppedAnimation<Color>(_primary),
                  backgroundColor: _primary.withValues(alpha: 0.15),
                ),
              ),

              const SizedBox(height: 16),

              // Step indicators
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _StepDot(
                      done: true,
                      active: _phase == _ViewerPhase.downloading,
                      label: 'Download',
                      color: _primary),
                  _StepLine(
                      done: _phase == _ViewerPhase.opening ||
                          _phase == _ViewerPhase.ready,
                      color: _primary),
                  _StepDot(
                      done: _phase == _ViewerPhase.ready,
                      active: _phase == _ViewerPhase.opening,
                      label: 'Prepare',
                      color: _primary),
                  _StepLine(done: _phase == _ViewerPhase.ready, color: _primary),
                  _StepDot(
                      done: _phase == _ViewerPhase.ready,
                      active: false,
                      label: 'Read',
                      color: _primary),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Error screen ───────────────────────────────────────────────────────────

  Widget _buildErrorScreen() {
    return Container(
      color: const Color(0xFF1A1A2E),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(18),
                decoration: const BoxDecoration(
                    color: Color(0x22EF4444), shape: BoxShape.circle),
                child: const Icon(Icons.warning_amber_rounded,
                    color: Color(0xFFEF4444), size: 44),
              ),
              const SizedBox(height: 20),
              Text(
                _errorMessage ?? 'Something went wrong.',
                textAlign: TextAlign.center,
                style: const TextStyle(
                    fontSize: 14, color: Colors.white70, height: 1.5),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: _retry,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 24, vertical: 12),
                ),
                icon: const Icon(Icons.refresh_rounded, size: 18),
                label: const Text('Retry',
                    style: TextStyle(fontWeight: FontWeight.w700)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Reader screen ──────────────────────────────────────────────────────────

  Widget _buildReaderScreen() {
    return Stack(
      children: [
        // ── PDF View ─────────────────────────────────────────────────────
        // pdfx uses Android's native PdfRenderer API on a background thread.
        // Page rendering NEVER runs on the main thread → zero ANR risk.
        // PageView handles fling internally with Flutter physics → no lag.
        PdfViewPinch(
          controller: _pdfController!,
          onDocumentLoaded: (doc) {
            // Pure ValueNotifier update — no setState, no rebuild
            _totalPagesNotifier.value = doc.pagesCount;
          },
          onPageChanged: (page) {
            // Pure ValueNotifier update — no setState, no rebuild
            _currentPageNotifier.value = page;
          },
          builders: PdfViewPinchBuilders<DefaultBuilderOptions>(
            options: const DefaultBuilderOptions(),
            documentLoaderBuilder: (_) => Center(
              child: CircularProgressIndicator(
                strokeWidth: 2.5,
                valueColor: AlwaysStoppedAnimation<Color>(_primary),
              ),
            ),
            pageLoaderBuilder: (_) => Center(
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(
                    _primary.withValues(alpha: 0.6)),
              ),
            ),
            errorBuilder: (_, error) => Center(
              child: Text('Page error: $error',
                  style: const TextStyle(color: Colors.white70)),
            ),
          ),
        ),

        // ── Floating control bar ──────────────────────────────────────────
        // Only this sub-tree updates when page changes — viewer is untouched.
        Positioned(
          bottom: 20,
          left: 16,
          right: 16,
          child: Center(
            child: ValueListenableBuilder<int>(
              valueListenable: _currentPageNotifier,
              builder: (_, currentPage, __) => ValueListenableBuilder<int>(
                valueListenable: _totalPagesNotifier,
                builder: (_, totalPages, __) => _FloatingBar(
                  currentPage: currentPage,
                  totalPages: totalPages,
                  primaryColor: _primary,
                  onPrev: currentPage > 1
                      ? () => _pdfController?.previousPage(
                            duration:
                                const Duration(milliseconds: 250),
                            curve: Curves.easeInOut,
                          )
                      : null,
                  onNext: currentPage < totalPages
                      ? () => _pdfController?.nextPage(
                            duration:
                                const Duration(milliseconds: 250),
                            curve: Curves.easeInOut,
                          )
                      : null,
                  onJump: _showJumpToPage,
                  onOpenBrowser: _openInBrowser,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ── Phase enum ─────────────────────────────────────────────────────────────────

enum _ViewerPhase { downloading, opening, ready, error }

// ── Floating bottom bar (stateless) ───────────────────────────────────────────

class _FloatingBar extends StatelessWidget {
  final int currentPage;
  final int totalPages;
  final Color primaryColor;
  final VoidCallback? onPrev;
  final VoidCallback? onNext;
  final VoidCallback onJump;
  final VoidCallback onOpenBrowser;

  const _FloatingBar({
    required this.currentPage,
    required this.totalPages,
    required this.primaryColor,
    required this.onPrev,
    required this.onNext,
    required this.onJump,
    required this.onOpenBrowser,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A).withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.28),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _Btn(
              icon: Icons.chevron_left_rounded,
              size: 24,
              onTap: onPrev),
          const SizedBox(width: 2),
          GestureDetector(
            onTap: totalPages > 0 ? onJump : null,
            child: Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '$currentPage',
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.bold),
                  ),
                  Text(
                    ' / ${totalPages > 0 ? totalPages : "—"}',
                    style: const TextStyle(
                        color: Colors.white60, fontSize: 13),
                  ),
                  const SizedBox(width: 3),
                  const Icon(Icons.unfold_more_rounded,
                      color: Colors.white38, size: 13),
                ],
              ),
            ),
          ),
          const SizedBox(width: 2),
          _Btn(
              icon: Icons.chevron_right_rounded,
              size: 24,
              onTap: onNext),
          Container(
            height: 14,
            width: 1,
            color: Colors.white24,
            margin: const EdgeInsets.symmetric(horizontal: 6),
          ),
          _Btn(
              icon: Icons.open_in_browser_rounded,
              size: 18,
              onTap: onOpenBrowser),
        ],
      ),
    );
  }
}

class _Btn extends StatelessWidget {
  final IconData icon;
  final double size;
  final VoidCallback? onTap;

  const _Btn(
      {required this.icon, required this.size, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 34,
      height: 34,
      child: IconButton(
        padding: EdgeInsets.zero,
        icon: Icon(icon,
            size: size,
            color: onTap != null ? Colors.white : Colors.white24),
        onPressed: onTap,
      ),
    );
  }
}

// ── Step indicator widgets ──────────────────────────────────────────────────

class _StepDot extends StatelessWidget {
  final bool done;
  final bool active;
  final String label;
  final Color color;

  const _StepDot(
      {required this.done,
      required this.active,
      required this.label,
      required this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: done
                ? color
                : active
                    ? color.withValues(alpha: 0.6)
                    : Colors.white24,
          ),
        ),
        const SizedBox(height: 4),
        Text(label,
            style: TextStyle(
                fontSize: 9,
                color: done || active ? Colors.white70 : Colors.white30)),
      ],
    );
  }
}

class _StepLine extends StatelessWidget {
  final bool done;
  final Color color;
  const _StepLine({required this.done, required this.color});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        width: 32,
        height: 2,
        decoration: BoxDecoration(
          color: done ? color : Colors.white24,
          borderRadius: BorderRadius.circular(2),
        ),
      ),
    );
  }
}
