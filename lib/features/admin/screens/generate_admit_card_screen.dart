import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:pdfx/pdfx.dart' as pdfx;
import 'package:printing/printing.dart';
import 'package:provider/provider.dart';
import 'package:smart_school/core/theme/app_colors.dart';
import 'package:smart_school/core/utils/pdf_image_helper.dart';
import 'package:smart_school/features/auth/providers/auth_provider.dart';
import 'package:smart_school/models/school_models.dart';
import 'package:smart_school/models/student_model.dart';

import '../providers/setup_provider.dart';
import '../providers/student_provider.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Enum – available admit card templates
// ─────────────────────────────────────────────────────────────────────────────
enum AdmitCardTemplate { classic, modern, minimal, compact }

extension AdmitCardTemplateExt on AdmitCardTemplate {
  String get label {
    switch (this) {
      case AdmitCardTemplate.classic:
        return 'Classic';
      case AdmitCardTemplate.modern:
        return 'Modern';
      case AdmitCardTemplate.minimal:
        return 'Minimal';
      case AdmitCardTemplate.compact:
        return 'Compact\n(6/page)';
    }
  }

  IconData get icon {
    switch (this) {
      case AdmitCardTemplate.classic:
        return Icons.credit_card_outlined;
      case AdmitCardTemplate.modern:
        return Icons.style_outlined;
      case AdmitCardTemplate.minimal:
        return Icons.article_outlined;
      case AdmitCardTemplate.compact:
        return Icons.dashboard_outlined;
    }
  }

  Color get accentColor {
    switch (this) {
      case AdmitCardTemplate.classic:
        return Colors.deepPurple;
      case AdmitCardTemplate.modern:
        return const Color(0xFF1A237E);
      case AdmitCardTemplate.minimal:
        return Colors.blueGrey;
      case AdmitCardTemplate.compact:
        return Colors.teal;
    }
  }

