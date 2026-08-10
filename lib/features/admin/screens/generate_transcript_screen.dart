import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:provider/provider.dart';
import 'package:smart_school/features/auth/providers/auth_provider.dart';
import 'package:smart_school/models/school_models.dart';
import 'package:smart_school/models/student_model.dart';

import '../providers/exam_provider.dart';
import '../providers/setup_provider.dart';
import '../providers/student_provider.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';

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
  late List<Student> _currentStudents;
  bool _isLoading = false;
  Uint8List? _pdfBytes;
  final PdfViewerController _pdfViewerController = PdfViewerController();

  @override
  void initState() {
    super.initState();
    _currentStudents = widget.students;
    if (_currentStudents.isNotEmpty) {
      _selectedClassId = _currentStudents.first.classId;
      _selectedSectionId = _currentStudents.first.sectionId;
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _generatePdf();
    });
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
            icon: const Icon(Icons.zoom_out),
            onPressed: () {
              _pdfViewerController.zoomLevel = (_pdfViewerController.zoomLevel - 0.5).clamp(1.0, 3.0);
            },
            tooltip: 'Zoom Out',
          ),
          IconButton(
            icon: const Icon(Icons.zoom_in),
            onPressed: () {
              _pdfViewerController.zoomLevel = (_pdfViewerController.zoomLevel + 0.5).clamp(1.0, 3.0);
            },
            tooltip: 'Zoom In',
          ),
          IconButton(
            icon: const Icon(Icons.print),
            onPressed: () async {
              if (_pdfBytes != null) {
                await Printing.layoutPdf(onLayout: (_) async => _pdfBytes!);
              }
            },
            tooltip: 'Print',
          ),
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: () async {
              if (_pdfBytes != null) {
                await Printing.sharePdf(bytes: _pdfBytes!, filename: 'transcripts.pdf');
              }
            },
            tooltip: 'Share',
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
                ? const Center(
                    child: Text('No students selected for transcripts.'),
                  )
                : SfPdfViewer.memory(
                    _pdfBytes!,
                    controller: _pdfViewerController,
                    key: ValueKey(
                      'transcript_${_selectedClassId}_${_selectedSectionId}_${_currentStudents.length}',
                    ),
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
            child: _buildDropdown<String?>(
              label: 'Class',
              value: uniqueClasses.containsKey(_selectedClassId) ? _selectedClassId : null,
              items: [
                if (!uniqueClasses.containsKey(_selectedClassId) && _selectedClassId != null)
                  DropdownMenuItem(value: _selectedClassId, child: const Text('Unknown Class')),
                if (!uniqueClasses.containsKey(_selectedClassId) && _selectedClassId == null)
                  const DropdownMenuItem(value: null, child: Text('Select Class')),
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
                label: 'Section',
                value: uniqueSections.containsKey(_selectedSectionId) ? _selectedSectionId : null,
                items: [
                  const DropdownMenuItem(
                    value: null,
                    child: Text('All Sections'),
                  ),
                  if (!uniqueSections.containsKey(_selectedSectionId) && _selectedSectionId != null)
                    DropdownMenuItem(value: _selectedSectionId, child: const Text('Unknown Section')),
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
    final pdf = pw.Document();

    final schoolName = school?.name ?? 'Unknown School';
    final schoolLogoUrl = school?.avatar ?? '';
    final schoolAddress = school?.address ?? '';
    final schoolPhone = school?.phone ?? '';
    final schoolEmail = school?.email ?? '';

    pw.ImageProvider? schoolLogo;
    if (schoolLogoUrl.isNotEmpty) {
      try {
        schoolLogo = await networkImage(schoolLogoUrl);
      } catch (e) {
        // Fallback
      }
    }

    pw.PageTheme makePageTheme({pw.Widget Function(pw.Context)? foreground}) {
      return pw.PageTheme(
        pageFormat: format,
        margin: const pw.EdgeInsets.all(24),
        buildBackground: (pw.Context context) {
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

    for (var student in _currentStudents) {
      // Collect all results for this student across all exams
      final studentExamsWithResults = <Exam, List<Result>>{};
      for (var exam in exams) {
        final results = exam.results.where((r) => r.studentId == student.userId).toList();
        if (results.isNotEmpty) {
          studentExamsWithResults[exam] = results;
        }
      }

      if (studentExamsWithResults.isEmpty) continue; // Skip if no marks in any exam

      final dummyPdf = pw.Document();
      dummyPdf.addPage(
        pw.MultiPage(
          pageTheme: makePageTheme(),
          build: (context) => _buildTranscriptPage(
            context,
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
          build: (pw.Context context) {
            return _buildTranscriptPage(
              context,
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
          build: (context) => pw.Center(
            child: pw.Text('No results found for the selected students.'),
          ),
        ),
      );
    }

    return pdf.save();
  }

  List<pw.Widget> _buildTranscriptPage(
    pw.Context context,
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
            _buildInfoRow('Class', className),
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
}
