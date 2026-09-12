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
enum AdmitCardTemplate { classic, modern, minimal }

extension AdmitCardTemplateExt on AdmitCardTemplate {
  String get label {
    switch (this) {
      case AdmitCardTemplate.classic:
        return 'Classic';
      case AdmitCardTemplate.modern:
        return 'Modern';
      case AdmitCardTemplate.minimal:
        return 'Minimal';
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
    }
  }

  Color get accentColor {
    switch (this) {
      case AdmitCardTemplate.classic:
        return Colors.deepPurple;
      case AdmitCardTemplate.modern:
        return Colors.indigo;
      case AdmitCardTemplate.minimal:
        return Colors.blueGrey;
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

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _generatePdf();
    });
  }

  // ── PDF generation ─────────────────────────────────────────────────────────

  Future<void> _generatePdf() async {
    if (!mounted) return;
    setState(() => _isLoading = true);

    final authNotifier = context.read<AuthNotifier>();
    final school = authNotifier.user?.school;

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
              _currentStudents = List.from(
                context.read<StudentsNotifier>().students,
              );
            });
            _generatePdf();
          }
        });
  }

  // ── Build the PDF document ──────────────────────────────────────────────────

  Future<Uint8List> _buildPdf(PdfPageFormat format, School? school) async {
    final pdf = pw.Document();

    // ── Resolve class / section names ──
    String resolvedClassName = 'N/A';
    if (_selectedClassId != null) {
      try {
        resolvedClassName = context
            .read<ClassSetupNotifier>()
            .classes
            .firstWhere((c) => c.id == _selectedClassId)
            .name;
      } catch (_) {}
    }

    String resolvedSectionName = 'N/A';
    if (_selectedSectionId != null) {
      try {
        resolvedSectionName = context
            .read<SectionSetupNotifier>()
            .sections
            .firstWhere((s) => s.id == _selectedSectionId)
            .name;
      } catch (_) {}
    }

    // ── School metadata ──
    final schoolName = school?.name ?? 'School Name';
    final schoolAddress = school?.address ?? '';
    final schoolPhone = school?.phone ?? '';
    final schoolEmail = school?.email ?? '';
    final schoolLogoUrl = school?.avatar ?? '';

    pw.ImageProvider? schoolLogo;
    if (schoolLogoUrl.isNotEmpty) {
      try {
        schoolLogo =
            await PdfImageHelper.getCachedImageProvider(schoolLogoUrl);
      } catch (_) {}
    }

    // ── Student avatars ──
    final Map<String, pw.ImageProvider> avatars = {};
    for (final student in _currentStudents) {
      final url = student.user?.avatar ?? '';
      if (url.isNotEmpty) {
        try {
          avatars[student.userId] =
              await PdfImageHelper.getCachedImageProvider(url);
        } catch (_) {}
      }
    }

    // ── Subjects for the chosen class ──
    final List<ExamAssignment> subjectAssignments = widget.exam.assignments
        .where((a) {
          if (_selectedClassId != null && a.classId != _selectedClassId) {
            return false;
          }
          if (_selectedSectionId != null &&
              a.sectionId != null &&
              a.sectionId != _selectedSectionId) {
            return false;
          }
          return true;
        })
        .toList();

    // ── Emit one page per student ──
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
          margin: const pw.EdgeInsets.all(0),
          build: (pw.Context ctx) {
            switch (_selectedTemplate) {
              case AdmitCardTemplate.classic:
                return _buildClassicTemplate(
                  student,
                  className,
                  sectionName,
                  schoolName,
                  schoolAddress,
                  schoolPhone,
                  schoolEmail,
                  schoolLogo,
                  avatar,
                  subjectAssignments,
                );
              case AdmitCardTemplate.modern:
                return _buildModernTemplate(
                  student,
                  className,
                  sectionName,
                  schoolName,
                  schoolAddress,
                  schoolPhone,
                  schoolEmail,
                  schoolLogo,
                  avatar,
                  subjectAssignments,
                );
              case AdmitCardTemplate.minimal:
                return _buildMinimalTemplate(
                  student,
                  className,
                  sectionName,
                  schoolName,
                  schoolAddress,
                  schoolPhone,
                  schoolEmail,
                  schoolLogo,
                  avatar,
                  subjectAssignments,
                );
            }
          },
        ),
      );
    }

    return pdf.save();
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // Template 1 – CLASSIC
  // ═══════════════════════════════════════════════════════════════════════════
  pw.Widget _buildClassicTemplate(
    Student student,
    String className,
    String sectionName,
    String schoolName,
    String schoolAddress,
    String schoolPhone,
    String schoolEmail,
    pw.ImageProvider? schoolLogo,
    pw.ImageProvider? avatar,
    List<ExamAssignment> subjects,
  ) {
    const headerColor = PdfColors.deepPurple;
    const accentColor = PdfColors.amber;

    return pw.Container(
      color: PdfColors.white,
      padding: const pw.EdgeInsets.all(32),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          // ── Header bar ──────────────────────────────────────────
          pw.Container(
            padding: const pw.EdgeInsets.symmetric(
              vertical: 14,
              horizontal: 16,
            ),
            decoration: const pw.BoxDecoration(
              color: headerColor,
              borderRadius: pw.BorderRadius.all(pw.Radius.circular(8)),
            ),
            child: pw.Row(
              children: [
                if (schoolLogo != null)
                  pw.Container(
                    width: 50,
                    height: 50,
                    margin: const pw.EdgeInsets.only(right: 12),
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
                          fontSize: 14,
                        ),
                      ),
                      if (schoolAddress.isNotEmpty)
                        pw.Text(
                          schoolAddress,
                          style: const pw.TextStyle(
                            color: PdfColors.grey300,
                            fontSize: 8,
                          ),
                        ),
                      if (schoolPhone.isNotEmpty || schoolEmail.isNotEmpty)
                        pw.Text(
                          [
                            if (schoolPhone.isNotEmpty) 'Ph: $schoolPhone',
                            if (schoolEmail.isNotEmpty) schoolEmail,
                          ].join('  |  '),
                          style: const pw.TextStyle(
                            color: PdfColors.amber,
                            fontSize: 7,
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          pw.SizedBox(height: 12),

          // ── "ADMIT CARD" banner ──
          pw.Container(
            width: double.infinity,
            padding: const pw.EdgeInsets.symmetric(vertical: 6),
            decoration: const pw.BoxDecoration(
              border: pw.Border(
                top: pw.BorderSide(color: accentColor, width: 2),
                bottom: pw.BorderSide(color: accentColor, width: 2),
              ),
            ),
            child: pw.Text(
              'ADMIT CARD  —  ${widget.exam.name.toUpperCase()}',
              style: pw.TextStyle(
                fontWeight: pw.FontWeight.bold,
                fontSize: 12,
                color: headerColor,
                letterSpacing: 1.5,
              ),
              textAlign: pw.TextAlign.center,
            ),
          ),

          pw.SizedBox(height: 18),

          // ── Student info row ──
          pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // Photo
              pw.Container(
                width: 90,
                height: 110,
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(color: headerColor, width: 2),
                  borderRadius:
                      const pw.BorderRadius.all(pw.Radius.circular(6)),
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
                            fontSize: 36,
                            fontWeight: pw.FontWeight.bold,
                            color: headerColor,
                          ),
                        ),
                      ),
              ),
              pw.SizedBox(width: 20),
              // Details
              pw.Expanded(
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    _classicDetailRow(
                      'Name',
                      student.user?.name ?? 'N/A',
                      bold: true,
                    ),
                    _classicDetailRow('Roll No.', student.rollId),
                    _classicDetailRow('Class', '$className - $sectionName'),
                    _classicDetailRow(
                      'Exam',
                      widget.exam.name,
                    ),
                    if (widget.exam.startDate != null)
                      _classicDetailRow(
                        'Exam Period',
                        '${DateFormat('dd MMM yyyy').format(widget.exam.startDate!)} '
                            '– ${DateFormat('dd MMM yyyy').format(widget.exam.endDate ?? widget.exam.startDate!)}',
                      ),
                  ],
                ),
              ),
            ],
          ),

          pw.SizedBox(height: 18),
          pw.Divider(color: PdfColors.deepPurple200, thickness: 0.8),
          pw.SizedBox(height: 8),

          // ── Subject table ──
          pw.Text(
            'EXAMINATION SCHEDULE',
            style: pw.TextStyle(
              fontWeight: pw.FontWeight.bold,
              fontSize: 10,
              color: headerColor,
              letterSpacing: 1,
            ),
          ),
          pw.SizedBox(height: 8),
          _buildClassicSubjectTable(subjects),

          pw.Spacer(),

          // ── Instructions box ──
          pw.Container(
            width: double.infinity,
            padding: const pw.EdgeInsets.all(10),
            decoration: pw.BoxDecoration(
              color: PdfColors.deepPurple50,
              borderRadius:
                  const pw.BorderRadius.all(pw.Radius.circular(6)),
              border: pw.Border.all(color: PdfColors.deepPurple100),
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  'INSTRUCTIONS',
                  style: pw.TextStyle(
                    fontWeight: pw.FontWeight.bold,
                    fontSize: 8,
                    color: headerColor,
                    letterSpacing: 0.8,
                  ),
                ),
                pw.SizedBox(height: 4),
                for (final instr in _admitCardInstructions)
                  pw.Padding(
                    padding: const pw.EdgeInsets.only(bottom: 2),
                    child: pw.Text(
                      '• $instr',
                      style: const pw.TextStyle(fontSize: 7.5),
                    ),
                  ),
              ],
            ),
          ),

          pw.SizedBox(height: 14),

          // ── Signatures ──
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            crossAxisAlignment: pw.CrossAxisAlignment.end,
            children: [
              _signatureBlock('Signature of Student'),
              _signatureBlock('Signature of Principal'),
            ],
          ),

          pw.SizedBox(height: 10),

          // ── Footer ──
          pw.Container(
            width: double.infinity,
            padding: const pw.EdgeInsets.symmetric(vertical: 6),
            decoration: const pw.BoxDecoration(
              color: headerColor,
              borderRadius:
                  pw.BorderRadius.all(pw.Radius.circular(6)),
            ),
            child: pw.Text(
              'This admit card is issued by $schoolName. Not valid without official seal.',
              textAlign: pw.TextAlign.center,
              style: const pw.TextStyle(
                color: PdfColors.white,
                fontSize: 7.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  pw.Widget _buildClassicSubjectTable(List<ExamAssignment> subjects) {
    if (subjects.isEmpty) {
      return pw.Text(
        'No subjects assigned.',
        style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey),
      );
    }
    const headerColor = PdfColors.deepPurple;
    return pw.Table(
      border: pw.TableBorder.all(color: PdfColors.deepPurple100),
      columnWidths: const {
        0: pw.FlexColumnWidth(0.5),
        1: pw.FlexColumnWidth(2),
        2: pw.FlexColumnWidth(1.5),
      },
      children: [
        // Header row
        pw.TableRow(
          decoration: const pw.BoxDecoration(color: headerColor),
          children: [
            _tableCell('No.', isHeader: true),
            _tableCell('Subject', isHeader: true),
            _tableCell('Date', isHeader: true),
          ],
        ),
        ...subjects.asMap().entries.map((e) {
          final i = e.key;
          final a = e.value;
          final bg = i.isEven ? PdfColors.white : PdfColors.deepPurple50;
          return pw.TableRow(
            decoration: pw.BoxDecoration(color: bg),
            children: [
              _tableCell('${i + 1}'),
              _tableCell(a.subjectName),
              _tableCell(DateFormat('dd MMM yyyy').format(a.date)),
            ],
          );
        }),
      ],
    );
  }

  pw.Widget _classicDetailRow(String label, String value,
      {bool bold = false}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 5),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.SizedBox(
            width: 70,
            child: pw.Text(
              label,
              style: pw.TextStyle(
                fontSize: 9,
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.deepPurple800,
              ),
            ),
          ),
          pw.Text(
            ': ',
            style: pw.TextStyle(
              fontWeight: pw.FontWeight.bold,
              fontSize: 9,
            ),
          ),
          pw.Expanded(
            child: pw.Text(
              value,
              style: pw.TextStyle(
                fontSize: 9,
                fontWeight:
                    bold ? pw.FontWeight.bold : pw.FontWeight.normal,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // Template 2 – MODERN
  // ═══════════════════════════════════════════════════════════════════════════
  pw.Widget _buildModernTemplate(
    Student student,
    String className,
    String sectionName,
    String schoolName,
    String schoolAddress,
    String schoolPhone,
    String schoolEmail,
    pw.ImageProvider? schoolLogo,
    pw.ImageProvider? avatar,
    List<ExamAssignment> subjects,
  ) {
    return pw.Stack(
      children: [
        // ── Gradient-ish background (two rectangles) ──
        pw.Positioned.fill(
          child: pw.Column(
            children: [
              pw.Container(height: 230, color: PdfColors.indigo700),
              pw.Expanded(child: pw.Container(color: PdfColors.white)),
            ],
          ),
        ),

        pw.Padding(
          padding: const pw.EdgeInsets.all(28),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // ── School header ──
              pw.Row(
                children: [
                  if (schoolLogo != null)
                    pw.Container(
                      width: 55,
                      height: 55,
                      margin: const pw.EdgeInsets.only(right: 14),
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
                            fontSize: 15,
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
                      ],
                    ),
                  ),
                ],
              ),

              pw.SizedBox(height: 6),
              pw.Container(
                width: double.infinity,
                padding: const pw.EdgeInsets.symmetric(vertical: 5),
                decoration: pw.BoxDecoration(
                  color: PdfColors.teal700,
                  borderRadius:
                      const pw.BorderRadius.all(pw.Radius.circular(4)),
                ),
                child: pw.Text(
                  'ADMIT CARD',
                  textAlign: pw.TextAlign.center,
                  style: pw.TextStyle(
                    color: PdfColors.white,
                    fontWeight: pw.FontWeight.bold,
                    fontSize: 12,
                    letterSpacing: 3,
                  ),
                ),
              ),

              pw.SizedBox(height: 16),

              // ── Student info card (floating) ──
              pw.Container(
                decoration: pw.BoxDecoration(
                  color: PdfColors.white,
                  borderRadius:
                      const pw.BorderRadius.all(pw.Radius.circular(10)),
                  boxShadow: const [
                    pw.BoxShadow(
                      color: PdfColors.indigo100,
                      blurRadius: 8,
                      offset: PdfPoint(0, 3),
                    ),
                  ],
                ),
                padding: const pw.EdgeInsets.all(16),
                child: pw.Row(
                  children: [
                    // Avatar
                    pw.Container(
                      width: 80,
                      height: 95,
                      margin: const pw.EdgeInsets.only(right: 16),
                      decoration: pw.BoxDecoration(
                        borderRadius:
                            const pw.BorderRadius.all(pw.Radius.circular(8)),
                        border: pw.Border.all(
                          color: PdfColors.teal300,
                          width: 2,
                        ),
                      ),
                      child: avatar != null
                          ? pw.ClipRRect(
                              horizontalRadius: 6,
                              verticalRadius: 6,
                              child:
                                  pw.Image(avatar, fit: pw.BoxFit.cover),
                            )
                          : pw.Center(
                              child: pw.Text(
                                student.user?.name.isNotEmpty == true
                                    ? student.user!.name[0].toUpperCase()
                                    : '?',
                                style: pw.TextStyle(
                                  fontSize: 30,
                                  fontWeight: pw.FontWeight.bold,
                                  color: PdfColors.indigo700,
                                ),
                              ),
                            ),
                    ),
                    pw.Expanded(
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text(
                            student.user?.name ?? 'N/A',
                            style: pw.TextStyle(
                              fontWeight: pw.FontWeight.bold,
                              fontSize: 13,
                              color: PdfColors.indigo900,
                            ),
                          ),
                          pw.SizedBox(height: 4),
                          _modernChip(
                            'Roll: ${student.rollId}',
                            PdfColors.indigo50,
                            PdfColors.indigo700,
                          ),
                          pw.SizedBox(height: 4),
                          _modernChip(
                            '$className – $sectionName',
                            PdfColors.teal50,
                            PdfColors.teal700,
                          ),
                          pw.SizedBox(height: 6),
                          pw.Text(
                            widget.exam.name,
                            style: pw.TextStyle(
                              fontWeight: pw.FontWeight.bold,
                              fontSize: 9,
                              color: PdfColors.grey700,
                            ),
                          ),
                          if (widget.exam.startDate != null)
                            pw.Text(
                              '${DateFormat('dd MMM yyyy').format(widget.exam.startDate!)} – ${DateFormat('dd MMM yyyy').format(widget.exam.endDate ?? widget.exam.startDate!)}',
                              style: const pw.TextStyle(
                                fontSize: 8,
                                color: PdfColors.grey,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              pw.SizedBox(height: 16),

              // ── Schedule header ──
              pw.Text(
                'EXAMINATION SCHEDULE',
                style: pw.TextStyle(
                  fontWeight: pw.FontWeight.bold,
                  fontSize: 10,
                  color: PdfColors.indigo700,
                  letterSpacing: 1,
                ),
              ),

              pw.SizedBox(height: 8),

              // ── Subject badges ──
              if (subjects.isEmpty)
                pw.Text(
                  'No subjects assigned.',
                  style: const pw.TextStyle(
                    fontSize: 9,
                    color: PdfColors.grey,
                  ),
                )
              else
                pw.Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: subjects.asMap().entries.map((e) {
                    final colors = [
                      [PdfColors.indigo700, PdfColors.indigo50],
                      [PdfColors.teal700, PdfColors.teal50],
                      [PdfColors.purple700, PdfColors.purple50],
                      [PdfColors.blue700, PdfColors.blue50],
                      [PdfColors.green700, PdfColors.green50],
                    ];
                    final c = colors[e.key % colors.length];
                    final a = e.value;
                    return pw.Container(
                      width: 145,
                      padding: const pw.EdgeInsets.all(8),
                      decoration: pw.BoxDecoration(
                        color: c[1],
                        borderRadius:
                            const pw.BorderRadius.all(pw.Radius.circular(6)),
                        border: pw.Border.all(color: c[0], width: 0.5),
                      ),
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text(
                            a.subjectName,
                            style: pw.TextStyle(
                              fontWeight: pw.FontWeight.bold,
                              fontSize: 9,
                              color: c[0],
                            ),
                          ),
                          pw.SizedBox(height: 3),
                          pw.Text(
                            DateFormat('EEEE, dd MMM yyyy').format(a.date),
                            style: pw.TextStyle(
                              fontSize: 7.5,
                              color: c[0],
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),

              pw.Spacer(),

              // ── Instructions ──
              pw.Container(
                width: double.infinity,
                padding: const pw.EdgeInsets.all(10),
                decoration: pw.BoxDecoration(
                  color: PdfColors.grey100,
                  borderRadius:
                      const pw.BorderRadius.all(pw.Radius.circular(6)),
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      'INSTRUCTIONS',
                      style: pw.TextStyle(
                        fontWeight: pw.FontWeight.bold,
                        fontSize: 8,
                        color: PdfColors.indigo700,
                      ),
                    ),
                    pw.SizedBox(height: 4),
                    for (final i in _admitCardInstructions)
                      pw.Text(
                        '• $i',
                        style: const pw.TextStyle(
                          fontSize: 7.5,
                          color: PdfColors.grey700,
                        ),
                      ),
                  ],
                ),
              ),

              pw.SizedBox(height: 14),

              // ── Signatures ──
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  _signatureBlock('Signature of Student'),
                  _signatureBlock('Signature of Principal'),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  pw.Widget _modernChip(
      String text, PdfColor bgColor, PdfColor textColor) {
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: pw.BoxDecoration(
        color: bgColor,
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(20)),
      ),
      child: pw.Text(
        text,
        style: pw.TextStyle(
          fontSize: 8,
          color: textColor,
          fontWeight: pw.FontWeight.bold,
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // Template 3 – MINIMAL
  // ═══════════════════════════════════════════════════════════════════════════
  pw.Widget _buildMinimalTemplate(
    Student student,
    String className,
    String sectionName,
    String schoolName,
    String schoolAddress,
    String schoolPhone,
    String schoolEmail,
    pw.ImageProvider? schoolLogo,
    pw.ImageProvider? avatar,
    List<ExamAssignment> subjects,
  ) {
    return pw.Container(
      color: PdfColors.white,
      padding: const pw.EdgeInsets.all(36),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          // ── School header – text only, no colors ──
          pw.Row(
            children: [
              if (schoolLogo != null)
                pw.Container(
                  width: 45,
                  height: 45,
                  margin: const pw.EdgeInsets.only(right: 12),
                  child: pw.Image(schoolLogo, fit: pw.BoxFit.contain),
                ),
              pw.Expanded(
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      schoolName.toUpperCase(),
                      style: pw.TextStyle(
                        fontWeight: pw.FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    if (schoolAddress.isNotEmpty)
                      pw.Text(
                        schoolAddress,
                        style: const pw.TextStyle(
                          fontSize: 8,
                          color: PdfColors.grey700,
                        ),
                      ),
                    if (schoolPhone.isNotEmpty || schoolEmail.isNotEmpty)
                      pw.Text(
                        [
                          if (schoolPhone.isNotEmpty) 'Ph: $schoolPhone',
                          if (schoolEmail.isNotEmpty) schoolEmail,
                        ].join('  |  '),
                        style: const pw.TextStyle(
                          fontSize: 7.5,
                          color: PdfColors.grey600,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),

          pw.SizedBox(height: 10),
          pw.Divider(thickness: 2, color: PdfColors.black),

          // ── Title ──
          pw.Center(
            child: pw.Text(
              'ADMIT CARD',
              style: pw.TextStyle(
                fontWeight: pw.FontWeight.bold,
                fontSize: 18,
                letterSpacing: 4,
              ),
            ),
          ),
          pw.Center(
            child: pw.Text(
              widget.exam.name,
              style: const pw.TextStyle(fontSize: 11, color: PdfColors.grey700),
            ),
          ),

          pw.SizedBox(height: 4),
          pw.Divider(thickness: 1, color: PdfColors.black),
          pw.SizedBox(height: 12),

          // ── Student details + photo ──
          pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Expanded(
                child: pw.Column(
                  children: [
                    _minimalDetailRow('Student Name', student.user?.name ?? 'N/A'),
                    _minimalDetailRow('Roll Number', student.rollId),
                    _minimalDetailRow('Class', '$className – $sectionName'),
                    if (widget.exam.startDate != null)
                      _minimalDetailRow(
                        'Exam Dates',
                        '${DateFormat('dd/MM/yyyy').format(widget.exam.startDate!)} to ${DateFormat('dd/MM/yyyy').format(widget.exam.endDate ?? widget.exam.startDate!)}',
                      ),
                  ],
                ),
              ),
              // Photo box
              pw.Container(
                width: 80,
                height: 100,
                margin: const pw.EdgeInsets.only(left: 16),
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(color: PdfColors.black, width: 1),
                ),
                child: avatar != null
                    ? pw.Image(avatar, fit: pw.BoxFit.cover)
                    : pw.Center(
                        child: pw.Text(
                          'PHOTO',
                          style: pw.TextStyle(
                            fontSize: 9,
                            color: PdfColors.grey,
                            fontWeight: pw.FontWeight.bold,
                          ),
                        ),
                      ),
              ),
            ],
          ),

          pw.SizedBox(height: 14),
          pw.Divider(thickness: 0.5, color: PdfColors.grey400),
          pw.SizedBox(height: 8),

          // ── Schedule table ──
          pw.Text(
            'EXAMINATION SCHEDULE',
            style: pw.TextStyle(
              fontWeight: pw.FontWeight.bold,
              fontSize: 10,
              letterSpacing: 0.8,
            ),
          ),
          pw.SizedBox(height: 8),

          if (subjects.isEmpty)
            pw.Text(
              'No subjects assigned.',
              style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey),
            )
          else
            pw.Table(
              border: pw.TableBorder.all(
                color: PdfColors.grey400,
                width: 0.5,
              ),
              columnWidths: const {
                0: pw.FlexColumnWidth(0.5),
                1: pw.FlexColumnWidth(2.5),
                2: pw.FlexColumnWidth(1.8),
              },
              children: [
                // Header
                pw.TableRow(
                  decoration: const pw.BoxDecoration(
                    color: PdfColors.grey300,
                  ),
                  children: [
                    _tableCell('No.', isHeader: true, textColor: PdfColors.black),
                    _tableCell('Subject', isHeader: true, textColor: PdfColors.black),
                    _tableCell('Date', isHeader: true, textColor: PdfColors.black),
                  ],
                ),
                ...subjects.asMap().entries.map((e) {
                  final i = e.key;
                  final a = e.value;
                  final bg = i.isEven ? PdfColors.white : PdfColors.grey100;
                  return pw.TableRow(
                    decoration: pw.BoxDecoration(color: bg),
                    children: [
                      _tableCell('${i + 1}', textColor: PdfColors.black),
                      _tableCell(a.subjectName, textColor: PdfColors.black),
                      _tableCell(
                        DateFormat('dd MMM yyyy').format(a.date),
                        textColor: PdfColors.black,
                      ),
                    ],
                  );
                }),
              ],
            ),

          pw.Spacer(),

          // ── Instructions ──
          pw.Text(
            'INSTRUCTIONS:',
            style: pw.TextStyle(
              fontWeight: pw.FontWeight.bold,
              fontSize: 9,
              letterSpacing: 0.5,
            ),
          ),
          pw.SizedBox(height: 4),
          for (final i in _admitCardInstructions)
            pw.Text(
              '${_admitCardInstructions.indexOf(i) + 1}. $i',
              style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey700),
            ),

          pw.SizedBox(height: 16),
          pw.Divider(thickness: 0.5),

          // ── Signatures ──
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              _signatureBlock('Signature of Student'),
              _signatureBlock('Signature of Principal'),
            ],
          ),
        ],
      ),
    );
  }

  pw.Widget _minimalDetailRow(String label, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 6),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.SizedBox(
            width: 85,
            child: pw.Text(
              label,
              style: pw.TextStyle(
                fontWeight: pw.FontWeight.bold,
                fontSize: 9,
              ),
            ),
          ),
          pw.Text(': ', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9)),
          pw.Expanded(
            child: pw.Text(
              value,
              style: const pw.TextStyle(fontSize: 9),
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // Shared helpers
  // ═══════════════════════════════════════════════════════════════════════════

  pw.Widget _tableCell(
    String text, {
    bool isHeader = false,
    PdfColor textColor = PdfColors.white,
  }) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      child: pw.Text(
        text,
        style: pw.TextStyle(
          fontSize: 9,
          fontWeight: isHeader ? pw.FontWeight.bold : pw.FontWeight.normal,
          color: isHeader ? textColor : PdfColors.black,
        ),
      ),
    );
  }

  pw.Widget _signatureBlock(String label) {
    return pw.Column(
      children: [
        pw.Container(
          width: 120,
          child: pw.Divider(color: PdfColors.black, thickness: 0.8),
        ),
        pw.SizedBox(height: 2),
        pw.Text(
          label,
          style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey700),
        ),
      ],
    );
  }

  static const List<String> _admitCardInstructions = [
    'Bring this admit card to every examination.',
    'Report 30 minutes before the exam starts.',
    'Mobile phones are strictly prohibited in the exam hall.',
    'No student will be allowed to enter after the exam begins.',
    'This card is non-transferable.',
  ];

  // ─────────────────────────────────────────────────────────────────────────
  // Build (Flutter UI)
  // ─────────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final allClasses = context.watch<ClassSetupNotifier>().classes;
    final allSections = context.watch<SectionSetupNotifier>().sections;

    final uniqueClasses = <String, String>{};
    for (final c in allClasses) {
      uniqueClasses[c.id] = c.name;
    }

    final uniqueSections = <String, String>{};
    if (_selectedClassId != null) {
      for (final s in allSections) {
        if (s.classId == _selectedClassId) {
          uniqueSections[s.id] = s.name;
        }
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Admit Card — ${widget.exam.name}',
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        backgroundColor: AppColors.primaryAdmin,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.print),
            tooltip: 'Print',
            onPressed: () async {
              if (_pdfBytes != null) {
                await Printing.layoutPdf(onLayout: (_) async => _pdfBytes!);
              }
            },
          ),
          IconButton(
            icon: const Icon(Icons.share),
            tooltip: 'Share',
            onPressed: () async {
              if (_pdfBytes != null) {
                await Printing.sharePdf(
                  bytes: _pdfBytes!,
                  filename:
                      'admit_card_${widget.exam.name.replaceAll(' ', '_')}.pdf',
                );
              }
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
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Choose Template',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
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
                    margin: const EdgeInsets.symmetric(horizontal: 5),
                    padding: const EdgeInsets.symmetric(
                      vertical: 12,
                      horizontal: 8,
                    ),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? t.accentColor.withValues(alpha: 0.1)
                          : Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected ? t.accentColor : Colors.grey.shade200,
                        width: isSelected ? 2 : 1,
                      ),
                    ),
                    child: Column(
                      children: [
                        Icon(
                          t.icon,
                          color: isSelected ? t.accentColor : Colors.grey,
                          size: 26,
                        ),
                        const SizedBox(height: 6),
                        Text(
                          t.label,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: isSelected
                                ? FontWeight.bold
                                : FontWeight.w500,
                            color:
                                isSelected ? t.accentColor : Colors.grey.shade700,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        if (isSelected)
                          Container(
                            margin: const EdgeInsets.only(top: 5),
                            width: 24,
                            height: 3,
                            decoration: BoxDecoration(
                              color: t.accentColor,
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
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

  // ── Filters ───────────────────────────────────────────────────────────────
  Widget _buildFilters(
    Map<String, String> uniqueClasses,
    Map<String, String> uniqueSections,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.primaryAdmin.withValues(alpha: 0.05),
        border: Border(
          bottom: BorderSide(color: Colors.grey.shade200),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildDropdown<String?>(
              label: 'Class',
              value: uniqueClasses.containsKey(_selectedClassId)
                  ? _selectedClassId
                  : null,
              items: [
                if (!uniqueClasses.containsKey(_selectedClassId) &&
                    _selectedClassId != null)
                  DropdownMenuItem(
                    value: _selectedClassId,
                    child: const Text('Unknown Class'),
                  ),
                ...uniqueClasses.entries.map(
                  (e) => DropdownMenuItem(value: e.key, child: Text(e.value)),
                ),
              ],
              onChanged: (val) {
                if (val != _selectedClassId) {
                  setState(() {
                    _selectedClassId = val;
                    _selectedSectionId = null;
                  });
                  _fetchStudents();
                }
              },
            ),
          ),
          if (uniqueSections.isNotEmpty) ...[
            const SizedBox(width: 12),
            Expanded(
              child: _buildDropdown<String?>(
                label: 'Section',
                value: uniqueSections.containsKey(_selectedSectionId)
                    ? _selectedSectionId
                    : null,
                items: [
                  const DropdownMenuItem<String?>(
                    value: null,
                    child: Text('All Sections'),
                  ),
                  ...uniqueSections.entries.map(
                    (e) =>
                        DropdownMenuItem(value: e.key, child: Text(e.value)),
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
            fontSize: 11,
            fontWeight: FontWeight.bold,
            color: AppColors.primaryAdmin,
          ),
        ),
        const SizedBox(height: 4),
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
              icon: const Icon(
                Icons.arrow_drop_down,
                color: AppColors.primaryAdmin,
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ── PDF preview area ───────────────────────────────────────────────────────
  Widget _buildPreviewArea() {
    if (_isLoading || _pdfBytes == null) {
      return const Center(child: CircularProgressIndicator());
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
              'No students found for the selected class/section.',
              style: TextStyle(color: Colors.grey.shade500),
            ),
          ],
        ),
      );
    }
    return pdfx.PdfViewPinch(controller: _pdfController!);
  }
}
