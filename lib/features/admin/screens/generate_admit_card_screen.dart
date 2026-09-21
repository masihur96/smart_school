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
// Enum - available admit card templates
// ─────────────────────────────────────────────────────────────────────────────
enum AdmitCardTemplate { classic, modern, minimal, compact, halfPage }

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
      case AdmitCardTemplate.halfPage:
        return 'Half Page\n(2/page)';
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
      case AdmitCardTemplate.halfPage:
        return Icons.view_agenda_outlined;
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
      case AdmitCardTemplate.halfPage:
        return Colors.indigo;
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
      case AdmitCardTemplate.halfPage:
        return '2 cards per page, clear UI';
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
  bool _isLoading = true;
  String? _errorMsg;
  Uint8List? _pdfBytes;
  pdfx.PdfControllerPinch? _pdfController;
  AdmitCardTemplate _selectedTemplate = AdmitCardTemplate.classic;
  final TextEditingController _instructionController = TextEditingController();
  String _topInstruction = '';
  List<Student> _allFetchedStudents = [];
  List<String> _excludedStudentIds = [];

  @override
  void dispose() {
    _instructionController.dispose();
    _pdfController?.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _currentStudents = List.from(widget.students);
    _allFetchedStudents = List.from(widget.students);
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
          _errorMsg = null;
        });
      }
    } catch (e, st) {
      print('PDF Generation Error: $e');
      print(st);
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMsg = e.toString();
        });
      }
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
              _excludedStudentIds.clear();
              _allFetchedStudents = List.from(
                context.read<StudentsNotifier>().students,
              );
              _currentStudents = List.from(_allFetchedStudents);
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
        final a = widget.exam.assignments.firstWhere(
          (a) => a.classId == _selectedClassId,
          orElse: () => widget.exam.assignments.first,
        );
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
          orElse: () => widget.exam.assignments.first,
        );
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
    final signatureFontFuture = safeFont(PdfGoogleFonts.dancingScriptBold());
    final logoFuture = safeImage(schoolLogoUrl);

    final signatoryName =
        context.read<AuthNotifier>().user?.name ?? 'Principal';

    final studentIds = <String>[];
    final avatarFutures = <Future<pw.ImageProvider?>>[];
    for (final student in _currentStudents) {
      final url = student.user?.avatar ?? '';
      studentIds.add(student.userId);
      avatarFutures.add(safeImage(url));
    }

    // Wait for ALL in parallel - fastest possible loading
    final allResults = await Future.wait<Object?>([
      fontRegFuture,
      fontBoldFuture,
      signatureFontFuture,
      logoFuture,
      ...avatarFutures,
    ]);

    final fontReg = allResults[0] as pw.Font?;
    final fontBold = allResults[1] as pw.Font?;
    final signatureFont = allResults[2] as pw.Font?;
    final schoolLogo = allResults[3] as pw.ImageProvider?;
    final Map<String, pw.ImageProvider> avatars = {};
    for (var i = 0; i < studentIds.length; i++) {
      final img = allResults[4 + i] as pw.ImageProvider?;
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

    // ── Build per-student subject list ────────────────────────────────────
    // A student can belong to multiple classes (e.g. Class One AND Nurani).
    // For each student we collect ExamAssignments for ALL their classes so
    // that their admit card always shows every subject they are enrolled in,
    // regardless of which class was used as the filter to pull this cohort.
    //
    // IMPORTANT: We use student.user?.classIds (the full list stored on the
    // user record) rather than student.embeddedClasses, because the API
    // endpoint that fetches students by a specific class only populates
    // embeddedClasses with the filtered class — it does NOT return all classes
    // the student belongs to. user.classIds always contains every assigned
    // class ID regardless of which filter was used.
    List<ExamAssignment> subjectsForStudent(Student student) {
      final Set<String> studentClassIds = {
        student.classId,
        // user.classIds is the complete list of all enrolled classes
        ...?student.user?.classIds,
        // embeddedClasses as fallback (may be partial)
        ...student.embeddedClasses.map((c) => c.id),
      }.where((id) => id.isNotEmpty).toSet();

      return widget.exam.assignments
          .where((a) => studentClassIds.contains(a.classId))
          .toList()
        ..sort((a, b) => a.date.compareTo(b.date));
    }

    // ── HALF-PAGE: 2 cards per A4 page ──────────────────────────────────────
    if (_selectedTemplate == AdmitCardTemplate.halfPage) {
      const int perPage = 2;
      for (var i = 0; i < _currentStudents.length; i += perPage) {
        final pageStudents = _currentStudents.skip(i).take(perPage).toList();
        pdf.addPage(
          pw.Page(
            pageFormat: format,
            margin: const pw.EdgeInsets.all(20),
            build: (pw.Context ctx) {
              return pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.stretch,
                children: [
                  pw.Expanded(
                    child: _buildHalfPageCard(
                      student: pageStudents[0],
                      className: pageStudents[0].className?.isNotEmpty == true
                          ? pageStudents[0].className!
                          : resolvedClassName,
                      sectionName:
                          pageStudents[0].sectionName?.isNotEmpty == true
                          ? pageStudents[0].sectionName!
                          : resolvedSectionName,
                      schoolName: schoolName,
                      schoolLogo: schoolLogo,
                      avatar: avatars[pageStudents[0].userId],
                      subjects: subjectsForStudent(pageStudents[0]),
                      instruction: _topInstruction,
                      signatoryName: signatoryName,
                      signatureFont: signatureFont,
                    ),
                  ),
                  if (pageStudents.length > 1) ...[
                    pw.SizedBox(height: 20),
                    pw.Expanded(
                      child: _buildHalfPageCard(
                        student: pageStudents[1],
                        className: pageStudents[1].className?.isNotEmpty == true
                            ? pageStudents[1].className!
                            : resolvedClassName,
                        sectionName:
                            pageStudents[1].sectionName?.isNotEmpty == true
                            ? pageStudents[1].sectionName!
                            : resolvedSectionName,
                        schoolName: schoolName,
                        schoolLogo: schoolLogo,
                        avatar: avatars[pageStudents[1].userId],
                        subjects: subjectsForStudent(pageStudents[1]),
                        instruction: _topInstruction,
                        signatoryName: signatoryName,
                        signatureFont: signatureFont,
                      ),
                    ),
                  ] else
                    pw.Expanded(child: pw.SizedBox()),
                ],
              );
            },
          ),
        );
      }
      return pdf.save();
    }

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
                childAspectRatio: 1.06,
                children: pageStudents.map((student) {
                  final cn = student.className?.isNotEmpty == true
                      ? student.className!
                      : resolvedClassName;
                  final sn = student.sectionName?.isNotEmpty == true
                      ? student.sectionName!
                      : resolvedSectionName;
                  final studentSubjects = subjectsForStudent(student);
                  return _buildCompactCard(
                    student: student,
                    className: cn,
                    sectionName: sn,
                    schoolName: schoolName,
                    schoolLogo: schoolLogo,
                    avatar: avatars[student.userId],
                    subjects: studentSubjects,
                    instruction: _topInstruction,
                    signatoryName: signatoryName,
                    signatureFont: signatureFont,
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
      final studentSubjects = subjectsForStudent(student);
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
                  subjects: studentSubjects,
                  signatoryName: signatoryName,
                  signatureFont: signatureFont,
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
                  subjects: studentSubjects,
                  signatoryName: signatoryName,
                  signatureFont: signatureFont,
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
                  subjects: studentSubjects,
                  signatoryName: signatoryName,
                  signatureFont: signatureFont,
                );
              case AdmitCardTemplate.compact:
              case AdmitCardTemplate.halfPage:
                return pw.SizedBox(); // handled above
            }
          },
        ),
      );
    }

    return pdf.save();
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // TEMPLATE 1 - CLASSIC  (redesigned for 15+ subjects on one A4 page)
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
    String? signatoryName,
    pw.Font? signatureFont,
  }) {
    const primary = PdfColors.deepPurple800;
    const accent = PdfColors.amber700;
    const light = PdfColors.deepPurple50;

    final half = (subjects.length / 2).ceil();
    final leftSubjects = subjects.take(half).toList();
    final rightSubjects = subjects.skip(half).toList();

    pw.Widget subjectTable(List<ExamAssignment> rows, int startIndex) {
      if (rows.isEmpty) return pw.SizedBox();
      return pw.Table(
        border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
        columnWidths: const {
          0: pw.FixedColumnWidth(22),
          1: pw.FlexColumnWidth(2.5),
          2: pw.FlexColumnWidth(2.2),
        },
        children: [
          pw.TableRow(
            decoration: const pw.BoxDecoration(color: primary),
            children: [
              _tCell('#', isHeader: true, fontSize: 8.5),
              _tCell('Subject', isHeader: true, fontSize: 8.5),
              _tCell('Date / Day', isHeader: true, fontSize: 8.5),
            ],
          ),
          ...rows.asMap().entries.map((e) {
            final idx = startIndex + e.key;
            final a = e.value;
            final bg = idx.isEven ? PdfColors.white : light;
            return pw.TableRow(
              decoration: pw.BoxDecoration(color: bg),
              children: [
                _tCell('${idx + 1}', centered: true, fontSize: 8.5),
                _tCell(a.subjectName, fontSize: 8.5),
                _tCell(
                  '${DateFormat('dd/MM/yy').format(a.date)} (${DateFormat('EEE').format(a.date)})',
                  fontSize: 8.5,
                ),
              ],
            );
          }),
        ],
      );
    }

    return pw.Container(
      color: PdfColors.white,
      padding: const pw.EdgeInsets.fromLTRB(32, 24, 32, 24),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.stretch,
        children: [
          // ── Header / Letterhead ─────────────────────────────────────────
          pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.center,
            children: [
              if (schoolLogo != null)
                pw.Container(
                  width: 55,
                  height: 55,
                  margin: const pw.EdgeInsets.only(right: 15),
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
                        letterSpacing: 1.2,
                      ),
                    ),
                    pw.SizedBox(height: 3),
                    if (schoolAddress.isNotEmpty)
                      pw.Text(
                        schoolAddress,
                        textAlign: pw.TextAlign.center,
                        style: const pw.TextStyle(
                          fontSize: 9,
                          color: PdfColors.grey700,
                        ),
                      ),
                    if (schoolPhone.isNotEmpty || schoolEmail.isNotEmpty) ...[
                      pw.SizedBox(height: 2),
                      pw.Text(
                        [
                          if (schoolPhone.isNotEmpty) 'Ph: $schoolPhone',
                          if (schoolEmail.isNotEmpty) 'Email: $schoolEmail',
                        ].join('   |   '),
                        textAlign: pw.TextAlign.center,
                        style: const pw.TextStyle(
                          fontSize: 8.5,
                          color: PdfColors.grey600,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (schoolLogo != null)
                pw.SizedBox(width: 70), // Balance logo on left
            ],
          ),

          pw.SizedBox(height: 8),
          pw.Container(height: 2.5, color: primary),
          pw.Container(height: 1.5, color: accent),
          pw.SizedBox(height: 12),

          // ── Title Section (Column layout) ──────────────────────────────
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.center,
            children: [
              pw.Text(
                widget.exam.name.toUpperCase(),
                style: pw.TextStyle(
                  color: primary,
                  fontWeight: pw.FontWeight.bold,
                  fontSize: 13,
                  letterSpacing: 1.5,
                ),
              ),
              if (widget.exam.startDate != null) ...[
                pw.SizedBox(height: 4),
                pw.Text(
                  '${DateFormat('dd MMM yyyy').format(widget.exam.startDate!)}  –  ${DateFormat('dd MMM yyyy').format(widget.exam.endDate ?? widget.exam.startDate!)}',
                  style: const pw.TextStyle(
                    fontSize: 9.5,
                    color: PdfColors.grey700,
                  ),
                ),
              ],
              pw.SizedBox(height: 10),
              pw.Container(
                padding: const pw.EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 6,
                ),
                decoration: pw.BoxDecoration(
                  color: primary,
                  borderRadius: const pw.BorderRadius.all(
                    pw.Radius.circular(6),
                  ),
                ),
                child: pw.Text(
                  'ADMIT CARD',
                  style: pw.TextStyle(
                    color: PdfColors.white,
                    fontWeight: pw.FontWeight.bold,
                    fontSize: 14,
                    letterSpacing: 5,
                  ),
                ),
              ),
            ],
          ),
          pw.SizedBox(height: 14),

          // ── Student info box (Professional grid) ───────────────────────
          pw.Container(
            padding: const pw.EdgeInsets.all(12),
            decoration: pw.BoxDecoration(
              border: pw.Border.all(color: PdfColors.grey400, width: 1),
              borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
            ),
            child: pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Container(
                  width: 80,
                  height: 100,
                  decoration: pw.BoxDecoration(
                    color: light,
                    borderRadius: const pw.BorderRadius.all(
                      pw.Radius.circular(6),
                    ),
                    border: pw.Border.all(color: PdfColors.grey400),
                  ),
                  child: avatar != null
                      ? pw.ClipRRect(
                          horizontalRadius: 5,
                          verticalRadius: 5,
                          child: pw.Image(avatar, fit: pw.BoxFit.cover),
                        )
                      : pw.Center(
                          child: pw.Text(
                            student.user?.name.isNotEmpty == true
                                ? student.user!.name[0].toUpperCase()
                                : '?',
                            style: pw.TextStyle(
                              fontSize: 32,
                              fontWeight: pw.FontWeight.bold,
                              color: primary,
                            ),
                          ),
                        ),
                ),
                pw.SizedBox(width: 16),
                pw.Expanded(
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        student.user?.name ?? 'N/A',
                        style: pw.TextStyle(
                          fontSize: 14,
                          fontWeight: pw.FontWeight.bold,
                          color: primary,
                        ),
                      ),
                      pw.SizedBox(height: 10),
                      pw.Row(
                        children: [
                          pw.Expanded(
                            child: _classicField(
                              'Roll No.',
                              student.rollId,
                              primary: primary,
                              big: true,
                            ),
                          ),
                          pw.SizedBox(width: 12),
                          pw.Expanded(
                            child: _classicField(
                              'Class / Section',
                              '$className  –  $sectionName',
                              primary: primary,
                              big: true,
                            ),
                          ),
                        ],
                      ),
                      pw.SizedBox(height: 10),
                      pw.Row(
                        children: [
                          pw.Expanded(
                            child: _classicField(
                              'Contact',
                              student.guardianContact.isNotEmpty
                                  ? student.guardianContact
                                  : (student.user?.phone ?? 'N/A'),
                              primary: primary,
                              big: true,
                            ),
                          ),
                          pw.SizedBox(width: 12),
                          pw.Expanded(
                            child: _classicField(
                              'Email',
                              student.user?.email ?? 'N/A',
                              primary: primary,
                              big: true,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          pw.SizedBox(height: 16),

          if (_topInstruction.isNotEmpty) ...[
            pw.Container(
              width: double.infinity,
              padding: const pw.EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 8,
              ),
              decoration: pw.BoxDecoration(
                color: PdfColors.amber50,
                border: pw.Border.all(color: accent, width: 1),
                borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
              ),
              child: pw.Text(
                _topInstruction,
                textAlign: pw.TextAlign.center,
                style: pw.TextStyle(
                  fontWeight: pw.FontWeight.bold,
                  fontSize: 10.5,
                  color: primary,
                ),
              ),
            ),
            pw.SizedBox(height: 16),
          ],

          // ── Schedule heading ────────────────────────────────────────────
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            crossAxisAlignment: pw.CrossAxisAlignment.end,
            children: [
              pw.Text(
                'EXAMINATION SCHEDULE',
                style: pw.TextStyle(
                  fontWeight: pw.FontWeight.bold,
                  fontSize: 11,
                  color: primary,
                  letterSpacing: 1,
                ),
              ),
              pw.Container(
                padding: const pw.EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: pw.BoxDecoration(
                  color: accent,
                  borderRadius: const pw.BorderRadius.all(
                    pw.Radius.circular(4),
                  ),
                ),
                child: pw.Text(
                  '${subjects.length} Subject${subjects.length == 1 ? '' : 's'}',
                  style: pw.TextStyle(
                    fontSize: 8.5,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.black,
                  ),
                ),
              ),
            ],
          ),
          pw.SizedBox(height: 6),

          // ── 2-column subject table ──────────────────────────────────────
          if (subjects.isEmpty)
            pw.Container(
              padding: const pw.EdgeInsets.all(12),
              color: PdfColors.grey100,
              child: pw.Text(
                'No subjects scheduled.',
                style: const pw.TextStyle(
                  fontSize: 10,
                  color: PdfColors.grey600,
                ),
                textAlign: pw.TextAlign.center,
              ),
            )
          else
            pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Expanded(child: subjectTable(leftSubjects, 0)),
                pw.SizedBox(width: 10),
                pw.Expanded(child: subjectTable(rightSubjects, half)),
              ],
            ),

          pw.Spacer(),

          // ── Instructions ───────────────────────────────────────────────
          pw.Container(
            padding: const pw.EdgeInsets.all(12),
            decoration: pw.BoxDecoration(
              color: light,
              borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
              border: pw.Border.all(color: PdfColors.deepPurple200, width: 0.5),
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  'IMPORTANT INSTRUCTIONS',
                  style: pw.TextStyle(
                    fontWeight: pw.FontWeight.bold,
                    fontSize: 9.5,
                    color: primary,
                    letterSpacing: 0.5,
                  ),
                ),
                pw.SizedBox(height: 6),
                pw.Wrap(
                  spacing: 24,
                  runSpacing: 4,
                  children: _instructions.asMap().entries.map((e) {
                    return pw.SizedBox(
                      width: 220,
                      child: pw.Text(
                        '${e.key + 1}.  ${e.value}',
                        style: const pw.TextStyle(
                          fontSize: 8,
                          color: PdfColors.grey800,
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),

          pw.SizedBox(height: 10),

          // ── Signatures ─────────────────────────────────────────────────
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            crossAxisAlignment: pw.CrossAxisAlignment.end,
            children: [
              _sigBlock('Student Signature', primary),
              _sigBlock('Parent / Guardian', primary),
              _sigBlock(
                'Principal Signature',
                primary,
                signatoryName: signatoryName,
                signatureFont: signatureFont,
              ),
            ],
          ),

          pw.SizedBox(height: 8),
          pw.Container(height: 1.5, color: accent),
          pw.Container(height: 3, color: primary),
          pw.SizedBox(height: 4),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text(
                'Issued by $schoolName',
                style: const pw.TextStyle(
                  fontSize: 8,
                  color: PdfColors.grey600,
                ),
              ),
              pw.Text(
                'Date: ${DateFormat('dd MMM yyyy').format(DateTime.now())}',
                style: const pw.TextStyle(
                  fontSize: 8,
                  color: PdfColors.grey600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // TEMPLATE 2 - MODERN  (redesigned for 15+ subjects on one A4 page)
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
    String? signatoryName,
    pw.Font? signatureFont,
  }) {
    const primary = PdfColor.fromInt(0xFF1A237E);
    const secondary = PdfColor.fromInt(0xFF00695C);
    const accent = PdfColor.fromInt(0xFFFFA000);
    const bgLight = PdfColor.fromInt(0xFFF3F4FF);

    final half = (subjects.length / 2).ceil();
    final leftSubjects = subjects.take(half).toList();
    final rightSubjects = subjects.skip(half).toList();

    final rowColors = <PdfColor>[
      secondary,
      primary,
      const PdfColor.fromInt(0xFF6A1B9A),
      const PdfColor.fromInt(0xFF1565C0),
      const PdfColor.fromInt(0xFF558B2F),
      const PdfColor.fromInt(0xFF4E342E),
    ];

    pw.Widget modernSubjectTable(List<ExamAssignment> rows, int startIndex) {
      if (rows.isEmpty) return pw.SizedBox();
      return pw.Column(
        children: [
          pw.Container(
            padding: const pw.EdgeInsets.symmetric(horizontal: 5, vertical: 4),
            color: primary,
            child: pw.Row(
              children: [
                pw.SizedBox(
                  width: 20,
                  child: pw.Text(
                    '#',
                    style: pw.TextStyle(
                      color: PdfColors.white,
                      fontWeight: pw.FontWeight.bold,
                      fontSize: 8.5,
                    ),
                  ),
                ),
                pw.Expanded(
                  flex: 3,
                  child: pw.Text(
                    'Subject',
                    style: pw.TextStyle(
                      color: PdfColors.white,
                      fontWeight: pw.FontWeight.bold,
                      fontSize: 8.5,
                    ),
                  ),
                ),
                pw.Expanded(
                  flex: 2,
                  child: pw.Text(
                    'Date & Day',
                    style: pw.TextStyle(
                      color: PdfColors.white,
                      fontWeight: pw.FontWeight.bold,
                      fontSize: 8.5,
                    ),
                  ),
                ),
              ],
            ),
          ),
          ...rows.asMap().entries.map((e) {
            final idx = startIndex + e.key;
            final a = e.value;
            final color = rowColors[idx % rowColors.length];
            return pw.Container(
              decoration: pw.BoxDecoration(
                color: idx.isEven ? PdfColors.white : bgLight,
                border: const pw.Border(
                  bottom: pw.BorderSide(color: PdfColors.grey200, width: 0.3),
                ),
              ),
              child: pw.Row(
                children: [
                  pw.Container(
                    width: 20,
                    padding: const pw.EdgeInsets.symmetric(vertical: 4),
                    color: color,
                    child: pw.Center(
                      child: pw.Text(
                        '${idx + 1}',
                        style: pw.TextStyle(
                          color: PdfColors.white,
                          fontWeight: pw.FontWeight.bold,
                          fontSize: 8.5,
                        ),
                      ),
                    ),
                  ),
                  pw.Expanded(
                    flex: 3,
                    child: pw.Padding(
                      padding: const pw.EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 3,
                      ),
                      child: pw.Text(
                        a.subjectName,
                        style: pw.TextStyle(
                          fontWeight: pw.FontWeight.bold,
                          fontSize: 8.5,
                          color: primary,
                        ),
                        maxLines: 1,
                      ),
                    ),
                  ),
                  pw.Expanded(
                    flex: 2,
                    child: pw.Padding(
                      padding: const pw.EdgeInsets.symmetric(
                        horizontal: 4,
                        vertical: 3,
                      ),
                      child: pw.Text(
                        '${DateFormat('dd/MM/yy').format(a.date)} (${DateFormat('EEE').format(a.date)})',
                        style: const pw.TextStyle(
                          fontSize: 8.5,
                          color: PdfColors.grey700,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      );
    }

    return pw.Stack(
      children: [
        pw.Positioned.fill(child: pw.Container(color: PdfColors.white)),
        pw.Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: pw.SizedBox(height: 90, child: pw.Container(color: primary)),
        ),
        pw.Positioned(
          top: 0,
          right: 0,
          bottom: 0,
          child: pw.SizedBox(width: 6, child: pw.Container(color: secondary)),
        ),

        pw.Padding(
          padding: const pw.EdgeInsets.fromLTRB(26, 16, 36, 16),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.center,
            children: [
              // ── School header ───────────────────────────────────────────
              pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.center,
                children: [
                  if (schoolLogo != null)
                    pw.Container(
                      width: 50,
                      height: 50,
                      margin: const pw.EdgeInsets.only(right: 12),
                      decoration: pw.BoxDecoration(
                        shape: pw.BoxShape.circle,
                        color: PdfColors.white,
                        border: pw.Border.all(color: accent, width: 2),
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
                        pw.SizedBox(height: 2),
                        if (schoolAddress.isNotEmpty)
                          pw.Text(
                            schoolAddress,
                            style: const pw.TextStyle(
                              color: PdfColors.indigo100,
                              fontSize: 8.5,
                            ),
                          ),
                        if (schoolPhone.isNotEmpty || schoolEmail.isNotEmpty)
                          pw.Text(
                            [
                              if (schoolPhone.isNotEmpty) schoolPhone,
                              if (schoolEmail.isNotEmpty) schoolEmail,
                            ].join('  |  '),
                            style: const pw.TextStyle(
                              color: PdfColors.indigo200,
                              fontSize: 8,
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),

              pw.SizedBox(height: 24),

              // ── Title Section (like Classic) ────────────────────────────
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.center,
                mainAxisAlignment: pw.MainAxisAlignment.center,
                children: [
                  pw.SizedBox(height: 24),
                  pw.Text(
                    widget.exam.name.toUpperCase(),
                    style: pw.TextStyle(
                      color: primary,
                      fontWeight: pw.FontWeight.bold,
                      fontSize: 13,
                      letterSpacing: 1.5,
                    ),
                  ),
                  if (widget.exam.startDate != null) ...[
                    pw.SizedBox(height: 4),
                    pw.Text(
                      '${DateFormat('dd MMM yyyy').format(widget.exam.startDate!)}  –  ${DateFormat('dd MMM yyyy').format(widget.exam.endDate ?? widget.exam.startDate!)}',
                      style: const pw.TextStyle(
                        fontSize: 9.5,
                        color: PdfColors.grey700,
                      ),
                    ),
                  ],
                  pw.SizedBox(height: 8),
                  pw.Container(
                    padding: const pw.EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 6,
                    ),
                    decoration: pw.BoxDecoration(
                      color: accent,
                      borderRadius: const pw.BorderRadius.all(
                        pw.Radius.circular(6),
                      ),
                    ),
                    child: pw.Text(
                      'ADMIT CARD',
                      style: pw.TextStyle(
                        color: PdfColors.black,
                        fontWeight: pw.FontWeight.bold,
                        fontSize: 12,
                        letterSpacing: 4,
                      ),
                    ),
                  ),
                  pw.SizedBox(height: 24),
                ],
              ),

              pw.SizedBox(height: 16),

              // ── Student card ─────────────────────────────────────────────
              pw.Container(
                decoration: pw.BoxDecoration(
                  color: primary,
                  borderRadius: const pw.BorderRadius.all(
                    pw.Radius.circular(10),
                  ),
                  boxShadow: const [
                    pw.BoxShadow(
                      color: PdfColors.grey400,
                      blurRadius: 6,
                      offset: PdfPoint(0, 3),
                    ),
                  ],
                ),
                child: pw.Row(
                  crossAxisAlignment: pw.CrossAxisAlignment.center,
                  children: [
                    pw.Container(
                      width: 8,
                      height: 110,
                      decoration: const pw.BoxDecoration(
                        color: secondary,
                        borderRadius: pw.BorderRadius.only(
                          topLeft: pw.Radius.circular(10),
                          bottomLeft: pw.Radius.circular(10),
                        ),
                      ),
                    ),
                    pw.Container(
                      width: 80,
                      height: 96,
                      margin: const pw.EdgeInsets.all(10),
                      decoration: pw.BoxDecoration(
                        borderRadius: const pw.BorderRadius.all(
                          pw.Radius.circular(6),
                        ),
                        border: pw.Border.all(color: secondary, width: 1.5),
                        color: bgLight,
                      ),
                      child: avatar != null
                          ? pw.ClipRRect(
                              horizontalRadius: 5,
                              verticalRadius: 5,
                              child: pw.Image(avatar, fit: pw.BoxFit.cover),
                            )
                          : pw.Center(
                              child: pw.Text(
                                student.user?.name.isNotEmpty == true
                                    ? student.user!.name[0].toUpperCase()
                                    : '?',
                                style: pw.TextStyle(
                                  fontSize: 32,
                                  fontWeight: pw.FontWeight.bold,
                                  color: primary,
                                ),
                              ),
                            ),
                    ),
                    pw.Expanded(
                      child: pw.Padding(
                        padding: const pw.EdgeInsets.fromLTRB(6, 12, 12, 12),
                        child: pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.start,
                          children: [
                            pw.Text(
                              student.user?.name ?? 'N/A',
                              style: pw.TextStyle(
                                fontWeight: pw.FontWeight.bold,
                                fontSize: 15,
                                color: PdfColors.white,
                              ),
                            ),
                            pw.SizedBox(height: 8),
                            pw.Row(
                              children: [
                                pw.Expanded(
                                  child: _modernChip(
                                    Icons.tag,
                                    'Roll No.',
                                    student.rollId,
                                    PdfColors.black,
                                    big: true,
                                    whiteText: true,
                                  ),
                                ),
                                pw.SizedBox(width: 10),
                                pw.Expanded(
                                  child: _modernChip(
                                    Icons.school,
                                    'Class',
                                    '$className - $sectionName',
                                    PdfColors.black,
                                    big: true,
                                    whiteText: true,
                                  ),
                                ),
                              ],
                            ),
                            pw.SizedBox(height: 8),
                            pw.Row(
                              children: [
                                if (student.guardianContact.isNotEmpty)
                                  pw.Expanded(
                                    child: _modernChip(
                                      Icons.phone,
                                      'Contact',
                                      student.guardianContact,
                                      PdfColors.black,
                                      big: true,
                                      whiteText: true,
                                    ),
                                  ),
                                if (student.guardianContact.isNotEmpty)
                                  pw.SizedBox(width: 10),
                                if (student.user != null &&
                                    student.user!.email.isNotEmpty)
                                  pw.Expanded(
                                    child: _modernChip(
                                      Icons.email,
                                      'Email',
                                      student.user!.email,
                                      PdfColors.black,
                                      big: true,
                                      whiteText: true,
                                    ),
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

              if (_topInstruction.isNotEmpty) ...[
                pw.Container(
                  width: double.infinity,
                  padding: const pw.EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  decoration: pw.BoxDecoration(
                    color: bgLight,
                    border: const pw.Border(
                      left: pw.BorderSide(color: secondary, width: 4),
                    ),
                  ),
                  child: pw.Text(
                    _topInstruction,
                    style: pw.TextStyle(
                      fontWeight: pw.FontWeight.bold,
                      fontSize: 10.5,
                      color: primary,
                    ),
                  ),
                ),
                pw.SizedBox(height: 16),
              ],

              // ── Schedule heading ──────────────────────────────────────────
              pw.Row(
                children: [
                  pw.Container(width: 4, height: 16, color: secondary),
                  pw.SizedBox(width: 8),
                  pw.Text(
                    'EXAMINATION SCHEDULE',
                    style: pw.TextStyle(
                      fontWeight: pw.FontWeight.bold,
                      fontSize: 11,
                      color: primary,
                      letterSpacing: 1,
                    ),
                  ),
                  pw.Spacer(),
                  pw.Container(
                    padding: const pw.EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: pw.BoxDecoration(
                      color: accent,
                      borderRadius: const pw.BorderRadius.all(
                        pw.Radius.circular(10),
                      ),
                    ),
                    child: pw.Text(
                      '${subjects.length} Subjects',
                      style: pw.TextStyle(
                        fontSize: 8.5,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.black,
                      ),
                    ),
                  ),
                ],
              ),
              pw.SizedBox(height: 6),

              // ── 2-col subject table ───────────────────────────────────────
              if (subjects.isEmpty)
                pw.Container(
                  padding: const pw.EdgeInsets.all(12),
                  color: bgLight,
                  child: pw.Text(
                    'No subjects scheduled.',
                    style: const pw.TextStyle(
                      fontSize: 10,
                      color: PdfColors.grey600,
                    ),
                  ),
                )
              else
                pw.Row(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Expanded(child: modernSubjectTable(leftSubjects, 0)),
                    pw.SizedBox(width: 10),
                    pw.Expanded(child: modernSubjectTable(rightSubjects, half)),
                  ],
                ),

              pw.Spacer(),

              // ── Instructions ──────────────────────────────────────────────
              pw.Container(
                padding: const pw.EdgeInsets.all(12),
                decoration: pw.BoxDecoration(
                  color: bgLight,
                  borderRadius: const pw.BorderRadius.all(
                    pw.Radius.circular(6),
                  ),
                  border: pw.Border.all(color: PdfColors.indigo100, width: 0.5),
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      'INSTRUCTIONS',
                      style: pw.TextStyle(
                        fontWeight: pw.FontWeight.bold,
                        fontSize: 9.5,
                        color: primary,
                        letterSpacing: 0.5,
                      ),
                    ),
                    pw.SizedBox(height: 6),
                    pw.Wrap(
                      spacing: 24,
                      runSpacing: 4,
                      children: _instructions.asMap().entries.map((e) {
                        return pw.SizedBox(
                          width: 220,
                          child: pw.Text(
                            '${e.key + 1}.  ${e.value}',
                            style: const pw.TextStyle(
                              fontSize: 8,
                              color: PdfColors.grey800,
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
              pw.SizedBox(height: 10),

              // ── Signatures + barcode ──────────────────────────────────────
              pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.end,
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  _sigBlock('Student Signature', primary),
                  pw.Column(
                    children: [
                      pw.BarcodeWidget(
                        data: student.userId.isNotEmpty
                            ? student.userId
                            : student.rollId,
                        barcode: pw.Barcode.code128(),
                        width: 90,
                        height: 26,
                        drawText: false,
                        color: primary,
                      ),
                      pw.SizedBox(height: 4),
                      pw.Text(
                        student.rollId,
                        style: const pw.TextStyle(
                          fontSize: 8,
                          color: PdfColors.grey600,
                        ),
                      ),
                    ],
                  ),
                  _sigBlock(
                    'Principal Signature',
                    primary,
                    signatoryName: signatoryName,
                    signatureFont: signatureFont,
                  ),
                ],
              ),

              pw.SizedBox(height: 10),

              // ── Footer ────────────────────────────────────────────────────
              pw.Container(
                padding: const pw.EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: const pw.BoxDecoration(color: primary),
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text(
                      '$schoolName  |  Issued ${DateFormat('dd MMM yyyy').format(DateTime.now())}',
                      style: const pw.TextStyle(
                        fontSize: 8.5,
                        color: PdfColors.white,
                      ),
                    ),
                    pw.Text(
                      'NOT VALID WITHOUT OFFICIAL SEAL',
                      style: pw.TextStyle(
                        fontSize: 8.5,
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
  // TEMPLATE 3 - MINIMAL  (redesigned for 15+ subjects on one A4 page)
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
    String? signatoryName,
    pw.Font? signatureFont,
  }) {
    final half = (subjects.length / 2).ceil();
    final leftSubjects = subjects.take(half).toList();
    final rightSubjects = subjects.skip(half).toList();

    pw.Widget minSubjectTable(List<ExamAssignment> rows, int startIndex) {
      if (rows.isEmpty) return pw.SizedBox();
      return pw.Table(
        border: pw.TableBorder.all(color: PdfColors.black, width: 0.5),
        columnWidths: const {
          0: pw.FixedColumnWidth(22),
          1: pw.FlexColumnWidth(2.5),
          2: pw.FlexColumnWidth(2.2),
        },
        children: [
          pw.TableRow(
            decoration: const pw.BoxDecoration(color: PdfColors.grey800),
            children: [
              _tCell('SL', isHeader: true, centered: true, fontSize: 8.5),
              _tCell('Subject Name', isHeader: true, fontSize: 8.5),
              _tCell('Date (Day)', isHeader: true, fontSize: 8.5),
            ],
          ),
          ...rows.asMap().entries.map((e) {
            final idx = startIndex + e.key;
            final a = e.value;
            final bg = idx.isEven ? PdfColors.white : PdfColors.grey100;
            return pw.TableRow(
              decoration: pw.BoxDecoration(color: bg),
              children: [
                _tCell(
                  '${idx + 1}',
                  centered: true,
                  textColor: PdfColors.black,
                  fontSize: 8.5,
                ),
                _tCell(
                  a.subjectName,
                  textColor: PdfColors.black,
                  fontSize: 8.5,
                ),
                _tCell(
                  '${DateFormat('dd/MM/yy').format(a.date)} (${DateFormat('EEE').format(a.date)})',
                  textColor: PdfColors.black,
                  fontSize: 8.5,
                ),
              ],
            );
          }),
        ],
      );
    }

    return pw.Container(
      color: PdfColors.white,
      child: pw.Stack(
        children: [
          pw.Positioned.fill(
            child: pw.Container(
              margin: const pw.EdgeInsets.all(12),
              decoration: pw.BoxDecoration(
                border: pw.Border.all(color: PdfColors.black, width: 2),
              ),
            ),
          ),
          pw.Positioned.fill(
            child: pw.Container(
              margin: const pw.EdgeInsets.all(16),
              decoration: pw.BoxDecoration(
                border: pw.Border.all(color: PdfColors.black, width: 0.5),
              ),
            ),
          ),

          pw.Padding(
            padding: const pw.EdgeInsets.fromLTRB(28, 20, 28, 20),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.stretch,
              children: [
                // ── Letterhead ─────────────────────────────────────────────
                pw.Row(
                  crossAxisAlignment: pw.CrossAxisAlignment.center,
                  mainAxisAlignment: pw.MainAxisAlignment.center,
                  children: [
                    if (schoolLogo != null)
                      pw.Container(
                        width: 50,
                        height: 50,
                        margin: const pw.EdgeInsets.only(right: 15),
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
                            fontSize: 16,
                            letterSpacing: 1.5,
                          ),
                        ),
                        pw.SizedBox(height: 3),
                        if (schoolAddress.isNotEmpty)
                          pw.Text(
                            schoolAddress,
                            textAlign: pw.TextAlign.center,
                            style: const pw.TextStyle(
                              fontSize: 9,
                              color: PdfColors.grey700,
                            ),
                          ),
                        if (schoolPhone.isNotEmpty ||
                            schoolEmail.isNotEmpty) ...[
                          pw.SizedBox(height: 2),
                          pw.Text(
                            [
                              if (schoolPhone.isNotEmpty) 'Ph: $schoolPhone',
                              if (schoolEmail.isNotEmpty) schoolEmail,
                            ].join('     '),
                            textAlign: pw.TextAlign.center,
                            style: const pw.TextStyle(
                              fontSize: 8.5,
                              color: PdfColors.grey600,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),

                pw.SizedBox(height: 8),
                pw.Divider(thickness: 2, color: PdfColors.black),
                pw.Divider(thickness: 0.5, color: PdfColors.black),
                pw.SizedBox(height: 8),

                // ── Title Section (Column layout) ──────────────────────────────
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.center,
                  children: [
                    pw.Text(
                      widget.exam.name.toUpperCase(),
                      style: pw.TextStyle(
                        fontWeight: pw.FontWeight.bold,
                        fontSize: 13,
                        letterSpacing: 1.5,
                      ),
                    ),
                    if (widget.exam.startDate != null) ...[
                      pw.SizedBox(height: 4),
                      pw.Text(
                        '${DateFormat('dd MMM yyyy').format(widget.exam.startDate!)}  –  ${DateFormat('dd MMM yyyy').format(widget.exam.endDate ?? widget.exam.startDate!)}',
                        style: const pw.TextStyle(
                          fontSize: 9.5,
                          color: PdfColors.grey700,
                        ),
                      ),
                    ],
                    pw.SizedBox(height: 10),
                    pw.Text(
                      'ADMIT CARD',
                      style: pw.TextStyle(
                        fontWeight: pw.FontWeight.bold,
                        fontSize: 16,
                        letterSpacing: 6,
                      ),
                    ),
                  ],
                ),

                pw.SizedBox(height: 12),
                pw.Divider(thickness: 0.5, color: PdfColors.black),
                pw.SizedBox(height: 12),

                // ── Student info + photo ────────────────────────────────────
                pw.Row(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Container(
                      width: 80,
                      height: 100,
                      margin: const pw.EdgeInsets.only(right: 16),
                      decoration: pw.BoxDecoration(
                        border: pw.Border.all(color: PdfColors.black, width: 1),
                      ),
                      child: avatar != null
                          ? pw.Image(avatar, fit: pw.BoxFit.cover)
                          : pw.Center(
                              child: pw.Text(
                                'PHOTO',
                                style: pw.TextStyle(
                                  fontWeight: pw.FontWeight.bold,
                                  fontSize: 10,
                                  color: PdfColors.grey500,
                                ),
                              ),
                            ),
                    ),
                    pw.Expanded(
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          _minimalField(
                            'Name of Student',
                            student.user?.name ?? 'N/A',
                            big: true,
                          ),
                          pw.SizedBox(height: 6),
                          pw.Row(
                            children: [
                              pw.Expanded(
                                child: _minimalField(
                                  'Roll No.',
                                  student.rollId,
                                  big: true,
                                ),
                              ),
                              pw.SizedBox(width: 14),
                              pw.Expanded(
                                child: _minimalField(
                                  'Class / Section',
                                  '$className - $sectionName',
                                  big: true,
                                ),
                              ),
                            ],
                          ),
                          pw.SizedBox(height: 6),
                          pw.Row(
                            children: [
                              pw.Expanded(
                                child: _minimalField(
                                  'Guardian Contact',
                                  student.guardianContact.isNotEmpty
                                      ? student.guardianContact
                                      : (student.user?.phone ?? 'N/A'),
                                  big: true,
                                ),
                              ),
                              pw.SizedBox(width: 14),
                              pw.Expanded(
                                child: _minimalField(
                                  'Email',
                                  student.user?.email ?? 'N/A',
                                  big: true,
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

                if (_topInstruction.isNotEmpty) ...[
                  pw.Container(
                    width: double.infinity,
                    padding: const pw.EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    decoration: pw.BoxDecoration(
                      color: PdfColors.grey100,
                      border: pw.Border.all(color: PdfColors.grey400, width: 1),
                      borderRadius: const pw.BorderRadius.all(
                        pw.Radius.circular(4),
                      ),
                    ),
                    child: pw.Text(
                      _topInstruction,
                      textAlign: pw.TextAlign.center,
                      style: pw.TextStyle(
                        fontWeight: pw.FontWeight.bold,
                        fontSize: 10.5,
                        color: PdfColors.black,
                      ),
                    ),
                  ),
                  pw.SizedBox(height: 12),
                ],

                // ── Schedule ────────────────────────────────────────────────
                pw.Text(
                  'EXAMINATION SCHEDULE  (${subjects.length} Subject${subjects.length == 1 ? '' : 's'})',
                  style: pw.TextStyle(
                    fontWeight: pw.FontWeight.bold,
                    fontSize: 10,
                    letterSpacing: 0.5,
                  ),
                ),
                pw.SizedBox(height: 6),

                if (subjects.isEmpty)
                  pw.Container(
                    padding: const pw.EdgeInsets.all(12),
                    color: PdfColors.grey100,
                    child: pw.Text(
                      'No subjects scheduled.',
                      style: const pw.TextStyle(
                        fontSize: 10,
                        color: PdfColors.grey600,
                      ),
                      textAlign: pw.TextAlign.center,
                    ),
                  )
                else
                  pw.Row(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Expanded(child: minSubjectTable(leftSubjects, 0)),
                      pw.SizedBox(width: 10),
                      pw.Expanded(child: minSubjectTable(rightSubjects, half)),
                    ],
                  ),

                pw.Spacer(),

                // ── Instructions ────────────────────────────────────────────
                pw.Text(
                  'INSTRUCTIONS TO CANDIDATES:',
                  style: pw.TextStyle(
                    fontWeight: pw.FontWeight.bold,
                    fontSize: 9.5,
                    letterSpacing: 0.4,
                  ),
                ),
                pw.SizedBox(height: 6),
                pw.Table(
                  columnWidths: const {
                    0: pw.FixedColumnWidth(14),
                    1: pw.FlexColumnWidth(1),
                    2: pw.FixedColumnWidth(14),
                    3: pw.FlexColumnWidth(1),
                  },
                  children: List.generate((_instructions.length / 2).ceil(), (
                    row,
                  ) {
                    final left = row * 2;
                    final right = left + 1;
                    return pw.TableRow(
                      children: [
                        pw.Padding(
                          padding: const pw.EdgeInsets.only(bottom: 4),
                          child: pw.Text(
                            '${left + 1}.',
                            style: pw.TextStyle(
                              fontWeight: pw.FontWeight.bold,
                              fontSize: 8,
                            ),
                          ),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.only(
                            bottom: 4,
                            right: 12,
                          ),
                          child: pw.Text(
                            _instructions[left],
                            style: const pw.TextStyle(fontSize: 8),
                          ),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.only(bottom: 4),
                          child: pw.Text(
                            right < _instructions.length ? '${right + 1}.' : '',
                            style: pw.TextStyle(
                              fontWeight: pw.FontWeight.bold,
                              fontSize: 8,
                            ),
                          ),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.only(bottom: 4),
                          child: pw.Text(
                            right < _instructions.length
                                ? _instructions[right]
                                : '',
                            style: const pw.TextStyle(fontSize: 8),
                          ),
                        ),
                      ],
                    );
                  }),
                ),

                pw.SizedBox(height: 10),
                pw.Divider(thickness: 0.5, color: PdfColors.black),

                // ── Signatures ──────────────────────────────────────────────
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                  children: [
                    _minimalSigBlock("Student's Signature"),

                    _minimalSigBlock(
                      "Principal's Signature",
                      signatoryName: signatoryName,
                      signatureFont: signatureFont,
                    ),
                  ],
                ),

                pw.SizedBox(height: 4),
                pw.Divider(thickness: 0.5),
                pw.SizedBox(height: 2),
                pw.Center(
                  child: pw.Text(
                    'Computer-generated by $schoolName. Issued on ${DateFormat('dd MMMM yyyy').format(DateTime.now())}.',
                    textAlign: pw.TextAlign.center,
                    style: const pw.TextStyle(
                      fontSize: 6.5,
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
  // TEMPLATE 5 - HALF PAGE (2 cards per A4 page)
  // ═══════════════════════════════════════════════════════════════════════════
  pw.Widget _buildHalfPageCard({
    required Student student,
    required String className,
    required String sectionName,
    required String schoolName,
    required pw.ImageProvider? schoolLogo,
    required pw.ImageProvider? avatar,
    required List<ExamAssignment> subjects,
    required String instruction,
    String? signatoryName,
    pw.Font? signatureFont,
  }) {
    const primary = PdfColors.indigo700;
    const accent = PdfColors.amber700;
    const light = PdfColors.indigo50;

    final half = (subjects.length / 2).ceil();
    final leftSubjects = subjects.take(half).toList();
    final rightSubjects = subjects.skip(half).toList();

    pw.Widget subjectTable(List<ExamAssignment> rows, int startIndex) {
      if (rows.isEmpty) return pw.SizedBox();
      return pw.Table(
        border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
        columnWidths: const {
          0: pw.FixedColumnWidth(22),
          1: pw.FlexColumnWidth(2.5),
          2: pw.FlexColumnWidth(2.2),
        },
        children: [
          pw.TableRow(
            decoration: const pw.BoxDecoration(color: primary),
            children: [
              _tCell('#', isHeader: true, fontSize: 8),
              _tCell('Subject', isHeader: true, fontSize: 8),
              _tCell('Date / Day', isHeader: true, fontSize: 8),
            ],
          ),
          ...rows.asMap().entries.map((e) {
            final idx = startIndex + e.key;
            final a = e.value;
            final bg = idx.isEven ? PdfColors.white : light;
            return pw.TableRow(
              decoration: pw.BoxDecoration(color: bg),
              children: [
                _tCell('${idx + 1}', centered: true, fontSize: 8),
                _tCell(a.subjectName, fontSize: 8),
                _tCell(
                  '${DateFormat('dd/MM/yy').format(a.date)} (${DateFormat('EEE').format(a.date)})',
                  fontSize: 8,
                ),
              ],
            );
          }),
        ],
      );
    }

    return pw.Container(
      margin: const pw.EdgeInsets.only(bottom: 20),
      padding: const pw.EdgeInsets.all(16),
      decoration: pw.BoxDecoration(
        color: PdfColors.white,
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(12)),
        border: pw.Border.all(color: primary, width: 2),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.stretch,
        children: [
          // Top Section: Student Info (Left), Exam Info (Center) & School Info (Right)
          pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.center,
            children: [
              // 1. Student Info (Left)
              pw.Expanded(
                flex: 9,
                child: pw.Row(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Container(
                      width: 55,
                      height: 70,
                      decoration: pw.BoxDecoration(
                        color: light,
                        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
                        border: pw.Border.all(color: PdfColors.grey400),
                      ),
                      child: avatar != null
                          ? pw.ClipRRect(
                              horizontalRadius: 5,
                              verticalRadius: 5,
                              child: pw.Image(avatar, fit: pw.BoxFit.cover),
                            )
                          : pw.Center(
                              child: pw.Text(
                                student.user?.name.isNotEmpty == true
                                    ? student.user!.name[0].toUpperCase()
                                    : '?',
                                style: pw.TextStyle(
                                  fontSize: 22,
                                  fontWeight: pw.FontWeight.bold,
                                  color: primary,
                                ),
                              ),
                            ),
                    ),
                    pw.SizedBox(width: 10),
                    pw.Expanded(
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text(
                            student.user?.name ?? 'N/A',
                            style: pw.TextStyle(
                              fontSize: 11,
                              fontWeight: pw.FontWeight.bold,
                              color: primary,
                            ),
                          ),
                          pw.SizedBox(height: 5),
                          pw.Row(
                            children: [
                              pw.Expanded(
                                child: _classicField('Roll No.', student.rollId, primary: primary),
                              ),
                              pw.Expanded(
                                child: _classicField('Class', '$className – $sectionName', primary: primary),
                              ),
                            ],
                          ),
                          pw.SizedBox(height: 5),
                          pw.Row(
                            children: [
                              pw.Expanded(
                                child: _classicField('Contact', student.guardianContact.isNotEmpty ? student.guardianContact : (student.user?.phone ?? 'N/A'), primary: primary),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Vertical Divider 1
              pw.Container(
                width: 1,
                height: 70,
                color: PdfColors.grey300,
                margin: const pw.EdgeInsets.symmetric(horizontal: 10),
              ),

              // 2. Exam Info (Center)
              pw.Expanded(
                flex: 5,
                child: pw.Column(
                  mainAxisAlignment: pw.MainAxisAlignment.center,
                  crossAxisAlignment: pw.CrossAxisAlignment.center,
                  children: [
                    pw.Text(
                      'ADMIT CARD',
                      textAlign: pw.TextAlign.center,
                      style: pw.TextStyle(
                        color: primary,
                        fontWeight: pw.FontWeight.bold,
                        fontSize: 10,
                        letterSpacing: 1.5,
                      ),
                    ),
                    pw.SizedBox(height: 6),
                    pw.Text(
                      widget.exam.name.toUpperCase(),
                      textAlign: pw.TextAlign.center,
                      style: pw.TextStyle(
                        color: PdfColors.grey700,
                        fontWeight: pw.FontWeight.bold,
                        fontSize: 8.5,
                      ),
                    ),
                  ],
                ),
              ),

              // Vertical Divider 2
              pw.Container(
                width: 1,
                height: 70,
                color: PdfColors.grey300,
                margin: const pw.EdgeInsets.symmetric(horizontal: 10),
              ),

              // 3. School Info (Right)
              pw.Expanded(
                flex: 6,
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                  mainAxisAlignment: pw.MainAxisAlignment.center,
                  children: [
                    if (schoolLogo != null)
                      pw.Container(
                        width: 45,
                        height: 45,
                        margin: const pw.EdgeInsets.only(bottom: 6),
                        decoration: pw.BoxDecoration(
                          shape: pw.BoxShape.circle,
                          border: pw.Border.all(color: primary, width: 1.5),
                          image: pw.DecorationImage(
                            image: schoolLogo,
                            fit: pw.BoxFit.contain,
                          ),
                        ),
                      ),
                    pw.Text(
                      schoolName.toUpperCase(),
                      textAlign: pw.TextAlign.right,
                      style: pw.TextStyle(
                        color: primary,
                        fontWeight: pw.FontWeight.bold,
                        fontSize: 10,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          pw.SizedBox(height: 12),

          if (instruction.isNotEmpty) ...[
            pw.Container(
              width: double.infinity,
              padding: const pw.EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 6,
              ),
              decoration: pw.BoxDecoration(
                color: PdfColors.amber50,
                border: pw.Border.all(color: accent, width: 1),
                borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
              ),
              child: pw.Text(
                instruction,
                textAlign: pw.TextAlign.center,
                style: pw.TextStyle(
                  fontWeight: pw.FontWeight.bold,
                  fontSize: 9,
                  color: primary,
                ),
              ),
            ),
            pw.SizedBox(height: 10),
          ],

          // Schedule Heading
          pw.Text(
            'EXAMINATION SCHEDULE',
            style: pw.TextStyle(
              fontWeight: pw.FontWeight.bold,
              fontSize: 10,
              color: primary,
              letterSpacing: 1,
            ),
          ),
          pw.SizedBox(height: 6),

          // 2-column subject table
          if (subjects.isEmpty)
            pw.Container(
              padding: const pw.EdgeInsets.all(12),
              color: PdfColors.grey100,
              child: pw.Text(
                'No subjects scheduled.',
                style: const pw.TextStyle(
                  fontSize: 10,
                  color: PdfColors.grey600,
                ),
                textAlign: pw.TextAlign.center,
              ),
            )
          else
            pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Expanded(child: subjectTable(leftSubjects, 0)),
                pw.SizedBox(width: 10),
                pw.Expanded(child: subjectTable(rightSubjects, half)),
              ],
            ),

          pw.Spacer(),

          // Signatures
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            crossAxisAlignment: pw.CrossAxisAlignment.end,
            children: [
              _sigBlock('Student Signature', primary),
              _sigBlock(
                'Principal Signature',
                primary,
                signatoryName: signatoryName,
                signatureFont: signatureFont,
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // TEMPLATE 4 - COMPACT  (no exam schedule · 6 cards per A4 page)
  // ═══════════════════════════════════════════════════════════════════════════
  pw.Widget _buildCompactCard({
    required Student student,
    required String className,
    required String sectionName,
    required String schoolName,
    required pw.ImageProvider? schoolLogo,
    required pw.ImageProvider? avatar,
    required List<ExamAssignment> subjects,
    required String instruction,
    String? signatoryName,
    pw.Font? signatureFont,
  }) {
    const primary = PdfColor.fromInt(0xFF00695C); // teal 800
    const accent = PdfColor.fromInt(0xFFFFA000); // amber 700
    const bgLight = PdfColor.fromInt(0xFFE0F2F1); // teal 50

    pw.Widget _minCompactSubjectTable(
      List<ExamAssignment> rows,
      PdfColor primaryColor,
    ) {
      if (rows.isEmpty) return pw.SizedBox();
      return pw.Table(
        border: pw.TableBorder.all(color: PdfColors.grey400, width: 0.5),
        columnWidths: const {
          0: pw.FlexColumnWidth(2),
          1: pw.FlexColumnWidth(1.2),
        },
        children: [
          pw.TableRow(
            decoration: pw.BoxDecoration(color: primaryColor),
            children: [
              pw.Padding(
                padding: const pw.EdgeInsets.all(2),
                child: pw.Text(
                  'Subject',
                  style: pw.TextStyle(
                    color: PdfColors.white,
                    fontSize: 5,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
              ),
              pw.Padding(
                padding: const pw.EdgeInsets.all(2),
                child: pw.Text(
                  'Date',
                  style: pw.TextStyle(
                    color: PdfColors.white,
                    fontSize: 5,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          ...rows.map((a) {
            return pw.TableRow(
              children: [
                pw.Padding(
                  padding: const pw.EdgeInsets.all(2),
                  child: pw.Text(
                    a.subjectName,
                    style: pw.TextStyle(fontSize: 5, color: primaryColor),
                    maxLines: 1,
                  ),
                ),
                pw.Padding(
                  padding: const pw.EdgeInsets.all(2),
                  child: pw.Text(
                    DateFormat('dd/MM').format(a.date),
                    style: const pw.TextStyle(
                      fontSize: 5,
                      color: PdfColors.grey700,
                    ),
                  ),
                ),
              ],
            );
          }),
        ],
      );
    }

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
                    borderRadius: const pw.BorderRadius.all(
                      pw.Radius.circular(3),
                    ),
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

          // ── Body (Photo & Info) ──────────────────────────────────────
          pw.Padding(
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
                    borderRadius: const pw.BorderRadius.all(
                      pw.Radius.circular(4),
                    ),
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
                      _cRow('Class', '$className - $sectionName', primary),
                      if (widget.exam.startDate != null)
                        _cRow(
                          'Period',
                          '${DateFormat('dd/MM/yy').format(widget.exam.startDate!)} - '
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

          // ── Instruction & Schedule ───────────────────────────────────
          pw.Expanded(
            child: pw.Padding(
              padding: const pw.EdgeInsets.symmetric(horizontal: 8),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.stretch,
                children: [
                  if (instruction.isNotEmpty) ...[
                    pw.Container(
                      width: double.infinity,
                      padding: const pw.EdgeInsets.all(3),
                      margin: const pw.EdgeInsets.only(bottom: 6),
                      decoration: pw.BoxDecoration(
                        color: PdfColors.amber50,
                        border: pw.Border.all(color: accent, width: 0.5),
                        borderRadius: const pw.BorderRadius.all(
                          pw.Radius.circular(3),
                        ),
                      ),
                      child: pw.Text(
                        instruction,
                        textAlign: pw.TextAlign.center,
                        style: pw.TextStyle(
                          fontWeight: pw.FontWeight.bold,
                          fontSize: 5.5,
                          color: primary,
                        ),
                      ),
                    ),
                  ],
                  if (subjects.isNotEmpty)
                    pw.Expanded(
                      child: pw.Row(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Expanded(
                            child: _minCompactSubjectTable(
                              subjects
                                  .take((subjects.length / 2).ceil())
                                  .toList(),
                              primary,
                            ),
                          ),
                          pw.SizedBox(width: 4),
                          pw.Expanded(
                            child: _minCompactSubjectTable(
                              subjects
                                  .skip((subjects.length / 2).ceil())
                                  .toList(),
                              primary,
                            ),
                          ),
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
                      child: pw.Divider(
                        color: PdfColors.grey500,
                        thickness: 0.5,
                      ),
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
                      height: 20, // signature space
                      alignment: pw.Alignment.bottomRight,
                      child: (signatoryName != null && signatureFont != null)
                          ? pw.Text(
                              signatoryName,
                              style: pw.TextStyle(
                                font: signatureFont,
                                fontSize: 14,
                                color: PdfColors.black,
                              ),
                            )
                          : pw.SizedBox(),
                    ),
                    pw.Container(
                      width: 72,
                      child: pw.Divider(
                        color: PdfColors.grey500,
                        thickness: 0.5,
                      ),
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
    PdfColor color, {
    bool big = false,
    bool whiteText = false,
  }) {
    final bgColor = whiteText
        ? const PdfColor(1, 1, 1, 0.1)
        : PdfColor(color.red, color.green, color.blue, 0.08);
    final borderColor = whiteText
        ? const PdfColor(1, 1, 1, 0.3)
        : PdfColor(color.red, color.green, color.blue, 0.3);
    final labelColor = whiteText ? PdfColors.white : color;
    final valueColor = whiteText ? PdfColors.white : PdfColors.black;

    return pw.Container(
      padding: pw.EdgeInsets.symmetric(
        horizontal: big ? 12 : 8,
        vertical: big ? 6 : 4,
      ),
      decoration: pw.BoxDecoration(
        color: bgColor,
        border: pw.Border.all(color: borderColor, width: 0.5),
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
                  fontSize: big ? 7.5 : 5.5,
                  color: PdfColors.black,
                  fontWeight: pw.FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
              pw.SizedBox(height: 1),
              pw.Text(
                value,
                style: pw.TextStyle(
                  fontSize: big ? 11 : 8,
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

  /// Table cell used by Classic and Minimal schedule tables
  pw.Widget _tCell(
    String text, {
    bool isHeader = false,
    bool centered = false,
    PdfColor textColor = PdfColors.white,
    double fontSize = 8.5,
  }) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(horizontal: 5, vertical: 3),
      child: pw.Text(
        text,
        textAlign: centered ? pw.TextAlign.center : pw.TextAlign.left,
        style: pw.TextStyle(
          fontSize: fontSize,
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
  pw.Widget _sigBlock(
    String label,
    PdfColor lineColor, {
    String? signatoryName,
    pw.Font? signatureFont,
  }) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.center,
      children: [
        pw.Container(
          width: 120,
          height: 30, // reserved space for signature
          alignment: pw.Alignment.bottomCenter,
          child: (signatoryName != null && signatureFont != null)
              ? pw.FittedBox(
                  fit: pw.BoxFit.scaleDown,
                  child: pw.Text(
                    signatoryName,
                    maxLines: 1,
                    style: pw.TextStyle(
                      font: signatureFont,
                      fontSize: 20,
                      color: PdfColors.black,
                    ),
                  ),
                )
              : pw.SizedBox(),
        ),
        pw.Container(
          width: 120,
          child: pw.Divider(color: lineColor, thickness: 0.8),
        ),
        pw.SizedBox(height: 4),
        pw.Text(
          label,
          style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700),
          textAlign: pw.TextAlign.center,
        ),
      ],
    );
  }

  /// Signature block for Minimal template
  pw.Widget _minimalSigBlock(
    String label, {
    String? signatoryName,
    pw.Font? signatureFont,
  }) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.center,
      children: [
        pw.Container(
          width: 130,
          height: 30, // reserved space for signature
          alignment: pw.Alignment.bottomCenter,
          child: (signatoryName != null && signatureFont != null)
              ? pw.Text(
                  signatoryName,
                  style: pw.TextStyle(
                    font: signatureFont,
                    fontSize: 20,
                    color: PdfColors.black,
                  ),
                )
              : pw.SizedBox(),
        ),
        pw.Container(
          width: 130,
          child: pw.Divider(color: PdfColors.black, thickness: 0.8),
        ),
        pw.SizedBox(height: 2),
        pw.Text(
          label,
          style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700),
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
          'Admit Card - ${widget.exam.name}',
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        backgroundColor: AppColors.primaryAdmin,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.playlist_remove_rounded),
            tooltip: 'Include/Exclude Students',
            onPressed: _allFetchedStudents.isEmpty
                ? null
                : _showExcludeStudentsDialog,
          ),
          IconButton(
            icon: const Icon(Icons.print_outlined),
            tooltip: 'Print',
            onPressed: _pdfBytes == null
                ? null
                : () async {
                    await Printing.layoutPdf(onLayout: (_) async => _pdfBytes!);
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
          _buildInstructionInput(),
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
                          color: isSelected
                              ? t.accentColor
                              : Colors.grey.shade400,
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
          const Icon(
            Icons.filter_list,
            size: 16,
            color: AppColors.primaryAdmin,
          ),
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

  // ── Top Instruction Input ──────────────────────────────────────────────────
  Widget _buildInstructionInput() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: Colors.white,
      child: TextField(
        controller: _instructionController,
        decoration: InputDecoration(
          labelText: 'Top Instruction (Optional)',
          hintText: 'e.g. Please bring your ID card...',
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 12,
          ),
          isDense: true,
          suffixIcon: IconButton(
            icon: const Icon(
              Icons.check_circle_outline,
              color: AppColors.primaryAdmin,
            ),
            onPressed: () {
              if (_topInstruction != _instructionController.text) {
                setState(() => _topInstruction = _instructionController.text);
                _generatePdf();
              }
            },
          ),
        ),
        onSubmitted: (value) {
          if (_topInstruction != value) {
            setState(() => _topInstruction = value);
            _generatePdf();
          }
        },
      ),
    );
  }

  // ── Exclude Students Dialog ────────────────────────────────────────────────
  void _showExcludeStudentsDialog() {
    if (_allFetchedStudents.isEmpty) return;

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setStateDialog) {
            return AlertDialog(
              title: const Text(
                'Include / Exclude Students',
                style: TextStyle(fontSize: 16),
              ),
              content: Container(
                width: 400,
                height: MediaQuery.of(context).size.height * 0.6,
                child: ListView.builder(
                  shrinkWrap: false,
                  itemCount: _allFetchedStudents.length,
                  itemBuilder: (context, index) {
                    final student = _allFetchedStudents[index];
                    final isExcluded = _excludedStudentIds.contains(
                      student.userId,
                    );
                    return CheckboxListTile(
                      value: !isExcluded,
                      dense: true,
                      title: Text(
                        student.user?.name ?? 'Unknown',
                        style: const TextStyle(fontSize: 14),
                      ),
                      subtitle: Text(
                        'Roll: ${student.rollId}',
                        style: const TextStyle(fontSize: 12),
                      ),
                      onChanged: (val) {
                        setStateDialog(() {
                          if (val == true) {
                            _excludedStudentIds.remove(student.userId);
                          } else {
                            _excludedStudentIds.add(student.userId);
                          }
                        });
                      },
                    );
                  },
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () {
                    Navigator.pop(ctx);
                    setState(() {
                      _currentStudents = _allFetchedStudents
                          .where((s) => !_excludedStudentIds.contains(s.userId))
                          .toList();
                    });
                    _generatePdf();
                  },
                  child: const Text('Apply'),
                ),
              ],
            );
          },
        );
      },
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
    if (_isLoading) {
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
    if (_errorMsg != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Text(
            'Error generating PDF:\n$_errorMsg',
            style: const TextStyle(color: Colors.red),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }
    if (_pdfBytes == null || _currentStudents.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.person_off_outlined,
              size: 64,
              color: Colors.grey.shade300,
            ),
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
