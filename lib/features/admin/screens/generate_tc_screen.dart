import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:provider/provider.dart';
import 'package:smart_school/features/auth/providers/auth_provider.dart';
import 'package:smart_school/models/school_models.dart';
import 'package:smart_school/models/student_model.dart';

class GenerateTcScreen extends StatelessWidget {
  final Student student;
  final String className;
  final String sectionName;

  const GenerateTcScreen({
    super.key,
    required this.student,
    required this.className,
    required this.sectionName,
  });

  @override
  Widget build(BuildContext context) {
    final authNotifier = context.read<AuthNotifier>();
    final school = authNotifier.user?.school;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Transfer Certificate Preview'),
        backgroundColor: Colors.purple,
        foregroundColor: Colors.white,
      ),
      body: PdfPreview(build: (format) => _generateTcPdf(format, school)),
    );
  }

  Future<Uint8List> _generateTcPdf(PdfPageFormat format, School? school) async {
    final pdf = pw.Document();

    final schoolName = school?.name ?? 'Unknown School';
    final schoolAddress = school?.address ?? 'Unknown Address';
    final schoolLogoUrl = school?.avatar ?? '';
    print("schoolLogoUrl:: $schoolLogoUrl");

    pw.ImageProvider? schoolLogo;
    if (schoolLogoUrl.isNotEmpty) {
      try {
        schoolLogo = await networkImage(schoolLogoUrl);
      } catch (e) {
        // Fallback if image fails to load
      }
    }

    pdf.addPage(
      pw.Page(
        pageFormat: format,
        build: (pw.Context context) {
          return pw.Container(
            padding: const pw.EdgeInsets.all(24),
            decoration: pw.BoxDecoration(
              border: pw.Border.all(color: PdfColors.black, width: 2),
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                // Header
                pw.Center(
                  child: pw.Column(
                    children: [
                      if (schoolLogo != null)
                        pw.Container(
                          height: 80,
                          width: 80,
                          child: pw.Image(schoolLogo),
                        ),
                      if (schoolLogo != null) pw.SizedBox(height: 10),
                      pw.Text(
                        schoolName.toUpperCase(),
                        style: pw.TextStyle(
                          fontSize: 24,
                          fontWeight: pw.FontWeight.bold,
                        ),
                        textAlign: pw.TextAlign.center,
                      ),
                      pw.SizedBox(height: 8),
                      pw.Text(
                        schoolAddress,
                        style: const pw.TextStyle(fontSize: 12),
                        textAlign: pw.TextAlign.center,
                      ),
                      pw.SizedBox(height: 20),
                      pw.Text(
                        'TRANSFER CERTIFICATE',
                        style: pw.TextStyle(
                          fontSize: 18,
                          fontWeight: pw.FontWeight.bold,
                          decoration: pw.TextDecoration.underline,
                        ),
                      ),
                    ],
                  ),
                ),
                pw.SizedBox(height: 40),

                // Content
                _buildPdfRow(
                  '1. Name of the Pupil:',
                  student.user?.name ?? 'Unknown',
                ),
                _buildPdfRow('2. Admission/Roll Number:', student.rollId),
                _buildPdfRow(
                  '3. Class in which pupil last studied:',
                  className,
                ),
                _buildPdfRow('4. Section:', sectionName),
                _buildPdfRow(
                  '5. Contact Number:',
                  student.guardianContact.isNotEmpty
                      ? student.guardianContact
                      : (student.user?.phone ?? 'N/A'),
                ),
                _buildPdfRow('6. Email Address:', student.user?.email ?? 'N/A'),

                pw.SizedBox(height: 20),
                pw.Text(
                  'This is to certify that the above mentioned student has successfully completed their studies at this institution up to the stated class. Their character and conduct have been satisfactory during their tenure.',
                  style: const pw.TextStyle(fontSize: 12, lineSpacing: 2),
                  textAlign: pw.TextAlign.justify,
                ),

                pw.Spacer(),

                // Signatures
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.center,
                      children: [
                        // Placeholder for signature image if available
                        pw.SizedBox(height: 40),
                        pw.Container(
                          width: 120,
                          child: pw.Divider(
                            color: PdfColors.black,
                            thickness: 1,
                          ),
                        ),
                        pw.SizedBox(height: 4),
                        pw.Text(
                          'Class Teacher Signature',
                          style: pw.TextStyle(
                            fontWeight: pw.FontWeight.bold,
                            fontSize: 10,
                          ),
                        ),
                      ],
                    ),
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.center,
                      children: [
                        // Placeholder for signature image if available
                        pw.SizedBox(height: 40),
                        pw.Container(
                          width: 120,
                          child: pw.Divider(
                            color: PdfColors.black,
                            thickness: 1,
                          ),
                        ),
                        pw.SizedBox(height: 4),
                        pw.Text(
                          'Principal Signature',
                          style: pw.TextStyle(
                            fontWeight: pw.FontWeight.bold,
                            fontSize: 10,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                pw.SizedBox(height: 20),
                pw.Center(
                  child: pw.Text(
                    'Date: ${DateTime.now().toLocal().toString().split(' ')[0]}',
                    style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );

    return pdf.save();
  }

  pw.Widget _buildPdfRow(String label, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 12),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.SizedBox(
            width: 200,
            child: pw.Text(
              label,
              style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
            ),
          ),
          pw.Expanded(child: pw.Text(value, style: const pw.TextStyle())),
        ],
      ),
    );
  }
}
