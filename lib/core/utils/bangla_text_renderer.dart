import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

/// Renders Bengali (Bangla) text correctly inside PDF documents.
///
/// The Dart `pdf` package does NOT apply Unicode text shaping — it maps
/// codepoints to glyphs directly, which causes Bengali vowel signs (মাত্রা)
/// and conjunct consonants (যুক্তাক্ষর) to appear in the wrong positions.
///
/// Solution:
///   1. Render text through Flutter's ICU-based shaping engine (dart:ui).
///   2. Capture the result as a PNG image.
///   3. Embed as `pw.Image` in the PDF.
///
/// For Latin/ASCII text this class returns a normal `pw.Text` widget.
class BanglaTextRenderer {
  BanglaTextRenderer._();

  /// Bengali Unicode block: U+0980 – U+09FF
  static bool hasBengali(String text) =>
      text.runes.any((r) => r >= 0x0980 && r <= 0x09FF);

  // ─── Core renderer ────────────────────────────────────────────────────────

  /// Renders [text] through Flutter's shaping engine and returns PNG bytes.
  /// [pixelRatio] controls output resolution — 3.0 ≈ 300 DPI quality.
  static Future<Uint8List?> renderToImageBytes(
    String text, {
    double fontSize = 10.0,
    bool bold = false,
    Color color = Colors.black,
    double maxWidth = 800.0,
    double pixelRatio = 3.0,
  }) async {
    if (text.trim().isEmpty) return null;
    try {
      final scaledFontSize = fontSize * pixelRatio;
      final scaledMaxWidth = maxWidth * pixelRatio;

      // GoogleFonts.hindSiliguri() tells Flutter's font system which font
      // family to use. Flutter's ICU shaper will pick it up automatically.
      final fontFamily = GoogleFonts.hindSiliguri().fontFamily;

      final paragraphStyle = ui.ParagraphStyle(
        textDirection: ui.TextDirection.ltr,
        fontFamily: fontFamily,
        fontSize: scaledFontSize,
        fontWeight: bold ? ui.FontWeight.bold : ui.FontWeight.normal,
        height: 1.35,
      );

      final textStyle = ui.TextStyle(
        fontFamily: fontFamily,
        fontSize: scaledFontSize,
        fontWeight: bold ? ui.FontWeight.bold : ui.FontWeight.normal,
        color: color,
        height: 1.35,
      );

      final builder = ui.ParagraphBuilder(paragraphStyle)
        ..pushStyle(textStyle)
        ..addText(text);

      final paragraph = builder.build()
        ..layout(ui.ParagraphConstraints(width: scaledMaxWidth));

      final w = (paragraph.maxIntrinsicWidth.ceil() + 6).clamp(1, 99999);
      final h = (paragraph.height.ceil() + 6).clamp(1, 99999);

      final recorder = ui.PictureRecorder();
      final canvas = ui.Canvas(
        recorder,
        Rect.fromLTWH(0, 0, w.toDouble(), h.toDouble()),
      );

      canvas.drawParagraph(paragraph, const Offset(3, 3));
      paragraph.dispose();

      final picture = recorder.endRecording();
      final image = await picture.toImage(w, h);
      final byteData =
          await image.toByteData(format: ui.ImageByteFormat.png);
      image.dispose();

      return byteData?.buffer.asUint8List();
    } catch (_) {
      return null;
    }
  }

  // ─── pw.Widget helpers ────────────────────────────────────────────────────

