import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:provider/provider.dart';

import 'package:smart_school/features/auth/providers/auth_provider.dart';
import 'package:smart_school/models/student_model.dart';
import 'package:smart_school/models/school_models.dart';

class GenerateIdCardScreen extends StatelessWidget {
  final List<Student> students;

  const GenerateIdCardScreen({
    super.key,
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
              ? 'ID Card Preview'
              : 'ID Cards Preview (${students.length})',
        ),
        backgroundColor: Colors.purple,
        foregroundColor: Colors.white,
      ),
      body: students.isEmpty
          ? const Center(child: Text('No students to generate ID cards.'))
          : PdfPreview(
              build: (format) => _generateIdCardsPdf(format, school),
            ),
    );
  }

  Future<Uint8List> _generateIdCardsPdf(
      PdfPageFormat format, School? school) async {
    final pdf = pw.Document();

    final schoolName = school?.name ?? 'Unknown School';
    final schoolLogoUrl = school?.avatar ?? '';
    final schoolAddress = school?.address ?? '';
    final schoolPhone = school?.phone ?? '';

    pw.ImageProvider? schoolLogo;
    if (schoolLogoUrl.isNotEmpty) {
      try {
        schoolLogo = await networkImage(schoolLogoUrl);
      } catch (e) {
        // Fallback
      }
    }

    // A standard ID card is approx 54mm x 86mm (CR80).
    // In PDF points (1 mm = 2.83465 points), 54mm = 153 points, 86mm = 243 points.
    // For standard A4 printing, we can fit multiple in a grid.
    const double cardWidth = 160 * 1.5;
    const double cardHeight = 250 * 1.5;

    // Fetch all student avatars concurrently
    final Map<String, pw.ImageProvider> avatars = {};
    for (var student in students) {
      final avatarUrl = student.user?.avatar ?? '';
      if (avatarUrl.isNotEmpty) {
        try {
          avatars[student.userId] = await networkImage(avatarUrl);
        } catch (e) {
          // Fallback
        }
      }
    }

    // Group students into pages (e.g. 8 per page on A4)
    // A4 is 595 x 842 points.
    // We can fit 2 columns, 4 rows = 8 cards.
    final itemsPerPage = 8;
    for (var i = 0; i < students.length; i += itemsPerPage) {
      final pageStudents = students.skip(i).take(itemsPerPage).toList();

      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(32),
          build: (pw.Context context) {
            return pw.Wrap(
              spacing: 20,
              runSpacing: 20,
              children: pageStudents.map((student) {
                return _buildIdCard(
                  student,
                  schoolName,
                  schoolLogo,
                  avatars[student.userId],
                  cardWidth,
                  cardHeight,
                  schoolAddress,
                  schoolPhone,
                );
              }).toList(),
            );
          },
        ),
      );
    }

    return pdf.save();
  }

  pw.Widget _buildIdCard(
    Student student,
    String schoolName,
    pw.ImageProvider? schoolLogo,
    pw.ImageProvider? studentAvatar,
    double width,
    double height,
    String schoolAddress,
    String schoolPhone,
  ) {
    final className = student.className ?? 'N/A';
    final sectionName = student.sectionName ?? 'N/A';

    return pw.Container(
      width: width,
      height: height,
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.purple, width: 2),
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(12)),
        color: PdfColors.white,
      ),
      child: pw.Column(
        children: [
          // Header
          pw.Container(
            padding: const pw.EdgeInsets.symmetric(vertical: 8, horizontal: 8),
            decoration: const pw.BoxDecoration(
              color: PdfColors.purple,
              borderRadius: pw.BorderRadius.only(
                topLeft: pw.Radius.circular(10),
                topRight: pw.Radius.circular(10),
              ),
            ),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.center,
              children: [
                if (schoolLogo != null)
                  pw.Container(
                    height: 30,
                    width: 30,
                    margin: const pw.EdgeInsets.only(right: 8),
                    decoration: pw.BoxDecoration(
                      shape: pw.BoxShape.circle,
                      image: pw.DecorationImage(image: schoolLogo, fit: pw.BoxFit.cover),
                    ),
                  ),
                pw.Expanded(
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.center,
                    children: [
                      pw.Text(
                        schoolName.toUpperCase(),
                        style: pw.TextStyle(
                          color: PdfColors.white,
                          fontWeight: pw.FontWeight.bold,
                          fontSize: 10,
                        ),
                        textAlign: pw.TextAlign.center,
                      ),
                      if (schoolAddress.isNotEmpty)
                        pw.Text(
                          schoolAddress,
                          style: const pw.TextStyle(
                            color: PdfColors.white,
                            fontSize: 6,
                          ),
                          textAlign: pw.TextAlign.center,
                          maxLines: 1,
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          pw.SizedBox(height: 12),
          
          // Photo
          pw.Container(
            height: 70,
            width: 70,
            decoration: pw.BoxDecoration(
              shape: pw.BoxShape.circle,
              border: pw.Border.all(color: PdfColors.purple, width: 2),
            ),
            child: studentAvatar != null
                ? pw.ClipOval(child: pw.Image(studentAvatar, fit: pw.BoxFit.cover))
                : pw.Center(
                    child: pw.Text(
                      student.user?.name.isNotEmpty == true
                          ? student.user!.name[0].toUpperCase()
                          : '?',
                      style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold, color: PdfColors.purple),
                    ),
                  ),
          ),
          
          pw.SizedBox(height: 12),
          
          // Student Name
          pw.Text(
            student.user?.name ?? 'Unknown',
            style: pw.TextStyle(
              fontWeight: pw.FontWeight.bold,
              fontSize: 14,
              color: PdfColors.purple900,
            ),
            textAlign: pw.TextAlign.center,
          ),
          pw.Text(
            'Student',
            style: const pw.TextStyle(
              fontSize: 10,
              color: PdfColors.grey700,
            ),
            textAlign: pw.TextAlign.center,
          ),
          
          pw.SizedBox(height: 10),
          
          // Details
          pw.Padding(
            padding: const pw.EdgeInsets.symmetric(horizontal: 16),
            child: pw.Column(
              children: [
                _buildDetailRow('Roll No', student.rollId),
                _buildDetailRow('Class', '$className - $sectionName'),
                _buildDetailRow('Contact', student.guardianContact.isNotEmpty ? student.guardianContact : (student.user?.phone ?? 'N/A')),
              ],
            ),
          ),
          
          pw.Spacer(),
          
          // Footer / Signature
          pw.Padding(
            padding: const pw.EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              crossAxisAlignment: pw.CrossAxisAlignment.end,
              children: [
                pw.Column(
                  children: [
                    pw.SizedBox(height: 20),
                    pw.Container(width: 50, child: pw.Divider(color: PdfColors.black, thickness: 1)),
                    pw.Text('Holder Sign', style: const pw.TextStyle(fontSize: 8)),
                  ],
                ),
                pw.Column(
                  children: [
                    pw.SizedBox(height: 20),
                    pw.Container(width: 50, child: pw.Divider(color: PdfColors.black, thickness: 1)),
                    pw.Text('Principal', style: const pw.TextStyle(fontSize: 8)),
                  ],
                ),
              ],
            ),
          ),
          
          // Bottom Bar
          pw.Container(
            height: 15,
            width: double.infinity,
            decoration: const pw.BoxDecoration(
              color: PdfColors.purple,
              borderRadius: pw.BorderRadius.only(
                bottomLeft: pw.Radius.circular(10),
                bottomRight: pw.Radius.circular(10),
              ),
            ),
            child: pw.Center(
              child: pw.Text(
                schoolPhone.isNotEmpty ? 'Phone: $schoolPhone' : 'Valid for Current Academic Year',
                style: const pw.TextStyle(color: PdfColors.white, fontSize: 7),
              ),
            ),
          ),
        ],
      ),
    );
  }

  pw.Widget _buildDetailRow(String label, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 2),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.SizedBox(
            width: 50,
            child: pw.Text(
              '$label:',
              style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9, color: PdfColors.purple800),
            ),
          ),
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
}
