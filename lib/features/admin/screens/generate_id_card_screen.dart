import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:pdfx/pdfx.dart' as pdfx;
import 'package:printing/printing.dart';
import 'package:provider/provider.dart';
import 'package:smart_school/core/theme/app_colors.dart';
import 'package:smart_school/core/utils/pdf_image_helper.dart';
import 'package:smart_school/features/auth/providers/auth_provider.dart';
import 'package:smart_school/l10n/app_localizations.dart';
import 'package:smart_school/models/school_models.dart';
import 'package:smart_school/models/student_model.dart';

import '../providers/setup_provider.dart';
import '../providers/student_provider.dart';

class GenerateIdCardScreen extends StatefulWidget {
  final List<Student> students;

  const GenerateIdCardScreen({super.key, required this.students});

  @override
  State<GenerateIdCardScreen> createState() => _GenerateIdCardScreenState();
}

class _GenerateIdCardScreenState extends State<GenerateIdCardScreen> {
  String? _selectedClassId;
  String? _selectedSectionId;
  String _selectedTemplate = 'Default';
  final List<String> _templates = ['Default', 'Modern', 'Classic', 'Minimalist'];
  late List<Student> _currentStudents;
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
      _generatePdf();
    });
  }

  Future<void> _generatePdf() async {
    setState(() => _isLoading = true);
    final authNotifier = context.read<AuthNotifier>();
    final school = authNotifier.user?.school;

    try {
      final bytes = await _generateIdCardsPdf(PdfPageFormat.a4, school);
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
      debugPrint('❌ PDF Generation Error: $e\n$st');
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
              ? 'ID Card Preview'
              : 'ID Cards Preview (${_currentStudents.length})',
        ),
        backgroundColor: AppColors.primaryAdmin,
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
                await Printing.sharePdf(
                  bytes: _pdfBytes!,
                  filename: 'id_cards.pdf',
                );
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
                    child: Text(AppLocalizations.of(context)!.noStudentsForIdCards),
                  )
                : pdfx.PdfViewPinch(controller: _pdfController!),
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
      color: AppColors.primaryAdmin.withValues(alpha: 0.05),
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
              value: uniqueClasses.containsKey(_selectedClassId)
                  ? _selectedClassId
                  : null,
              items: [
                if (!uniqueClasses.containsKey(_selectedClassId) &&
                    _selectedClassId != null)
                  DropdownMenuItem(
                    value: _selectedClassId,
                    child: Text(AppLocalizations.of(context)!.unknownClass),
                  ),
                if (!uniqueClasses.containsKey(_selectedClassId) &&
                    _selectedClassId == null)
                  DropdownMenuItem(
                    value: null,
                    child: Text(AppLocalizations.of(context)!.selectClass),
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
                label: AppLocalizations.of(context)!.section,
                value: uniqueSections.containsKey(_selectedSectionId)
                    ? _selectedSectionId
                    : null,
                items: [
                  DropdownMenuItem(
                    value: null,
                    child: Text(AppLocalizations.of(context)!.allSections),
                  ),
                  if (!uniqueSections.containsKey(_selectedSectionId) &&
                      _selectedSectionId != null)
                    DropdownMenuItem(
                      value: _selectedSectionId,
                      child: Text(AppLocalizations.of(context)!.unknownSection),
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
            color: AppColors.primaryAdmin,
          ),
        ),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
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

  Future<Uint8List> _generateIdCardsPdf(
    PdfPageFormat format,
    School? school,
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

    // A standard ID card is approx 54mm x 86mm (CR80).
    // In PDF points (1 mm = 2.83465 points), 54mm = 153 points, 86mm = 243 points.
    // For standard A4 printing, we can fit multiple in a grid.
    const double cardWidth = 160 * 1.5;
    const double cardHeight = 250 * 1.5;

    // Fetch all student avatars concurrently
    final Map<String, pw.ImageProvider> avatars = {};
    for (var student in _currentStudents) {
      final avatarUrl = student.user?.avatar ?? '';
      if (avatarUrl.isNotEmpty) {
        try {
          avatars[student.userId] = await PdfImageHelper.getCachedImageProvider(
            avatarUrl,
          );
        } catch (e) {
          // Fallback
        }
      }
    }

    // Group students into pages (4 per page on A4)
    // A4 is 595 x 842 points.
    // We can fit 2 columns, 2 rows = 4 cards.
    final itemsPerPage = 4;
    for (var i = 0; i < _currentStudents.length; i += itemsPerPage) {
      final pageStudents = _currentStudents.skip(i).take(itemsPerPage).toList();

      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(32),
          build: (pw.Context context) {
            return pw.Wrap(
              spacing: 20,
              runSpacing: 20,
              children: pageStudents.map((student) {
                return _buildSelectedIdCard(
                  student,
                  schoolName,
                  schoolLogo,
                  avatars[student.userId],
                  cardWidth,
                  cardHeight,
                  schoolAddress,
                  schoolPhone,
                  schoolEmail,
                  resolvedClassName,
                  resolvedSectionName,
                );
              }).toList(),
            );
          },
        ),
      );
    }

    return pdf.save();
  }

  pw.Widget _buildSelectedIdCard(
    Student student,
    String schoolName,
    pw.ImageProvider? schoolLogo,
    pw.ImageProvider? studentAvatar,
    double width,
    double height,
    String schoolAddress,
    String schoolPhone,
    String schoolEmail,
    String resolvedClassName,
    String resolvedSectionName,
  ) {
    if (_selectedTemplate == 'Modern') {
      return _buildModernIdCard(student, schoolName, schoolLogo, studentAvatar, width, height, schoolAddress, schoolPhone, schoolEmail, resolvedClassName, resolvedSectionName);
    } else if (_selectedTemplate == 'Classic') {
      return _buildClassicIdCard(student, schoolName, schoolLogo, studentAvatar, width, height, schoolAddress, schoolPhone, schoolEmail, resolvedClassName, resolvedSectionName);
    } else if (_selectedTemplate == 'Minimalist') {
      return _buildMinimalistIdCard(student, schoolName, schoolLogo, studentAvatar, width, height, schoolAddress, schoolPhone, schoolEmail, resolvedClassName, resolvedSectionName);
    }
    return _buildDefaultIdCard(student, schoolName, schoolLogo, studentAvatar, width, height, schoolAddress, schoolPhone, schoolEmail, resolvedClassName, resolvedSectionName);
  }

  pw.Widget _buildDefaultIdCard(
    Student student,
    String schoolName,
    pw.ImageProvider? schoolLogo,
    pw.ImageProvider? studentAvatar,
    double width,
    double height,
    String schoolAddress,
    String schoolPhone,
    String schoolEmail,
    String resolvedClassName,
    String resolvedSectionName,
  ) {
    final className = student.className?.isNotEmpty == true
        ? student.className!
        : resolvedClassName;
    final sectionName = student.sectionName?.isNotEmpty == true
        ? student.sectionName!
        : resolvedSectionName;
    
    final barcodeData = 'ID: ${student.rollId}\n'
        'Name: ${student.user?.name ?? 'N/A'}\n'
        'Class: $className-$sectionName\n'
        'Phone: ${student.user?.phone ?? student.guardianContact}\n'
        'Email: ${student.user?.email ?? 'N/A'}\n'
        'School Ph: $schoolPhone\n'
        'School Email: $schoolEmail';

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
                        schoolName,
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
                          ? student.user!.name[0]
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
            student.user?.name ?? 'UNKNOWN',
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
                _buildDetailRow(AppLocalizations.of(context)!.rollNo, student.rollId),
                _buildDetailRow(
                  AppLocalizations.of(context)!.className,
                  '$className - $sectionName',
                ),
                _buildDetailRow(
                  'Contact',
                  student.guardianContact.isNotEmpty
                      ? student.guardianContact
                      : (student.user?.phone ?? 'N/A'),
                ),
                _buildDetailRow(AppLocalizations.of(context)!.email, student.user?.email ?? 'N/A'),
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
                  width: 40,
                  height: 40,
                  child: pw.BarcodeWidget(
                    data: barcodeData,
                    barcode: pw.Barcode.qrCode(),
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
              label,
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

  // --- MODERN TEMPLATE ---
  pw.Widget _buildModernIdCard(
    Student student,
    String schoolName,
    pw.ImageProvider? schoolLogo,
    pw.ImageProvider? studentAvatar,
    double width,
    double height,
    String schoolAddress,
    String schoolPhone,
    String schoolEmail,
    String resolvedClassName,
    String resolvedSectionName,
  ) {
    final className = student.className?.isNotEmpty == true ? student.className! : resolvedClassName;
    final sectionName = student.sectionName?.isNotEmpty == true ? student.sectionName! : resolvedSectionName;
    final barcodeData = 'ID: ${student.rollId}\n'
        'Name: ${student.user?.name ?? 'N/A'}\n'
        'Class: $className-$sectionName\n'
        'Phone: ${student.user?.phone ?? student.guardianContact}\n'
        'Email: ${student.user?.email ?? 'N/A'}\n'
        'School Ph: $schoolPhone\n'
        'School Email: $schoolEmail';

    return pw.Container(
      width: width,
      height: height,
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.indigo700, width: 3),
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(12)),
        color: PdfColors.white,
      ),
      child: pw.Column(
        children: [
          // ── Header ──
          pw.Container(
            padding: const pw.EdgeInsets.symmetric(vertical: 10, horizontal: 8),
            decoration: const pw.BoxDecoration(
              color: PdfColors.indigo700,
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
                        schoolName,
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
                          style: const pw.TextStyle(color: PdfColors.white, fontSize: 6),
                          textAlign: pw.TextAlign.center,
                          maxLines: 1,
                        ),
                      if (schoolPhone.isNotEmpty || schoolEmail.isNotEmpty)
                        pw.Text(
                          [
                            if (schoolPhone.isNotEmpty) 'Ph: $schoolPhone',
                            if (schoolEmail.isNotEmpty) schoolEmail,
                          ].join(' | '),
                          style: const pw.TextStyle(color: PdfColors.amber, fontSize: 5),
                          textAlign: pw.TextAlign.center,
                          maxLines: 1,
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // ── Identity Card Banner ──
          pw.Container(
            width: double.infinity,
            color: PdfColors.amber,
            padding: const pw.EdgeInsets.symmetric(vertical: 4),
            child: pw.Text(
              'IDENTITY CARD',
              style: pw.TextStyle(
                color: PdfColors.indigo900,
                fontWeight: pw.FontWeight.bold,
                fontSize: 9,
                letterSpacing: 1.5,
              ),
              textAlign: pw.TextAlign.center,
            ),
          ),

          pw.SizedBox(height: 10),

          // ── Photo ──
          pw.Container(
            height: 80,
            width: 80,
            decoration: pw.BoxDecoration(
              shape: pw.BoxShape.circle,
              border: pw.Border.all(color: PdfColors.indigo700, width: 3),
              color: PdfColors.grey200,
            ),
            child: studentAvatar != null
                ? pw.ClipOval(child: pw.Image(studentAvatar, fit: pw.BoxFit.cover))
                : pw.Center(
                    child: pw.Text(
                      student.user?.name.isNotEmpty == true
                          ? student.user!.name[0]
                          : '?',
                      style: pw.TextStyle(
                        fontSize: 30,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.indigo700,
                      ),
                    ),
                  ),
          ),

          pw.SizedBox(height: 8),

          // ── Student Name ──
          pw.Text(
            student.user?.name ?? 'Unknown',
            style: pw.TextStyle(
              fontWeight: pw.FontWeight.bold,
              fontSize: 13,
              color: PdfColors.indigo900,
            ),
            textAlign: pw.TextAlign.center,
            maxLines: 1,
          ),
          pw.Text(
            'STUDENT',
            style: pw.TextStyle(
              fontSize: 8,
              color: PdfColors.indigo700,
              fontWeight: pw.FontWeight.bold,
              letterSpacing: 1.5,
            ),
            textAlign: pw.TextAlign.center,
          ),

          pw.SizedBox(height: 10),
          pw.Divider(color: PdfColors.indigo100),
          pw.SizedBox(height: 4),

          // ── Details ──
          pw.Padding(
            padding: const pw.EdgeInsets.symmetric(horizontal: 16),
            child: pw.Column(
              children: [
                _buildDetailRow('ID', student.rollId),
                _buildDetailRow('Class', '$className - $sectionName'),
                _buildDetailRow(
                  'Phone',
                  student.guardianContact.isNotEmpty
                      ? student.guardianContact
                      : (student.user?.phone ?? 'N/A'),
                ),
                _buildDetailRow('Email', student.user?.email ?? 'N/A'),
              ],
            ),
          ),

          pw.Spacer(),

          // ── Footer ──
          pw.Padding(
            padding: const pw.EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              crossAxisAlignment: pw.CrossAxisAlignment.end,
              children: [
                pw.Container(
                  width: 42,
                  height: 42,
                  child: pw.BarcodeWidget(
                    data: barcodeData,
                    barcode: pw.Barcode.qrCode(),
                    drawText: false,
                    color: PdfColors.indigo900,
                  ),
                ),
                pw.Column(
                  children: [
                    pw.Container(
                      width: 60,
                      child: pw.Divider(color: PdfColors.indigo700, thickness: 1),
                    ),
                    pw.Text(
                      'Principal',
                      style: pw.TextStyle(
                        fontSize: 8,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.indigo700,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  pw.Widget _buildModernDetailRow(String label, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 3),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.center,
        children: [
          pw.Expanded(
            flex: 2,
            child: pw.Text(label, style: pw.TextStyle(fontSize: 8, color: PdfColors.grey600, fontWeight: pw.FontWeight.bold), textAlign: pw.TextAlign.right),
          ),
          pw.SizedBox(width: 8),
          pw.Expanded(
            flex: 3,
            child: pw.Text(value, style: pw.TextStyle(fontSize: 9, color: PdfColors.grey900, fontWeight: pw.FontWeight.bold), textAlign: pw.TextAlign.left),
          ),
        ],
      ),
    );
  }

  // --- CLASSIC TEMPLATE ---
  pw.Widget _buildClassicIdCard(
    Student student,
    String schoolName,
    pw.ImageProvider? schoolLogo,
    pw.ImageProvider? studentAvatar,
    double width,
    double height,
    String schoolAddress,
    String schoolPhone,
    String schoolEmail,
    String resolvedClassName,
    String resolvedSectionName,
  ) {
    final className = student.className?.isNotEmpty == true ? student.className! : resolvedClassName;
    final sectionName = student.sectionName?.isNotEmpty == true ? student.sectionName! : resolvedSectionName;
    final barcodeData = 'ID: ${student.rollId}\n'
        'Name: ${student.user?.name ?? 'N/A'}\n'
        'Class: $className-$sectionName\n'
        'Phone: ${student.user?.phone ?? student.guardianContact}\n'
        'Email: ${student.user?.email ?? 'N/A'}\n'
        'School Ph: $schoolPhone\n'
        'School Email: $schoolEmail';

    return pw.Container(
      width: width,
      height: height,
      decoration: pw.BoxDecoration(
        color: PdfColors.white,
        border: pw.Border.all(color: PdfColors.blue900, width: 3),
      ),
      child: pw.Column(
        children: [
          // Header
          pw.Container(
            padding: const pw.EdgeInsets.symmetric(vertical: 8, horizontal: 8),
            decoration: const pw.BoxDecoration(color: PdfColors.blue900),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.center,
              children: [
                if (schoolLogo != null)
                  pw.Container(
                    height: 35,
                    width: 35,
                    margin: const pw.EdgeInsets.only(right: 8),
                    decoration: const pw.BoxDecoration(shape: pw.BoxShape.circle, color: PdfColors.white),
                    child: pw.ClipOval(child: pw.Image(schoolLogo, fit: pw.BoxFit.contain)),
                  ),
                pw.Expanded(
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.center,
                    children: [
                      pw.Text(
                        schoolName,
                        style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 13, color: PdfColors.white),
                        textAlign: pw.TextAlign.center,
                      ),
                      if (schoolAddress.isNotEmpty)
                        pw.Text(
                          schoolAddress,
                          style: const pw.TextStyle(fontSize: 6, color: PdfColors.white),
                          textAlign: pw.TextAlign.center,
                          maxLines: 1,
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          pw.Container(
            width: double.infinity,
            padding: const pw.EdgeInsets.symmetric(vertical: 4),
            decoration: const pw.BoxDecoration(color: PdfColors.amber),
            child: pw.Text(
              'STUDENT IDENTITY CARD',
              style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9, color: PdfColors.blue900, letterSpacing: 1.5),
              textAlign: pw.TextAlign.center,
            ),
          ),
          pw.SizedBox(height: 12),
          
          pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // Photo Left
              pw.Padding(
                padding: const pw.EdgeInsets.only(left: 12),
                child: pw.Container(
                  height: 80,
                  width: 65,
                  decoration: pw.BoxDecoration(
                    border: pw.Border.all(color: PdfColors.amber, width: 2),
                    color: PdfColors.grey200,
                  ),
                  child: studentAvatar != null
                      ? pw.Image(studentAvatar, fit: pw.BoxFit.cover)
                      : pw.Center(child: pw.Text('Photo', style: const pw.TextStyle(color: PdfColors.grey600, fontSize: 8))),
                ),
              ),
              pw.SizedBox(width: 12),
              // Details Right
              pw.Expanded(
                child: pw.Padding(
                  padding: const pw.EdgeInsets.only(right: 12),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        student.user?.name ?? 'UNKNOWN',
                        style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 12, color: PdfColors.blue900),
                      ),
                      pw.SizedBox(height: 2),
                      pw.Divider(color: PdfColors.amber, thickness: 1),
                      pw.SizedBox(height: 4),
                      _buildClassicDetailRow('ID', student.rollId),
                      _buildClassicDetailRow('Class', '$className - $sectionName'),

                      _buildClassicDetailRow('Contact', student.guardianContact.isNotEmpty ? student.guardianContact : (student.user?.phone ?? 'N/A')),
                    ],
                  ),
                ),
              ),
            ],
          ),
          
          pw.Spacer(),
          // Footer
          pw.Padding(
            padding: const pw.EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              crossAxisAlignment: pw.CrossAxisAlignment.end,
              children: [
                pw.Container(
                  width: 35,
                  height: 35,
                  child: pw.BarcodeWidget(
                    data: barcodeData,
                    barcode: pw.Barcode.qrCode(),
                    drawText: false,
                    color: PdfColors.blue900,
                  ),
                ),
                pw.Column(
                  children: [
                    pw.Container(width: 60, child: pw.Divider(color: PdfColors.blue900, thickness: 1)),
                    pw.SizedBox(height: 2),
                    pw.Text('Principal', style: pw.TextStyle(fontSize: 8, color: PdfColors.blue900, fontWeight: pw.FontWeight.bold)),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  pw.Widget _buildClassicDetailRow(String label, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 3),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.SizedBox(width: 35, child: pw.Text(label, style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 8, color: PdfColors.blue900))),
          pw.Text(': ', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 8, color: PdfColors.blue900)),
          pw.Expanded(child: pw.Text(value, style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold, color: PdfColors.black))),
        ],
      ),
    );
  }

  // --- MINIMALIST TEMPLATE ---
  pw.Widget _buildMinimalistIdCard(
    Student student,
    String schoolName,
    pw.ImageProvider? schoolLogo,
    pw.ImageProvider? studentAvatar,
    double width,
    double height,
    String schoolAddress,
    String schoolPhone,
    String schoolEmail,
    String resolvedClassName,
    String resolvedSectionName,
  ) {
    final className = student.className?.isNotEmpty == true ? student.className! : resolvedClassName;
    final sectionName = student.sectionName?.isNotEmpty == true ? student.sectionName! : resolvedSectionName;
    final barcodeData = 'ID: ${student.rollId}\n'
        'Name: ${student.user?.name ?? 'N/A'}\n'
        'Class: $className-$sectionName\n'
        'Phone: ${student.user?.phone ?? student.guardianContact}\n'
        'Email: ${student.user?.email ?? 'N/A'}\n'
        'School Ph: $schoolPhone\n'
        'School Email: $schoolEmail';

    return pw.Container(
      width: width,
      height: height,
      decoration: pw.BoxDecoration(
        color: PdfColors.white,
        border: pw.Border.all(color: PdfColors.grey400, width: 1),
        borderRadius: pw.BorderRadius.circular(16),
      ),
      padding: const pw.EdgeInsets.all(16),
      child: pw.Column(
        children: [
          // Header
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
                      style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 11, color: PdfColors.grey900, letterSpacing: 1),
                      maxLines: 3,
                    ),
                    if (schoolAddress.isNotEmpty) ...[
                      pw.SizedBox(height: 2),
                      pw.Text(
                        schoolAddress,
                        style: const pw.TextStyle(fontSize: 6, color: PdfColors.grey700),
                        maxLines: 1,
                      ),
                    ],
                    if (schoolPhone.isNotEmpty || schoolEmail.isNotEmpty) ...[
                      pw.SizedBox(height: 2),
                      pw.Text(
                        [if (schoolPhone.isNotEmpty) 'Ph: $schoolPhone', if (schoolEmail.isNotEmpty) schoolEmail].join(' | '),
                        style: const pw.TextStyle(fontSize: 5, color: PdfColors.grey700),
                        maxLines: 1,
                      ),
                    ],
                  ],
                ),
              ),
              if (schoolLogo != null)
                pw.Container(
                  height: 30,
                  width: 30,
                  margin: const pw.EdgeInsets.only(left: 8),
                  child: pw.Image(schoolLogo, fit: pw.BoxFit.contain),
                ),
            ],
          ),
          pw.SizedBox(height: 6),
          pw.Divider(color: PdfColors.grey300, thickness: 1),
          pw.SizedBox(height: 10),
          
          // Photo & Name Row
          pw.Row(
            children: [
              pw.Container(
                height: 65,
                width: 65,
                decoration: pw.BoxDecoration(
                  shape: pw.BoxShape.circle,
                  color: PdfColors.grey100,
                  border: pw.Border.all(color: PdfColors.grey300, width: 1),
                ),
                child: studentAvatar != null
                    ? pw.ClipOval(child: pw.Image(studentAvatar, fit: pw.BoxFit.cover))
                    : pw.Center(child: pw.Text(student.user?.name.isNotEmpty == true ? student.user!.name[0] : '?', style: const pw.TextStyle(color: PdfColors.grey400, fontSize: 24))),
              ),
              pw.SizedBox(width: 16),
              pw.Expanded(
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      student.user?.name ?? 'Unknown',
                      style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 14, color: PdfColors.black),
                    ),
                    pw.SizedBox(height: 2),
                    pw.Text('STUDENT', style: pw.TextStyle(fontSize: 8, color: PdfColors.grey600, fontWeight: pw.FontWeight.bold, letterSpacing: 1.5)),
                  ],
                ),
              ),
            ],
          ),
          
          pw.SizedBox(height: 20),
          
          // Details
          pw.Row(
            children: [
              pw.Expanded(
                flex: 2,
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text('ID Number', style: const pw.TextStyle(fontSize: 7, color: PdfColors.grey600)),
                    pw.Text(student.rollId, style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold, color: PdfColors.grey900)),
                    pw.SizedBox(height: 8),
                    pw.Text('Class & Section', style: const pw.TextStyle(fontSize: 7, color: PdfColors.grey600)),
                    pw.Text('$className - $sectionName', style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold, color: PdfColors.grey900)),
                  ],
                ),
              ),
              pw.Expanded(
                flex: 2,
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text('Email', style: const pw.TextStyle(fontSize: 7, color: PdfColors.grey600)),
                    pw.Text(student.user?.email ?? 'N/A', style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold, color: PdfColors.grey900)),
                    pw.SizedBox(height: 8),
                    pw.Text('Contact', style: const pw.TextStyle(fontSize: 7, color: PdfColors.grey600)),
                    pw.Text(student.guardianContact.isNotEmpty ? student.guardianContact : (student.user?.phone ?? 'N/A'), style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold, color: PdfColors.grey900)),
                  ],
                ),
              ),
            ],
          ),
          
          pw.Spacer(),
          // Footer
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            crossAxisAlignment: pw.CrossAxisAlignment.end,
            children: [
              pw.Container(
                width: 45,
                height: 45,
                child: pw.BarcodeWidget(
                  data: barcodeData,
                  barcode: pw.Barcode.qrCode(),
                  drawText: false,
                  color: PdfColors.grey800,
                ),
              ),
              pw.Column(
                children: [
                  pw.Container(width: 60, child: pw.Divider(color: PdfColors.grey800, thickness: 1)),
                  pw.SizedBox(height: 4),
                  pw.Text('Authorized Signature', style: const pw.TextStyle(fontSize: 6, color: PdfColors.grey700)),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}
