import 'dart:typed_data';
import 'package:smart_school/l10n/app_localizations.dart';

import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:provider/provider.dart';
import 'package:smart_school/core/utils/pdf_image_helper.dart';
import 'package:smart_school/features/auth/providers/auth_provider.dart';
import 'package:smart_school/models/school_models.dart';
import 'package:smart_school/models/student_model.dart';

import '../providers/exam_provider.dart';
import '../providers/setup_provider.dart';
import '../providers/student_provider.dart';
import 'package:pdfx/pdfx.dart' as pdfx;

class GenerateTranscriptScreen extends StatefulWidget {
  final List<Student> students;

  const GenerateTranscriptScreen({
    super.key,
    required this.students,
  });

  @override
  State<GenerateTranscriptScreen> createState() =>
      _GenerateTranscriptScreenState();
}

class _GenerateTranscriptScreenState extends State<GenerateTranscriptScreen> {
  String? _selectedClassId;
  String? _selectedSectionId;
  String _selectedTemplate = 'Default';
  final List<String> _templates = ['Default', 'Modern', 'Classic', 'Minimalist'];
  late List<Student> _currentStudents;
  final Map<String, List<Result>> _fetchedExamResults = {};
  bool _isLoading = false;
  Uint8List? _pdfBytes;
  pdfx.PdfControllerPinch? _pdfController;

