import 'dart:developer';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:provider/provider.dart';
import 'package:smart_school/features/auth/providers/auth_provider.dart';
import 'package:smart_school/models/school_models.dart';
import 'package:smart_school/models/student_model.dart';
import 'package:pdfx/pdfx.dart' as pdfx;

import '../providers/exam_provider.dart';
import '../providers/setup_provider.dart';
import '../providers/student_provider.dart';

class GenerateReportCardScreen extends StatefulWidget {
  final Exam exam;
  final List<Student> students;

  const GenerateReportCardScreen({
    super.key,
    required this.exam,
    required this.students,
  });

  @override
  State<GenerateReportCardScreen> createState() =>
      _GenerateReportCardScreenState();
}

class _GenerateReportCardScreenState extends State<GenerateReportCardScreen> {
  String? _selectedClassId;
  String? _selectedSectionId;
  late List<Student> _currentStudents;
  List<Result> _fetchedResults = [];
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
    } else if (widget.exam.assignments.isNotEmpty) {
      _selectedClassId = widget.exam.assignments.first.classId;
      _selectedSectionId = widget.exam.assignments.first.sectionId;
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

      final results = await examsNotifier.fetchResultsForExam(
        examId: widget.exam.id,
        classId: _selectedClassId,
        sectionId: _selectedSectionId,
        assignments: widget.exam.assignments,
      );

      if (mounted) {
        _fetchedResults = results;
      }
    } catch (e) {
      log('Error fetching report card data: $e');
    }

    if (mounted) {
      await _generatePdf();
    }
  }

  Future<void> _generatePdf() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    final authNotifier = context.read<AuthNotifier>();
    final subjectSetupNotifier = context.read<SubjectSetupNotifier>();
    final classSetupNotifier = context.read<ClassSetupNotifier>();
    final sectionSetupNotifier = context.read<SectionSetupNotifier>();

    final school = authNotifier.user?.school;
    final allSubjects = subjectSetupNotifier.subjects;
    final allClasses = classSetupNotifier.classes;
    final allSections = sectionSetupNotifier.sections;

    try {
      final bytes = await _generateReportCardsPdf(
        PdfPageFormat.a4,
        school,
        allSubjects,
        allClasses,
        allSections,
      );
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
    } catch (e, st) {
      log('Error generating report cards PDF: $e\n$st');
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
    final uniqueClasses = <String, String>{};
    for (var a in widget.exam.assignments) {
      uniqueClasses[a.classId] = a.className;
    }

    final allSections = context.watch<SectionSetupNotifier>().sections;
    final uniqueSections = <String, String>{};
    if (_selectedClassId != null) {
      for (var s in allSections) {
        if (s.classId == _selectedClassId) {
          uniqueSections[s.id] = s.name;
        }
      }
      for (var a in widget.exam.assignments.where(
        (a) => a.classId == _selectedClassId,
      )) {
        if (a.sectionId != null) {
          uniqueSections[a.sectionId!] = a.sectionName ?? 'N/A';
        }
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(
          _currentStudents.length == 1
              ? 'Report Card Preview'
              : 'Report Cards (${_currentStudents.length})',
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
            tooltip: 'Print',
          ),
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: () async {
              if (_pdfBytes != null) {
                await Printing.sharePdf(bytes: _pdfBytes!, filename: 'report_cards.pdf');
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
                    child: Text('No students selected for report cards.'),
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
                if (!uniqueClasses.containsKey(_selectedClassId) &&
                    _selectedClassId == null)
                  const DropdownMenuItem(
                    value: null,
                    child: Text('Select Class'),
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
            const SizedBox(width: 16),
            Expanded(
              child: _buildDropdown<String?>(
                label: 'Section',
                value: uniqueSections.containsKey(_selectedSectionId)
                    ? _selectedSectionId
                    : null,
                items: [
                  const DropdownMenuItem(
                    value: null,
                    child: Text('All Sections'),
                  ),
                  if (!uniqueSections.containsKey(_selectedSectionId) &&
                      _selectedSectionId != null)
                    DropdownMenuItem(
                      value: _selectedSectionId,
                      child: const Text('Unknown Section'),
                    ),
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
    required T value,
    required List<DropdownMenuItem<T>> items,
    required ValueChanged<T?> onChanged,
  }) {
    return DropdownButtonFormField<T>(
      initialValue: value,
      items: items,
      onChanged: onChanged,
      decoration: InputDecoration(
        labelText: label,
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  Future<Uint8List> _generateReportCardsPdf(
    PdfPageFormat format,
    School? school,
    List<Subject> allSubjects,
    List<ClassRoom> allClasses,
    List<Section> allSections,
  ) async {
    final pdf = pw.Document();

    final schoolName = school?.name ?? 'Smart School';
    final schoolLogoUrl = school?.avatar ?? '';
    final schoolAddress = school?.address ?? '';
    final schoolPhone = school?.phone ?? '';
    final schoolEmail = school?.email ?? '';

    pw.ImageProvider? schoolLogo;
    if (schoolLogoUrl.isNotEmpty) {
      try {
        schoolLogo = await networkImage(schoolLogoUrl);
      } catch (e) {
        // Fallback if image fails to load
      }
    }

    final allResults = [
      ...widget.exam.results,
      ..._fetchedResults,
    ];

    bool matchesStudent(Result r, Student student) {
      if (r.studentId.isNotEmpty) {
        if (r.studentId == student.userId) return true;
        if (student.user != null && r.studentId == student.user!.id) return true;
        if (r.studentId == student.rollId) return true;
      }
      return false;
    }

    final studentTotals = <String, double>{};
    for (var student in _currentStudents) {
      double total = 0;
      for (var r in allResults.where((r) => matchesStudent(r, student))) {
        total += r.marksObtained;
      }
      studentTotals[student.userId] = total;
    }

    final sortedStudentIds = studentTotals.keys.toList()
      ..sort((a, b) => studentTotals[b]!.compareTo(studentTotals[a]!));

    final studentRanks = <String, int>{};
    int currentRank = 1;
    for (int i = 0; i < sortedStudentIds.length; i++) {
      if (i > 0 &&
          studentTotals[sortedStudentIds[i]]! <
              studentTotals[sortedStudentIds[i - 1]]!) {
        currentRank = i + 1;
      }
      studentRanks[sortedStudentIds[i]] = currentRank;
    }

    for (var student in _currentStudents) {
      final studentResults = allResults
          .where((r) => matchesStudent(r, student))
          .toList();

      if (studentResults.isEmpty) continue; // Skip if no marks

      pdf.addPage(
        pw.Page(
          pageFormat: format,
          margin: const pw.EdgeInsets.all(20),
          build: (pw.Context context) {
            return _buildReportCardSinglePage(
              context: context,
              student: student,
              results: studentResults,
              rank: studentRanks[student.userId] ?? 0,
              schoolName: schoolName,
              schoolLogo: schoolLogo,
              schoolAddress: schoolAddress,
              schoolPhone: schoolPhone,
              schoolEmail: schoolEmail,
              allSubjects: allSubjects,
              allClasses: allClasses,
              allSections: allSections,
            );
          },
        ),
      );
    }

    // If no students had results
    if (pdf.document.pdfPageList.pages.isEmpty) {
      pdf.addPage(
        pw.Page(
          pageFormat: format,
          margin: const pw.EdgeInsets.all(20),
          build: (context) => pw.Center(
            child: pw.Text(
              'No results found for the selected students.',
              style: pw.TextStyle(
                fontSize: 14,
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.grey700,
              ),
            ),
          ),
        ),
      );
    }

    return pdf.save();
  }

  pw.Widget _buildReportCardSinglePage({
    required pw.Context context,
    required Student student,
    required List<Result> results,
    required int rank,
    required String schoolName,
    required pw.ImageProvider? schoolLogo,
    required String schoolAddress,
    required String schoolPhone,
    required String schoolEmail,
    required List<Subject> allSubjects,
    required List<ClassRoom> allClasses,
    required List<Section> allSections,
  }) {
    double totalMarksAll = 0;
    double marksObtainedAll = 0;

    for (var r in results) {
      totalMarksAll += r.totalMarks;
      marksObtainedAll += r.marksObtained;
    }

    final double percentage = totalMarksAll > 0
        ? (marksObtainedAll / totalMarksAll) * 100
        : 0.0;
    final String overallGrade = _calculateGrade(percentage);
    final String className = _resolveClassName(student, _selectedClassId, allClasses, widget.exam.assignments);
    final String sectionName = _resolveSectionName(student, _selectedSectionId, allSections, widget.exam.assignments);

    final primaryColor = PdfColor.fromHex('#1E1B4B'); // Deep Navy
    final accentColor = PdfColor.fromHex('#4338CA');  // Indigo Accent
    final goldColor = PdfColor.fromHex('#D97706');    // Amber Gold
    final bgTint = PdfColor.fromHex('#F8FAFC');       // Slate Tint
    final borderTint = PdfColor.fromHex('#E2E8F0');   // Subtle Border

    return pw.Container(
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: accentColor, width: 1.5),
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
      ),
      padding: const pw.EdgeInsets.all(16),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.stretch,
        children: [
          // 1. SCHOOL HEADER
          pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.center,
            children: [
              if (schoolLogo != null)
                pw.Container(
                  height: 48,
                  width: 48,
                  margin: const pw.EdgeInsets.only(right: 12),
                  child: pw.Image(schoolLogo),
                )
              else
                pw.Container(
                  height: 44,
                  width: 44,
                  margin: const pw.EdgeInsets.only(right: 12),
                  decoration: pw.BoxDecoration(
                    color: primaryColor,
                    shape: pw.BoxShape.circle,
                  ),
                  child: pw.Center(
                    child: pw.Text(
                      schoolName.isNotEmpty ? schoolName[0].toUpperCase() : 'S',
                      style: pw.TextStyle(
                        color: PdfColors.white,
                        fontSize: 20,
                        fontWeight: pw.FontWeight.bold,
                      ),
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
                        fontWeight: pw.FontWeight.bold,
                        fontSize: 15,
                        color: primaryColor,
                      ),
                    ),
                    pw.SizedBox(height: 2),
                    if (schoolAddress.isNotEmpty)
                      pw.Text(
                        schoolAddress,
                        style: pw.TextStyle(fontSize: 8, color: PdfColors.grey700),
                      ),
                    if (schoolPhone.isNotEmpty || schoolEmail.isNotEmpty)
                      pw.Text(
                        [
                          if (schoolPhone.isNotEmpty) 'Phone: $schoolPhone',
                          if (schoolEmail.isNotEmpty) 'Email: $schoolEmail',
                        ].join(' | '),
                        style: pw.TextStyle(fontSize: 8, color: PdfColors.grey600),
                      ),
                  ],
                ),
              ),
              pw.Container(
                padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: pw.BoxDecoration(
                  color: bgTint,
                  border: pw.Border.all(color: borderTint),
                  borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
                ),
                child: pw.Column(
                  children: [
                    pw.Text(
                      'ACADEMIC REPORT',
                      style: pw.TextStyle(
                        fontSize: 7.5,
                        fontWeight: pw.FontWeight.bold,
                        color: primaryColor,
                      ),
                    ),
                    pw.Text(
                      'OFFICIAL RESULT',
                      style: pw.TextStyle(fontSize: 6.5, color: PdfColors.grey600),
                    ),
                  ],
                ),
              ),
            ],
          ),

          pw.SizedBox(height: 8),
          pw.Divider(color: accentColor, thickness: 1),
          pw.SizedBox(height: 8),

          // 2. EXAM BANNER
          pw.Container(
            padding: const pw.EdgeInsets.symmetric(vertical: 6, horizontal: 12),
            decoration: pw.BoxDecoration(
              color: primaryColor,
              borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
            ),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text(
                  'STUDENT PROGRESS REPORT',
                  style: pw.TextStyle(
                    color: PdfColors.white,
                    fontSize: 10.5,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.Text(
                  widget.exam.name.toUpperCase(),
                  style: pw.TextStyle(
                    color: goldColor,
                    fontSize: 10,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),

          pw.SizedBox(height: 8),

          // 3. STUDENT INFO GRID
          pw.Container(
            padding: const pw.EdgeInsets.all(10),
            decoration: pw.BoxDecoration(
              color: bgTint,
              border: pw.Border.all(color: borderTint),
              borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
            ),
            child: pw.Row(
              children: [
                pw.Expanded(
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      _buildProfileRow('Student Name', student.user?.name ?? 'N/A', isBold: true),
                      pw.SizedBox(height: 4),
                      _buildProfileRow('Roll Number', student.rollId.isNotEmpty ? student.rollId : 'N/A'),
                      pw.SizedBox(height: 4),
                      _buildProfileRow('Class & Sec', '$className - $sectionName'),
                    ],
                  ),
                ),
                pw.Container(
                  width: 1,
                  height: 38,
                  color: borderTint,
                  margin: const pw.EdgeInsets.symmetric(horizontal: 12),
                ),
                pw.Expanded(
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      _buildProfileRow('Student ID', student.userId),
                      pw.SizedBox(height: 4),
                      _buildProfileRow('Total Subjects', '${results.length} Subjects'),
                      pw.SizedBox(height: 4),
                      _buildProfileRow(
                        'Result Status',
                        percentage >= 40 ? 'PASSED' : 'NEEDS ATTENTION',
                        valueColor: percentage >= 40 ? PdfColor.fromHex('#15803D') : PdfColor.fromHex('#B91C1C'),
                        isBold: true,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          pw.SizedBox(height: 10),

          // 4. MARKS TABLE
          pw.TableHelper.fromTextArray(
            headerDecoration: pw.BoxDecoration(color: primaryColor),
            headerStyle: pw.TextStyle(
              color: PdfColors.white,
              fontWeight: pw.FontWeight.bold,
              fontSize: 8.5,
            ),
            headerHeight: 22,
            cellHeight: 18,
            cellAlignment: pw.Alignment.centerLeft,
            cellStyle: const pw.TextStyle(fontSize: 8),
            cellAlignments: {
              0: pw.Alignment.centerLeft,
              1: pw.Alignment.center,
              2: pw.Alignment.center,
              3: pw.Alignment.center,
              4: pw.Alignment.center,
              5: pw.Alignment.centerLeft,
            },
            headers: ['SUBJECT', 'MAX MARKS', 'PASS MARKS', 'OBTAINED', 'GRADE', 'REMARKS'],
            data: [
              ...results.map((r) {
                final pct = r.totalMarks > 0 ? (r.marksObtained / r.totalMarks) * 100 : 0.0;
                final grade = _calculateGrade(pct);
                final passMarks = (r.totalMarks * 0.4).toStringAsFixed(0);

                String subjectName = r.subject?.name ?? '';
                if (subjectName.isEmpty || subjectName == 'Unknown') {
                  try {
                    subjectName = widget.exam.assignments
                        .firstWhere((a) => a.subjectId == r.subjectId)
                        .subjectName;
                  } catch (_) {}
                }
                if (subjectName.isEmpty || subjectName == 'Unknown') {
                  try {
                    subjectName = allSubjects
                        .firstWhere((s) => s.id == r.subjectId)
                        .name;
                  } catch (_) {}
                }
                if (subjectName.isEmpty) {
                  subjectName = 'Subject';
                }

                return [
                  subjectName,
                  r.totalMarks.toStringAsFixed(0),
                  passMarks,
                  r.marksObtained.toStringAsFixed(1),
                  grade,
                  r.remarks.isNotEmpty ? r.remarks : '-',
                ];
              }),
            ],
          ),

          pw.SizedBox(height: 10),

          // 5. SUMMARY STATS CARDS
          pw.Row(
            children: [
              _buildMetricCard('Total Score', '${marksObtainedAll.toStringAsFixed(1)} / ${totalMarksAll.toStringAsFixed(0)}', primaryColor),
              pw.SizedBox(width: 8),
              _buildMetricCard('Percentage', '${percentage.toStringAsFixed(2)}%', accentColor),
              pw.SizedBox(width: 8),
              _buildMetricCard('Overall Grade', overallGrade, goldColor),
              pw.SizedBox(width: 8),
              _buildMetricCard('Class Rank', _getOrdinal(rank), rank == 1 ? goldColor : primaryColor),
            ],
          ),

          pw.SizedBox(height: 10),

          // 6. GRADING SCALE & REMARKS
          pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Expanded(
                flex: 4,
                child: pw.Container(
                  padding: const pw.EdgeInsets.all(8),
                  decoration: pw.BoxDecoration(
                    color: bgTint,
                    border: pw.Border.all(color: borderTint),
                    borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
                  ),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        'GRADING SCALE',
                        style: pw.TextStyle(fontSize: 7.5, fontWeight: pw.FontWeight.bold, color: primaryColor),
                      ),
                      pw.SizedBox(height: 4),
                      pw.Text(
                        'A+: 90-100% | A: 80-89% | B: 70-79%\nC: 60-69%   | D: 50-59% | F: <50%',
                        style: const pw.TextStyle(fontSize: 7, color: PdfColors.grey800),
                      ),
                    ],
                  ),
                ),
              ),
              pw.SizedBox(width: 8),
              pw.Expanded(
                flex: 6,
                child: pw.Container(
                  padding: const pw.EdgeInsets.all(8),
                  decoration: pw.BoxDecoration(
                    color: bgTint,
                    border: pw.Border.all(color: borderTint),
                    borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
                  ),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        'CLASS TEACHER\'S REMARKS',
                        style: pw.TextStyle(fontSize: 7.5, fontWeight: pw.FontWeight.bold, color: primaryColor),
                      ),
                      pw.SizedBox(height: 4),
                      pw.Text(
                        _getTeacherComment(percentage),
                        style: pw.TextStyle(fontSize: 7.5, fontStyle: pw.FontStyle.italic, color: PdfColors.grey800),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),

          pw.Spacer(),

          // 7. SIGNATURE FOOTER
          pw.Container(
            padding: const pw.EdgeInsets.only(top: 8),
            decoration: const pw.BoxDecoration(
              border: pw.Border(top: pw.BorderSide(color: PdfColors.grey400, width: 0.8)),
            ),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Column(
                  children: [
                    pw.Container(width: 120, height: 1, color: PdfColors.black),
                    pw.SizedBox(height: 3),
                    pw.Text('Class Teacher Signature', style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold)),
                  ],
                ),
                pw.Column(
                  children: [
                    pw.Container(width: 100, height: 1, color: PdfColors.grey400),
                    pw.SizedBox(height: 3),
                    pw.Text('Official Seal', style: const pw.TextStyle(fontSize: 7.5, color: PdfColors.grey600)),
                  ],
                ),
                pw.Column(
                  children: [
                    pw.Container(width: 120, height: 1, color: PdfColors.black),
                    pw.SizedBox(height: 3),
                    pw.Text('Principal Signature', style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold)),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  pw.Widget _buildProfileRow(String label, String value, {bool isBold = false, PdfColor? valueColor}) {
    return pw.Row(
      children: [
        pw.SizedBox(
          width: 75,
          child: pw.Text(
            '$label:',
            style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold, color: PdfColors.grey700),
          ),
        ),
        pw.Expanded(
          child: pw.Text(
            value,
            style: pw.TextStyle(
              fontSize: 8.5,
              fontWeight: isBold ? pw.FontWeight.bold : pw.FontWeight.normal,
              color: valueColor ?? PdfColors.black,
            ),
          ),
        ),
      ],
    );
  }

  pw.Widget _buildMetricCard(String title, String value, PdfColor color) {
    return pw.Expanded(
      child: pw.Container(
        padding: const pw.EdgeInsets.symmetric(vertical: 6, horizontal: 4),
        decoration: pw.BoxDecoration(
          color: PdfColor.fromHex('#F8FAFC'),
          border: pw.Border.all(color: color, width: 1),
          borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
        ),
        child: pw.Column(
          children: [
            pw.Text(
              title.toUpperCase(),
              style: pw.TextStyle(fontSize: 6.5, fontWeight: pw.FontWeight.bold, color: PdfColors.grey700),
            ),
            pw.SizedBox(height: 2),
            pw.Text(
              value,
              style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold, color: color),
            ),
          ],
        ),
      ),
    );
  }

  String _getTeacherComment(double percentage) {
    if (percentage >= 90) {
      return 'Outstanding academic performance! Demonstrates exceptional understanding and mastery across all subjects.';
    } else if (percentage >= 80) {
      return 'Excellent performance! Shows commendable dedication and strong academic capabilities.';
    } else if (percentage >= 70) {
      return 'Very good effort. Consistent progress shown; continue working hard to reach peak potential.';
    } else if (percentage >= 60) {
      return 'Good effort. Satisfactory understanding, though additional focus is recommended in weaker subjects.';
    } else if (percentage >= 50) {
      return 'Pass. Needs to increase study hours and seek regular guidance to improve grades.';
    } else {
      return 'Needs significant improvement. Parent-teacher conference is recommended to support academic growth.';
    }
  }

  String _resolveClassName(
    Student student,
    String? selectedClassId,
    List<ClassRoom> allClasses,
    List<ExamAssignment> assignments,
  ) {
    if (selectedClassId != null) {
      try {
        return assignments.firstWhere((a) => a.classId == selectedClassId).className;
      } catch (_) {}
      try {
        return allClasses.firstWhere((c) => c.id == selectedClassId).name;
      } catch (_) {}
    }
    if (student.className != null && student.className!.isNotEmpty) {
      return student.className!;
    }
    try {
      return allClasses.firstWhere((c) => c.id == student.classId).name;
    } catch (_) {}
    try {
      return assignments.firstWhere((a) => a.classId == student.classId).className;
    } catch (_) {}
    return 'N/A';
  }

  String _resolveSectionName(
    Student student,
    String? selectedSectionId,
    List<Section> allSections,
    List<ExamAssignment> assignments,
  ) {
    if (selectedSectionId != null) {
      try {
        return allSections.firstWhere((s) => s.id == selectedSectionId).name;
      } catch (_) {}
      try {
        return assignments
            .firstWhere((a) => a.sectionId == selectedSectionId)
            .sectionName ?? 'N/A';
      } catch (_) {}
    }
    if (student.sectionName != null && student.sectionName!.isNotEmpty) {
      return student.sectionName!;
    }
    try {
      return allSections.firstWhere((s) => s.id == student.sectionId).name;
    } catch (_) {}
    try {
      return assignments
          .firstWhere((a) => a.sectionId == student.sectionId)
          .sectionName ?? 'N/A';
    } catch (_) {}
    return 'N/A';
  }

  String _getOrdinal(int number) {
    if (number == 0) return 'N/A';
    if (number % 100 >= 11 && number % 100 <= 13) {
      return '${number}th';
    }
    switch (number % 10) {
      case 1:
        return '${number}st';
      case 2:
        return '${number}nd';
      case 3:
        return '${number}rd';
      default:
        return '${number}th';
    }
  }

  String _calculateGrade(double percentage) {
    if (percentage >= 90) return 'A+';
    if (percentage >= 80) return 'A';
    if (percentage >= 70) return 'B';
    if (percentage >= 60) return 'C';
    if (percentage >= 50) return 'D';
    return 'F';
  }
}
