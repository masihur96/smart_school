import 'dart:developer';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pdfx/pdfx.dart' as pdfx;
import 'package:printing/printing.dart';
import 'package:provider/provider.dart';
import 'package:smart_school/core/theme/app_colors.dart';
import 'package:smart_school/core/utils/class_routine_pdf_helper.dart';
import 'package:smart_school/features/admin/providers/routine_provider.dart';
import 'package:smart_school/features/admin/providers/setup_provider.dart';
import 'package:smart_school/features/admin/providers/teacher_provider.dart';
import 'package:smart_school/features/auth/providers/auth_provider.dart';
import 'package:smart_school/models/school_models.dart' hide Teacher;
import 'package:smart_school/models/teacher_model.dart';

class RoutinePdfPreviewScreen extends StatefulWidget {
  final String? initialClassId;
  final String? initialSectionId;

  const RoutinePdfPreviewScreen({
    super.key,
    this.initialClassId,
    this.initialSectionId,
  });

  @override
  State<RoutinePdfPreviewScreen> createState() =>
      _RoutinePdfPreviewScreenState();
}

class _RoutinePdfPreviewScreenState extends State<RoutinePdfPreviewScreen> {
  String? _selectedClassId;
  String? _selectedSectionId;
  RoutinePdfLayout _selectedLayout = RoutinePdfLayout.dayByDay;

  bool _isLoading = false;
  Uint8List? _pdfBytes;
  pdfx.PdfControllerPinch? _pdfController;
  int _pageCount = 0;
  int _currentPage = 1;