  @override
  void dispose() {
    _pdfController?.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _currentStudents = widget.students;
    if (_currentStudents.isNotEmpty) {
      _selectedClassId = _currentStudents.first.classId;
      _selectedSectionId = _currentStudents.first.sectionId;
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchDataAndGeneratePdf();
    });
  }

  Future<void> _fetchDataAndGeneratePdf() async {
    if (!mounted) return;
    setState(() => _isLoading = true);

    final studentsNotifier = context.read<StudentsNotifier>();
    final examsNotifier = context.read<ExamsNotifier>();

    try {
      if (_selectedClassId != null) {
        await studentsNotifier.fetchStudentsBySection(
          classId: _selectedClassId!,
          sectionId: _selectedSectionId,
        );
        if (mounted && studentsNotifier.students.isNotEmpty) {
          _currentStudents = List.from(studentsNotifier.students);
        }
      }

      final exams = examsNotifier.state;
      for (var exam in exams) {
        final results = await examsNotifier.fetchResultsForExam(
          examId: exam.id,
          classId: _selectedClassId,
          sectionId: _selectedSectionId,
          assignments: exam.assignments,
        );
        if (mounted) {
          _fetchedExamResults[exam.id] = results;
        }
      }
    } catch (_) {}

    if (mounted) {
      await _generatePdf();
    }
  }

  Future<void> _generatePdf() async {
    setState(() => _isLoading = true);
    final authNotifier = context.read<AuthNotifier>();
    final school = authNotifier.user?.school;
    final exams = context.read<ExamsNotifier>().state;

    try {
      final bytes = await _generateTranscriptsPdf(PdfPageFormat.a4, school, exams);
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
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _fetchStudents() {
    _fetchDataAndGeneratePdf();
  }

  @override
  Widget build(BuildContext context) {
    final allClasses = context.watch<ClassSetupNotifier>().classes;
    final allSections = context.watch<SectionSetupNotifier>().sections;

    final uniqueClasses = <String, String>{};
    for (var c in allClasses) {
      uniqueClasses[c.id] = c.name;
    }

    final uniqueSections = <String, String>{};
    if (_selectedClassId != null) {
      for (var s in allSections) {
        if (s.classId == _selectedClassId) {
          uniqueSections[s.id] = s.name;
        }
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(
          _currentStudents.length == 1
              ? 'Transcript Preview'
              : 'Transcripts (${_currentStudents.length})',
        ),
        backgroundColor: Colors.purple,
        foregroundColor: Colors.white,
        actions: [

          IconButton(
            icon: const Icon(Icons.print),
            onPressed: () async {
              if (_pdfBytes != null) {
                await Printing.layoutPdf(onLayout: (_) async => _pdfBytes!);
              }
            },
            tooltip: AppLocalizations.of(context)!.print,
          ),
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: () async {
              if (_pdfBytes != null) {
                await Printing.sharePdf(bytes: _pdfBytes!, filename: 'transcripts.pdf');
              }
            },
            tooltip: AppLocalizations.of(context)!.share,
          ),
        ],
      ),
      body: Column(
        children: [
          _buildFilters(uniqueClasses, uniqueSections),
          Expanded(
            child: _isLoading || _pdfBytes == null
                ? const Center(child: CircularProgressIndicator())
                : _currentStudents.isEmpty
                ? Center(
                    child: Text(AppLocalizations.of(context)!.noStudentsForTranscripts),
                  )
                : pdfx.PdfViewPinch(
                    controller: _pdfController!,
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilters(
    Map<String, String> uniqueClasses,
    Map<String, String> uniqueSections,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.purple.shade50,
      child: Row(
        children: [
          Expanded(
            child: _buildDropdown<String>(
              label: 'Template',
              value: _selectedTemplate,
              items: _templates
                  .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                  .toList(),
              onChanged: (val) {
                if (val != null && val != _selectedTemplate) {
                  setState(() {
                    _selectedTemplate = val;
                  });
                  _generatePdf();
                }
              },
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: _buildDropdown<String?>(
              label: AppLocalizations.of(context)!.className,
              value: uniqueClasses.containsKey(_selectedClassId) ? _selectedClassId : null,
              items: [
                if (!uniqueClasses.containsKey(_selectedClassId) && _selectedClassId != null)
                  DropdownMenuItem(value: _selectedClassId, child: Text(AppLocalizations.of(context)!.unknownClass)),
                if (!uniqueClasses.containsKey(_selectedClassId) && _selectedClassId == null)
                  DropdownMenuItem(value: null, child: Text(AppLocalizations.of(context)!.selectClass)),
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
            const SizedBox(width: 16),
            Expanded(
              child: _buildDropdown<String?>(
                label: AppLocalizations.of(context)!.section,
                value: uniqueSections.containsKey(_selectedSectionId) ? _selectedSectionId : null,
                items: [
                  DropdownMenuItem(
                    value: null,
                    child: Text(AppLocalizations.of(context)!.allSections),
                  ),
                  if (!uniqueSections.containsKey(_selectedSectionId) && _selectedSectionId != null)
                    DropdownMenuItem(value: _selectedSectionId, child: Text(AppLocalizations.of(context)!.unknownSection)),
                  ...uniqueSections.entries.map(
                    (e) => DropdownMenuItem(value: e.key, child: Text(e.value)),
                  ),
                ],
                onChanged: (val) {
                  if (val != _selectedSectionId) {
                    setState(() {
                      _selectedSectionId = val;
                    });
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
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: Colors.purple,
          ),
        ),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.purple.shade200),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<T>(
              value: value,
              items: items,
              onChanged: onChanged,
              isExpanded: true,
              icon: const Icon(Icons.arrow_drop_down, color: Colors.purple),
            ),
          ),
        ),
      ],
    );
  }

  Future<Uint8List> _generateTranscriptsPdf(
    PdfPageFormat format,
    School? school,
    List<Exam> exams,
  ) async {
    pw.Font? fontReg;
    pw.Font? fontBold;
    try {
      fontReg = await PdfGoogleFonts.notoSansBengaliRegular();
      fontBold = await PdfGoogleFonts.notoSansBengaliBold();
    } catch (_) {}

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

    final schoolName = school?.name ?? 'Unknown School';
    final schoolLogoUrl = school?.avatar ?? '';
    final schoolAddress = school?.address ?? '';
    final schoolPhone = school?.phone ?? '';
    final schoolEmail = school?.email ?? '';

    pw.ImageProvider? schoolLogo;
    if (schoolLogoUrl.isNotEmpty) {
      try {
        schoolLogo = await PdfImageHelper.getCachedImageProvider(schoolLogoUrl);
      } catch (e) {
        // Fallback
      }
    }

    pw.PageTheme makePageTheme({pw.Widget Function(pw.Context)? foreground}) {
      return pw.PageTheme(
        pageFormat: format,
        margin: const pw.EdgeInsets.all(24),
        buildBackground: (pw.Context context) {
          if (_selectedTemplate == 'Minimalist') {
            return pw.SizedBox();
          } else if (_selectedTemplate == 'Classic') {
            return pw.FullPage(
              ignoreMargins: true,
              child: pw.Container(
                margin: const pw.EdgeInsets.all(24),
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(color: PdfColors.black, width: 2),
                ),
              ),
            );
          } else if (_selectedTemplate == 'Modern') {
            return pw.FullPage(
              ignoreMargins: true,
              child: pw.Container(
                margin: const pw.EdgeInsets.all(24),
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(color: PdfColors.teal, width: 2),
                  borderRadius: pw.BorderRadius.circular(16),
                ),
              ),
            );
          }
          return pw.FullPage(
            ignoreMargins: true,
            child: pw.Container(
              margin: const pw.EdgeInsets.all(24),
              decoration: pw.BoxDecoration(
                border: pw.Border.all(color: PdfColors.blue100, width: 2),
                borderRadius: pw.BorderRadius.circular(12),
              ),
            ),
          );
        },
        buildForeground: foreground,
      );
    }

    bool matchesStudent(Result r, Student student) {
      if (r.studentId.isNotEmpty) {
        if (r.studentId == student.userId) return true;
        if (student.user != null && r.studentId == student.user!.id) return true;
        if (r.studentId == student.rollId) return true;
      }
      return false;
    }

    for (var student in _currentStudents) {
      // Collect all results for this student across all exams
      final studentExamsWithResults = <Exam, List<Result>>{};
      for (var exam in exams) {
        final allResults = [
          ...exam.results,
          ...?_fetchedExamResults[exam.id],
        ];
        final results = allResults.where((r) => matchesStudent(r, student)).toList();
        if (results.isNotEmpty) {
          studentExamsWithResults[exam] = results;
        }
      }

      if (studentExamsWithResults.isEmpty) continue; // Skip if no marks in any exam

      final dummyPdf = pw.Document();
      dummyPdf.addPage(
        pw.MultiPage(
          pageTheme: makePageTheme(),
          build: (pw.Context pwContext) => _buildSelectedTranscriptPage(
            pwContext,
            student,
            studentExamsWithResults,
            schoolName,
            schoolLogo,
            schoolAddress,
            schoolPhone,
            schoolEmail,
          ),
        ),
      );
      final int studentPages = dummyPdf.document.pdfPageList.pages.length;
      final int startPage = pdf.document.pdfPageList.pages.length + 1;
      final int endPage = startPage + studentPages - 1;

      pdf.addPage(
        pw.MultiPage(
          pageTheme: makePageTheme(
            foreground: (pw.Context context) {
              if (context.pageNumber == endPage) {
                return pw.FullPage(
                  ignoreMargins: true,
                  child: pw.Container(
                    padding: const pw.EdgeInsets.only(right: 64, bottom: 64),
                    alignment: pw.Alignment.bottomRight,
                    child: pw.Column(
                      mainAxisSize: pw.MainAxisSize.min,
                      children: [
                        pw.Container(
                          width: 100,
                          child: pw.Divider(color: PdfColors.black, thickness: 1),
                        ),
                        pw.SizedBox(height: 4),
                        pw.Text(
                          'Principal',
                          style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                );
              }
              return pw.SizedBox();
            },
          ),
          build: (pw.Context pwContext) {
            return _buildSelectedTranscriptPage(
              pwContext,
              student,
              studentExamsWithResults,
              schoolName,
              schoolLogo,
              schoolAddress,
              schoolPhone,
              schoolEmail,
            );
          },
        ),
      );
    }

    if (pdf.document.pdfPageList.pages.isEmpty) {
      pdf.addPage(
        pw.Page(
          build: (pw.Context pwContext) => pw.Center(
            child: pw.Text(AppLocalizations.of(context)!.noResultsSelectedStudents),
          ),
        ),
      );
    }

    return pdf.save();
  }

  List<pw.Widget> _buildSelectedTranscriptPage(
    pw.Context pwContext,
    Student student,
    Map<Exam, List<Result>> studentExamsWithResults,
    String schoolName,
    pw.ImageProvider? schoolLogo,
    String schoolAddress,
    String schoolPhone,
    String schoolEmail,
  ) {
    if (_selectedTemplate == 'Modern') {
      return _buildModernTranscriptPage(
        pwContext, student, studentExamsWithResults, schoolName, schoolLogo, schoolAddress, schoolPhone, schoolEmail,
      );
    } else if (_selectedTemplate == 'Classic') {
      return _buildClassicTranscriptPage(
        pwContext, student, studentExamsWithResults, schoolName, schoolLogo, schoolAddress, schoolPhone, schoolEmail,
      );
    } else if (_selectedTemplate == 'Minimalist') {
      return _buildMinimalistTranscriptPage(
        pwContext, student, studentExamsWithResults, schoolName, schoolLogo, schoolAddress, schoolPhone, schoolEmail,
      );
    }
    return _buildDefaultTranscriptPage(
      pwContext, student, studentExamsWithResults, schoolName, schoolLogo, schoolAddress, schoolPhone, schoolEmail,
    );
  }

  List<pw.Widget> _buildDefaultTranscriptPage(
    pw.Context pwContext,
    Student student,
    Map<Exam, List<Result>> studentExamsWithResults,
    String schoolName,
    pw.ImageProvider? schoolLogo,
    String schoolAddress,
    String schoolPhone,
    String schoolEmail,
  ) {
    double grandTotalMarks = 0;
    double grandMarksObtained = 0;

    for (var results in studentExamsWithResults.values) {
      for (var r in results) {
        grandTotalMarks += r.totalMarks;
        grandMarksObtained += r.marksObtained;
      }
    }

    final double percentage = grandTotalMarks > 0
        ? (grandMarksObtained / grandTotalMarks) * 100
        : 0.0;
    final String overallGrade = _calculateGrade(percentage);
    final double overallGPA = _calculateGPA(percentage);

    String className = student.className ?? 'N/A';
    if (_selectedClassId != null) {
      try {
        className = this.context.read<ClassSetupNotifier>().classes.firstWhere((c) => c.id == _selectedClassId).name;
      } catch (_) {}
    }

    return [
      pw.Padding(
        padding: const pw.EdgeInsets.all(24),
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            // HEADER
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.center,
              crossAxisAlignment: pw.CrossAxisAlignment.center,
              children: [
                if (schoolLogo != null)
                  pw.Container(
                    height: 50,
                    width: 50,
                    margin: const pw.EdgeInsets.only(right: 16),
                    child: pw.Image(schoolLogo),
                  ),
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.center,
                  children: [
                    pw.Text(
                      schoolName,
                      style: pw.TextStyle(
                        fontWeight: pw.FontWeight.bold,
                        fontSize: 22,
                        color: PdfColors.blue900,
                      ),
                    ),
                    pw.SizedBox(height: 4),
                    pw.Text(
                      'ACADEMIC TRANSCRIPT',
                      style: pw.TextStyle(
                        fontWeight: pw.FontWeight.bold,
                        fontSize: 14,
                        color: PdfColors.blue900,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            pw.SizedBox(height: 32),

            // STUDENT INFO
            _buildInfoRow('Student Name', student.user?.name ?? 'N/A'),
            pw.SizedBox(height: 8),
            _buildInfoRow('Student ID', student.rollId),
            pw.SizedBox(height: 8),
            _buildInfoRow(AppLocalizations.of(context)!.className, className),
            pw.SizedBox(height: 24),

            // TABLE
            pw.TableHelper.fromTextArray(
              border: pw.TableBorder.all(color: PdfColors.blue200),
              headerDecoration: const pw.BoxDecoration(color: PdfColors.blue50),
              headerStyle: pw.TextStyle(
                color: PdfColors.black,
                fontWeight: pw.FontWeight.bold,
                fontSize: 10,
              ),
              cellStyle: const pw.TextStyle(fontSize: 10),
              cellAlignment: pw.Alignment.center,
              headers: ['Exam', AppLocalizations.of(context)!.className, 'GPA', 'Grade', 'Remarks'],
              data: [
                ...studentExamsWithResults.entries.map((entry) {
                  final exam = entry.key;
                  final results = entry.value;

                  double totalMarks = 0;
                  double marksObtained = 0;
                  for (var r in results) {
                    totalMarks += r.totalMarks;
                    marksObtained += r.marksObtained;
                  }

                  final pct = totalMarks > 0 ? (marksObtained / totalMarks) * 100 : 0.0;
                  final grade = _calculateGrade(pct);
                  final gpa = _calculateGPA(pct);

                  return [
                    exam.name,
                    className,
                    gpa.toStringAsFixed(2),
                    grade,
                    _getRemarks(gpa),
                  ];
                }),
              ],
            ),
            pw.SizedBox(height: 8),
            
            // CGPA SUMMARY
            pw.Container(
              width: double.infinity,
              padding: const pw.EdgeInsets.symmetric(vertical: 8),
              decoration: pw.BoxDecoration(
                color: PdfColors.blue50,
                borderRadius: pw.BorderRadius.circular(4),
              ),
              child: pw.Center(
                child: pw.Text(
                  'CGPA : ${overallGPA.toStringAsFixed(2)} ($overallGrade)',
                  style: pw.TextStyle(
                    fontWeight: pw.FontWeight.bold,
                    fontSize: 12,
                    color: PdfColors.blue900,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    ];
  }

  pw.Widget _buildInfoRow(String label, String value) {
    return pw.Row(
      children: [
        pw.SizedBox(
          width: 100,
          child: pw.Text(
            label,
            style: const pw.TextStyle(fontSize: 10),
          ),
        ),
        pw.Text(
          ': $value',
          style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold),
        ),
      ],
    );
  }

  String _calculateGrade(double percentage) {
    if (percentage >= 80) return 'A+';
    if (percentage >= 70) return 'A';
    if (percentage >= 60) return 'A-';
    if (percentage >= 50) return 'B';
    if (percentage >= 40) return 'C';
    if (percentage >= 33) return 'D';
    return 'F';
  }

  double _calculateGPA(double percentage) {
    if (percentage >= 80) return 5.0;
    if (percentage >= 70) return 4.0;
    if (percentage >= 60) return 3.5;
    if (percentage >= 50) return 3.0;
    if (percentage >= 40) return 2.0;
    if (percentage >= 33) return 1.0;
    return 0.0;
  }

  String _getRemarks(double gpa) {
    if (gpa == 5.0) return 'Excellent';
    if (gpa >= 4.0) return 'Very Good';
    if (gpa >= 3.0) return 'Good';
    if (gpa >= 2.0) return 'Average';
    if (gpa >= 1.0) return 'Pass';
    return 'Fail';
  }

  // --- MODERN TEMPLATE ---
  List<pw.Widget> _buildModernTranscriptPage(
    pw.Context pwContext,
    Student student,
    Map<Exam, List<Result>> studentExamsWithResults,
    String schoolName,
    pw.ImageProvider? schoolLogo,
    String schoolAddress,
    String schoolPhone,
    String schoolEmail,
  ) {
    double grandTotalMarks = 0;
    double grandMarksObtained = 0;

    for (var results in studentExamsWithResults.values) {
      for (var r in results) {
        grandTotalMarks += r.totalMarks;
        grandMarksObtained += r.marksObtained;
      }
    }

    final double percentage = grandTotalMarks > 0 ? (grandMarksObtained / grandTotalMarks) * 100 : 0.0;
    final String overallGrade = _calculateGrade(percentage);
    final double overallGPA = _calculateGPA(percentage);

    String className = student.className ?? 'N/A';
    if (_selectedClassId != null) {
      try {
        className = this.context.read<ClassSetupNotifier>().classes.firstWhere((c) => c.id == _selectedClassId).name;
      } catch (_) {}
    }

    return [
      pw.Padding(
        padding: const pw.EdgeInsets.all(32),
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            // Header: Teal accent, left aligned
            pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                if (schoolLogo != null)
                  pw.Container(
                    height: 60,
                    width: 60,
                    margin: const pw.EdgeInsets.only(right: 16),
                    child: pw.Image(schoolLogo),
                  ),
                pw.Expanded(
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        schoolName.toUpperCase(),
                        style: pw.TextStyle(
                          fontWeight: pw.FontWeight.bold,
                          fontSize: 24,
                          color: PdfColors.teal900,
                        ),
                      ),
                      pw.SizedBox(height: 4),
                      pw.Text(
                        'OFFICIAL ACADEMIC TRANSCRIPT',
                        style: pw.TextStyle(
                          fontWeight: pw.FontWeight.bold,
                          fontSize: 12,
                          color: PdfColors.teal600,
                          letterSpacing: 2,
                        ),
                      ),
                      pw.SizedBox(height: 2),
                      if (schoolAddress.isNotEmpty) pw.Text(schoolAddress, style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700)),
                      if (schoolPhone.isNotEmpty || schoolEmail.isNotEmpty)
                        pw.Text('$schoolPhone ${schoolEmail.isNotEmpty ? '| $schoolEmail' : ''}', style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700)),
                    ],
                  ),
                ),
              ],
            ),
            pw.SizedBox(height: 24),
            pw.Divider(color: PdfColors.teal100, thickness: 2),
            pw.SizedBox(height: 24),

            // Student Info in Cards
            pw.Row(
              children: [
                pw.Expanded(
                  child: pw.Container(
                    padding: const pw.EdgeInsets.all(12),
                    decoration: pw.BoxDecoration(
                      color: PdfColors.teal50,
                      borderRadius: pw.BorderRadius.circular(8),
                    ),
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text('STUDENT DETAILS', style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, color: PdfColors.teal900)),
                        pw.SizedBox(height: 8),
                        _buildInfoRow('Name', student.user?.name ?? 'N/A'),
                        pw.SizedBox(height: 4),
                        _buildInfoRow('ID', student.rollId),
                        pw.SizedBox(height: 4),
                        _buildInfoRow('Class', className),
                      ],
                    ),
                  ),
                ),
                pw.SizedBox(width: 16),
                pw.Expanded(
                  child: pw.Container(
                    padding: const pw.EdgeInsets.all(12),
                    decoration: pw.BoxDecoration(
                      color: PdfColors.teal50,
                      borderRadius: pw.BorderRadius.circular(8),
                    ),
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text('ACADEMIC SUMMARY', style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, color: PdfColors.teal900)),
                        pw.SizedBox(height: 8),
                        _buildInfoRow('Cumulative GPA', overallGPA.toStringAsFixed(2)),
                        pw.SizedBox(height: 4),
                        _buildInfoRow('Overall Grade', overallGrade),
                        pw.SizedBox(height: 4),
                        _buildInfoRow('Status', percentage >= 33 ? 'Passed' : 'Failed'),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            pw.SizedBox(height: 24),

            // Results Table
            pw.TableHelper.fromTextArray(
              border: pw.TableBorder.all(color: PdfColors.teal100),
              headerDecoration: const pw.BoxDecoration(color: PdfColors.teal),
              headerStyle: pw.TextStyle(
                color: PdfColors.white,
                fontWeight: pw.FontWeight.bold,
                fontSize: 10,
              ),
              cellStyle: const pw.TextStyle(fontSize: 10),
              cellAlignment: pw.Alignment.center,
              headers: ['Exam', 'Class', 'GPA', 'Grade', 'Remarks'],
              data: [
                ...studentExamsWithResults.entries.map((entry) {
                  final exam = entry.key;
                  final results = entry.value;

                  double totalMarks = 0;
                  double marksObtained = 0;
                  for (var r in results) {
                    totalMarks += r.totalMarks;
                    marksObtained += r.marksObtained;
                  }

                  final pct = totalMarks > 0 ? (marksObtained / totalMarks) * 100 : 0.0;
                  final grade = _calculateGrade(pct);
                  final gpa = _calculateGPA(pct);

                  return [
                    exam.name,
                    className,
                    gpa.toStringAsFixed(2),
                    grade,
                    _getRemarks(gpa),
                  ];
                }),
              ],
            ),
          ],
        ),
      ),
    ];
  }

  // --- CLASSIC TEMPLATE ---
  List<pw.Widget> _buildClassicTranscriptPage(
    pw.Context pwContext,
    Student student,
    Map<Exam, List<Result>> studentExamsWithResults,
    String schoolName,
    pw.ImageProvider? schoolLogo,
    String schoolAddress,
    String schoolPhone,
    String schoolEmail,
  ) {
    double grandTotalMarks = 0;
    double grandMarksObtained = 0;

    for (var results in studentExamsWithResults.values) {
      for (var r in results) {
        grandTotalMarks += r.totalMarks;
        grandMarksObtained += r.marksObtained;
      }
    }

    final double percentage = grandTotalMarks > 0 ? (grandMarksObtained / grandTotalMarks) * 100 : 0.0;
    final String overallGrade = _calculateGrade(percentage);
    final double overallGPA = _calculateGPA(percentage);

    String className = student.className ?? 'N/A';
    if (_selectedClassId != null) {
      try {
        className = this.context.read<ClassSetupNotifier>().classes.firstWhere((c) => c.id == _selectedClassId).name;
      } catch (_) {}
    }

    return [
      pw.Padding(
        padding: const pw.EdgeInsets.all(32),
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.center,
          children: [
            // Center Aligned Header
            if (schoolLogo != null)
              pw.Container(
                height: 70,
                width: 70,
                margin: const pw.EdgeInsets.only(bottom: 12),
                child: pw.Image(schoolLogo),
              ),
            pw.Text(
              schoolName,
              style: pw.TextStyle(
                fontWeight: pw.FontWeight.bold,
                fontSize: 26,
              ),
            ),
            pw.SizedBox(height: 4),
            pw.Text(
              schoolAddress,
              style: const pw.TextStyle(fontSize: 10),
            ),
            pw.SizedBox(height: 16),
            pw.Container(
              padding: const pw.EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              decoration: pw.BoxDecoration(
                border: pw.Border.all(color: PdfColors.black, width: 1),
              ),
              child: pw.Text(
                'STUDENT TRANSCRIPT',
                style: pw.TextStyle(
                  fontWeight: pw.FontWeight.bold,
                  fontSize: 14,
                  letterSpacing: 2,
                ),
              ),
            ),
            pw.SizedBox(height: 32),

            // Student Info
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    _buildInfoRow('Student Name', student.user?.name ?? 'N/A'),
                    pw.SizedBox(height: 6),
                    _buildInfoRow('Student ID', student.rollId),
                  ],
                ),
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    _buildInfoRow('Class', className),
                    pw.SizedBox(height: 6),
                    _buildInfoRow('Issue Date', '${DateTime.now().day}/${DateTime.now().month}/${DateTime.now().year}'),
                  ],
                ),
              ],
            ),
            pw.SizedBox(height: 24),
            pw.Divider(color: PdfColors.black, thickness: 1),
            pw.SizedBox(height: 24),

            // Table with classic borders
            pw.TableHelper.fromTextArray(
              border: pw.TableBorder.all(color: PdfColors.black, width: 1),
              headerDecoration: const pw.BoxDecoration(color: PdfColors.grey300),
              headerStyle: pw.TextStyle(
                color: PdfColors.black,
                fontWeight: pw.FontWeight.bold,
                fontSize: 11,
              ),
              cellStyle: const pw.TextStyle(fontSize: 11),
              cellAlignment: pw.Alignment.center,
              headers: ['Examination', 'Class', 'GPA', 'Grade', 'Remarks'],
              data: [
                ...studentExamsWithResults.entries.map((entry) {
                  final exam = entry.key;
                  final results = entry.value;

                  double totalMarks = 0;
                  double marksObtained = 0;
                  for (var r in results) {
                    totalMarks += r.totalMarks;
                    marksObtained += r.marksObtained;
                  }

                  final pct = totalMarks > 0 ? (marksObtained / totalMarks) * 100 : 0.0;
                  final grade = _calculateGrade(pct);
                  final gpa = _calculateGPA(pct);

                  return [
                    exam.name,
                    className,
                    gpa.toStringAsFixed(2),
                    grade,
                    _getRemarks(gpa),
                  ];
                }),
              ],
            ),
            pw.SizedBox(height: 32),

            // Final Result Summary Classic
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.end,
              children: [
                pw.Container(
                  padding: const pw.EdgeInsets.all(12),
                  decoration: pw.BoxDecoration(
                    border: pw.Border.all(color: PdfColors.black, width: 1),
                  ),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text('FINAL RESULT', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 12)),
                      pw.SizedBox(height: 8),
                      pw.Row(children: [
                        pw.SizedBox(width: 80, child: pw.Text('CGPA:', style: const pw.TextStyle(fontSize: 11))),
                        pw.Text(overallGPA.toStringAsFixed(2), style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 11)),
                      ]),
                      pw.SizedBox(height: 4),
                      pw.Row(children: [
                        pw.SizedBox(width: 80, child: pw.Text('Overall Grade:', style: const pw.TextStyle(fontSize: 11))),
                        pw.Text(overallGrade, style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 11)),
                      ]),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    ];
  }

  // --- MINIMALIST TEMPLATE ---
  List<pw.Widget> _buildMinimalistTranscriptPage(
    pw.Context pwContext,
    Student student,
    Map<Exam, List<Result>> studentExamsWithResults,
    String schoolName,
    pw.ImageProvider? schoolLogo,
    String schoolAddress,
    String schoolPhone,
    String schoolEmail,
  ) {
    double grandTotalMarks = 0;
    double grandMarksObtained = 0;

    for (var results in studentExamsWithResults.values) {
      for (var r in results) {
        grandTotalMarks += r.totalMarks;
        grandMarksObtained += r.marksObtained;
      }
    }

    final double percentage = grandTotalMarks > 0 ? (grandMarksObtained / grandTotalMarks) * 100 : 0.0;
    final String overallGrade = _calculateGrade(percentage);
    final double overallGPA = _calculateGPA(percentage);

    String className = student.className ?? 'N/A';
    if (_selectedClassId != null) {
      try {
        className = this.context.read<ClassSetupNotifier>().classes.firstWhere((c) => c.id == _selectedClassId).name;
      } catch (_) {}
    }

    return [
      pw.Padding(
        padding: const pw.EdgeInsets.all(32),
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            // Minimal Header
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Expanded(
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        schoolName,
                        style: pw.TextStyle(
                          fontWeight: pw.FontWeight.bold,
                          fontSize: 20,
                        ),
                      ),
                      pw.SizedBox(height: 4),
                      pw.Text(
                        'Academic Transcript',
                        style: const pw.TextStyle(
                          fontSize: 12,
                          color: PdfColors.grey700,
                        ),
                      ),
                    ],
                  ),
                ),
                if (schoolLogo != null)
                  pw.Container(
                    height: 40,
                    width: 40,
                    child: pw.Image(schoolLogo),
                  ),
              ],
            ),
            pw.SizedBox(height: 24),

            // Minimal Info
            pw.Row(
              children: [
                pw.Expanded(
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text('Student', style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey600)),
                      pw.SizedBox(height: 2),
                      pw.Text(student.user?.name ?? 'N/A', style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold)),
                    ],
                  ),
                ),
                pw.Expanded(
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text('ID', style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey600)),
                      pw.SizedBox(height: 2),
                      pw.Text(student.rollId, style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold)),
                    ],
                  ),
                ),
                pw.Expanded(
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text('Class', style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey600)),
                      pw.SizedBox(height: 2),
                      pw.Text(className, style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold)),
                    ],
                  ),
                ),
              ],
            ),
            pw.SizedBox(height: 32),

            // Minimal Table (lines only on bottom)
            pw.TableHelper.fromTextArray(
              border: const pw.TableBorder(
                horizontalInside: pw.BorderSide(color: PdfColors.grey300, width: 0.5),
                bottom: pw.BorderSide(color: PdfColors.grey300, width: 0.5),
              ),
              headerDecoration: const pw.BoxDecoration(
                border: pw.Border(bottom: pw.BorderSide(color: PdfColors.black, width: 1)),
              ),
              headerStyle: pw.TextStyle(
                color: PdfColors.black,
                fontWeight: pw.FontWeight.bold,
                fontSize: 10,
              ),
              cellStyle: const pw.TextStyle(fontSize: 10, color: PdfColors.grey800),
              cellAlignment: pw.Alignment.centerLeft,
              headers: ['Exam', 'Class', 'GPA', 'Grade', 'Remarks'],
              data: [
                ...studentExamsWithResults.entries.map((entry) {
                  final exam = entry.key;
                  final results = entry.value;

                  double totalMarks = 0;
                  double marksObtained = 0;
                  for (var r in results) {
                    totalMarks += r.totalMarks;
                    marksObtained += r.marksObtained;
                  }

                  final pct = totalMarks > 0 ? (marksObtained / totalMarks) * 100 : 0.0;
                  final grade = _calculateGrade(pct);
                  final gpa = _calculateGPA(pct);

                  return [
                    exam.name,
                    className,
                    gpa.toStringAsFixed(2),
                    grade,
                    _getRemarks(gpa),
                  ];
                }),
              ],
            ),
            pw.SizedBox(height: 48),

            // Minimal Footer Summary
            pw.Row(
              children: [
                pw.Expanded(
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text('CGPA', style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey600)),
                      pw.SizedBox(height: 2),
                      pw.Text(overallGPA.toStringAsFixed(2), style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
                    ],
                  ),
                ),
                pw.Expanded(
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text('Overall Grade', style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey600)),
                      pw.SizedBox(height: 2),
                      pw.Text(overallGrade, style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    ];
  }
}
