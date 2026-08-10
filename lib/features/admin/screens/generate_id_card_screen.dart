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
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
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

    try {
      final bytes = await _generateIdCardsPdf(PdfPageFormat.a4, school);
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
              ? 'ID Card Preview'
              : 'ID Cards Preview (${_currentStudents.length})',
        ),
        backgroundColor: AppColors.primaryAdmin,
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
                await Printing.sharePdf(bytes: _pdfBytes!, filename: 'id_cards.pdf');
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
                    child: Text('No students selected for ID cards.'),
                  )
                : SfPdfViewer.memory(
                    _pdfBytes!,
                    controller: _pdfViewerController,
                    key: ValueKey(
                      'idcard_${_selectedClassId}_${_selectedSectionId}_${_currentStudents.length}',
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
      color: AppColors.primaryAdmin.withValues(alpha: 0.05),
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
            color: AppColors.primaryAdmin,
          ),
        ),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppColors.primaryAdmin.withValues(alpha: 0.3)),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<T>(
              value: value,
              items: items,
              onChanged: onChanged,
              isExpanded: true,
              icon: const Icon(Icons.arrow_drop_down, color: AppColors.primaryAdmin),
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
    final pdf = pw.Document();

    String resolvedClassName = 'N/A';
    if (_selectedClassId != null) {
      try {
        resolvedClassName = context.read<ClassSetupNotifier>().classes.firstWhere((c) => c.id == _selectedClassId).name;
      } catch (_) {}
    }

    String resolvedSectionName = 'N/A';
    if (_selectedSectionId != null) {
      try {
        resolvedSectionName = context.read<SectionSetupNotifier>().sections.firstWhere((s) => s.id == _selectedSectionId).name;
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
    for (var student in _currentStudents) {
      final avatarUrl = student.user?.avatar ?? '';
      if (avatarUrl.isNotEmpty) {
        try {
          avatars[student.userId] = await networkImage(avatarUrl);
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
    String resolvedClassName,
    String resolvedSectionName,
  ) {
    final className = student.className?.isNotEmpty == true ? student.className! : resolvedClassName;
    final sectionName = student.sectionName?.isNotEmpty == true ? student.sectionName! : resolvedSectionName;

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
}
