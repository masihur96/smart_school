import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:provider/provider.dart';
import 'package:smart_school/core/utils/bangla_text_renderer.dart';
import 'package:smart_school/core/utils/pdf_image_helper.dart';
import 'package:smart_school/features/auth/providers/auth_provider.dart';
import 'package:smart_school/models/school_models.dart';
import 'package:smart_school/models/student_model.dart';
import 'package:smart_school/l10n/app_localizations.dart';

class GenerateTcScreen extends StatefulWidget {
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
  State<GenerateTcScreen> createState() => _GenerateTcScreenState();
}

class _GenerateTcScreenState extends State<GenerateTcScreen> {
  String _selectedTemplate = 'Default';
  final List<String> _templates = ['Default', 'Modern', 'Classic', 'Minimalist'];

  @override
  Widget build(BuildContext context) {
    final authNotifier = context.read<AuthNotifier>();
    final school = authNotifier.user?.school;

    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.tcPreview),
        backgroundColor: Colors.purple,
        foregroundColor: Colors.white,
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                dropdownColor: Colors.purple.shade700,
                style: const TextStyle(color: Colors.white),
                icon: const Icon(Icons.arrow_drop_down, color: Colors.white),
                value: _selectedTemplate,
                items: _templates.map((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(value),
                  );
                }).toList(),
                onChanged: (newValue) {
                  if (newValue != null) {
                    setState(() {
                      _selectedTemplate = newValue;
                    });
                  }
                },
              ),
            ),
          ),
        ],
      ),
      body: PdfPreview(
        build: (format) => _generateTcPdf(format, school),
      ),
    );
  }

  Future<Uint8List> _generateTcPdf(PdfPageFormat format, School? school) async {
    final pdf = pw.Document();

    final schoolName = school?.name ?? 'Unknown School';
    final schoolAddress = school?.address ?? '';
    final schoolPhone = school?.phone ?? '';
    final schoolEmail = school?.email ?? '';
    final schoolLogoUrl = school?.avatar ?? '';

    pw.ImageProvider? schoolLogo;
    if (schoolLogoUrl.isNotEmpty) {
      try {
        schoolLogo = await PdfImageHelper.getCachedImageProvider(schoolLogoUrl);
      } catch (e) {
        // Fallback
      }
    }

    final studentName = widget.student.user?.name ?? 'Unknown';
    final contactNo = widget.student.guardianContact.isNotEmpty
        ? widget.student.guardianContact
        : (widget.student.user?.phone ?? 'N/A');

    final stringsToRender = <String>{
      schoolName,
      schoolAddress,
      studentName,
      widget.student.rollId,
      widget.className,
      widget.sectionName,
      contactNo,
      schoolPhone,
      schoolEmail,
    };
    stringsToRender.removeWhere((s) => s.trim().isEmpty);

    await BanglaTextRenderer.preRenderBatchToGlobal(
      stringsToRender,
      fontSize: 12,
      maxWidth: 350,
    );

    pdf.addPage(
      pw.Page(
        pageFormat: format,
        build: (pw.Context context) {
          if (_selectedTemplate == 'Modern') {
            return _buildModernTcPage(context, schoolName, schoolAddress, schoolPhone, schoolEmail, schoolLogo, studentName, contactNo);
          } else if (_selectedTemplate == 'Classic') {
            return _buildClassicTcPage(context, schoolName, schoolAddress, schoolPhone, schoolEmail, schoolLogo, studentName, contactNo);
          } else if (_selectedTemplate == 'Minimalist') {
            return _buildMinimalistTcPage(context, schoolName, schoolAddress, schoolPhone, schoolEmail, schoolLogo, studentName, contactNo);
          }
          return _buildDefaultTcPage(context, schoolName, schoolAddress, schoolPhone, schoolEmail, schoolLogo, studentName, contactNo);
        },
      ),
    );

    return pdf.save();
  }

  pw.Widget _buildPdfRow(String label, String value, {double labelWidth = 200, PdfColor? labelColor, PdfColor? valueColor}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 12),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.SizedBox(
            width: labelWidth,
            child: pw.Text(label, style: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: labelColor ?? PdfColors.black)),
          ),
          pw.Expanded(
            child: BanglaTextRenderer.cachedWidget(value, style: pw.TextStyle(fontSize: 12, color: valueColor)),
          ),
        ],
      ),
    );
  }

  pw.Widget _buildDefaultTcPage(
    pw.Context context,
    String schoolName,
    String schoolAddress,
    String schoolPhone,
    String schoolEmail,
    pw.ImageProvider? schoolLogo,
    String studentName,
    String contactNo,
  ) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(24),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.black, width: 2),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Center(
            child: pw.Column(
              children: [
                if (schoolLogo != null)
                  pw.Container(height: 80, width: 80, child: pw.Image(schoolLogo)),
                if (schoolLogo != null) pw.SizedBox(height: 10),
                pw.FittedBox(
                  fit: pw.BoxFit.scaleDown,
                  child: BanglaTextRenderer.cachedWidget(schoolName, style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold)),
                ),
                pw.SizedBox(height: 8),
                if (schoolAddress.isNotEmpty)
                  BanglaTextRenderer.cachedWidget(schoolAddress, style: const pw.TextStyle(fontSize: 12)),
                pw.SizedBox(height: 20),
                pw.Text('TRANSFER CERTIFICATE', style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold, decoration: pw.TextDecoration.underline)),
              ],
            ),
          ),
          pw.SizedBox(height: 40),

          _buildPdfRow('1. Name of the Pupil:', studentName),
          _buildPdfRow('2. Admission/Roll Number:', widget.student.rollId),
          _buildPdfRow('3. Class in which pupil last studied:', widget.className),
          _buildPdfRow('4. Section:', widget.sectionName),
          _buildPdfRow('5. Contact Number:', contactNo),
          _buildPdfRow('6. Email Address:', widget.student.user?.email ?? 'N/A'),

          pw.SizedBox(height: 20),
          pw.Text(
            'This is to certify that the above mentioned student has successfully completed their studies at this institution up to the stated class. Their character and conduct have been satisfactory during their tenure.',
            style: const pw.TextStyle(fontSize: 12, lineSpacing: 2),
            textAlign: pw.TextAlign.justify,
          ),

          pw.Spacer(),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.center,
                children: [
                  pw.SizedBox(height: 40),
                  pw.Container(width: 120, child: pw.Divider(color: PdfColors.black, thickness: 1)),
                  pw.SizedBox(height: 4),
                  pw.Text('Class Teacher Signature', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10)),
                ],
              ),
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.center,
                children: [
                  pw.SizedBox(height: 40),
                  pw.Container(width: 120, child: pw.Divider(color: PdfColors.black, thickness: 1)),
                  pw.SizedBox(height: 4),
                  pw.Text('Principal Signature', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10)),
                ],
              ),
            ],
          ),
          pw.SizedBox(height: 20),
          pw.Center(child: pw.Text('Date: ${DateTime.now().toLocal().toString().split(' ')[0]}', style: pw.TextStyle(fontWeight: pw.FontWeight.bold))),
        ],
      ),
    );
  }

  pw.Widget _buildModernTcPage(
    pw.Context context,
    String schoolName,
    String schoolAddress,
    String schoolPhone,
    String schoolEmail,
    pw.ImageProvider? schoolLogo,
    String studentName,
    String contactNo,
  ) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(32),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.teal, width: 2),
        borderRadius: pw.BorderRadius.circular(16),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.center,
            children: [
              if (schoolLogo != null)
                pw.Container(height: 60, width: 60, margin: const pw.EdgeInsets.only(right: 16), child: pw.Image(schoolLogo)),
              pw.Expanded(
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.FittedBox(
                      fit: pw.BoxFit.scaleDown,
                      alignment: pw.Alignment.centerLeft,
                      child: BanglaTextRenderer.cachedWidget(schoolName, style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 24, color: PdfColors.teal900)),
                    ),
                    pw.SizedBox(height: 4),
                    pw.Text('OFFICIAL TRANSFER CERTIFICATE', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 12, color: PdfColors.teal600, letterSpacing: 2)),
                    pw.SizedBox(height: 4),
                    if (schoolAddress.isNotEmpty)
                      BanglaTextRenderer.cachedWidget(schoolAddress, style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700)),
                    if (schoolPhone.isNotEmpty || schoolEmail.isNotEmpty)
                      pw.Padding(
                        padding: const pw.EdgeInsets.only(top: 2),
                        child: pw.Text('$schoolPhone ${schoolEmail.isNotEmpty ? '| $schoolEmail' : ''}', style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700)),
                      ),
                  ],
                ),
              ),
            ],
          ),
          pw.SizedBox(height: 24),
          pw.Divider(color: PdfColors.teal100, thickness: 2),
          pw.SizedBox(height: 24),

          pw.Container(
            padding: const pw.EdgeInsets.all(16),
            decoration: pw.BoxDecoration(color: PdfColors.teal50, borderRadius: pw.BorderRadius.circular(8)),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text('STUDENT DETAILS', style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, color: PdfColors.teal900)),
                pw.SizedBox(height: 12),
                _buildPdfRow('Name of the Pupil:', studentName, labelWidth: 150),
                _buildPdfRow('Admission/Roll No:', widget.student.rollId, labelWidth: 150),
                _buildPdfRow('Class:', widget.className, labelWidth: 150),
                _buildPdfRow('Section:', widget.sectionName, labelWidth: 150),
                _buildPdfRow('Contact:', contactNo, labelWidth: 150),
              ],
            ),
          ),

          pw.SizedBox(height: 32),
          pw.Text('CERTIFICATION', style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, color: PdfColors.teal900)),
          pw.SizedBox(height: 8),
          pw.Text(
            'This is to certify that the above mentioned student has successfully completed their studies at this institution up to the stated class. Their character and conduct have been satisfactory during their tenure.',
            style: const pw.TextStyle(fontSize: 12, lineSpacing: 2),
            textAlign: pw.TextAlign.justify,
          ),

          pw.Spacer(),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text('Date: ${DateTime.now().toLocal().toString().split(' ')[0]}', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.grey700)),
                ],
              ),
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.center,
                children: [
                  pw.SizedBox(height: 40),
                  pw.Container(width: 150, child: pw.Divider(color: PdfColors.teal900, thickness: 1)),
                  pw.SizedBox(height: 4),
                  pw.Text('Principal / Headmaster', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.teal900, fontSize: 10)),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  pw.Widget _buildClassicTcPage(
    pw.Context context,
    String schoolName,
    String schoolAddress,
    String schoolPhone,
    String schoolEmail,
    pw.ImageProvider? schoolLogo,
    String studentName,
    String contactNo,
  ) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(32),
      decoration: pw.BoxDecoration(border: pw.Border.all(color: PdfColors.black, width: 1)),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.center,
        children: [
          if (schoolLogo != null)
            pw.Container(height: 70, width: 70, margin: const pw.EdgeInsets.only(bottom: 12), child: pw.Image(schoolLogo)),
          pw.FittedBox(
            fit: pw.BoxFit.scaleDown,
            alignment: pw.Alignment.center,
            child: BanglaTextRenderer.cachedWidget(schoolName, style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 26)),
          ),
          pw.SizedBox(height: 4),
          if (schoolAddress.isNotEmpty)
            BanglaTextRenderer.cachedWidget(schoolAddress, style: const pw.TextStyle(fontSize: 10)),
          if (schoolPhone.isNotEmpty || schoolEmail.isNotEmpty)
            pw.Padding(
              padding: const pw.EdgeInsets.only(top: 2),
              child: pw.Text('$schoolPhone ${schoolEmail.isNotEmpty ? '| $schoolEmail' : ''}', style: const pw.TextStyle(fontSize: 10)),
            ),
          pw.SizedBox(height: 16),
          pw.Container(
            padding: const pw.EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            decoration: pw.BoxDecoration(border: pw.Border.all(color: PdfColors.black, width: 1)),
            child: pw.Text('TRANSFER CERTIFICATE', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 14, letterSpacing: 2)),
          ),
          pw.SizedBox(height: 32),

          pw.Container(
            padding: const pw.EdgeInsets.symmetric(vertical: 8),
            child: pw.Column(
              children: [
                _buildPdfRow('1. Name of the Pupil:', studentName),
                _buildPdfRow('2. Admission/Roll No:', widget.student.rollId),
                _buildPdfRow('3. Class:', widget.className),
                _buildPdfRow('4. Section:', widget.sectionName),
                _buildPdfRow('5. Contact:', contactNo),
              ],
            ),
          ),

          pw.SizedBox(height: 24),
          pw.Divider(color: PdfColors.black, thickness: 1),
          pw.SizedBox(height: 24),
          pw.Text(
            'This is to certify that the above mentioned student has successfully completed their studies at this institution up to the stated class. Their character and conduct have been satisfactory during their tenure.',
            style: const pw.TextStyle(fontSize: 12, lineSpacing: 2),
            textAlign: pw.TextAlign.justify,
          ),

          pw.Spacer(),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.center,
                children: [
                  pw.SizedBox(height: 40),
                  pw.Container(width: 120, child: pw.Divider(color: PdfColors.black, thickness: 1)),
                  pw.SizedBox(height: 4),
                  pw.Text('Date', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10)),
                  pw.Text(DateTime.now().toLocal().toString().split(' ')[0], style: const pw.TextStyle(fontSize: 10)),
                ],
              ),
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.center,
                children: [
                  pw.SizedBox(height: 40),
                  pw.Container(width: 150, child: pw.Divider(color: PdfColors.black, thickness: 1)),
                  pw.SizedBox(height: 4),
                  pw.Text('Signature of Principal', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10)),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  pw.Widget _buildMinimalistTcPage(
    pw.Context context,
    String schoolName,
    String schoolAddress,
    String schoolPhone,
    String schoolEmail,
    pw.ImageProvider? schoolLogo,
    String studentName,
    String contactNo,
  ) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(32),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            crossAxisAlignment: pw.CrossAxisAlignment.center,
            children: [
              pw.Expanded(
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.FittedBox(
                      fit: pw.BoxFit.scaleDown,
                      alignment: pw.Alignment.centerLeft,
                      child: BanglaTextRenderer.cachedWidget(schoolName, style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 22)),
                    ),
                    pw.SizedBox(height: 4),
                    pw.Text('Transfer Certificate', style: const pw.TextStyle(fontSize: 12, color: PdfColors.grey700)),
                    if (schoolAddress.isNotEmpty)
                      pw.Padding(
                        padding: const pw.EdgeInsets.only(top: 4),
                        child: BanglaTextRenderer.cachedWidget(schoolAddress, style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700)),
                      ),
                    if (schoolPhone.isNotEmpty || schoolEmail.isNotEmpty)
                      pw.Padding(
                        padding: const pw.EdgeInsets.only(top: 2),
                        child: pw.Text('$schoolPhone ${schoolEmail.isNotEmpty ? '| $schoolEmail' : ''}', style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700)),
                      ),
                  ],
                ),
              ),
              if (schoolLogo != null)
                pw.Container(height: 50, width: 50, margin: const pw.EdgeInsets.only(left: 16), child: pw.Image(schoolLogo)),
            ],
          ),
          pw.SizedBox(height: 32),

          pw.Row(
            children: [
              pw.Expanded(
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text('Student', style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey600)),
                    pw.SizedBox(height: 2),
                    BanglaTextRenderer.cachedWidget(studentName, style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold)),
                  ],
                ),
              ),
              pw.Expanded(
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text('ID', style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey600)),
                    pw.SizedBox(height: 2),
                    BanglaTextRenderer.cachedWidget(widget.student.rollId, style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold)),
                  ],
                ),
              ),
              pw.Expanded(
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text('Class', style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey600)),
                    pw.SizedBox(height: 2),
                    BanglaTextRenderer.cachedWidget(widget.className, style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold)),
                  ],
                ),
              ),
            ],
          ),
          pw.SizedBox(height: 16),
          pw.Row(
            children: [
              pw.Expanded(
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text('Section', style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey600)),
                    pw.SizedBox(height: 2),
                    BanglaTextRenderer.cachedWidget(widget.sectionName, style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold)),
                  ],
                ),
              ),
              pw.Expanded(
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text('Contact', style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey600)),
                    pw.SizedBox(height: 2),
                    BanglaTextRenderer.cachedWidget(contactNo, style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold)),
                  ],
                ),
              ),
              pw.Expanded(child: pw.SizedBox()),
            ],
          ),
          
          pw.SizedBox(height: 32),
          pw.Container(
            padding: const pw.EdgeInsets.symmetric(vertical: 16),
            decoration: const pw.BoxDecoration(
              border: pw.Border(top: pw.BorderSide(color: PdfColors.grey300, width: 0.5), bottom: pw.BorderSide(color: PdfColors.grey300, width: 0.5)),
            ),
            child: pw.Text(
              'This is to certify that the above mentioned student has successfully completed their studies at this institution up to the stated class. Their character and conduct have been satisfactory during their tenure.',
              style: const pw.TextStyle(fontSize: 12, lineSpacing: 2, color: PdfColors.grey800),
              textAlign: pw.TextAlign.justify,
            ),
          ),

          pw.Spacer(),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            crossAxisAlignment: pw.CrossAxisAlignment.end,
            children: [
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text('Date of Issue', style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey600)),
                  pw.SizedBox(height: 2),
                  pw.Text(DateTime.now().toLocal().toString().split(' ')[0], style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold)),
                ],
              ),
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.end,
                children: [
                  pw.SizedBox(height: 40),
                  pw.Container(width: 150, child: pw.Divider(color: PdfColors.black, thickness: 1)),
                  pw.SizedBox(height: 4),
                  pw.Text('Authorized Signature', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10)),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}