  @override
  void initState() {
    super.initState();
    _selectedClassId = widget.initialClassId;
    _selectedSectionId = widget.initialSectionId;

    final classNotifier = context.read<ClassSetupNotifier>();
    if (_selectedClassId == null && classNotifier.classes.isNotEmpty) {
      _selectedClassId = classNotifier.classes.first.id;
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _generatePdf();
    });
  }

  @override
  void dispose() {
    _pdfController?.dispose();
    super.dispose();
  }

  Future<void> _generatePdf() async {
    if (!mounted) return;
    setState(() => _isLoading = true);

    try {
      final authNotifier = context.read<AuthNotifier>();
      final school = authNotifier.user?.school;

      final classNotifier = context.read<ClassSetupNotifier>();
      final sectionNotifier = context.read<SectionSetupNotifier>();
      final subjectNotifier = context.read<SubjectSetupNotifier>();
      final teacherNotifier = context.read<TeachersNotifier>();
      final routineNotifier = context.read<RoutineNotifier>();

      final classes = classNotifier.classes;
      final sections = sectionNotifier.sections;
      final subjects = subjectNotifier.subjects;
      final teachers = teacherNotifier.teachers;
      final routineState = routineNotifier.state;

      // Resolve class name
      final matchedClass = classes.firstWhere(
        (c) => c.id == _selectedClassId,
        orElse: () => ClassRoom(id: '', name: 'Selected Class'),
      );
      final className = matchedClass.name.isNotEmpty
          ? matchedClass.name
          : (_selectedClassId ?? 'General');

      // Resolve section name
      String? sectionName;
      if (_selectedSectionId != null && _selectedSectionId!.isNotEmpty) {
        final matchedSection = sections.firstWhere(
          (s) => s.id == _selectedSectionId,
          orElse: () => Section(id: '', name: '', classId: ''),
        );
        if (matchedSection.name.isNotEmpty) {
          sectionName = matchedSection.name;
        }
      }

      // Filter entries
      final List<RoutineEntry> filteredEntries;
      if (_selectedClassId == null || _selectedClassId!.isEmpty) {
        filteredEntries = routineState.values.expand((list) => list).toList();
      } else if (_selectedSectionId == null || _selectedSectionId!.isEmpty) {
        filteredEntries = routineState.entries
            .where((e) => e.key.startsWith('${_selectedClassId}_'))
            .expand((e) => e.value)
            .toList();
      } else {
        final key = '${_selectedClassId}_$_selectedSectionId';
        filteredEntries = routineState[key] ?? <RoutineEntry>[];
      }

      final bytes = await ClassRoutinePdfHelper.generateRoutinePdfBytes(
        school: school,
        className: className,
        sectionName: sectionName,
        entries: filteredEntries,
        subjects: subjects,
        teachers: teachers,
        layout: _selectedLayout,
      );

      if (mounted) {
        setState(() {
          _pdfBytes = bytes;
          _pdfController?.dispose();
          _pdfController = pdfx.PdfControllerPinch(
            document: pdfx.PdfDocument.openData(bytes),
          );
          _currentPage = 1;
          _isLoading = false;
        });
      }
    } catch (e, st) {
      log('Error generating routine PDF: $e\n$st');
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to generate PDF: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _printPdf() async {
    if (_pdfBytes == null) return;
    final cleanClass = (_selectedClassId ?? 'Class').replaceAll(' ', '_');
    final filename =
        'Class_Routine_${cleanClass}_${DateFormat('yyyyMMdd').format(DateTime.now())}.pdf';

    await Printing.layoutPdf(
      onLayout: (format) async => _pdfBytes!,
      name: filename,
    );
  }

  Future<void> _sharePdf() async {
    if (_pdfBytes == null) return;
    final cleanClass = (_selectedClassId ?? 'Class').replaceAll(' ', '_');
    final filename =
        'Class_Routine_${cleanClass}_${DateFormat('yyyyMMdd').format(DateTime.now())}.pdf';

    await Printing.sharePdf(bytes: _pdfBytes!, filename: filename);
  }

  @override
  Widget build(BuildContext context) {
    final rawClasses = context.watch<ClassSetupNotifier>().classes;
    final classes = rawClasses
        .fold<Map<String, ClassRoom>>({}, (map, c) {
          map[c.id] = c;
          return map;
        })
        .values
        .toList();

    final allSections = context.watch<SectionSetupNotifier>().sections;
    final filteredSections = allSections
        .where((s) => s.classId == _selectedClassId)
        .fold<Map<String, Section>>({}, (map, s) {
          map[s.id] = s;
          return map;
        })
        .values
        .toList();

    return Scaffold(
      appBar: AppBar(
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Routine PDF Preview',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            Text(
              'Official Academic Timetable',
              style: TextStyle(fontSize: 12, color: Colors.white70),
            ),
          ],
        ),
        backgroundColor: AppColors.primaryAdmin,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          // Direct Print
          IconButton(
            icon: const Icon(Icons.print_rounded),
            tooltip: 'Print Timetable',
            onPressed: _pdfBytes != null ? _printPdf : null,
          ),
          // Direct Share
          IconButton(
            icon: const Icon(Icons.share_rounded),
            tooltip: 'Share Timetable PDF',
            onPressed: _pdfBytes != null ? _sharePdf : null,
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: Column(
        children: [
          // Filter & Layout Controls
          _buildFilterBar(classes, filteredSections),

          // Main PDF Previewer
          Expanded(
            child: _isLoading
                ? const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(color: AppColors.primaryAdmin),
                        SizedBox(height: 16),
                        Text(
                          'Generating Routine PDF...',
                          style: TextStyle(
                            color: Colors.grey,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  )
                : _pdfBytes == null || _pdfController == null
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.picture_as_pdf_outlined,
                          size: 56,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'Select a class above to generate the routine.',
                          style: TextStyle(color: Colors.grey),
                        ),
                        const SizedBox(height: 12),
                        ElevatedButton.icon(
                          onPressed: _generatePdf,
                          icon: const Icon(Icons.refresh),
                          label: const Text('Generate PDF'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primaryAdmin,
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  )
                : Container(
                    color: const Color(0xFFF1F5F9),
                    child: pdfx.PdfViewPinch(
                      controller: _pdfController!,
                      onPageChanged: (page) {
                        setState(() => _currentPage = page);
                      },
                      onDocumentLoaded: (document) {
                        setState(() => _pageCount = document.pagesCount);
                      },
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterBar(
    List<ClassRoom> classes,
    List<Section> filteredSections,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          // Dropdowns Row
          Row(
            children: [
              // Class Picker
              Expanded(
                flex: 5,
                child: Container(
                  height: 42,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String?>(
                      value: classes.any((c) => c.id == _selectedClassId)
                          ? _selectedClassId
                          : null,
                      hint: const Text(
                        'Select Class',
                        style: TextStyle(fontSize: 13),
                      ),
                      isExpanded: true,
                      icon: const Icon(Icons.arrow_drop_down, color: AppColors.primaryAdmin),
                      items: classes
                          .map(
                            (c) => DropdownMenuItem(
                              value: c.id,
                              child: Text(
                                c.name,
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          )
                          .toList(),
                      onChanged: (val) {
                        setState(() {
                          _selectedClassId = val;
                          _selectedSectionId = null;
                        });
                        _generatePdf();
                      },
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),

              // Section Picker
              Expanded(
                flex: 5,
                child: Container(
                  height: 42,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String?>(
                      value: filteredSections.any((s) => s.id == _selectedSectionId)
                          ? _selectedSectionId
                          : null,
                      hint: Text(
                        filteredSections.isEmpty
                            ? 'All Sections'
                            : 'All Sections',
                        style: const TextStyle(fontSize: 13),
                      ),
                      isExpanded: true,
                      icon: const Icon(Icons.arrow_drop_down, color: AppColors.primaryAdmin),
                      items: [
                        const DropdownMenuItem(
                          value: null,
                          child: Text(
                            'All Sections',
                            style: TextStyle(fontSize: 13),
                          ),
                        ),
                        ...filteredSections.map(
                          (s) => DropdownMenuItem(
                            value: s.id,
                            child: Text(
                              s.name,
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      ],
                      onChanged: (val) {
                        setState(() => _selectedSectionId = val);
                        _generatePdf();
                      },
                    ),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 10),

          // Layout Switcher Strip
          Row(
            children: [
              // Segmented Buttons for Layout
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  padding: const EdgeInsets.all(3),
                  child: Row(
                    children: [
                      Expanded(
                        child: _buildLayoutPill(
                          label: 'Day-by-Day',
                          icon: Icons.view_day_outlined,
                          layout: RoutinePdfLayout.dayByDay,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: _buildLayoutPill(
                          label: 'Weekly Grid',
                          icon: Icons.grid_view_rounded,
                          layout: RoutinePdfLayout.weeklyGrid,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Page Counter Indicator
              if (_pageCount > 0) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '$_currentPage/$_pageCount',
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF475569),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLayoutPill({
    required String label,
    required IconData icon,
    required RoutinePdfLayout layout,
  }) {
    final isSelected = _selectedLayout == layout;
    return InkWell(
      onTap: () {
        if (_selectedLayout != layout) {
          setState(() => _selectedLayout = layout);
          _generatePdf();
        }
      },
      borderRadius: BorderRadius.circular(6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.06),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 14,
              color: isSelected ? AppColors.primaryAdmin : Colors.grey[600],
            ),
            const SizedBox(width: 5),
            Flexible(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                  color: isSelected ? AppColors.primaryAdmin : Colors.grey[700],
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
