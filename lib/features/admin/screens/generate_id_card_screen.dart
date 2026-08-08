import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:provider/provider.dart';
import 'package:smart_school/core/theme/app_colors.dart';
import 'package:smart_school/features/auth/providers/auth_provider.dart';
import 'package:smart_school/models/school_models.dart';
import 'package:smart_school/models/student_model.dart';

class GenerateIdCardScreen extends StatelessWidget {
  final List<Student> students;

  const GenerateIdCardScreen({super.key, required this.students});

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
        backgroundColor: AppColors.primaryAdmin,
      ),
      body: students.isEmpty
          ? const Center(child: Text('No students to generate ID cards.'))
          : PdfPreview(build: (format) => _generateIdCardsPdf(format, school)),
    );
  }

  Future<Uint8List> _generateIdCardsPdf(
    PdfPageFormat format,
    School? school,
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
                  schoolEmail,
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
    String schoolEmail,
  ) {
    final className = student.className ?? 'N/A';
    final sectionName = student.sectionName ?? 'N/A';

    return pw.Container(
      width: width,
      height: height,
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.deepPurple, width: 3),
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(12)),
        color: PdfColors.white,
      ),
      child: pw.Column(
        children: [
          // Header
          pw.Container(
            padding: const pw.EdgeInsets.symmetric(vertical: 10, horizontal: 8),
            decoration: const pw.BoxDecoration(
              color: PdfColors.deepPurple,
              borderRadius: pw.BorderRadius.only(
                topLeft: pw.Radius.circular(9),
                topRight: pw.Radius.circular(9),
              ),
            ),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.center,
              crossAxisAlignment: pw.CrossAxisAlignment.center,
              children: [
                if (schoolLogo != null)
                  pw.Container(
                    height: 35,
                    width: 35,
                    margin: const pw.EdgeInsets.only(right: 8),
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
                          maxLines: 2,
                        ),
                      if (schoolPhone.isNotEmpty || schoolEmail.isNotEmpty)
                        pw.Text(
                          [
                            if (schoolPhone.isNotEmpty) 'Ph: $schoolPhone',
                            if (schoolEmail.isNotEmpty) 'Email: $schoolEmail',
                          ].join(' | '),
                          style: const pw.TextStyle(
                            color: PdfColors.amber,
                            fontSize: 5,
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

          // Identity Card Banner
          pw.Container(
            width: double.infinity,
            color: PdfColors.amber,
            padding: const pw.EdgeInsets.symmetric(vertical: 4),
            child: pw.Text(
              'IDENTITY CARD',
              style: pw.TextStyle(
                color: PdfColors.black,
                fontWeight: pw.FontWeight.bold,
                fontSize: 10,
                letterSpacing: 1.5,
              ),
              textAlign: pw.TextAlign.center,
            ),
          ),

          pw.SizedBox(height: 12),

          // Photo
          pw.Container(
            height: 85,
            width: 85,
            decoration: pw.BoxDecoration(
              shape: pw.BoxShape.circle,
              border: pw.Border.all(color: PdfColors.amber, width: 3),
              boxShadow: const [
                pw.BoxShadow(
                  color: PdfColors.grey300,
                  blurRadius: 4,
                  offset: PdfPoint(0, 2),
                ),
              ],
            ),
            child: studentAvatar != null
                ? pw.ClipOval(
                    child: pw.Image(studentAvatar, fit: pw.BoxFit.cover),
                  )
                : pw.Center(
                    child: pw.Text(
                      student.user?.name.isNotEmpty == true
                          ? student.user!.name[0].toUpperCase()
                          : '?',
                      style: pw.TextStyle(
                        fontSize: 32,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.deepPurple,
                      ),
                    ),
                  ),
          ),

          pw.SizedBox(height: 12),

          // Student Name
          pw.Text(
            student.user?.name.toUpperCase() ?? 'UNKNOWN',
            style: pw.TextStyle(
              fontWeight: pw.FontWeight.bold,
              fontSize: 14,
              color: PdfColors.deepPurple900,
            ),
            textAlign: pw.TextAlign.center,
            maxLines: 1,
          ),
          pw.Text(
            'STUDENT',
            style: pw.TextStyle(
              fontSize: 9,
              color: PdfColors.red800,
              fontWeight: pw.FontWeight.bold,
              letterSpacing: 1,
            ),
            textAlign: pw.TextAlign.center,
          ),

          pw.SizedBox(height: 12),

          // Details
          pw.Padding(
            padding: const pw.EdgeInsets.symmetric(horizontal: 16),
            child: pw.Column(
              children: [
                _buildDetailRow('Roll No', student.rollId),
                _buildDetailRow('Class', '$className - $sectionName'),
                _buildDetailRow(
                  'Contact',
                  student.guardianContact.isNotEmpty
                      ? student.guardianContact
                      : (student.user?.phone ?? 'N/A'),
                ),
                _buildDetailRow('Email', student.user?.email ?? 'N/A'),
              ],
            ),
          ),

          pw.Spacer(),

          // Barcode & Signatures
          pw.Padding(
            padding: const pw.EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              crossAxisAlignment: pw.CrossAxisAlignment.end,
              children: [
                // Barcode
                pw.Container(
                  width: 50,
                  height: 30,
                  child: pw.BarcodeWidget(
                    data: student.userId.isNotEmpty
                        ? student.userId
                        : 'UNKNOWN',
                    barcode: pw.Barcode.code128(),
                    drawText: false,
                    color: PdfColors.black,
                  ),
                ),
                // Principal Signature
                pw.Column(
                  children: [
                    pw.Container(
                      width: 60,
                      child: pw.Divider(color: PdfColors.black, thickness: 1),
                    ),
                    pw.SizedBox(height: 2),
                    pw.Text(
                      'Principal',
                      style: pw.TextStyle(
                        fontSize: 8,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.deepPurple,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Bottom Bar
          pw.Container(
            height: 18,
            width: double.infinity,
            decoration: const pw.BoxDecoration(
              color: PdfColors.deepPurple,
              borderRadius: pw.BorderRadius.only(
                bottomLeft: pw.Radius.circular(9),
                bottomRight: pw.Radius.circular(9),
              ),
            ),
            child: pw.Center(
              child: pw.Text(
                'Valid for Current Academic Session',
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
      padding: const pw.EdgeInsets.symmetric(vertical: 3),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.SizedBox(
            width: 55,
            child: pw.Text(
              '$label',
              style: pw.TextStyle(
                fontWeight: pw.FontWeight.bold,
                fontSize: 9,
                color: PdfColors.deepPurple800,
              ),
            ),
          ),
          pw.Text(
            ': ',
            style: pw.TextStyle(
              fontWeight: pw.FontWeight.bold,
              fontSize: 9,
              color: PdfColors.deepPurple800,
            ),
          ),
          pw.Expanded(
            child: pw.Text(
              value,
              style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold),
              maxLines: 1,
            ),
          ),
        ],
      ),
    );
  }
}
