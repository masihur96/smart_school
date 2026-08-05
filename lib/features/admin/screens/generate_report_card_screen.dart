import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:provider/provider.dart';

import 'package:smart_school/features/auth/providers/auth_provider.dart';
import 'package:smart_school/models/school_models.dart';
import 'package:smart_school/models/student_model.dart';
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
  State<GenerateReportCardScreen> createState() => _GenerateReportCardScreenState();
}

class _GenerateReportCardScreenState extends State<GenerateReportCardScreen> {
  String? _selectedClassId;
  String? _selectedSectionId;
  late List<Student> _currentStudents;
  bool _isLoading = false;

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
          _currentStudents = List.from(context.read<StudentsNotifier>().students);
          _isLoading = false;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final authNotifier = context.read<AuthNotifier>();
    final school = authNotifier.user?.school;

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
      for (var a in widget.exam.assignments.where((a) => a.classId == _selectedClassId)) {
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
      ),
      body: Column(
        children: [
          _buildFilters(uniqueClasses, uniqueSections),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _currentStudents.isEmpty
                    ? const Center(child: Text('No students selected for report cards.'))
                    : PdfPreview(
                        key: ValueKey('${_selectedClassId}_${_selectedSectionId}_${_currentStudents.length}'),
                        build: (format) => _generateReportCardsPdf(format, school),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilters(Map<String, String> uniqueClasses, Map<String, String> uniqueSections) {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.purple.shade50,
      child: Row(
        children: [
          Expanded(
            child: _buildDropdown(
              label: 'Class',
              value: _selectedClassId,
              items: uniqueClasses.entries.map((e) => DropdownMenuItem(value: e.key, child: Text(e.value))).toList(),
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
              child: _buildDropdown(
                label: 'Section',
                value: _selectedSectionId,
                items: [
                  const DropdownMenuItem(value: null, child: Text('All Sections')),
                  ...uniqueSections.entries.map((e) => DropdownMenuItem(value: e.key, child: Text(e.value))),
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
        Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.purple)),
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

  Future<Uint8List> _generateReportCardsPdf(
      PdfPageFormat format, School? school) async {
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

    for (var student in _currentStudents) {
      // Get all results for this student in the current exam
      final studentResults = widget.exam.results
          .where((r) => r.studentId == student.userId)
          .toList();

      if (studentResults.isEmpty) continue; // Skip if no marks

      pdf.addPage(
        pw.Page(
          pageFormat: format,
          build: (pw.Context context) {
            return _buildReportCardPage(
              context,
              student,
              studentResults,
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

    // If no students had results
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

  pw.Widget _buildReportCardPage(
    pw.Context context,
    Student student,
    List<Result> results,
    String schoolName,
    pw.ImageProvider? schoolLogo,
    String schoolAddress,
    String schoolPhone,
    String schoolEmail,
  ) {
    // Calculate totals
    double totalMarksAll = 0;
    double marksObtainedAll = 0;

    for (var r in results) {
      totalMarksAll += r.totalMarks;
      marksObtainedAll += r.marksObtained;
    }

    final double percentage =
        totalMarksAll > 0 ? (marksObtainedAll / totalMarksAll) * 100 : 0.0;
    final String overallGrade = _calculateGrade(percentage);

    return pw.Container(
      padding: const pw.EdgeInsets.all(32),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.deepPurple, width: 2),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          // HEADER
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.center,
            children: [
              if (schoolLogo != null)
                pw.Container(
                  height: 60,
                  width: 60,
                  margin: const pw.EdgeInsets.only(right: 16),
                  child: pw.Image(schoolLogo),
                ),
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.center,
                children: [
                  pw.Text(
                    schoolName.toUpperCase(),
                    style: pw.TextStyle(
                      fontWeight: pw.FontWeight.bold,
                      fontSize: 20,
                      color: PdfColors.deepPurple,
                    ),
                  ),
                  pw.SizedBox(height: 4),
                  if (schoolAddress.isNotEmpty)
                    pw.Text(
                      schoolAddress,
                      style: const pw.TextStyle(fontSize: 10),
                    ),
                  if (schoolPhone.isNotEmpty || schoolEmail.isNotEmpty)
                    pw.Text(
                      [
                        if (schoolPhone.isNotEmpty) 'Phone: $schoolPhone',
                        if (schoolEmail.isNotEmpty) 'Email: $schoolEmail'
                      ].join(' | '),
                      style: const pw.TextStyle(fontSize: 10),
                    ),
                ],
              ),
            ],
          ),
          pw.SizedBox(height: 20),
          pw.Divider(color: PdfColors.deepPurple, thickness: 2),
          
          pw.SizedBox(height: 20),
          
          // TITLE
          pw.Center(
            child: pw.Text(
              'STUDENT PROGRESS REPORT',
              style: pw.TextStyle(
                fontSize: 16,
                fontWeight: pw.FontWeight.bold,
                decoration: pw.TextDecoration.underline,
              ),
            ),
          ),
          pw.Center(
            child: pw.Text(
              widget.exam.name,
              style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold),
            ),
          ),
          
          pw.SizedBox(height: 24),
          
          // STUDENT INFO BOX
          pw.Container(
            padding: const pw.EdgeInsets.all(12),
            decoration: pw.BoxDecoration(
              border: pw.Border.all(color: PdfColors.grey400),
              color: PdfColors.grey100,
            ),
            child: pw.Row(
              children: [
                pw.Expanded(
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      _buildInfoRow('Student Name', student.user?.name ?? 'N/A'),
                      pw.SizedBox(height: 4),
                      _buildInfoRow('Class', () {
                        String name = student.className ?? 'N/A';
                        if (name == 'N/A' || name.isEmpty) {
                          try {
                            name = widget.exam.assignments.firstWhere((a) => a.classId == student.classId).className;
                          } catch (_) {}
                        }
                        return name;
                      }()),
                    ],
                  ),
                ),
                pw.Expanded(
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      _buildInfoRow('Roll No', student.rollId),
                      pw.SizedBox(height: 4),
                      _buildInfoRow('Section', () {
                        String name = student.sectionName ?? 'N/A';
                        if (name == 'N/A' || name.isEmpty) {
                          try {
                            name = widget.exam.assignments.firstWhere((a) => a.sectionId == student.sectionId).sectionName ?? 'N/A';
                          } catch (_) {}
                        }
                        return name;
                      }()),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          pw.SizedBox(height: 30),
          
          // MARKS TABLE
          pw.TableHelper.fromTextArray(
            headerDecoration: const pw.BoxDecoration(
              color: PdfColors.deepPurple,
            ),
            headerStyle: pw.TextStyle(
              color: PdfColors.white,
              fontWeight: pw.FontWeight.bold,
            ),
            cellAlignment: pw.Alignment.centerLeft,
            cellAlignments: {
              0: pw.Alignment.centerLeft,
              1: pw.Alignment.center,
              2: pw.Alignment.center,
              3: pw.Alignment.center,
              4: pw.Alignment.centerLeft,
            },
            headers: [
              'Subject',
              'Max Marks',
              'Marks Obtained',
              'Grade',
              'Remarks'
            ],
            data: [
              ...results.map((r) {
                final percentage = r.totalMarks > 0
                    ? (r.marksObtained / r.totalMarks) * 100
                    : 0.0;
                final grade = _calculateGrade(percentage);

                String subjectName = r.subject?.name ?? 'Unknown';
                if (subjectName == 'Unknown' || subjectName.isEmpty) {
                  try {
                    subjectName = widget.exam.assignments.firstWhere((a) => a.subjectId == r.subjectId).subjectName;
                  } catch (_) {}
                }

                return [
                  subjectName,
                  r.totalMarks.toStringAsFixed(0),
                  r.marksObtained.toStringAsFixed(1),
                  grade,
                  r.remarks.isNotEmpty ? r.remarks : '-',
                ];
              }),
            ],
          ),
          
          pw.SizedBox(height: 20),
          
          // TOTAL SUMMARY BOX
          pw.Container(
            padding: const pw.EdgeInsets.all(16),
            decoration: pw.BoxDecoration(
              border: pw.Border.all(color: PdfColors.deepPurple),
              color: PdfColors.purple50,
            ),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
              children: [
                _buildSummaryStat('Total Marks', '${marksObtainedAll.toStringAsFixed(1)} / ${totalMarksAll.toStringAsFixed(0)}'),
                _buildSummaryStat('Percentage', '${percentage.toStringAsFixed(2)}%'),
                _buildSummaryStat('Overall Grade', overallGrade),
              ],
            ),
          ),
          
          pw.Spacer(),
          
          // SIGNATURES
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Column(
                children: [
                  pw.SizedBox(height: 40),
                  pw.Container(width: 150, child: pw.Divider(color: PdfColors.black, thickness: 1)),
                  pw.SizedBox(height: 4),
                  pw.Text('Class Teacher Signature', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                ],
              ),
              pw.Column(
                children: [
                  pw.SizedBox(height: 40),
                  pw.Container(width: 150, child: pw.Divider(color: PdfColors.black, thickness: 1)),
                  pw.SizedBox(height: 4),
                  pw.Text('Principal Signature', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  pw.Widget _buildInfoRow(String label, String value) {
    return pw.Row(
      children: [
        pw.SizedBox(
          width: 80,
          child: pw.Text(
            '$label:',
            style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
          ),
        ),
        pw.Expanded(
          child: pw.Text(value),
        ),
      ],
    );
  }

  pw.Widget _buildSummaryStat(String label, String value) {
    return pw.Column(
      children: [
        pw.Text(
          label,
          style: pw.TextStyle(
            fontWeight: pw.FontWeight.bold,
            color: PdfColors.deepPurple,
            fontSize: 12,
          ),
        ),
        pw.SizedBox(height: 4),
        pw.Text(
          value,
          style: pw.TextStyle(
            fontWeight: pw.FontWeight.bold,
            fontSize: 16,
          ),
        ),
      ],
    );
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
