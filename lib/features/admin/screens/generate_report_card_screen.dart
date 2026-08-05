import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:provider/provider.dart';

import 'package:smart_school/features/auth/providers/auth_provider.dart';
import 'package:smart_school/models/school_models.dart';
import 'package:smart_school/models/student_model.dart';

class GenerateReportCardScreen extends StatelessWidget {
  final Exam exam;
  final List<Student> students;

  const GenerateReportCardScreen({
    super.key,
    required this.exam,
    required this.students,
  });

  @override
  Widget build(BuildContext context) {
    final authNotifier = context.read<AuthNotifier>();
    final school = authNotifier.user?.school;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          students.length == 1
              ? 'Report Card Preview'
              : 'Report Cards (${students.length})',
        ),
        backgroundColor: Colors.purple,
        foregroundColor: Colors.white,
      ),
      body: students.isEmpty
          ? const Center(child: Text('No students selected for report cards.'))
          : PdfPreview(
              build: (format) => _generateReportCardsPdf(format, school),
            ),
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

    for (var student in students) {
      // Get all results for this student in the current exam
      final studentResults = exam.results
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
              exam.name,
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
                            name = exam.assignments.firstWhere((a) => a.classId == student.classId).className;
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
                            name = exam.assignments.firstWhere((a) => a.sectionId == student.sectionId).sectionName ?? 'N/A';
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
                    subjectName = exam.assignments.firstWhere((a) => a.subjectId == r.subjectId).subjectName;
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