  String get description {
    switch (this) {
      case AdmitCardTemplate.classic:
        return 'Formal letterhead with full schedule';
      case AdmitCardTemplate.modern:
        return 'Bold contemporary card design';
      case AdmitCardTemplate.minimal:
        return 'Elegant monochrome layout';
      case AdmitCardTemplate.compact:
        return '6 cards per page, no routine';
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Screen Widget
// ─────────────────────────────────────────────────────────────────────────────
class GenerateAdmitCardScreen extends StatefulWidget {
  final Exam exam;
  final List<Student> students;

  const GenerateAdmitCardScreen({
    super.key,
    required this.exam,
    required this.students,
  });

  @override
  State<GenerateAdmitCardScreen> createState() =>
      _GenerateAdmitCardScreenState();
}

class _GenerateAdmitCardScreenState extends State<GenerateAdmitCardScreen> {
  String? _selectedClassId;
  String? _selectedSectionId;
  late List<Student> _currentStudents;
  bool _isLoading = false;
  Uint8List? _pdfBytes;
  pdfx.PdfControllerPinch? _pdfController;
  AdmitCardTemplate _selectedTemplate = AdmitCardTemplate.classic;

  @override
  void dispose() {
    _pdfController?.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _currentStudents = List.from(widget.students);
    if (_currentStudents.isNotEmpty) {
      _selectedClassId = _currentStudents.first.classId;
      _selectedSectionId = _currentStudents.first.sectionId;
    } else if (widget.exam.assignments.isNotEmpty) {
      _selectedClassId = widget.exam.assignments.first.classId;
      _selectedSectionId = widget.exam.assignments.first.sectionId;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) => _generatePdf());
  }

  // ───────────────────────────────────────────────────────────────────────────
  // PDF generation controller
  // ───────────────────────────────────────────────────────────────────────────

  Future<void> _generatePdf() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    final school = context.read<AuthNotifier>().user?.school;
    try {
      final bytes = await _buildPdf(PdfPageFormat.a4, school);
      if (mounted) {
        setState(() {
          _pdfBytes = bytes;
          _pdfController?.dispose();
          _pdfController = pdfx.PdfControllerPinch(
            document: pdfx.PdfDocument.openData(bytes),
          );
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _fetchStudents() {
    if (_selectedClassId == null) return;
    setState(() => _isLoading = true);
    context
        .read<StudentsNotifier>()
        .fetchStudentsBySection(
          classId: _selectedClassId!,
          sectionId: _selectedSectionId,
        )
        .then((_) {
          if (mounted) {
            setState(() {
              _currentStudents =
                  List.from(context.read<StudentsNotifier>().students);
            });
            _generatePdf();
          }
        });
  }

  // ───────────────────────────────────────────────────────────────────────────
  // PDF document builder
  // ───────────────────────────────────────────────────────────────────────────

  Future<Uint8List> _buildPdf(PdfPageFormat format, School? school) async {
    // ── Resolve class / section display names ─────────────────────────────
    String resolvedClassName = 'N/A';
    if (_selectedClassId != null) {
      try {
        resolvedClassName = context
            .read<ClassSetupNotifier>()
            .classes
            .firstWhere((c) => c.id == _selectedClassId)
            .name;
      } catch (_) {
        // fall back to assignment name
        final a = widget.exam.assignments
            .firstWhere((a) => a.classId == _selectedClassId,
                orElse: () => widget.exam.assignments.first);
        resolvedClassName = a.className;
      }
    }
    String resolvedSectionName = 'N/A';
    if (_selectedSectionId != null) {
      try {
        resolvedSectionName = context
            .read<SectionSetupNotifier>()
            .sections
            .firstWhere((s) => s.id == _selectedSectionId)
            .name;
      } catch (_) {
        final a = widget.exam.assignments.firstWhere(
            (a) => a.sectionId == _selectedSectionId,
            orElse: () => widget.exam.assignments.first);
        resolvedSectionName = a.sectionName ?? 'N/A';
      }
    }

    // ── School metadata ───────────────────────────────────────────────────
    final schoolName = school?.name ?? 'School Name';
    final schoolAddress = school?.address ?? '';
    final schoolPhone = school?.phone ?? '';
    final schoolEmail = school?.email ?? '';
    final schoolLogoUrl = school?.avatar ?? '';

    // ── PARALLEL: load fonts + school logo + all student avatars at once ──
    Future<pw.ImageProvider?> safeImage(String url) async {
      if (url.isEmpty) return null;
      try {
        return await PdfImageHelper.getCachedImageProvider(url);
      } catch (_) {
        return null;
      }
    }

    Future<pw.Font?> safeFont(Future<pw.Font> loader) async {
      try {
        return await loader;
      } catch (_) {
        return null;
      }
    }

    // Collect all futures simultaneously
    final fontRegFuture = safeFont(PdfGoogleFonts.notoSansBengaliRegular());
    final fontBoldFuture = safeFont(PdfGoogleFonts.notoSansBengaliBold());
    final logoFuture = safeImage(schoolLogoUrl);

    final studentIds = <String>[];
    final avatarFutures = <Future<pw.ImageProvider?>>[];
    for (final student in _currentStudents) {
      final url = student.user?.avatar ?? '';
      studentIds.add(student.userId);
      avatarFutures.add(safeImage(url));
    }

    // Wait for ALL in parallel — fastest possible loading
    final allResults = await Future.wait<Object?>([
      fontRegFuture,
      fontBoldFuture,
      logoFuture,
      ...avatarFutures,
    ]);

    final fontReg = allResults[0] as pw.Font?;
    final fontBold = allResults[1] as pw.Font?;
    final schoolLogo = allResults[2] as pw.ImageProvider?;
    final Map<String, pw.ImageProvider> avatars = {};
    for (var i = 0; i < studentIds.length; i++) {
      final img = allResults[3 + i] as pw.ImageProvider?;
      if (img != null) avatars[studentIds[i]] = img;
    }

    // ── Create document with Bengali font theme (supports any language) ───
    final pdf = pw.Document(
      theme: fontReg != null
          ? pw.ThemeData.withFont(
              base: fontReg,
              bold: fontBold ?? fontReg,
              italic: fontReg,
              boldItalic: fontBold ?? fontReg,
            )
          : pw.ThemeData(),
    );

    // Filtered subject assignments
    final List<ExamAssignment> subjectAssignments =
        widget.exam.assignments.where((a) {
          if (_selectedClassId != null && a.classId != _selectedClassId) {
            return false;
          }
          if (_selectedSectionId != null &&
              a.sectionId != null &&
              a.sectionId != _selectedSectionId) {
            return false;
          }
          return true;
        }).toList()
          ..sort((a, b) => a.date.compareTo(b.date));

    // ── COMPACT: 6 cards per A4 page ──────────────────────────────────────
    if (_selectedTemplate == AdmitCardTemplate.compact) {
      const int perPage = 6;
      for (var i = 0; i < _currentStudents.length; i += perPage) {
        final pageStudents = _currentStudents.skip(i).take(perPage).toList();
        pdf.addPage(
          pw.Page(
            pageFormat: format,
            margin: const pw.EdgeInsets.all(20),
            build: (pw.Context ctx) {
              return pw.GridView(
                crossAxisCount: 2,
                crossAxisSpacing: 14,
                mainAxisSpacing: 14,
                childAspectRatio: 1.72,
                children: pageStudents.map((student) {
                  final cn = student.className?.isNotEmpty == true
                      ? student.className!
                      : resolvedClassName;
                  final sn = student.sectionName?.isNotEmpty == true
                      ? student.sectionName!
                      : resolvedSectionName;
                  return _buildCompactCard(
                    student: student,
                    className: cn,
                    sectionName: sn,
                    schoolName: schoolName,
                    schoolLogo: schoolLogo,
                    avatar: avatars[student.userId],
                  );
                }).toList(),
              );
            },
          ),
        );
      }
      return pdf.save();
    }

    // ── FULL-PAGE templates: one student per page ─────────────────────────
    for (final student in _currentStudents) {
      final className = student.className?.isNotEmpty == true
          ? student.className!
          : resolvedClassName;
      final sectionName = student.sectionName?.isNotEmpty == true
          ? student.sectionName!
          : resolvedSectionName;
      final avatar = avatars[student.userId];

      pdf.addPage(
        pw.Page(
          pageFormat: format,
          margin: pw.EdgeInsets.zero,
          build: (pw.Context ctx) {
            switch (_selectedTemplate) {
              case AdmitCardTemplate.classic:
                return _buildClassicTemplate(
                  student: student,
                  className: className,
                  sectionName: sectionName,
                  schoolName: schoolName,
                  schoolAddress: schoolAddress,
                  schoolPhone: schoolPhone,
                  schoolEmail: schoolEmail,
                  schoolLogo: schoolLogo,
                  avatar: avatar,
                  subjects: subjectAssignments,
                );
              case AdmitCardTemplate.modern:
                return _buildModernTemplate(
                  student: student,
                  className: className,
                  sectionName: sectionName,
                  schoolName: schoolName,
                  schoolAddress: schoolAddress,
                  schoolPhone: schoolPhone,
                  schoolEmail: schoolEmail,
                  schoolLogo: schoolLogo,
                  avatar: avatar,
                  subjects: subjectAssignments,
                );
              case AdmitCardTemplate.minimal:
                return _buildMinimalTemplate(
                  student: student,
                  className: className,
                  sectionName: sectionName,
                  schoolName: schoolName,
                  schoolAddress: schoolAddress,
                  schoolPhone: schoolPhone,
                  schoolEmail: schoolEmail,
                  schoolLogo: schoolLogo,
                  avatar: avatar,
                  subjects: subjectAssignments,
                );
              case AdmitCardTemplate.compact:
                return pw.SizedBox(); // handled above
            }
          },
        ),
      );
    }

    return pdf.save();
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // TEMPLATE 1 – CLASSIC
  // Formal university-style: letterhead top, amber rule, student box with
  // photo, full schedule table with 4 columns, numbered instructions,
  // three signature blocks.
  // ═══════════════════════════════════════════════════════════════════════════
  pw.Widget _buildClassicTemplate({
    required Student student,
    required String className,
    required String sectionName,
    required String schoolName,
    required String schoolAddress,
    required String schoolPhone,
    required String schoolEmail,
    required pw.ImageProvider? schoolLogo,
    required pw.ImageProvider? avatar,
    required List<ExamAssignment> subjects,
  }) {
    const primary = PdfColors.deepPurple800;
    const accent = PdfColors.amber700;
    const light = PdfColors.deepPurple50;

    return pw.Container(
      color: PdfColors.white,
      padding: const pw.EdgeInsets.fromLTRB(36, 28, 36, 24),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.stretch,
        children: [
          // ── Letterhead ──────────────────────────────────────────────────
          pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.center,
            children: [
              if (schoolLogo != null)
                pw.Container(
                  width: 62,
                  height: 62,
                  margin: const pw.EdgeInsets.only(right: 16),
                  decoration: pw.BoxDecoration(
                    shape: pw.BoxShape.circle,
                    border: pw.Border.all(color: primary, width: 2),
                    image: pw.DecorationImage(
                      image: schoolLogo,
                      fit: pw.BoxFit.contain,
                    ),
                  ),
                ),
              pw.Expanded(
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.center,
                  children: [
                    pw.Text(
                      schoolName.toUpperCase(),
                      textAlign: pw.TextAlign.center,
                      style: pw.TextStyle(
                        color: primary,
                        fontWeight: pw.FontWeight.bold,
                        fontSize: 16,
                        letterSpacing: 1,
                      ),
                    ),
                    if (schoolAddress.isNotEmpty) ...[
                      pw.SizedBox(height: 3),
                      pw.Text(
                        schoolAddress,
                        textAlign: pw.TextAlign.center,
                        style: const pw.TextStyle(
                          fontSize: 8.5,
                          color: PdfColors.grey700,
                        ),
                      ),
                    ],
                    if (schoolPhone.isNotEmpty || schoolEmail.isNotEmpty) ...[
                      pw.SizedBox(height: 2),
                      pw.Text(
                        [
                          if (schoolPhone.isNotEmpty) '📞 $schoolPhone',
                          if (schoolEmail.isNotEmpty) '✉ $schoolEmail',
                        ].join('     '),
                        textAlign: pw.TextAlign.center,
                        style: const pw.TextStyle(
                          fontSize: 7.5,
                          color: PdfColors.grey600,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (schoolLogo != null) pw.SizedBox(width: 78),
            ],
          ),

          pw.SizedBox(height: 10),

          // ── Decorative rule ──
          pw.Container(height: 3, color: primary),
          pw.Container(height: 2, color: accent),
          pw.SizedBox(height: 8),

          // ── ADMIT CARD title ──
          pw.Center(
            child: pw.Container(
              padding: const pw.EdgeInsets.symmetric(
                horizontal: 24,
                vertical: 6,
              ),
              decoration: pw.BoxDecoration(
                color: primary,
                borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
              ),
              child: pw.Text(
                'ADMIT CARD',
                style: pw.TextStyle(
                  color: PdfColors.white,
                  fontWeight: pw.FontWeight.bold,
                  fontSize: 14,
                  letterSpacing: 4,
                ),
              ),
            ),
          ),
          pw.SizedBox(height: 4),
          pw.Center(
            child: pw.Text(
              widget.exam.name.toUpperCase(),
              style: pw.TextStyle(
                color: primary,
                fontWeight: pw.FontWeight.bold,
                fontSize: 10,
                letterSpacing: 2,
              ),
            ),
          ),
          if (widget.exam.startDate != null) ...[
            pw.SizedBox(height: 2),
            pw.Center(
              child: pw.Text(
                '${DateFormat('dd MMMM yyyy').format(widget.exam.startDate!)}  —  ${DateFormat('dd MMMM yyyy').format(widget.exam.endDate ?? widget.exam.startDate!)}',
                style: const pw.TextStyle(
                  fontSize: 8,
                  color: PdfColors.grey700,
                ),
              ),
            ),
          ],

          pw.SizedBox(height: 14),
          pw.Container(height: 1, color: PdfColors.grey300),
          pw.SizedBox(height: 12),

          // ── Student information box ──────────────────────────────────────
          pw.Container(
            decoration: pw.BoxDecoration(
              border: pw.Border.all(color: PdfColors.grey300, width: 0.8),
              borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
            ),
            child: pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                // Photo box
                pw.Container(
                  width: 95,
                  height: 120,
                  decoration: pw.BoxDecoration(
                    color: light,
                    borderRadius: const pw.BorderRadius.only(
                      topLeft: pw.Radius.circular(5),
                      bottomLeft: pw.Radius.circular(5),
                    ),
                    border: pw.Border(
                      right: pw.BorderSide(color: PdfColors.grey300),
                    ),
                  ),
                  child: avatar != null
                      ? pw.ClipRRect(
                          horizontalRadius: 5,
                          verticalRadius: 5,
                          child: pw.Image(avatar, fit: pw.BoxFit.cover),
                        )
                      : pw.Center(
                          child: pw.Column(
                            mainAxisAlignment: pw.MainAxisAlignment.center,
                            children: [
                              pw.Text(
                                student.user?.name.isNotEmpty == true
                                    ? student.user!.name[0].toUpperCase()
                                    : '?',
                                style: pw.TextStyle(
                                  fontSize: 38,
                                  fontWeight: pw.FontWeight.bold,
                                  color: primary,
                                ),
                              ),
                              pw.Text(
                                'PHOTO',
                                style: const pw.TextStyle(
                                  fontSize: 7,
                                  color: PdfColors.grey500,
                                ),
                              ),
                            ],
                          ),
                        ),
                ),

                // Details
                pw.Expanded(
                  child: pw.Padding(
                    padding: const pw.EdgeInsets.all(12),
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        _classicField('Student Name', student.user?.name ?? 'N/A', primary: primary, big: true),
                        pw.SizedBox(height: 6),
                        pw.Row(
                          children: [
                            pw.Expanded(
                              child: _classicField('Roll Number', student.rollId, primary: primary),
                            ),
                            pw.SizedBox(width: 12),
                            pw.Expanded(
                              child: _classicField('Class', '$className  –  $sectionName', primary: primary),
                            ),
                          ],
                        ),
                        pw.SizedBox(height: 6),
                        pw.Row(
                          children: [
                            pw.Expanded(
                              child: _classicField('Guardian Contact', student.guardianContact.isNotEmpty ? student.guardianContact : (student.user?.phone ?? 'N/A'), primary: primary),
                            ),
                            pw.SizedBox(width: 12),
                            pw.Expanded(
                              child: _classicField('Email', student.user?.email ?? 'N/A', primary: primary),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

                // Serial / Ref number badge on right
                pw.Container(
                  width: 24,
                  decoration: pw.BoxDecoration(
                    color: accent,
                    borderRadius: const pw.BorderRadius.only(
                      topRight: pw.Radius.circular(5),
                      bottomRight: pw.Radius.circular(5),
                    ),
                  ),
                  child: pw.Center(
                    child: pw.Transform.rotateBox(
                      angle: 1.5708,
                      child: pw.Text(
                        'ROLL: ${student.rollId}',
                        style: pw.TextStyle(
                          fontWeight: pw.FontWeight.bold,
                          fontSize: 6.5,
                          color: PdfColors.black,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          pw.SizedBox(height: 14),

          // ── Examination Schedule ─────────────────────────────────────────
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text(
                'EXAMINATION SCHEDULE',
                style: pw.TextStyle(
                  fontWeight: pw.FontWeight.bold,
                  fontSize: 10,
                  color: primary,
                  letterSpacing: 1,
                ),
              ),
              pw.Container(
                padding: const pw.EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 3,
                ),
                decoration: pw.BoxDecoration(
                  color: accent,
                  borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
                ),
                child: pw.Text(
                  '${subjects.length} Subject${subjects.length == 1 ? '' : 's'}',
                  style: pw.TextStyle(
                    fontSize: 8,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.black,
                  ),
                ),
              ),
            ],
          ),
          pw.SizedBox(height: 6),

          if (subjects.isEmpty)
            pw.Container(
              padding: const pw.EdgeInsets.all(10),
              decoration: pw.BoxDecoration(
                color: PdfColors.grey100,
                borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
              ),
              child: pw.Text(
                'No subjects scheduled for this class/section.',
                style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey600),
                textAlign: pw.TextAlign.center,
              ),
            )
          else
            pw.Table(
              border: pw.TableBorder.all(
                color: PdfColors.grey300,
                width: 0.5,
              ),
              columnWidths: const {
                0: pw.FixedColumnWidth(28),
                1: pw.FlexColumnWidth(2.5),
                2: pw.FlexColumnWidth(2.2),
                3: pw.FlexColumnWidth(1.5),
              },
              children: [
                // Header
                pw.TableRow(
                  decoration: const pw.BoxDecoration(color: primary),
                  children: [
                    _tCell('#', isHeader: true),
                    _tCell('Subject', isHeader: true),
                    _tCell('Date & Day', isHeader: true),
                    _tCell('Examiner', isHeader: true),
                  ],
                ),
                ...subjects.asMap().entries.map((e) {
                  final idx = e.key;
                  final a = e.value;
                  final bg = idx.isEven ? PdfColors.white : light;
                  return pw.TableRow(
                    decoration: pw.BoxDecoration(color: bg),
                    children: [
                      _tCell('${idx + 1}', centered: true),
                      _tCell(a.subjectName),
                      _tCell(
                        '${DateFormat('dd MMM yyyy').format(a.date)}\n${DateFormat('EEEE').format(a.date)}',
                      ),
                      _tCell(
                        a.examinerName.isNotEmpty ? a.examinerName : '—',
                      ),
                    ],
                  );
                }),
              ],
            ),

          pw.Spacer(),

          // ── Instructions ─────────────────────────────────────────────────
          pw.Container(
            padding: const pw.EdgeInsets.all(10),
            decoration: pw.BoxDecoration(
              color: light,
              borderRadius: const pw.BorderRadius.all(pw.Radius.circular(5)),
              border: pw.Border.all(color: PdfColors.deepPurple200, width: 0.5),
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  'IMPORTANT INSTRUCTIONS',
                  style: pw.TextStyle(
                    fontWeight: pw.FontWeight.bold,
                    fontSize: 8,
                    color: primary,
                    letterSpacing: 0.8,
                  ),
                ),
                pw.SizedBox(height: 5),
                pw.Wrap(
                  spacing: 24,
                  runSpacing: 2,
                  children: _instructions.asMap().entries.map((e) {
                    return pw.SizedBox(
                      width: 230,
                      child: pw.Text(
                        '${e.key + 1}.  ${e.value}',
                        style: const pw.TextStyle(
                          fontSize: 7.5,
                          color: PdfColors.grey800,
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),

          pw.SizedBox(height: 14),

          // ── Signature blocks ─────────────────────────────────────────────
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            crossAxisAlignment: pw.CrossAxisAlignment.end,
            children: [
              _sigBlock('Student Signature', primary),
              _sigBlock("Parent / Guardian Signature", primary),
              _sigBlock('Principal Signature', primary),
            ],
          ),

          pw.SizedBox(height: 10),

          // ── Footer strip ─────────────────────────────────────────────────
          pw.Container(height: 1.5, color: accent),
          pw.Container(height: 3, color: primary),
          pw.SizedBox(height: 5),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text(
                'This admit card is issued by $schoolName.',
                style: const pw.TextStyle(fontSize: 7, color: PdfColors.grey600),
              ),
              pw.Text(
                'Issued: ${DateFormat('dd MMM yyyy').format(DateTime.now())}',
                style: const pw.TextStyle(fontSize: 7, color: PdfColors.grey600),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // TEMPLATE 2 – MODERN
  // Bold indigo/teal design: full-width colored header band with circular
  // school logo and student chip, left-accent colored subject cards in 2
  // columns, clean barcode footer.
  // ═══════════════════════════════════════════════════════════════════════════
  pw.Widget _buildModernTemplate({
    required Student student,
    required String className,
    required String sectionName,
    required String schoolName,
    required String schoolAddress,
    required String schoolPhone,
    required String schoolEmail,
    required pw.ImageProvider? schoolLogo,
    required pw.ImageProvider? avatar,
    required List<ExamAssignment> subjects,
  }) {
    const primary = PdfColor.fromInt(0xFF1A237E);   // deep indigo
    const secondary = PdfColor.fromInt(0xFF00695C); // deep teal
    const accent = PdfColor.fromInt(0xFFFFA000);    // amber
    const bgLight = PdfColor.fromInt(0xFFF3F4FF);

    return pw.Stack(
      children: [
        // ── Full page white background ──
        pw.Positioned.fill(child: pw.Container(color: PdfColors.white)),

        // ── Top colored band ──
        pw.Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: pw.SizedBox(
            height: 175,
            child: pw.Container(color: primary),
          ),
        ),

        // ── Decorative side bar (right) ──
        pw.Positioned(
          top: 0,
          right: 0,
          bottom: 0,
          child: pw.SizedBox(
            width: 8,
            child: pw.Container(color: secondary),
          ),
        ),

        // ── Main content ──
        pw.Padding(
          padding: const pw.EdgeInsets.fromLTRB(32, 22, 48, 24),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // ── School header ──────────────────────────────────────────
              pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.center,
                children: [
                  if (schoolLogo != null)
                    pw.Container(
                      width: 54,
                      height: 54,
                      margin: const pw.EdgeInsets.only(right: 14),
                      decoration: pw.BoxDecoration(
                        shape: pw.BoxShape.circle,
                        color: PdfColors.white,
                        border: pw.Border.all(color: accent, width: 2.5),
                        image: pw.DecorationImage(
                          image: schoolLogo,
                          fit: pw.BoxFit.contain,
                        ),
                      ),
                    ),
                  pw.Expanded(
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(
                          schoolName.toUpperCase(),
                          style: pw.TextStyle(
                            color: PdfColors.white,
                            fontWeight: pw.FontWeight.bold,
                            fontSize: 15,
                            letterSpacing: 0.5,
                          ),
                        ),
                        if (schoolAddress.isNotEmpty)
                          pw.Text(
                            schoolAddress,
                            style: const pw.TextStyle(
                              color: PdfColors.indigo100,
                              fontSize: 8,
                            ),
                          ),
                        if (schoolPhone.isNotEmpty || schoolEmail.isNotEmpty)
                          pw.Text(
                            [
                              if (schoolPhone.isNotEmpty) schoolPhone,
                              if (schoolEmail.isNotEmpty) schoolEmail,
                            ].join('  ·  '),
                            style: const pw.TextStyle(
                              color: PdfColors.indigo200,
                              fontSize: 7.5,
                            ),
                          ),
                      ],
                    ),
                  ),
                  // Admit Card badge (top-right)
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      pw.Container(
                        padding: const pw.EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 5,
                        ),
                        decoration: pw.BoxDecoration(
                          color: accent,
                          borderRadius:
                              const pw.BorderRadius.all(pw.Radius.circular(4)),
                        ),
                        child: pw.Text(
                          'ADMIT CARD',
                          style: pw.TextStyle(
                            color: PdfColors.black,
                            fontWeight: pw.FontWeight.bold,
                            fontSize: 10,
                            letterSpacing: 2,
                          ),
                        ),
                      ),
                      pw.SizedBox(height: 4),
                      pw.Text(
                        widget.exam.name,
                        style: const pw.TextStyle(
                          color: PdfColors.white,
                          fontSize: 8.5,
                        ),
                      ),
                    ],
                  ),
                ],
              ),

              pw.SizedBox(height: 14),

              // ── Student info card (floating over band boundary) ──────────
              pw.Container(
                decoration: pw.BoxDecoration(
                  color: PdfColors.white,
                  borderRadius:
                      const pw.BorderRadius.all(pw.Radius.circular(10)),
                  boxShadow: const [
                    pw.BoxShadow(
                      color: PdfColors.grey400,
                      blurRadius: 6,
                      offset: PdfPoint(0, 3),
                    ),
                  ],
                ),
                child: pw.Row(
                  crossAxisAlignment: pw.CrossAxisAlignment.stretch,
                  children: [
                    // Left accent bar
                    pw.Container(
                      width: 6,
                      decoration: const pw.BoxDecoration(
                        color: secondary,
                        borderRadius: pw.BorderRadius.only(
                          topLeft: pw.Radius.circular(10),
                          bottomLeft: pw.Radius.circular(10),
                        ),
                      ),
                    ),

                    // Photo
                    pw.Container(
                      width: 85,
                      height: 105,
                      margin: const pw.EdgeInsets.all(12),
                      decoration: pw.BoxDecoration(
                        borderRadius:
                            const pw.BorderRadius.all(pw.Radius.circular(6)),
                        border: pw.Border.all(color: secondary, width: 2),
                        color: bgLight,
                      ),
                      child: avatar != null
                          ? pw.ClipRRect(
                              horizontalRadius: 4,
                              verticalRadius: 4,
                              child: pw.Image(avatar, fit: pw.BoxFit.cover),
                            )
                          : pw.Center(
                              child: pw.Text(
                                student.user?.name.isNotEmpty == true
                                    ? student.user!.name[0].toUpperCase()
                                    : '?',
                                style: pw.TextStyle(
                                  fontSize: 34,
                                  fontWeight: pw.FontWeight.bold,
                                  color: primary,
                                ),
                              ),
                            ),
                    ),

                    // Details
                    pw.Expanded(
                      child: pw.Padding(
                        padding: const pw.EdgeInsets.symmetric(
                          vertical: 14,
                          horizontal: 10,
                        ),
                        child: pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.start,
                          mainAxisAlignment: pw.MainAxisAlignment.center,
                          children: [
                            pw.Text(
                              student.user?.name ?? 'N/A',
                              style: pw.TextStyle(
                                fontWeight: pw.FontWeight.bold,
                                fontSize: 14,
                                color: primary,
                              ),
                            ),
                            pw.SizedBox(height: 8),
                            pw.Wrap(
                              spacing: 8,
                              runSpacing: 6,
                              children: [
                                _modernChip(
                                  Icons.tag,
                                  'Roll No.',
                                  student.rollId,
                                  secondary,
                                ),
                                _modernChip(
                                  Icons.school,
                                  'Class',
                                  '$className – $sectionName',
                                  primary,
                                ),
                                if (student.user != null && student.user!.email.isNotEmpty)
                                  _modernChip(
                                    Icons.email,
                                    'Email',
                                    student.user!.email,
                                    const PdfColor.fromInt(0xFF6A1B9A),
                                  ),
                                if (student.guardianContact.isNotEmpty)
                                  _modernChip(
                                    Icons.phone,
                                    'Contact',
                                    student.guardianContact,
                                    const PdfColor.fromInt(0xFF1565C0),
                                  ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              pw.SizedBox(height: 16),

              // ── Exam period pills ────────────────────────────────────────
              if (widget.exam.startDate != null)
                pw.Row(
                  children: [
                    _modernInfoPill(
                      'Exam Start',
                      DateFormat('dd MMM yyyy').format(widget.exam.startDate!),
                      secondary,
                    ),
                    pw.SizedBox(width: 10),
                    _modernInfoPill(
                      'Exam End',
                      DateFormat('dd MMM yyyy').format(
                        widget.exam.endDate ?? widget.exam.startDate!,
                      ),
                      primary,
                    ),
                    pw.SizedBox(width: 10),
                    _modernInfoPill(
                      'Total Subjects',
                      '${subjects.length}',
                      accent,
                      textColor: PdfColors.black,
                    ),
                  ],
                ),

              pw.SizedBox(height: 14),

              // ── Schedule header ──────────────────────────────────────────
              pw.Row(
                children: [
                  pw.Container(width: 4, height: 16, color: secondary),
                  pw.SizedBox(width: 8),
                  pw.Text(
                    'EXAMINATION SCHEDULE',
                    style: pw.TextStyle(
                      fontWeight: pw.FontWeight.bold,
                      fontSize: 10,
                      color: primary,
                      letterSpacing: 1,
                    ),
                  ),
                ],
              ),
              pw.SizedBox(height: 8),

              // ── Subject cards grid ───────────────────────────────────────
              if (subjects.isEmpty)
                pw.Container(
                  padding: const pw.EdgeInsets.all(12),
                  decoration: pw.BoxDecoration(
                    color: bgLight,
                    borderRadius:
                        const pw.BorderRadius.all(pw.Radius.circular(6)),
                  ),
                  child: pw.Text(
                    'No subjects scheduled.',
                    style: const pw.TextStyle(
                      fontSize: 9,
                      color: PdfColors.grey600,
                    ),
                  ),
                )
              else
                pw.Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: subjects.asMap().entries.map((e) {
                    final i = e.key;
                    final a = e.value;
                    final colors = <PdfColor>[
                      secondary,
                      primary,
                      const PdfColor.fromInt(0xFF6A1B9A),
                      const PdfColor.fromInt(0xFF1565C0),
                      const PdfColor.fromInt(0xFF558B2F),
                      const PdfColor.fromInt(0xFF4E342E),
                    ];
                    final color = colors[i % colors.length];
                    return pw.Container(
                      width: 237,
                      padding: const pw.EdgeInsets.all(0),
                      decoration: pw.BoxDecoration(
                        border: pw.Border.all(
                          color: PdfColors.grey200,
                          width: 0.5,
                        ),
                        borderRadius:
                            const pw.BorderRadius.all(pw.Radius.circular(6)),
                      ),
                      child: pw.Row(
                        children: [
                          // Colored left bar with subject number
                          pw.Container(
                            width: 28,
                            decoration: pw.BoxDecoration(
                              color: color,
                              borderRadius: const pw.BorderRadius.only(
                                topLeft: pw.Radius.circular(5),
                                bottomLeft: pw.Radius.circular(5),
                              ),
                            ),
                            child: pw.Center(
                              child: pw.Text(
                                '${i + 1}',
                                style: pw.TextStyle(
                                  color: PdfColors.white,
                                  fontWeight: pw.FontWeight.bold,
                                  fontSize: 11,
                                ),
                              ),
                            ),
                          ),
                          pw.Expanded(
                            child: pw.Padding(
                              padding: const pw.EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 6,
                              ),
                              child: pw.Column(
                                crossAxisAlignment: pw.CrossAxisAlignment.start,
                                children: [
                                  pw.Text(
                                    a.subjectName,
                                    style: pw.TextStyle(
                                      fontWeight: pw.FontWeight.bold,
                                      fontSize: 9,
                                      color: primary,
                                    ),
                                    maxLines: 1,
                                  ),
                                  pw.SizedBox(height: 2),
                                  pw.Text(
                                    DateFormat('EEE, dd MMM yyyy').format(a.date),
                                    style: const pw.TextStyle(
                                      fontSize: 7.5,
                                      color: PdfColors.grey700,
                                    ),
                                  ),
                                  if (a.examinerName.isNotEmpty)
                                    pw.Text(
                                      'Examiner: ${a.examinerName}',
                                      style: const pw.TextStyle(
                                        fontSize: 7,
                                        color: PdfColors.grey500,
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),

              pw.Spacer(),

              // ── Instructions ─────────────────────────────────────────────
              pw.Container(
                padding: const pw.EdgeInsets.all(10),
                decoration: pw.BoxDecoration(
                  color: bgLight,
                  borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
                  border: pw.Border.all(color: PdfColors.indigo100, width: 0.5),
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      'INSTRUCTIONS',
                      style: pw.TextStyle(
                        fontWeight: pw.FontWeight.bold,
                        fontSize: 8,
                        color: primary,
                        letterSpacing: 0.8,
                      ),
                    ),
                    pw.SizedBox(height: 4),
                    pw.Wrap(
                      spacing: 24,
                      runSpacing: 2,
                      children: _instructions.asMap().entries.map((e) {
                        return pw.SizedBox(
                          width: 228,
                          child: pw.Text(
                            '${e.key + 1}.  ${e.value}',
                            style: const pw.TextStyle(
                              fontSize: 7.5,
                              color: PdfColors.grey800,
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),

              pw.SizedBox(height: 12),

              // ── Signature + barcode row ───────────────────────────────────
              pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.end,
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  _sigBlock('Student Signature', primary),
                  // Barcode
                  pw.Column(
                    children: [
                      pw.BarcodeWidget(
                        data: student.userId.isNotEmpty
                            ? student.userId
                            : student.rollId,
                        barcode: pw.Barcode.code128(),
                        width: 90,
                        height: 28,
                        drawText: false,
                        color: primary,
                      ),
                      pw.SizedBox(height: 2),
                      pw.Text(
                        student.rollId,
                        style: const pw.TextStyle(
                          fontSize: 7,
                          color: PdfColors.grey600,
                        ),
                      ),
                    ],
                  ),
                  _sigBlock('Principal Signature', primary),
                ],
              ),

              pw.SizedBox(height: 8),

              // ── Footer ───────────────────────────────────────────────────
              pw.Container(
                padding: const pw.EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: const pw.BoxDecoration(color: primary),
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text(
                      '$schoolName  ·  Issued ${DateFormat('dd MMM yyyy').format(DateTime.now())}',
                      style: const pw.TextStyle(
                        fontSize: 7,
                        color: PdfColors.white,
                      ),
                    ),
                    pw.Text(
                      'NOT VALID WITHOUT OFFICIAL SEAL',
                      style: pw.TextStyle(
                        fontSize: 7,
                        color: accent,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // TEMPLATE 3 – MINIMAL
  // Elegant double-border monochrome: centered letterhead, strong
  // typographic hierarchy, ruled table, formal numbered instructions,
  // three signature blocks with official seal placeholder.
  // ═══════════════════════════════════════════════════════════════════════════
  pw.Widget _buildMinimalTemplate({
    required Student student,
    required String className,
    required String sectionName,
    required String schoolName,
    required String schoolAddress,
    required String schoolPhone,
    required String schoolEmail,
    required pw.ImageProvider? schoolLogo,
    required pw.ImageProvider? avatar,
    required List<ExamAssignment> subjects,
  }) {
    return pw.Container(
      color: PdfColors.white,
      child: pw.Stack(
        children: [
          // ── Outer double border ──
          pw.Positioned.fill(
            child: pw.Container(
              margin: const pw.EdgeInsets.all(10),
              decoration: pw.BoxDecoration(
                border: pw.Border.all(color: PdfColors.black, width: 2),
              ),
            ),
          ),
          pw.Positioned.fill(
            child: pw.Container(
              margin: const pw.EdgeInsets.all(14),
              decoration: pw.BoxDecoration(
                border: pw.Border.all(color: PdfColors.black, width: 0.5),
              ),
            ),
          ),

          // ── Content ──
          pw.Padding(
            padding: const pw.EdgeInsets.fromLTRB(30, 24, 30, 22),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.stretch,
              children: [
                // ── School letterhead ───────────────────────────────────
                pw.Row(
                  crossAxisAlignment: pw.CrossAxisAlignment.center,
                  mainAxisAlignment: pw.MainAxisAlignment.center,
                  children: [
                    if (schoolLogo != null)
                      pw.Container(
                        width: 52,
                        height: 52,
                        margin: const pw.EdgeInsets.only(right: 14),
                        child: pw.Image(schoolLogo, fit: pw.BoxFit.contain),
                      ),
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.center,
                      children: [
                        pw.Text(
                          schoolName.toUpperCase(),
                          textAlign: pw.TextAlign.center,
                          style: pw.TextStyle(
                            fontWeight: pw.FontWeight.bold,
                            fontSize: 17,
                            letterSpacing: 1.5,
                          ),
                        ),
                        if (schoolAddress.isNotEmpty)
                          pw.Text(
                            schoolAddress,
                            textAlign: pw.TextAlign.center,
                            style: const pw.TextStyle(
                              fontSize: 8.5,
                              color: PdfColors.grey700,
                            ),
                          ),
                        if (schoolPhone.isNotEmpty || schoolEmail.isNotEmpty)
                          pw.Text(
                            [
                              if (schoolPhone.isNotEmpty) 'Ph: $schoolPhone',
                              if (schoolEmail.isNotEmpty) schoolEmail,
                            ].join('     '),
                            textAlign: pw.TextAlign.center,
                            style: const pw.TextStyle(
                              fontSize: 8,
                              color: PdfColors.grey600,
                            ),
                          ),
                      ],
                    ),
                  ],
                ),

                pw.SizedBox(height: 10),
                pw.Divider(thickness: 2, color: PdfColors.black),
                pw.SizedBox(height: 2),
                pw.Divider(thickness: 0.5, color: PdfColors.black),
                pw.SizedBox(height: 8),

                // ── ADMIT CARD heading ────────────────────────────────────
                pw.Center(
                  child: pw.Text(
                    'ADMIT CARD',
                    style: pw.TextStyle(
                      fontWeight: pw.FontWeight.bold,
                      fontSize: 20,
                      letterSpacing: 6,
                    ),
                  ),
                ),
                pw.Center(
                  child: pw.Text(
                    widget.exam.name.toUpperCase(),
                    style: pw.TextStyle(
                      fontWeight: pw.FontWeight.bold,
                      fontSize: 11,
                      letterSpacing: 2,
                      color: PdfColors.grey700,
                    ),
                  ),
                ),
                if (widget.exam.startDate != null) ...[
                  pw.SizedBox(height: 3),
                  pw.Center(
                    child: pw.Text(
                      '${DateFormat('dd MMMM yyyy').format(widget.exam.startDate!)}  to  ${DateFormat('dd MMMM yyyy').format(widget.exam.endDate ?? widget.exam.startDate!)}',
                      style: const pw.TextStyle(
                        fontSize: 8.5,
                        color: PdfColors.grey600,
                      ),
                    ),
                  ),
                ],

                pw.SizedBox(height: 8),
                pw.Divider(thickness: 0.5, color: PdfColors.black),
                pw.SizedBox(height: 10),

                // ── Student details + photo ────────────────────────────────
                pw.Row(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    // Photo
                    pw.Container(
                      width: 85,
                      height: 105,
                      margin: const pw.EdgeInsets.only(right: 20),
                      decoration: pw.BoxDecoration(
                        border: pw.Border.all(color: PdfColors.black, width: 1),
                      ),
                      child: avatar != null
                          ? pw.Image(avatar, fit: pw.BoxFit.cover)
                          : pw.Center(
                              child: pw.Column(
                                mainAxisAlignment: pw.MainAxisAlignment.center,
                                children: [
                                  pw.Text(
                                    'PHOTO',
                                    style: pw.TextStyle(
                                      fontWeight: pw.FontWeight.bold,
                                      fontSize: 10,
                                      color: PdfColors.grey500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                    ),

                    // Details
                    pw.Expanded(
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          _minimalField('Name of Student', student.user?.name ?? 'N/A', big: true),
                          pw.SizedBox(height: 5),
                          pw.Row(
                            children: [
                              pw.Expanded(
                                child: _minimalField('Roll No.', student.rollId),
                              ),
                              pw.SizedBox(width: 16),
                              pw.Expanded(
                                child: _minimalField('Class / Section', '$className – $sectionName'),
                              ),
                            ],
                          ),
                          pw.SizedBox(height: 5),
                          pw.Row(
                            children: [
                              pw.Expanded(
                                child: _minimalField(
                                  'Guardian Contact',
                                  student.guardianContact.isNotEmpty
                                      ? student.guardianContact
                                      : (student.user?.phone ?? 'N/A'),
                                ),
                              ),
                              pw.SizedBox(width: 16),
                              pw.Expanded(
                                child: _minimalField(
                                  'Email Address',
                                  student.user?.email ?? 'N/A',
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                pw.SizedBox(height: 12),
                pw.Divider(thickness: 0.5, color: PdfColors.black),
                pw.SizedBox(height: 8),

                // ── Schedule table ─────────────────────────────────────────
                pw.Text(
                  'EXAMINATION SCHEDULE',
                  style: pw.TextStyle(
                    fontWeight: pw.FontWeight.bold,
                    fontSize: 10,
                    letterSpacing: 1,
                  ),
                ),
                pw.SizedBox(height: 6),

                if (subjects.isEmpty)
                  pw.Text(
                    'No subjects scheduled for this class/section.',
                    style: const pw.TextStyle(
                      fontSize: 9,
                      color: PdfColors.grey500,
                    ),
                  )
                else
                  pw.Table(
                    border: pw.TableBorder.all(
                      color: PdfColors.black,
                      width: 0.5,
                    ),
                    columnWidths: const {
                      0: pw.FixedColumnWidth(26),
                      1: pw.FlexColumnWidth(2.5),
                      2: pw.FlexColumnWidth(2.0),
                      3: pw.FlexColumnWidth(1.4),
                    },
                    children: [
                      pw.TableRow(
                        decoration: const pw.BoxDecoration(
                          color: PdfColors.grey800,
                        ),
                        children: [
                          _tCell('SL', isHeader: true, centered: true),
                          _tCell('Subject Name', isHeader: true),
                          _tCell('Date & Day', isHeader: true),
                          _tCell('Examiner', isHeader: true),
                        ],
                      ),
                      ...subjects.asMap().entries.map((e) {
                        final i = e.key;
                        final a = e.value;
                        final bg = i.isEven ? PdfColors.white : PdfColors.grey100;
                        return pw.TableRow(
                          decoration: pw.BoxDecoration(color: bg),
                          children: [
                            _tCell('${i + 1}', centered: true, textColor: PdfColors.black),
                            _tCell(a.subjectName, textColor: PdfColors.black),
                            _tCell(
                              '${DateFormat('dd/MM/yyyy').format(a.date)}  (${DateFormat('EEE').format(a.date)})',
                              textColor: PdfColors.black,
                            ),
                            _tCell(
                              a.examinerName.isNotEmpty ? a.examinerName : '—',
                              textColor: PdfColors.black,
                            ),
                          ],
                        );
                      }),
                    ],
                  ),

                pw.Spacer(),

                // ── Instructions ─────────────────────────────────────────
                pw.Text(
                  'INSTRUCTIONS TO CANDIDATES:',
                  style: pw.TextStyle(
                    fontWeight: pw.FontWeight.bold,
                    fontSize: 8.5,
                    letterSpacing: 0.5,
                  ),
                ),
                pw.SizedBox(height: 5),
                pw.Table(
                  columnWidths: const {
                    0: pw.FixedColumnWidth(12),
                    1: pw.FlexColumnWidth(1),
                    2: pw.FixedColumnWidth(12),
                    3: pw.FlexColumnWidth(1),
                  },
                  children: List.generate(
                    (_instructions.length / 2).ceil(),
                    (row) {
                      final left = row * 2;
                      final right = left + 1;
                      return pw.TableRow(
                        children: [
                          pw.Padding(
                            padding: const pw.EdgeInsets.only(bottom: 2),
                            child: pw.Text(
                              '${left + 1}.',
                              style: pw.TextStyle(
                                fontWeight: pw.FontWeight.bold,
                                fontSize: 7.5,
                              ),
                            ),
                          ),
                          pw.Padding(
                            padding: const pw.EdgeInsets.only(bottom: 2, right: 10),
                            child: pw.Text(
                              _instructions[left],
                              style: const pw.TextStyle(fontSize: 7.5),
                            ),
                          ),
                          pw.Padding(
                            padding: const pw.EdgeInsets.only(bottom: 2),
                            child: pw.Text(
                              right < _instructions.length ? '${right + 1}.' : '',
                              style: pw.TextStyle(
                                fontWeight: pw.FontWeight.bold,
                                fontSize: 7.5,
                              ),
                            ),
                          ),
                          pw.Padding(
                            padding: const pw.EdgeInsets.only(bottom: 2),
                            child: pw.Text(
                              right < _instructions.length
                                  ? _instructions[right]
                                  : '',
                              style: const pw.TextStyle(fontSize: 7.5),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),

                pw.SizedBox(height: 12),
                pw.Divider(thickness: 0.5, color: PdfColors.black),
                pw.SizedBox(height: 10),

                // ── Signature blocks ──────────────────────────────────────
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                  children: [
                    _minimalSigBlock("Student's Signature"),
                    // Official seal placeholder
                    pw.Container(
                      width: 70,
                      height: 70,
                      decoration: pw.BoxDecoration(
                        border: pw.Border.all(
                          color: PdfColors.grey400,
                          width: 0.8,
                        ),
                        shape: pw.BoxShape.circle,
                      ),
                      child: pw.Center(
                        child: pw.Text(
                          'OFFICIAL\nSEAL',
                          textAlign: pw.TextAlign.center,
                          style: const pw.TextStyle(
                            fontSize: 8,
                            color: PdfColors.grey500,
                          ),
                        ),
                      ),
                    ),
                    _minimalSigBlock("Principal's Signature"),
                  ],
                ),

                pw.SizedBox(height: 8),
                pw.Divider(thickness: 0.5),
                pw.SizedBox(height: 4),
                pw.Center(
                  child: pw.Text(
                    'This admit card is computer-generated by $schoolName. Issued on ${DateFormat('dd MMMM yyyy').format(DateTime.now())}.',
                    textAlign: pw.TextAlign.center,
                    style: const pw.TextStyle(
                      fontSize: 7,
                      color: PdfColors.grey500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // TEMPLATE 4 – COMPACT  (no exam schedule · 6 cards per A4 page)
  // ═══════════════════════════════════════════════════════════════════════════
  pw.Widget _buildCompactCard({
    required Student student,
    required String className,
    required String sectionName,
    required String schoolName,
    required pw.ImageProvider? schoolLogo,
    required pw.ImageProvider? avatar,
  }) {
    const primary = PdfColor.fromInt(0xFF00695C);  // teal 800
    const accent = PdfColor.fromInt(0xFFFFA000);   // amber 700
    const bgLight = PdfColor.fromInt(0xFFE0F2F1);  // teal 50

    return pw.Container(
      decoration: pw.BoxDecoration(
        color: PdfColors.white,
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(7)),
        border: pw.Border.all(color: primary, width: 1.2),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.stretch,
        children: [
          // ── Header bar ────────────────────────────────────────────────
          pw.Container(
            padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            decoration: const pw.BoxDecoration(
              color: primary,
              borderRadius: pw.BorderRadius.only(
                topLeft: pw.Radius.circular(6),
                topRight: pw.Radius.circular(6),
              ),
            ),
            child: pw.Row(
              children: [
                if (schoolLogo != null)
                  pw.Container(
                    width: 22,
                    height: 22,
                    margin: const pw.EdgeInsets.only(right: 7),
                    decoration: pw.BoxDecoration(
                      shape: pw.BoxShape.circle,
                      color: PdfColors.white,
                      image: pw.DecorationImage(
                        image: schoolLogo,
                        fit: pw.BoxFit.contain,
                      ),
                    ),
                  ),
                pw.Expanded(
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        schoolName.toUpperCase(),
                        style: pw.TextStyle(
                          color: PdfColors.white,
                          fontWeight: pw.FontWeight.bold,
                          fontSize: 7,
                        ),
                        maxLines: 1,
                      ),
                      pw.Text(
                        'ADMIT CARD',
                        style: const pw.TextStyle(
                          color: PdfColors.teal100,
                          fontSize: 6,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ],
                  ),
                ),
                pw.Container(
                  padding: const pw.EdgeInsets.symmetric(
                    horizontal: 5,
                    vertical: 2,
                  ),
                  decoration: pw.BoxDecoration(
                    color: accent,
                    borderRadius:
                        const pw.BorderRadius.all(pw.Radius.circular(3)),
                  ),
                  child: pw.Text(
                    widget.exam.name,
                    style: pw.TextStyle(
                      fontSize: 5.5,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.black,
                    ),
                    maxLines: 2,
                  ),
                ),
              ],
            ),
          ),

          // ── Body ─────────────────────────────────────────────────────
          pw.Expanded(
            child: pw.Padding(
              padding: const pw.EdgeInsets.all(8),
              child: pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.center,
                children: [
                  // Photo
                  pw.Container(
                    width: 46,
                    height: 56,
                    margin: const pw.EdgeInsets.only(right: 9),
                    decoration: pw.BoxDecoration(
                      border: pw.Border.all(color: primary, width: 1),
                      borderRadius:
                          const pw.BorderRadius.all(pw.Radius.circular(4)),
                      color: bgLight,
                    ),
                    child: avatar != null
                        ? pw.ClipRRect(
                            horizontalRadius: 3,
                            verticalRadius: 3,
                            child: pw.Image(avatar, fit: pw.BoxFit.cover),
                          )
                        : pw.Center(
                            child: pw.Text(
                              student.user?.name.isNotEmpty == true
                                  ? student.user!.name[0].toUpperCase()
                                  : '?',
                              style: pw.TextStyle(
                                fontSize: 18,
                                fontWeight: pw.FontWeight.bold,
                                color: primary,
                              ),
                            ),
                          ),
                  ),
                  // Student info
                  pw.Expanded(
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      mainAxisAlignment: pw.MainAxisAlignment.center,
                      children: [
                        pw.Text(
                          student.user?.name ?? 'N/A',
                          style: pw.TextStyle(
                            fontWeight: pw.FontWeight.bold,
                            fontSize: 8.5,
                            color: primary,
                          ),
                          maxLines: 1,
                        ),
                        pw.SizedBox(height: 4),
                        _cRow('Roll No.', student.rollId, primary),
                        _cRow('Class', '$className – $sectionName', primary),
                        if (widget.exam.startDate != null)
                          _cRow(
                            'Period',
                            '${DateFormat('dd/MM/yy').format(widget.exam.startDate!)} – '
                                '${DateFormat('dd/MM/yy').format(widget.exam.endDate ?? widget.exam.startDate!)}',
                            primary,
                          ),
                        if (student.guardianContact.isNotEmpty)
                          _cRow('Contact', student.guardianContact, primary),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ── Signature footer ──────────────────────────────────────────
          pw.Container(
            padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: const pw.BoxDecoration(
              color: bgLight,
              borderRadius: pw.BorderRadius.only(
                bottomLeft: pw.Radius.circular(6),
                bottomRight: pw.Radius.circular(6),
              ),
            ),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Container(
                      width: 72,
                      child: pw.Divider(color: PdfColors.grey500, thickness: 0.5),
                    ),
                    pw.Text(
                      "Student",
                      style: const pw.TextStyle(
                        fontSize: 6,
                        color: PdfColors.grey700,
                      ),
                    ),
                  ],
                ),
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                  children: [
                    pw.Container(
                      width: 72,
                      child: pw.Divider(color: PdfColors.grey500, thickness: 0.5),
                    ),
                    pw.Text(
                      "Principal",
                      style: const pw.TextStyle(
                        fontSize: 6,
                        color: PdfColors.grey700,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ───────────────────────────────────────────────────────────────────────────
  // Shared PDF helper widgets
  // ───────────────────────────────────────────────────────────────────────────

  /// Classic: labeled field with bottom underline
  pw.Widget _classicField(
    String label,
    String value, {
    required PdfColor primary,
    bool big = false,
  }) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          label.toUpperCase(),
          style: pw.TextStyle(
            fontSize: 7,
            color: PdfColors.grey500,
            fontWeight: pw.FontWeight.bold,
            letterSpacing: 0.5,
          ),
        ),
        pw.SizedBox(height: 2),
        pw.Text(
          value,
          style: pw.TextStyle(
            fontSize: big ? 12 : 9.5,
            fontWeight: pw.FontWeight.bold,
            color: PdfColors.black,
          ),
          maxLines: 1,
        ),
        pw.Container(height: 0.5, color: PdfColors.grey300),
      ],
    );
  }

  /// Minimal: simple label-value row with dotted underline
  pw.Widget _minimalField(String label, String value, {bool big = false}) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          label,
          style: const pw.TextStyle(fontSize: 7, color: PdfColors.grey600),
        ),
        pw.SizedBox(height: 1),
        pw.Text(
          value,
          style: pw.TextStyle(
            fontSize: big ? 11 : 9,
            fontWeight: pw.FontWeight.bold,
          ),
        ),
        pw.Divider(color: PdfColors.grey400, thickness: 0.5),
      ],
    );
  }

  /// Modern: icon + label + value chip
  pw.Widget _modernChip(
    IconData icon,
    String label,
    String value,
    PdfColor color,
  ) {
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: pw.BoxDecoration(
        color: PdfColor(color.red, color.green, color.blue, 0.08),
        border: pw.Border.all(
          color: PdfColor(color.red, color.green, color.blue, 0.3),
          width: 0.5,
        ),
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(20)),
      ),
      child: pw.Row(
        mainAxisSize: pw.MainAxisSize.min,
        children: [
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                label.toUpperCase(),
                style: pw.TextStyle(
                  fontSize: 5.5,
                  color: color,
                  fontWeight: pw.FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
              pw.Text(
                value,
                style: pw.TextStyle(
                  fontSize: 8,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.black,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  pw.Widget _modernInfoPill(
    String label,
    String value,
    PdfColor color, {
    PdfColor textColor = PdfColors.white,
  }) {
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: pw.BoxDecoration(
        color: color,
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(20)),
      ),
      child: pw.Column(
        children: [
          pw.Text(
            label.toUpperCase(),
            style: pw.TextStyle(
              fontSize: 5.5,
              color: PdfColor(
                textColor.red,
                textColor.green,
                textColor.blue,
                0.7,
              ),
              letterSpacing: 0.5,
            ),
          ),
          pw.Text(
            value,
            style: pw.TextStyle(
              fontSize: 9,
              fontWeight: pw.FontWeight.bold,
              color: textColor,
            ),
          ),
        ],
      ),
    );
  }

  /// Table cell used by Classic and Minimal schedule tables
  pw.Widget _tCell(
    String text, {
    bool isHeader = false,
    bool centered = false,
    PdfColor textColor = PdfColors.white,
  }) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 5),
      child: pw.Text(
        text,
        textAlign: centered ? pw.TextAlign.center : pw.TextAlign.left,
        style: pw.TextStyle(
          fontSize: 8.5,
          fontWeight: isHeader ? pw.FontWeight.bold : pw.FontWeight.normal,
          color: isHeader ? textColor : PdfColors.black,
        ),
      ),
    );
  }

  /// Compact row helper
  pw.Widget _cRow(String label, String value, PdfColor accent) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 2.5),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            '$label: ',
            style: pw.TextStyle(
              fontWeight: pw.FontWeight.bold,
              fontSize: 7,
              color: accent,
            ),
          ),
          pw.Expanded(
            child: pw.Text(
              value,
              style: const pw.TextStyle(fontSize: 7, color: PdfColors.black),
              maxLines: 1,
            ),
          ),
        ],
      ),
    );
  }

  /// Signature block used by Classic and Modern
  pw.Widget _sigBlock(String label, PdfColor lineColor) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.center,
      children: [
        pw.Container(
          width: 100,
          child: pw.Divider(color: lineColor, thickness: 0.8),
        ),
        pw.SizedBox(height: 3),
        pw.Text(
          label,
          style: const pw.TextStyle(fontSize: 7.5, color: PdfColors.grey700),
          textAlign: pw.TextAlign.center,
        ),
      ],
    );
  }

  /// Signature block for Minimal template
  pw.Widget _minimalSigBlock(String label) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.center,
      children: [
        pw.Container(width: 110),
        pw.SizedBox(height: 30),
        pw.Container(
          width: 110,
          child: pw.Divider(color: PdfColors.black, thickness: 0.8),
        ),
        pw.Text(
          label,
          style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey700),
        ),
      ],
    );
  }

  static const List<String> _instructions = [
    'This admit card must be presented at the exam hall.',
    'Report 30 minutes before the scheduled start time.',
    'Mobile phones & electronic devices are prohibited.',
    'No candidate will be admitted after the exam begins.',
    'The card is non-transferable; carry a photo ID.',
    'Maintain silence and discipline throughout the exam.',
  ];

  // ───────────────────────────────────────────────────────────────────────────
  // Flutter UI
  // ───────────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final allClasses = context.watch<ClassSetupNotifier>().classes;
    final allSections = context.watch<SectionSetupNotifier>().sections;

    // ── Build class list: setup notifier + exam assignments as fallback ──────
    final uniqueClasses = <String, String>{};
    for (final c in allClasses) {
      uniqueClasses[c.id] = c.name;
    }
    // Seed from exam assignments so classes always show even before setup loads
    for (final a in widget.exam.assignments) {
      if (!uniqueClasses.containsKey(a.classId) && a.className.isNotEmpty) {
        uniqueClasses[a.classId] = a.className;
      }
    }

    // ── Build section list for the selected class ────────────────────────────
    final uniqueSections = <String, String>{};
    if (_selectedClassId != null) {
      for (final s in allSections) {
        if (s.classId == _selectedClassId) uniqueSections[s.id] = s.name;
      }
      // Seed from exam assignments for this class
      for (final a in widget.exam.assignments) {
        if (a.classId == _selectedClassId &&
            a.sectionId != null &&
            a.sectionName != null &&
            !uniqueSections.containsKey(a.sectionId)) {
          uniqueSections[a.sectionId!] = a.sectionName!;
        }
      }
    }

    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: Text(
          'Admit Card — ${widget.exam.name}',
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        backgroundColor: AppColors.primaryAdmin,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.print_outlined),
            tooltip: 'Print',
            onPressed: _pdfBytes == null
                ? null
                : () async {
                    await Printing.layoutPdf(
                      onLayout: (_) async => _pdfBytes!,
                    );
                  },
          ),
          IconButton(
            icon: const Icon(Icons.share_outlined),
            tooltip: 'Share',
            onPressed: _pdfBytes == null
                ? null
                : () async {
                    await Printing.sharePdf(
                      bytes: _pdfBytes!,
                      filename:
                          'admit_card_${widget.exam.name.replaceAll(' ', '_')}.pdf',
                    );
                  },
          ),
        ],
      ),
      body: Column(
        children: [
          _buildTemplateSelector(),
          _buildFilters(uniqueClasses, uniqueSections),
          Expanded(child: _buildPreviewArea()),
        ],
      ),
    );
  }

  // ── Template selector ─────────────────────────────────────────────────────
  Widget _buildTemplateSelector() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.palette_outlined, size: 16, color: Colors.grey),
              const SizedBox(width: 6),
              const Text(
                'Choose Template',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const Spacer(),
              Text(
                _selectedTemplate.description,
                style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: AdmitCardTemplate.values.map((t) {
              final isSelected = t == _selectedTemplate;
              return Expanded(
                child: GestureDetector(
                  onTap: () {
                    if (_selectedTemplate != t) {
                      setState(() => _selectedTemplate = t);
                      _generatePdf();
                    }
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    padding: const EdgeInsets.symmetric(
                      vertical: 10,
                      horizontal: 6,
                    ),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? t.accentColor.withValues(alpha: 0.08)
                          : Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: isSelected
                            ? t.accentColor
                            : Colors.grey.shade200,
                        width: isSelected ? 2 : 1,
                      ),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          t.icon,
                          color:
                              isSelected ? t.accentColor : Colors.grey.shade400,
                          size: 22,
                        ),
                        const SizedBox(height: 5),
                        Text(
                          t.label,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: isSelected
                                ? FontWeight.bold
                                : FontWeight.w500,
                            color: isSelected
                                ? t.accentColor
                                : Colors.grey.shade600,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        if (isSelected) ...[
                          const SizedBox(height: 4),
                          Container(
                            width: 20,
                            height: 3,
                            decoration: BoxDecoration(
                              color: t.accentColor,
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  // ── Class / section filters ────────────────────────────────────────────────
  Widget _buildFilters(
    Map<String, String> uniqueClasses,
    Map<String, String> uniqueSections,
  ) {
    // Ensure the current value is valid for the dropdown or fall back to null
    final classDropdownValue = uniqueClasses.containsKey(_selectedClassId)
        ? _selectedClassId
        : null;
    final sectionDropdownValue = uniqueSections.containsKey(_selectedSectionId)
        ? _selectedSectionId
        : null;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.primaryAdmin.withValues(alpha: 0.04),
        border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
      ),
      child: Row(
        children: [
          const Icon(Icons.filter_list, size: 16, color: AppColors.primaryAdmin),
          const SizedBox(width: 8),

          // ── Class dropdown ──────────────────────────────────────────────
          Expanded(
            child: _buildDropdown<String?>(
              label: 'Class',
              value: classDropdownValue,
              items: [
                const DropdownMenuItem<String?>(
                  value: null,
                  child: Text('Select Class'),
                ),
                ...uniqueClasses.entries.map(
                  (e) => DropdownMenuItem<String?>(
                    value: e.key,
                    child: Text(e.value),
                  ),
                ),
              ],
              onChanged: (val) {
                if (val != _selectedClassId) {
                  setState(() {
                    _selectedClassId = val;
                    _selectedSectionId = null;
                  });
                  if (val != null) _fetchStudents();
                }
              },
            ),
          ),

          // ── Section dropdown (only when sections exist for the class) ───
          if (uniqueSections.isNotEmpty) ...[
            const SizedBox(width: 12),
            Expanded(
              child: _buildDropdown<String?>(
                label: 'Section',
                value: sectionDropdownValue,
                items: [
                  const DropdownMenuItem<String?>(
                    value: null,
                    child: Text('All Sections'),
                  ),
                  ...uniqueSections.entries.map(
                    (e) => DropdownMenuItem<String?>(
                      value: e.key,
                      child: Text(e.value),
                    ),
                  ),
                ],
                onChanged: (val) {
                  if (val != _selectedSectionId) {
                    setState(() => _selectedSectionId = val);
                    _fetchStudents();
                  }
                },
              ),
            ),
          ],

          const SizedBox(width: 12),

          // ── Student count badge ─────────────────────────────────────────
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.primaryAdmin.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              '${_currentStudents.length} Student${_currentStudents.length == 1 ? '' : 's'}',
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: AppColors.primaryAdmin,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDropdown<T>({
    required String label,
    required T? value,
    required List<DropdownMenuItem<T>> items,
    required ValueChanged<T?> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.bold,
            color: AppColors.primaryAdmin,
          ),
        ),
        const SizedBox(height: 3),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: AppColors.primaryAdmin.withValues(alpha: 0.3),
            ),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<T>(
              value: value,
              items: items,
              onChanged: onChanged,
              isExpanded: true,
              isDense: true,
              icon: const Icon(
                Icons.keyboard_arrow_down,
                color: AppColors.primaryAdmin,
                size: 20,
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ── PDF preview ───────────────────────────────────────────────────────────
  Widget _buildPreviewArea() {
    if (_isLoading || _pdfBytes == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            Text(
              'Generating admit cards…',
              style: TextStyle(color: Colors.grey.shade600),
            ),
          ],
        ),
      );
    }
    if (_currentStudents.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.person_off_outlined,
                size: 64, color: Colors.grey.shade300),
            const SizedBox(height: 16),
            Text(
              'No students found for the selected class / section.',
              style: TextStyle(color: Colors.grey.shade500, fontSize: 14),
            ),
          ],
        ),
      );
    }
    return pdfx.PdfViewPinch(controller: _pdfController!);
  }
}
