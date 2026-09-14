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
  bool _isLoading = true;
  String? _errorMsg;
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
              _currentStudents = List.from(
                context.read<StudentsNotifier>().students,
              );
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
    final logoFuture = safeImage(schoolLogoUrl);

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

      // Subjects for this specific student (all their enrolled classes).
      final studentSubjects = subjectsForStudent(student);

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
        border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.4),
        columnWidths: const {
          0: pw.FixedColumnWidth(18),
          1: pw.FlexColumnWidth(2.5),
          2: pw.FlexColumnWidth(2.2),
        },
        children: [
          pw.TableRow(
            decoration: const pw.BoxDecoration(color: primary),
            children: [
              _tCell('#', isHeader: true, fontSize: 7),
              _tCell('Subject', isHeader: true, fontSize: 7),
              _tCell('Date / Day', isHeader: true, fontSize: 7),
            ],
          ),
          ...rows.asMap().entries.map((e) {
            final idx = startIndex + e.key;
            final a = e.value;
            final bg = idx.isEven ? PdfColors.white : light;
            return pw.TableRow(
              decoration: pw.BoxDecoration(color: bg),
              children: [
                _tCell('${idx + 1}', centered: true, fontSize: 7),
                _tCell(a.subjectName, fontSize: 7),
                _tCell(
                  '${DateFormat('dd/MM/yy').format(a.date)} (${DateFormat('EEE').format(a.date)})',
                  fontSize: 7,
                ),
              ],
            );
          }),
        ],
      );
    }

    return pw.Container(
      color: PdfColors.white,
      padding: const pw.EdgeInsets.fromLTRB(28, 16, 28, 14),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.stretch,
        children: [
          // ── Compact letterhead ─────────────────────────────────────────
          pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.center,
            children: [
              if (schoolLogo != null)
                pw.Container(
                  width: 48,
                  height: 48,
                  margin: const pw.EdgeInsets.only(right: 12),
                  decoration: pw.BoxDecoration(
                    shape: pw.BoxShape.circle,
                    border: pw.Border.all(color: primary, width: 1.5),
                    image: pw.DecorationImage(image: schoolLogo, fit: pw.BoxFit.contain),
                  ),
                ),
              pw.Expanded(
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.center,
                  children: [
                    pw.Text(
                      schoolName.toUpperCase(),
                      textAlign: pw.TextAlign.center,
                      style: pw.TextStyle(color: primary, fontWeight: pw.FontWeight.bold, fontSize: 14, letterSpacing: 0.8),
                    ),
                    if (schoolAddress.isNotEmpty)
                      pw.Text(schoolAddress, textAlign: pw.TextAlign.center, style: const pw.TextStyle(fontSize: 7.5, color: PdfColors.grey700)),
                    if (schoolPhone.isNotEmpty || schoolEmail.isNotEmpty)
                      pw.Text(
                        [if (schoolPhone.isNotEmpty) 'Ph: $schoolPhone', if (schoolEmail.isNotEmpty) 'Email: $schoolEmail'].join('   '),
                        textAlign: pw.TextAlign.center,
                        style: const pw.TextStyle(fontSize: 7, color: PdfColors.grey600),
                      ),
                  ],
                ),
              ),
              if (schoolLogo != null) pw.SizedBox(width: 60),
            ],
          ),

          pw.SizedBox(height: 5),
          pw.Container(height: 2.5, color: primary),
          pw.Container(height: 1.5, color: accent),
          pw.SizedBox(height: 4),

          // ── Title row ──────────────────────────────────────────────────
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.center,
            crossAxisAlignment: pw.CrossAxisAlignment.center,
            children: [
              pw.Container(
                padding: const pw.EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                decoration: pw.BoxDecoration(
                  color: primary,
                  borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
                ),
                child: pw.Text('ADMIT CARD',
                  style: pw.TextStyle(color: PdfColors.white, fontWeight: pw.FontWeight.bold, fontSize: 11, letterSpacing: 3)),
              ),
              pw.SizedBox(width: 10),
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(widget.exam.name.toUpperCase(),
                    style: pw.TextStyle(color: primary, fontWeight: pw.FontWeight.bold, fontSize: 8.5, letterSpacing: 1)),
                  if (widget.exam.startDate != null)
                    pw.Text(
                      '${DateFormat('dd MMM yyyy').format(widget.exam.startDate!)}  –  ${DateFormat('dd MMM yyyy').format(widget.exam.endDate ?? widget.exam.startDate!)}',
                      style: const pw.TextStyle(fontSize: 7, color: PdfColors.grey600)),
                ],
              ),
            ],
          ),
          pw.SizedBox(height: 5),

          // ── Student info box ───────────────────────────────────────────
          pw.Container(
            padding: const pw.EdgeInsets.all(7),
            decoration: pw.BoxDecoration(
              border: pw.Border.all(color: PdfColors.grey300, width: 0.8),
              borderRadius: const pw.BorderRadius.all(pw.Radius.circular(5)),
            ),
            child: pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.center,
              children: [
                pw.Container(
                  width: 68, height: 88,
                  decoration: pw.BoxDecoration(
                    color: light,
                    borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
                    border: pw.Border.all(color: PdfColors.grey300),
                  ),
                  child: avatar != null
                      ? pw.ClipRRect(horizontalRadius: 4, verticalRadius: 4, child: pw.Image(avatar, fit: pw.BoxFit.cover))
                      : pw.Center(child: pw.Text(
                          student.user?.name.isNotEmpty == true ? student.user!.name[0].toUpperCase() : '?',
                          style: pw.TextStyle(fontSize: 26, fontWeight: pw.FontWeight.bold, color: primary))),
                ),
                pw.SizedBox(width: 10),
                pw.Expanded(
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(student.user?.name ?? 'N/A',
                        style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold, color: primary)),
                      pw.SizedBox(height: 5),
                      pw.Row(children: [
                        pw.Expanded(child: _classicField('Roll No.', student.rollId, primary: primary)),
                        pw.SizedBox(width: 8),
                        pw.Expanded(child: _classicField('Class / Section', '$className  –  $sectionName', primary: primary)),
                        pw.SizedBox(width: 8),
                        pw.Expanded(child: _classicField('Contact', student.guardianContact.isNotEmpty ? student.guardianContact : (student.user?.phone ?? 'N/A'), primary: primary)),
                        pw.SizedBox(width: 8),
                        pw.Expanded(child: _classicField('Email', student.user?.email ?? 'N/A', primary: primary)),
                      ]),
                    ],
                  ),
                ),
                pw.Container(
                  width: 18, height: 88,
                  decoration: pw.BoxDecoration(
                    color: accent,
                    borderRadius: const pw.BorderRadius.only(topRight: pw.Radius.circular(4), bottomRight: pw.Radius.circular(4)),
                  ),
                  child: pw.Center(
                    child: pw.Transform.rotateBox(
                      angle: 1.5708,
                      child: pw.Text('ROLL: ${student.rollId}',
                        style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 6, color: PdfColors.black)),
                    ),
                  ),
                ),
              ],
            ),
          ),

          pw.SizedBox(height: 6),

          // ── Schedule heading ────────────────────────────────────────────
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text('EXAMINATION SCHEDULE',
                style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 8.5, color: primary, letterSpacing: 0.8)),
              pw.Container(
                padding: const pw.EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: pw.BoxDecoration(color: accent, borderRadius: const pw.BorderRadius.all(pw.Radius.circular(3))),
                child: pw.Text('${subjects.length} Subject${subjects.length == 1 ? '' : 's'}',
                  style: pw.TextStyle(fontSize: 7, fontWeight: pw.FontWeight.bold, color: PdfColors.black)),
              ),
            ],
          ),
          pw.SizedBox(height: 4),

          // ── 2-column subject table ──────────────────────────────────────
          if (subjects.isEmpty)
            pw.Container(
              padding: const pw.EdgeInsets.all(7),
              color: PdfColors.grey100,
              child: pw.Text('No subjects scheduled.', style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600), textAlign: pw.TextAlign.center),
            )
          else
            pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Expanded(child: subjectTable(leftSubjects, 0)),
                pw.SizedBox(width: 6),
                pw.Expanded(child: subjectTable(rightSubjects, half)),
              ],
            ),

          pw.Spacer(),

          // ── Instructions ───────────────────────────────────────────────
          pw.Container(
            padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 5),
            decoration: pw.BoxDecoration(
              color: light,
              borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
              border: pw.Border.all(color: PdfColors.deepPurple200, width: 0.4),
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text('IMPORTANT INSTRUCTIONS',
                  style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 7, color: primary, letterSpacing: 0.5)),
                pw.SizedBox(height: 3),
                pw.Wrap(
                  spacing: 20,
                  runSpacing: 1,
                  children: _instructions.asMap().entries.map((e) {
                    return pw.SizedBox(
                      width: 230,
                      child: pw.Text('${e.key + 1}.  ${e.value}',
                        style: const pw.TextStyle(fontSize: 7, color: PdfColors.grey800)),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),

          pw.SizedBox(height: 6),

          // ── Signatures ─────────────────────────────────────────────────
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            crossAxisAlignment: pw.CrossAxisAlignment.end,
            children: [
              _sigBlock('Student Signature', primary),
              _sigBlock('Parent / Guardian', primary),
              _sigBlock('Principal Signature', primary),
            ],
          ),

          pw.SizedBox(height: 5),
          pw.Container(height: 1.2, color: accent),
          pw.Container(height: 2.5, color: primary),
          pw.SizedBox(height: 2),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text('Issued by $schoolName', style: const pw.TextStyle(fontSize: 6.5, color: PdfColors.grey600)),
              pw.Text('Date: ${DateFormat('dd MMM yyyy').format(DateTime.now())}', style: const pw.TextStyle(fontSize: 6.5, color: PdfColors.grey600)),
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
  }) {
    const primary = PdfColor.fromInt(0xFF1A237E);
    const secondary = PdfColor.fromInt(0xFF00695C);
    const accent = PdfColor.fromInt(0xFFFFA000);
    const bgLight = PdfColor.fromInt(0xFFF3F4FF);

    final half = (subjects.length / 2).ceil();
    final leftSubjects = subjects.take(half).toList();
    final rightSubjects = subjects.skip(half).toList();

    final rowColors = <PdfColor>[
      secondary, primary,
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
            padding: const pw.EdgeInsets.symmetric(horizontal: 5, vertical: 3),
            color: primary,
            child: pw.Row(children: [
              pw.SizedBox(width: 17, child: pw.Text('#', style: pw.TextStyle(color: PdfColors.white, fontWeight: pw.FontWeight.bold, fontSize: 6.5))),
              pw.Expanded(flex: 3, child: pw.Text('Subject', style: pw.TextStyle(color: PdfColors.white, fontWeight: pw.FontWeight.bold, fontSize: 6.5))),
              pw.Expanded(flex: 2, child: pw.Text('Date & Day', style: pw.TextStyle(color: PdfColors.white, fontWeight: pw.FontWeight.bold, fontSize: 6.5))),
            ]),
          ),
          ...rows.asMap().entries.map((e) {
            final idx = startIndex + e.key;
            final a = e.value;
            final color = rowColors[idx % rowColors.length];
            return pw.Container(
              decoration: pw.BoxDecoration(
                color: idx.isEven ? PdfColors.white : bgLight,
                border: const pw.Border(bottom: pw.BorderSide(color: PdfColors.grey200, width: 0.3)),
              ),
              child: pw.Row(children: [
                pw.Container(
                  width: 17,
                  padding: const pw.EdgeInsets.symmetric(vertical: 3),
                  color: color,
                  child: pw.Center(child: pw.Text('${idx + 1}',
                    style: pw.TextStyle(color: PdfColors.white, fontWeight: pw.FontWeight.bold, fontSize: 6))),
                ),
                pw.Expanded(flex: 3, child: pw.Padding(
                  padding: const pw.EdgeInsets.symmetric(horizontal: 5, vertical: 2.5),
                  child: pw.Text(a.subjectName,
                    style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 6.5, color: primary), maxLines: 1),
                )),
                pw.Expanded(flex: 2, child: pw.Padding(
                  padding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 2.5),
                  child: pw.Text('${DateFormat('dd/MM/yy').format(a.date)} (${DateFormat('EEE').format(a.date)})',
                    style: const pw.TextStyle(fontSize: 6.5, color: PdfColors.grey700)),
                )),
              ]),
            );
          }),
        ],
      );
    }

    return pw.Stack(
      children: [
        pw.Positioned.fill(child: pw.Container(color: PdfColors.white)),
        pw.Positioned(top: 0, left: 0, right: 0,
          child: pw.SizedBox(height: 106, child: pw.Container(color: primary))),
        pw.Positioned(top: 0, right: 0, bottom: 0,
          child: pw.SizedBox(width: 6, child: pw.Container(color: secondary))),

        pw.Padding(
          padding: const pw.EdgeInsets.fromLTRB(22, 12, 34, 12),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // ── School header ───────────────────────────────────────────
              pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.center,
                children: [
                  if (schoolLogo != null)
                    pw.Container(
                      width: 42, height: 42,
                      margin: const pw.EdgeInsets.only(right: 10),
                      decoration: pw.BoxDecoration(
                        shape: pw.BoxShape.circle, color: PdfColors.white,
                        border: pw.Border.all(color: accent, width: 2),
                        image: pw.DecorationImage(image: schoolLogo, fit: pw.BoxFit.contain),
                      ),
                    ),
                  pw.Expanded(
                    child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
                      pw.Text(schoolName.toUpperCase(),
                        style: pw.TextStyle(color: PdfColors.white, fontWeight: pw.FontWeight.bold, fontSize: 12, letterSpacing: 0.4)),
                      if (schoolAddress.isNotEmpty)
                        pw.Text(schoolAddress, style: const pw.TextStyle(color: PdfColors.indigo100, fontSize: 7)),
                      if (schoolPhone.isNotEmpty || schoolEmail.isNotEmpty)
                        pw.Text(
                          [if (schoolPhone.isNotEmpty) schoolPhone, if (schoolEmail.isNotEmpty) schoolEmail].join('  |  '),
                          style: const pw.TextStyle(color: PdfColors.indigo200, fontSize: 6.5)),
                    ]),
                  ),
                  pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.end, children: [
                    pw.Container(
                      padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: pw.BoxDecoration(color: accent, borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4))),
                      child: pw.Text('ADMIT CARD',
                        style: pw.TextStyle(color: PdfColors.black, fontWeight: pw.FontWeight.bold, fontSize: 9, letterSpacing: 1.5)),
                    ),
                    pw.SizedBox(height: 3),
                    pw.Text(widget.exam.name, style: const pw.TextStyle(color: PdfColors.white, fontSize: 7.5)),
                    if (widget.exam.startDate != null)
                      pw.Text(
                        '${DateFormat('dd MMM yy').format(widget.exam.startDate!)} – ${DateFormat('dd MMM yy').format(widget.exam.endDate ?? widget.exam.startDate!)}',
                        style: const pw.TextStyle(color: PdfColors.indigo100, fontSize: 6.5)),
                  ]),
                ],
              ),

              pw.SizedBox(height: 7),

              // ── Student card ─────────────────────────────────────────────
              pw.Container(
                decoration: pw.BoxDecoration(
                  color: PdfColors.white,
                  borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
                  boxShadow: const [pw.BoxShadow(color: PdfColors.grey400, blurRadius: 4, offset: PdfPoint(0, 2))],
                ),
                child: pw.Row(
                  crossAxisAlignment: pw.CrossAxisAlignment.center,
                  children: [
                    pw.Container(width: 5, height: 88,
                      decoration: const pw.BoxDecoration(
                        color: secondary,
                        borderRadius: pw.BorderRadius.only(topLeft: pw.Radius.circular(8), bottomLeft: pw.Radius.circular(8)),
                      ),
                    ),
                    pw.Container(
                      width: 66, height: 82,
                      margin: const pw.EdgeInsets.all(7),
                      decoration: pw.BoxDecoration(
                        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(5)),
                        border: pw.Border.all(color: secondary, width: 1.5),
                        color: bgLight,
                      ),
                      child: avatar != null
                          ? pw.ClipRRect(horizontalRadius: 4, verticalRadius: 4, child: pw.Image(avatar, fit: pw.BoxFit.cover))
                          : pw.Center(child: pw.Text(
                              student.user?.name.isNotEmpty == true ? student.user!.name[0].toUpperCase() : '?',
                              style: pw.TextStyle(fontSize: 26, fontWeight: pw.FontWeight.bold, color: primary))),
                    ),
                    pw.Expanded(
                      child: pw.Padding(
                        padding: const pw.EdgeInsets.symmetric(vertical: 7, horizontal: 6),
                        child: pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.start,
                          children: [
                            pw.Text(student.user?.name ?? 'N/A',
                              style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 12, color: primary)),
                            pw.SizedBox(height: 5),
                            pw.Wrap(spacing: 5, runSpacing: 4, children: [
                              _modernChip(Icons.tag, 'Roll No.', student.rollId, secondary),
                              _modernChip(Icons.school, 'Class', '$className - $sectionName', primary),
                              if (student.guardianContact.isNotEmpty)
                                _modernChip(Icons.phone, 'Contact', student.guardianContact, const PdfColor.fromInt(0xFF1565C0)),
                              if (student.user != null && student.user!.email.isNotEmpty)
                                _modernChip(Icons.email, 'Email', student.user!.email, const PdfColor.fromInt(0xFF6A1B9A)),
                            ]),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              pw.SizedBox(height: 7),

              // ── Schedule heading ──────────────────────────────────────────
              pw.Row(children: [
                pw.Container(width: 3, height: 12, color: secondary),
                pw.SizedBox(width: 6),
                pw.Text('EXAMINATION SCHEDULE',
                  style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 8.5, color: primary, letterSpacing: 0.8)),
                pw.Spacer(),
                pw.Container(
                  padding: const pw.EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                  decoration: pw.BoxDecoration(color: accent, borderRadius: const pw.BorderRadius.all(pw.Radius.circular(10))),
                  child: pw.Text('${subjects.length} Subjects',
                    style: pw.TextStyle(fontSize: 6.5, fontWeight: pw.FontWeight.bold, color: PdfColors.black)),
                ),
              ]),
              pw.SizedBox(height: 5),

              // ── 2-col subject table ───────────────────────────────────────
              if (subjects.isEmpty)
                pw.Container(padding: const pw.EdgeInsets.all(8), color: bgLight,
                  child: pw.Text('No subjects scheduled.', style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600)))
              else
                pw.Row(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Expanded(child: modernSubjectTable(leftSubjects, 0)),
                    pw.SizedBox(width: 6),
                    pw.Expanded(child: modernSubjectTable(rightSubjects, half)),
                  ],
                ),

              pw.Spacer(),
              pw.SizedBox(height: 7), // A tiny bit of minimum spacing in case it's tight

              // ── Instructions ──────────────────────────────────────────────
              pw.Container(
                padding: const pw.EdgeInsets.symmetric(horizontal: 7, vertical: 5),
                decoration: pw.BoxDecoration(
                  color: bgLight,
                  borderRadius: const pw.BorderRadius.all(pw.Radius.circular(5)),
                  border: pw.Border.all(color: PdfColors.indigo100, width: 0.4),
                ),
                child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
                  pw.Text('INSTRUCTIONS',
                    style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 7, color: primary, letterSpacing: 0.5)),
                  pw.SizedBox(height: 3),
                  pw.Wrap(spacing: 18, runSpacing: 1, children: _instructions.asMap().entries.map((e) {
                    return pw.SizedBox(
                      width: 228,
                      child: pw.Text('${e.key + 1}.  ${e.value}', style: const pw.TextStyle(fontSize: 7, color: PdfColors.grey800)),
                    );
                  }).toList()),
                ]),
              ),

              pw.SizedBox(height: 7),

              // ── Signatures + barcode ──────────────────────────────────────
              pw.Row(crossAxisAlignment: pw.CrossAxisAlignment.end, mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children: [
                _sigBlock('Student Signature', primary),
                pw.Column(children: [
                  pw.BarcodeWidget(
                    data: student.userId.isNotEmpty ? student.userId : student.rollId,
                    barcode: pw.Barcode.code128(),
                    width: 78, height: 20,
                    drawText: false,
                    color: primary,
                  ),
                  pw.SizedBox(height: 2),
                  pw.Text(student.rollId, style: const pw.TextStyle(fontSize: 6.5, color: PdfColors.grey600)),
                ]),
                _sigBlock('Principal Signature', primary),
              ]),

              pw.SizedBox(height: 5),

              // ── Footer ────────────────────────────────────────────────────
              pw.Container(
                padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: const pw.BoxDecoration(color: primary),
                child: pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children: [
                  pw.Text('$schoolName  |  Issued ${DateFormat('dd MMM yyyy').format(DateTime.now())}',
                    style: const pw.TextStyle(fontSize: 6.5, color: PdfColors.white)),
                  pw.Text('NOT VALID WITHOUT OFFICIAL SEAL',
                    style: pw.TextStyle(fontSize: 6.5, color: accent, fontWeight: pw.FontWeight.bold)),
                ]),
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
  }) {
    final half = (subjects.length / 2).ceil();
    final leftSubjects = subjects.take(half).toList();
    final rightSubjects = subjects.skip(half).toList();

    pw.Widget minSubjectTable(List<ExamAssignment> rows, int startIndex) {
      if (rows.isEmpty) return pw.SizedBox();
      return pw.Table(
        border: pw.TableBorder.all(color: PdfColors.black, width: 0.4),
        columnWidths: const {
          0: pw.FixedColumnWidth(18),
          1: pw.FlexColumnWidth(2.5),
          2: pw.FlexColumnWidth(2.2),
        },
        children: [
          pw.TableRow(
            decoration: const pw.BoxDecoration(color: PdfColors.grey800),
            children: [
              _tCell('SL', isHeader: true, centered: true, fontSize: 7),
              _tCell('Subject Name', isHeader: true, fontSize: 7),
              _tCell('Date (Day)', isHeader: true, fontSize: 7),
            ],
          ),
          ...rows.asMap().entries.map((e) {
            final idx = startIndex + e.key;
            final a = e.value;
            final bg = idx.isEven ? PdfColors.white : PdfColors.grey100;
            return pw.TableRow(
              decoration: pw.BoxDecoration(color: bg),
              children: [
                _tCell('${idx + 1}', centered: true, textColor: PdfColors.black, fontSize: 7),
                _tCell(a.subjectName, textColor: PdfColors.black, fontSize: 7),
                _tCell('${DateFormat('dd/MM/yy').format(a.date)} (${DateFormat('EEE').format(a.date)})',
                  textColor: PdfColors.black, fontSize: 7),
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
            child: pw.Container(margin: const pw.EdgeInsets.all(8),
              decoration: pw.BoxDecoration(border: pw.Border.all(color: PdfColors.black, width: 2))),
          ),
          pw.Positioned.fill(
            child: pw.Container(margin: const pw.EdgeInsets.all(12),
              decoration: pw.BoxDecoration(border: pw.Border.all(color: PdfColors.black, width: 0.5))),
          ),

          pw.Padding(
            padding: const pw.EdgeInsets.fromLTRB(24, 16, 24, 14),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.stretch,
              children: [
                // ── Letterhead ─────────────────────────────────────────────
                pw.Row(
                  crossAxisAlignment: pw.CrossAxisAlignment.center,
                  mainAxisAlignment: pw.MainAxisAlignment.center,
                  children: [
                    if (schoolLogo != null)
                      pw.Container(width: 44, height: 44, margin: const pw.EdgeInsets.only(right: 12),
                        child: pw.Image(schoolLogo, fit: pw.BoxFit.contain)),
                    pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.center, children: [
                      pw.Text(schoolName.toUpperCase(), textAlign: pw.TextAlign.center,
                        style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 14, letterSpacing: 1.2)),
                      if (schoolAddress.isNotEmpty)
                        pw.Text(schoolAddress, textAlign: pw.TextAlign.center,
                          style: const pw.TextStyle(fontSize: 7.5, color: PdfColors.grey700)),
                      if (schoolPhone.isNotEmpty || schoolEmail.isNotEmpty)
                        pw.Text(
                          [if (schoolPhone.isNotEmpty) 'Ph: $schoolPhone', if (schoolEmail.isNotEmpty) schoolEmail].join('     '),
                          textAlign: pw.TextAlign.center,
                          style: const pw.TextStyle(fontSize: 7, color: PdfColors.grey600)),
                    ]),
                  ],
                ),

                pw.SizedBox(height: 5),
                pw.Divider(thickness: 2, color: PdfColors.black),
                pw.Divider(thickness: 0.5, color: PdfColors.black),
                pw.SizedBox(height: 3),

                // ── Title inline ────────────────────────────────────────────
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.center,
                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                  children: [
                    pw.Text('ADMIT CARD',
                      style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 15, letterSpacing: 5)),
                    pw.SizedBox(width: 10),
                    pw.Text('–  ${widget.exam.name.toUpperCase()}',
                      style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 8.5, letterSpacing: 1.5, color: PdfColors.grey700)),
                    if (widget.exam.startDate != null) ...[
                      pw.SizedBox(width: 8),
                      pw.Text(
                        '(${DateFormat('dd MMM yy').format(widget.exam.startDate!)} – ${DateFormat('dd MMM yy').format(widget.exam.endDate ?? widget.exam.startDate!)})',
                        style: const pw.TextStyle(fontSize: 7.5, color: PdfColors.grey600)),
                    ],
                  ],
                ),

                pw.SizedBox(height: 4),
                pw.Divider(thickness: 0.5, color: PdfColors.black),
                pw.SizedBox(height: 5),

                // ── Student info + photo ────────────────────────────────────
                pw.Row(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
                  pw.Container(
                    width: 70, height: 90,
                    margin: const pw.EdgeInsets.only(right: 12),
                    decoration: pw.BoxDecoration(border: pw.Border.all(color: PdfColors.black, width: 0.8)),
                    child: avatar != null
                        ? pw.Image(avatar, fit: pw.BoxFit.cover)
                        : pw.Center(child: pw.Text('PHOTO',
                            style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9, color: PdfColors.grey500))),
                  ),
                  pw.Expanded(
                    child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
                      _minimalField('Name of Student', student.user?.name ?? 'N/A', big: true),
                      pw.SizedBox(height: 3),
                      pw.Row(children: [
                        pw.Expanded(child: _minimalField('Roll No.', student.rollId)),
                        pw.SizedBox(width: 10),
                        pw.Expanded(child: _minimalField('Class / Section', '$className - $sectionName')),
                      ]),
                      pw.SizedBox(height: 3),
                      pw.Row(children: [
                        pw.Expanded(child: _minimalField('Guardian Contact',
                          student.guardianContact.isNotEmpty ? student.guardianContact : (student.user?.phone ?? 'N/A'))),
                        pw.SizedBox(width: 10),
                        pw.Expanded(child: _minimalField('Email', student.user?.email ?? 'N/A')),
                      ]),
                    ]),
                  ),
                ]),

                pw.SizedBox(height: 5),
                pw.Divider(thickness: 0.5, color: PdfColors.black),
                pw.SizedBox(height: 4),

                // ── Schedule ────────────────────────────────────────────────
                pw.Text(
                  'EXAMINATION SCHEDULE  (${subjects.length} Subject${subjects.length == 1 ? '' : 's'})',
                  style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 8, letterSpacing: 0.5)),
                pw.SizedBox(height: 4),

                if (subjects.isEmpty)
                  pw.Text('No subjects scheduled.', style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey500))
                else
                  pw.Row(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
                    pw.Expanded(child: minSubjectTable(leftSubjects, 0)),
                    pw.SizedBox(width: 6),
                    pw.Expanded(child: minSubjectTable(rightSubjects, half)),
                  ]),

                pw.Spacer(),
                pw.SizedBox(height: 5), // Minimum spacing

                // ── Instructions ────────────────────────────────────────────
                pw.Text('INSTRUCTIONS TO CANDIDATES:',
                  style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 7.5, letterSpacing: 0.4)),
                pw.SizedBox(height: 3),
                pw.Table(
                  columnWidths: const {
                    0: pw.FixedColumnWidth(10),
                    1: pw.FlexColumnWidth(1),
                    2: pw.FixedColumnWidth(10),
                    3: pw.FlexColumnWidth(1),
                  },
                  children: List.generate((_instructions.length / 2).ceil(), (row) {
                    final left = row * 2;
                    final right = left + 1;
                    return pw.TableRow(children: [
                      pw.Padding(padding: const pw.EdgeInsets.only(bottom: 1),
                        child: pw.Text('${left + 1}.', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 7))),
                      pw.Padding(padding: const pw.EdgeInsets.only(bottom: 1, right: 8),
                        child: pw.Text(_instructions[left], style: const pw.TextStyle(fontSize: 7))),
                      pw.Padding(padding: const pw.EdgeInsets.only(bottom: 1),
                        child: pw.Text(right < _instructions.length ? '${right + 1}.' : '',
                          style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 7))),
                      pw.Padding(padding: const pw.EdgeInsets.only(bottom: 1),
                        child: pw.Text(right < _instructions.length ? _instructions[right] : '',
                          style: const pw.TextStyle(fontSize: 7))),
                    ]);
                  }),
                ),

                pw.SizedBox(height: 7),
                pw.Divider(thickness: 0.5, color: PdfColors.black),
                pw.SizedBox(height: 5),

                // ── Signatures ──────────────────────────────────────────────
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                  children: [
                    _minimalSigBlock("Student's Signature"),
                    pw.Container(
                      width: 58, height: 58,
                      decoration: pw.BoxDecoration(
                        border: pw.Border.all(color: PdfColors.grey400, width: 0.8),
                        shape: pw.BoxShape.circle,
                      ),
                      child: pw.Center(child: pw.Text('OFFICIAL\nSEAL',
                        textAlign: pw.TextAlign.center,
                        style: const pw.TextStyle(fontSize: 7, color: PdfColors.grey500))),
                    ),
                    _minimalSigBlock("Principal's Signature"),
                  ],
                ),

                pw.SizedBox(height: 4),
                pw.Divider(thickness: 0.5),
                pw.SizedBox(height: 2),
                pw.Center(
                  child: pw.Text(
                    'Computer-generated by $schoolName. Issued on ${DateFormat('dd MMMM yyyy').format(DateTime.now())}.',
                    textAlign: pw.TextAlign.center,
                    style: const pw.TextStyle(fontSize: 6.5, color: PdfColors.grey500)),
                ),
              ],
            ),
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
  }) {
    const primary = PdfColor.fromInt(0xFF00695C); // teal 800
    const accent = PdfColor.fromInt(0xFFFFA000); // amber 700
    const bgLight = PdfColor.fromInt(0xFFE0F2F1); // teal 50

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
          'Admit Card - ${widget.exam.name}',
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