  /// Returns a [pw.Widget] that correctly displays [text] in a PDF.
  ///
  /// • No Bengali  → `pw.Text` (selectable text in PDF viewer).
  /// • Has Bengali → PNG image rendered via Flutter's shaping engine.
  static Future<pw.Widget> pdfWidget(
    String text, {
    double fontSize = 10.0,
    bool bold = false,
    Color color = Colors.black,
    pw.TextAlign textAlign = pw.TextAlign.left,
    int? maxLines,
    double maxWidth = 500.0,
    pw.TextStyle? fallbackStyle,
  }) async {
    if (text.isEmpty) return pw.SizedBox();

    if (!hasBengali(text)) {
      return pw.Text(
        text,
        style: fallbackStyle ??
            pw.TextStyle(
              fontSize: fontSize,
              fontWeight:
                  bold ? pw.FontWeight.bold : pw.FontWeight.normal,
            ),
        textAlign: textAlign,
        maxLines: maxLines,
      );
    }

    final bytes = await renderToImageBytes(
      text,
      fontSize: fontSize,
      bold: bold,
      color: color,
      maxWidth: maxWidth,
    );

    if (bytes == null) {
      return pw.Text(
        text,
        style: fallbackStyle ?? pw.TextStyle(fontSize: fontSize),
        textAlign: textAlign,
        maxLines: maxLines,
      );
    }

    return pw.Image(
      pw.MemoryImage(bytes),
      height: fontSize * 1.6,
      fit: pw.BoxFit.contain,
    );
  }

  /// A global cache to simplify usage in complex PDF builders.
  /// Call [preRenderBatchToGlobal] before building the PDF, then use [cachedWidget].
  static final Map<String, Uint8List?> _globalCache = {};

  /// Synchronous widget from pre-rendered bytes (use after [preRenderBatch]).
  static pw.Widget fromBytes(
    Uint8List? bytes,
    String fallbackText, {
    double fontSize = 10.0,
    bool bold = false,
    pw.TextStyle? style,
    pw.TextAlign textAlign = pw.TextAlign.left,
    PdfColor? color,
    int? maxLines,
  }) {
    if (bytes == null) {
      return pw.Text(
        fallbackText,
        textAlign: textAlign,
        maxLines: maxLines,
        style: style ??
            pw.TextStyle(
              fontSize: fontSize,
              fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal,
              color: color,
            ),
      );
    }
    return pw.Image(
      pw.MemoryImage(bytes),
      height: fontSize * 1.6,
      fit: pw.BoxFit.contain,
    );
  }

  /// Synchronous widget using the global cache (use after [preRenderBatchToGlobal]).
  static pw.Widget cachedWidget(
    String text, {
    double fontSize = 10.0,
    bool bold = false,
    pw.TextStyle? style,
    pw.TextAlign textAlign = pw.TextAlign.left,
    PdfColor? color,
    int? maxLines,
  }) {
    return fromBytes(
      _globalCache[text],
      text,
      fontSize: fontSize,
      bold: bold,
      style: style,
      textAlign: textAlign,
      color: color,
      maxLines: maxLines,
    );
  }

  /// Pre-renders a batch of strings in parallel and stores them in the global cache.
  static Future<void> preRenderBatchToGlobal(
    Iterable<String> texts, {
    double fontSize = 10.0,
    bool bold = false,
    Color color = Colors.black,
    double maxWidth = 500.0,
  }) async {
    final unique = texts.toSet();
    final futures = unique.map(
      (t) async => MapEntry(
        t,
        hasBengali(t)
            ? await renderToImageBytes(
                t,
                fontSize: fontSize,
                bold: bold,
                color: color,
                maxWidth: maxWidth,
              )
            : null,
      ),
    );
    final entries = await Future.wait(futures);
    for (final entry in entries) {
      _globalCache[entry.key] = entry.value;
    }
  }

  /// Pre-renders a batch of strings in parallel BEFORE building PDF pages.
  /// Returns a map of `text → PNG bytes (null if text has no Bengali)`.
  static Future<Map<String, Uint8List?>> preRenderBatch(
    Iterable<String> texts, {
    double fontSize = 10.0,
    bool bold = false,
    Color color = Colors.black,
    double maxWidth = 500.0,
  }) async {
    final unique = texts.toSet();
    final futures = unique.map(
      (t) async => MapEntry(
        t,
        hasBengali(t)
            ? await renderToImageBytes(
                t,
                fontSize: fontSize,
                bold: bold,
                color: color,
                maxWidth: maxWidth,
              )
            : null,
      ),
    );
    final entries = await Future.wait(futures);
    return Map.fromEntries(entries);
  }
}
