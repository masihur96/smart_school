import 'dart:developer';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:pdfx/pdfx.dart' as pdfx;
import 'package:printing/printing.dart';
import 'package:provider/provider.dart';
import 'package:smart_school/core/utils/bangla_text_renderer.dart';
import 'package:smart_school/core/utils/pdf_image_helper.dart';
import 'package:smart_school/features/auth/providers/auth_provider.dart';
import 'package:smart_school/l10n/app_localizations.dart';
import 'package:smart_school/models/school_models.dart';
import 'package:smart_school/models/student_model.dart';

import '../providers/exam_provider.dart';
import '../providers/setup_provider.dart';
import '../providers/student_provider.dart';

enum ReportCardViewMode {
  studentWise,
  classResultSheet,
}

class _ResultSheetSubject {
  final String id;
  final String name;
  final double maxMarks;

  _ResultSheetSubject({
    required this.id,
    required this.name,
    this.maxMarks = 100.0,
  });
}

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
  ReportCardViewMode _viewMode = ReportCardViewMode.studentWise;
  String? _selectedClassId;
  String? _selectedSectionId;
  late List<Student> _currentStudents;
  List<Result> _fetchedResults = [];
  bool _isLoading = false;
  bool _showFilters = true;
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
      final bytes = _viewMode == ReportCardViewMode.studentWise
          ? await _generateReportCardsPdf(
              PdfPageFormat.a4,
              school,
              allSubjects,
              allClasses,
              allSections,
            )
          : await _generateClassResultSheetPdf(
              PdfPageFormat.a4.landscape,
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
          _viewMode == ReportCardViewMode.studentWise
              ? (_currentStudents.length == 1
                  ? 'Report Card Preview'
                  : 'Report Cards (${_currentStudents.length})')
              : 'Class Result Sheet (${_currentStudents.length})',
        ),
        backgroundColor: Colors.purple,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: Icon(_showFilters ? Icons.filter_alt_off : Icons.filter_alt),
            onPressed: () {
              setState(() {
                _showFilters = !_showFilters;
              });
            },
            tooltip: _showFilters ? 'Hide Filters' : 'Show Filters',
          ),
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
                final className = _selectedClassId != null &&
                        uniqueClasses.containsKey(_selectedClassId)
                    ? uniqueClasses[_selectedClassId]!
                    : 'Class';
                final cleanClassName =
                    className.replaceAll(RegExp(r'\s+'), '_');
                final filename = _viewMode == ReportCardViewMode.studentWise
                    ? 'report_cards_$cleanClassName.pdf'
                    : 'result_sheet_$cleanClassName.pdf';
                await Printing.sharePdf(
                  bytes: _pdfBytes!,
                  filename: filename,
                );
              }
            },
            tooltip: AppLocalizations.of(context)!.share,
          ),
        ],
      ),
      body: Column(
        children: [
          _buildModeSelector(),
          if (_showFilters) _buildFilters(uniqueClasses, uniqueSections),
          Expanded(
            child: _isLoading || _pdfBytes == null
                ? const Center(child: CircularProgressIndicator())
                : _currentStudents.isEmpty
                ? Center(
                    child: Text(AppLocalizations.of(context)!.noStudentsForReportCards),
                  )
                : pdfx.PdfViewPinch(controller: _pdfController!),
          ),
        ],
      ),
    );
  }

  Widget _buildModeSelector() {
    return Container(
      width: double.infinity,
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: SegmentedButton<ReportCardViewMode>(
        segments: const [
          ButtonSegment(
            value: ReportCardViewMode.studentWise,
            label: Text('Student Report Cards'),
            icon: Icon(Icons.badge_outlined),
          ),
          ButtonSegment(
            value: ReportCardViewMode.classResultSheet,
            label: Text('Class Result Sheet'),
            icon: Icon(Icons.table_chart_outlined),
          ),
        ],
        selected: {_viewMode},
        onSelectionChanged: (newSelection) {
          if (newSelection.first != _viewMode) {
            setState(() {
              _viewMode = newSelection.first;
            });
            _generatePdf();
          }
        },
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
        schoolLogo = await PdfImageHelper.getCachedImageProvider(schoolLogoUrl);
      } catch (e) {
        // Fallback if image fails to load
      }
    }

    final allResults = [...widget.exam.results, ..._fetchedResults];

    bool matchesStudent(Result r, Student student) {
      if (r.studentId.isNotEmpty) {
        if (r.studentId == student.userId) return true;
        if (student.user != null && r.studentId == student.user!.id) {
          return true;
        }
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

    // ── Collect all strings that might contain Bengali ──────────────────────
    final allBengaliStrings = <String>{
      schoolName,
      schoolAddress,
      widget.exam.name,
    };

    for (var student in _currentStudents) {
      allBengaliStrings.add(student.user?.name ?? '');
      allBengaliStrings.add(student.rollId);

      final className = _resolveClassName(
        student, _selectedClassId, allClasses, widget.exam.assignments,
      );
      final sectionName = _resolveSectionName(
        student, _selectedSectionId, allSections, widget.exam.assignments,
      );
      allBengaliStrings.add(className);
      allBengaliStrings.add(sectionName);
      allBengaliStrings.add('$className - $sectionName');

      final results = allResults
          .where((r) => matchesStudent(r, student))
          .toList();
      for (var r in results) {
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
            subjectName =
                allSubjects.firstWhere((s) => s.id == r.subjectId).name;
          } catch (_) {}
        }
        allBengaliStrings.add(subjectName);
        if (r.remarks.isNotEmpty) allBengaliStrings.add(r.remarks);
      }
    }
    allBengaliStrings.removeWhere((s) => s.trim().isEmpty);

    // ── Pre-render all Bengali strings in parallel ───────────────────────────
    final rendered = await BanglaTextRenderer.preRenderBatch(
      allBengaliStrings,
      fontSize: 9,
      maxWidth: 400,
    );

    // ── Build PDF pages ──────────────────────────────────────────────────────
    for (var student in _currentStudents) {
      final studentResults = allResults
          .where((r) => matchesStudent(r, student))
          .toList();

      if (studentResults.isEmpty) continue;

      pdf.addPage(
        pw.Page(
          pageFormat: format,
          margin: const pw.EdgeInsets.all(20),
          build: (pw.Context pwContext) {
            return _buildReportCardSinglePage(
              pwContext: pwContext,
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
              rendered: rendered,
            );
          },
        ),
      );
    }

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

  Future<Uint8List> _generateClassResultSheetPdf(
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
        schoolLogo = await PdfImageHelper.getCachedImageProvider(schoolLogoUrl);
      } catch (e) {
        // Fallback if image fails to load
      }
    }

    final allResults = [...widget.exam.results, ..._fetchedResults];

    bool matchesStudent(Result r, Student student) {
      if (r.studentId.isNotEmpty) {
        if (r.studentId == student.userId) return true;
        if (student.user != null && r.studentId == student.user!.id) {
          return true;
        }
        if (r.studentId == student.rollId) return true;
      }
      return false;
    }

    // 1. Sort students by Roll Number
    final sortedStudents = List<Student>.from(_currentStudents)
      ..sort((a, b) {
        final rA = int.tryParse(a.rollId.trim());
        final rB = int.tryParse(b.rollId.trim());
        if (rA != null && rB != null) return rA.compareTo(rB);
        if (rA != null) return -1;
        if (rB != null) return 1;
        return (a.user?.name ?? '').compareTo(b.user?.name ?? '');
      });

    if (sortedStudents.isEmpty) {
      pdf.addPage(
        pw.Page(
          pageFormat: format,
          margin: const pw.EdgeInsets.all(20),
          build: (context) => pw.Center(
            child: pw.Text(
              'No student records found for the selected class/section.',
              style: pw.TextStyle(
                fontSize: 14,
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.grey700,
              ),
            ),
          ),
        ),
      );
      return pdf.save();
    }

    // 2. Resolve Class and Section name
    String resolvedClassName = 'All Classes';
    if (_selectedClassId != null) {
      try {
        resolvedClassName = widget.exam.assignments
            .firstWhere((a) => a.classId == _selectedClassId)
            .className;
      } catch (_) {
        try {
          resolvedClassName =
              allClasses.firstWhere((c) => c.id == _selectedClassId).name;
        } catch (_) {}
      }
    } else if (sortedStudents.isNotEmpty) {
      resolvedClassName = _resolveClassName(
        sortedStudents.first,
        _selectedClassId,
        allClasses,
        widget.exam.assignments,
      );
    }

    String resolvedSectionName = 'All Sections';
    if (_selectedSectionId != null) {
      try {
        resolvedSectionName =
            allSections.firstWhere((s) => s.id == _selectedSectionId).name;
      } catch (_) {
        try {
          resolvedSectionName = widget.exam.assignments
                  .firstWhere((a) => a.sectionId == _selectedSectionId)
                  .sectionName ??
              'All Sections';
        } catch (_) {}
      }
    } else if (sortedStudents.isNotEmpty &&
        sortedStudents.first.sectionName != null &&
        sortedStudents.first.sectionName!.isNotEmpty) {
      resolvedSectionName = sortedStudents.first.sectionName!;
    }

    // 3. Determine unique subjects for this class and exam
    final subjectsMap = <String, _ResultSheetSubject>{};

    for (var a in widget.exam.assignments) {
      final matchesClass =
          _selectedClassId == null || a.classId == _selectedClassId;
      final matchesSection = _selectedSectionId == null ||
          a.sectionId == null ||
          a.sectionId!.isEmpty ||
          a.sectionId == _selectedSectionId;
      if (matchesClass && matchesSection && a.subjectId.isNotEmpty) {
        if (!subjectsMap.containsKey(a.subjectId)) {
          String sName = a.subjectName.isNotEmpty ? a.subjectName : '';
          if (sName.isEmpty) {
            try {
              sName = allSubjects.firstWhere((s) => s.id == a.subjectId).name;
            } catch (_) {
              sName = 'Subject';
            }
          }
          subjectsMap[a.subjectId] = _ResultSheetSubject(
            id: a.subjectId,
            name: sName,
          );
        }
      }
    }

    for (var student in sortedStudents) {
      final sResults = allResults.where((r) => matchesStudent(r, student));
      for (var r in sResults) {
        final sId = r.subjectId ?? r.subject?.id ?? '';
        if (sId.isNotEmpty && !subjectsMap.containsKey(sId)) {
          String sName = r.subject?.name ?? '';
          if (sName.isEmpty) {
            try {
              sName = widget.exam.assignments
                  .firstWhere((a) => a.subjectId == sId)
                  .subjectName;
            } catch (_) {}
          }
          if (sName.isEmpty) {
            try {
              sName = allSubjects.firstWhere((s) => s.id == sId).name;
            } catch (_) {
              sName = 'Subject';
            }
          }
          subjectsMap[sId] = _ResultSheetSubject(
            id: sId,
            name: sName,
            maxMarks: r.totalMarks > 0 ? r.totalMarks : 100.0,
          );
        }
      }
    }

    final sheetSubjects = subjectsMap.values.toList();

    // 4. Calculate student marks, totals, and ranks
    final studentTotals = <String, double>{};
    final studentMaxTotals = <String, double>{};
    final studentSubjectResults = <String, Map<String, Result>>{};

    for (var student in sortedStudents) {
      double obtained = 0;
      double maxPossible = 0;
      final sMap = <String, Result>{};

      final sResults =
          allResults.where((r) => matchesStudent(r, student)).toList();
      for (var r in sResults) {
        final sId = r.subjectId ?? r.subject?.id ?? '';
        if (sId.isNotEmpty) {
          sMap[sId] = r;
        }
        obtained += r.marksObtained;
        maxPossible += (r.totalMarks > 0 ? r.totalMarks : 100.0);
      }

      if (maxPossible == 0) {
        maxPossible = sheetSubjects.fold(
          0.0,
          (sum, s) => sum + s.maxMarks,
        );
        if (maxPossible == 0) maxPossible = 100.0;
      }

      studentTotals[student.userId] = obtained;
      studentMaxTotals[student.userId] = maxPossible;
      studentSubjectResults[student.userId] = sMap;
    }

    // Rank by total marks descending
    final sortedStudentIdsForRank = sortedStudents.map((s) => s.userId).toList()
      ..sort((a, b) =>
          (studentTotals[b] ?? 0).compareTo(studentTotals[a] ?? 0));

    final studentRanks = <String, int>{};
    int curRank = 1;
    for (int i = 0; i < sortedStudentIdsForRank.length; i++) {
      if (i > 0 &&
          (studentTotals[sortedStudentIdsForRank[i]] ?? 0) <
              (studentTotals[sortedStudentIdsForRank[i - 1]] ?? 0)) {
        curRank = i + 1;
      }
      studentRanks[sortedStudentIdsForRank[i]] = curRank;
    }

    // 5. Pre-render all potential Bengali text
    final allBengaliStrings = <String>{
      schoolName,
      schoolAddress,
      widget.exam.name,
      resolvedClassName,
      resolvedSectionName,
    };

    for (var s in sheetSubjects) {
      allBengaliStrings.add(s.name);
    }

    for (var student in sortedStudents) {
      allBengaliStrings.add(student.user?.name ?? '');
      allBengaliStrings.add(student.rollId);
    }
    allBengaliStrings.removeWhere((s) => s.trim().isEmpty);

    final rendered = await BanglaTextRenderer.preRenderBatch(
      allBengaliStrings,
      fontSize: 8,
      maxWidth: 300,
    );

    // Pre-render white text for table header subjects if Bengali
    final headerSubjectRendered = <String, Uint8List?>{};
    for (var s in sheetSubjects) {
      if (BanglaTextRenderer.hasBengali(s.name)) {
        headerSubjectRendered[s.name] =
            await BanglaTextRenderer.renderToImageBytes(
          s.name,
          fontSize: 7.5,
          bold: true,
          color: Colors.white,
          maxWidth: 160,
        );
      }
    }

    // 6. Calculate statistics
    int passedCount = 0;
    int failedCount = 0;
    double highestTotal = 0;
    double sumAllTotals = 0;

    for (var student in sortedStudents) {
      final total = studentTotals[student.userId] ?? 0;
      final max = studentMaxTotals[student.userId] ?? 100;
      final pct = max > 0 ? (total / max) * 100 : 0.0;
      final grade = _calculateGrade(pct);

      if (total > highestTotal) highestTotal = total;
      sumAllTotals += total;

      final sResults = studentSubjectResults[student.userId] ?? {};
      bool hasSubjectFail = false;
      for (var r in sResults.values) {
        final subPct =
            r.totalMarks > 0 ? (r.marksObtained / r.totalMarks) * 100 : 0.0;
        if (subPct < 33.0) {
          hasSubjectFail = true;
          break;
        }
      }

      if (grade != 'F' && !hasSubjectFail && sResults.isNotEmpty) {
        passedCount++;
      } else {
        failedCount++;
      }
    }

    final double classAvgTotal = sortedStudents.isNotEmpty
        ? sumAllTotals / sortedStudents.length
        : 0.0;
    final double passRate = sortedStudents.isNotEmpty
        ? (passedCount / sortedStudents.length) * 100
        : 0.0;

    // Subject averages
    final subjectAverages = <String, double>{};
    for (var s in sheetSubjects) {
      double sumSub = 0;
      int countSub = 0;
      for (var student in sortedStudents) {
        final r = studentSubjectResults[student.userId]?[s.id];
        if (r != null) {
          sumSub += r.marksObtained;
          countSub++;
        }
      }
      subjectAverages[s.id] = countSub > 0 ? (sumSub / countSub) : 0.0;
    }

    // 7. Add MultiPage document
    pdf.addPage(
      pw.MultiPage(
        pageFormat: format,
        margin: const pw.EdgeInsets.symmetric(horizontal: 24, vertical: 20),
        header: (pw.Context pwContext) {
          return _buildResultSheetHeader(
            schoolName: schoolName,
            schoolAddress: schoolAddress,
            schoolPhone: schoolPhone,
            schoolEmail: schoolEmail,
            schoolLogo: schoolLogo,
            examName: widget.exam.name,
            className: resolvedClassName,
            sectionName: resolvedSectionName,
            totalStudents: sortedStudents.length,
            rendered: rendered,
            pageNumber: pwContext.pageNumber,
            totalPages: pwContext.pagesCount,
          );
        },
        footer: (pw.Context pwContext) {
          return pw.Container(
            margin: const pw.EdgeInsets.only(top: 8),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text(
                  'Generated by Smart School - ${DateTime.now().day}/${DateTime.now().month}/${DateTime.now().year}',
                  style: const pw.TextStyle(
                    fontSize: 7,
                    color: PdfColors.grey600,
                  ),
                ),
                pw.Text(
                  'Page ${pwContext.pageNumber} of ${pwContext.pagesCount}',
                  style: pw.TextStyle(
                    fontSize: 7,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.grey700,
                  ),
                ),
              ],
            ),
          );
        },
        build: (pw.Context pwContext) {
          return [
            _buildTabulationTable(
              sortedStudents: sortedStudents,
              sheetSubjects: sheetSubjects,
              studentTotals: studentTotals,
              studentMaxTotals: studentMaxTotals,
              studentRanks: studentRanks,
              studentSubjectResults: studentSubjectResults,
              subjectAverages: subjectAverages,
              classAvgTotal: classAvgTotal,
              rendered: rendered,
              headerSubjectRendered: headerSubjectRendered,
            ),
            pw.SizedBox(height: 12),
            _buildClassStatisticsCard(
              totalStudents: sortedStudents.length,
              passedCount: passedCount,
              failedCount: failedCount,
              passRate: passRate,
              highestTotal: highestTotal,
              classAvgTotal: classAvgTotal,
            ),
            pw.SizedBox(height: 24),
            _buildResultSheetSignatures(),
          ];
        },
      ),
    );

    return pdf.save();
  }

  pw.Widget _buildResultSheetHeader({
    required String schoolName,
    required String schoolAddress,
    required String schoolPhone,
    required String schoolEmail,
    required pw.ImageProvider? schoolLogo,
    required String examName,
    required String className,
    required String sectionName,
    required int totalStudents,
    required Map<String, Uint8List?> rendered,
    required int pageNumber,
    required int totalPages,
  }) {
    final primaryColor = PdfColor.fromHex('#1E1B4B');
    final accentColor = PdfColor.fromHex('#4338CA');
    final borderTint = PdfColor.fromHex('#E2E8F0');
    final bgTint = PdfColor.fromHex('#F8FAFC');

    if (pageNumber > 1) {
      return pw.Container(
        margin: const pw.EdgeInsets.only(bottom: 8),
        padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: pw.BoxDecoration(
          color: bgTint,
          border: pw.Border.all(color: borderTint, width: 0.8),
          borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
        ),
        child: pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Row(
              children: [
                BanglaTextRenderer.fromBytes(
                  rendered[schoolName],
                  schoolName.toUpperCase(),
                  fontSize: 9.5,
                  bold: true,
                  color: primaryColor,
                ),
                pw.Text('  |  ',
                    style: const pw.TextStyle(
                        fontSize: 9, color: PdfColors.grey500)),
                pw.Text(
                  '$examName - TABULATION SHEET (Contd.)',
                  style: pw.TextStyle(
                    fontSize: 8.5,
                    fontWeight: pw.FontWeight.bold,
                    color: accentColor,
                  ),
                ),
              ],
            ),
            pw.Text(
              'Class: $className | Section: $sectionName',
              style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey700),
            ),
          ],
        ),
      );
    }

    return pw.Container(
      margin: const pw.EdgeInsets.only(bottom: 10),
      child: pw.Column(
        children: [
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
                  height: 42,
                  width: 42,
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
                        fontSize: 18,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              pw.Expanded(
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    BanglaTextRenderer.fromBytes(
                      rendered[schoolName],
                      schoolName.toUpperCase(),
                      fontSize: 15,
                      bold: true,
                      color: primaryColor,
                    ),
                    pw.SizedBox(height: 2),
                    if (schoolAddress.isNotEmpty)
                      BanglaTextRenderer.fromBytes(
                        rendered[schoolAddress],
                        schoolAddress,
                        fontSize: 7.5,
                        color: PdfColors.grey700,
                      ),
                    if (schoolPhone.isNotEmpty || schoolEmail.isNotEmpty)
                      pw.Text(
                        [
                          if (schoolPhone.isNotEmpty) 'Phone: $schoolPhone',
                          if (schoolEmail.isNotEmpty) 'Email: $schoolEmail',
                        ].join(' | '),
                        style: const pw.TextStyle(
                          fontSize: 7.5,
                          color: PdfColors.grey600,
                        ),
                      ),
                  ],
                ),
              ),
              pw.Container(
                padding:
                    const pw.EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: pw.BoxDecoration(
                  color: bgTint,
                  border: pw.Border.all(color: borderTint),
                  borderRadius:
                      const pw.BorderRadius.all(pw.Radius.circular(6)),
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                  children: [
                    pw.Text(
                      'CLASS RESULT SHEET',
                      style: pw.TextStyle(
                        fontSize: 8.5,
                        fontWeight: pw.FontWeight.bold,
                        color: primaryColor,
                      ),
                    ),
                    pw.Text(
                      'TABULATION MARKSHEET',
                      style: const pw.TextStyle(
                        fontSize: 6.5,
                        color: PdfColors.grey600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          pw.SizedBox(height: 8),
          pw.Container(
            padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: pw.BoxDecoration(
              color: bgTint,
              border: pw.Border.all(color: borderTint),
              borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
            ),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Row(
                  children: [
                    pw.Text(
                      'EXAM: ',
                      style: pw.TextStyle(
                        color: PdfColors.grey700,
                        fontSize: 8,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                    BanglaTextRenderer.fromBytes(
                      rendered[examName],
                      examName,
                      fontSize: 8,
                      bold: true,
                      color: primaryColor,
                    ),
                  ],
                ),
                pw.Row(
                  children: [
                    pw.Text(
                      'CLASS: ',
                      style: pw.TextStyle(
                        color: PdfColors.grey700,
                        fontSize: 8,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                    BanglaTextRenderer.fromBytes(
                      rendered[className],
                      className,
                      fontSize: 8,
                      bold: true,
                      color: primaryColor,
                    ),
                  ],
                ),
                pw.Row(
                  children: [
                    pw.Text(
                      'SECTION: ',
                      style: pw.TextStyle(
                        color: PdfColors.grey700,
                        fontSize: 8,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                    BanglaTextRenderer.fromBytes(
                      rendered[sectionName],
                      sectionName,
                      fontSize: 8,
                      bold: true,
                      color: primaryColor,
                    ),
                  ],
                ),
                pw.Text(
                  'TOTAL STUDENTS: $totalStudents',
                  style: pw.TextStyle(
                    color: primaryColor,
                    fontSize: 8,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  pw.Widget _buildTabulationTable({
    required List<Student> sortedStudents,
    required List<_ResultSheetSubject> sheetSubjects,
    required Map<String, double> studentTotals,
    required Map<String, double> studentMaxTotals,
    required Map<String, int> studentRanks,
    required Map<String, Map<String, Result>> studentSubjectResults,
    required Map<String, double> subjectAverages,
    required double classAvgTotal,
    required Map<String, Uint8List?> rendered,
    required Map<String, Uint8List?> headerSubjectRendered,
  }) {
    final primaryColor = PdfColor.fromHex('#1E1B4B');
    final borderColor = PdfColor.fromHex('#CBD5E1');

    final columnWidths = <int, pw.TableColumnWidth>{
      0: const pw.FixedColumnWidth(34), // Roll
      1: const pw.FlexColumnWidth(2.6), // Name
    };
    int colIdx = 2;
    for (int i = 0; i < sheetSubjects.length; i++) {
      columnWidths[colIdx++] = const pw.FlexColumnWidth(1.2);
    }
    columnWidths[colIdx++] = const pw.FixedColumnWidth(44); // Total
    columnWidths[colIdx++] = const pw.FixedColumnWidth(38); // %
    columnWidths[colIdx++] = const pw.FixedColumnWidth(32); // Grade
    columnWidths[colIdx++] = const pw.FixedColumnWidth(32); // Rank
    columnWidths[colIdx++] = const pw.FixedColumnWidth(42); // Status

    return pw.Table(
      border: pw.TableBorder.all(color: borderColor, width: 0.5),
      columnWidths: columnWidths,
      children: [
        // ── Header Row ────────────────────────────────────────────────────────
        pw.TableRow(
          repeat: true,
          decoration: pw.BoxDecoration(color: primaryColor),
          children: [
            _buildTableHeaderCell('ROLL'),
            _buildTableHeaderCell('STUDENT NAME', align: pw.TextAlign.left),
            ...sheetSubjects.map((s) {
              return pw.Container(
                padding:
                    const pw.EdgeInsets.symmetric(horizontal: 2, vertical: 4),
                child: pw.Column(
                  mainAxisSize: pw.MainAxisSize.min,
                  children: [
                    BanglaTextRenderer.fromBytes(
                      headerSubjectRendered[s.name],
                      s.name,
                      fontSize: 7.5,
                      bold: true,
                      color: PdfColors.white,
                      textAlign: pw.TextAlign.center,
                    ),
                    pw.SizedBox(height: 1),
                    pw.Text(
                      '(${s.maxMarks.toStringAsFixed(0)})',
                      style: pw.TextStyle(
                        fontSize: 6,
                        color: PdfColor.fromHex('#CBD5E1'),
                      ),
                      textAlign: pw.TextAlign.center,
                    ),
                  ],
                ),
              );
            }),
            _buildTableHeaderCell('TOTAL'),
            _buildTableHeaderCell('%'),
            _buildTableHeaderCell('GRADE'),
            _buildTableHeaderCell('RANK'),
            _buildTableHeaderCell('STATUS'),
          ],
        ),

        // ── Student Rows ──────────────────────────────────────────────────────
        ...sortedStudents.asMap().entries.map((entry) {
          final idx = entry.key;
          final student = entry.value;
          final bg = idx.isEven ? PdfColors.white : PdfColor.fromHex('#F8FAFC');

          final total = studentTotals[student.userId] ?? 0;
          final max = studentMaxTotals[student.userId] ?? 100;
          final pct = max > 0 ? (total / max) * 100 : 0.0;
          final grade = _calculateGrade(pct);
          final rank = studentRanks[student.userId] ?? 0;

          final sResults = studentSubjectResults[student.userId] ?? {};
          bool hasSubjectFail = false;
          for (var r in sResults.values) {
            final subPct = r.totalMarks > 0
                ? (r.marksObtained / r.totalMarks) * 100
                : 0.0;
            if (subPct < 33.0) {
              hasSubjectFail = true;
              break;
            }
          }

          final isAbsent = sResults.isEmpty;
          final isPassed = grade != 'F' && !hasSubjectFail && !isAbsent;
          final statusText = isAbsent ? 'ABSENT' : (isPassed ? 'PASS' : 'FAIL');
          final statusColor = isAbsent
              ? PdfColors.grey600
              : (isPassed
                  ? PdfColor.fromHex('#15803D')
                  : PdfColor.fromHex('#DC2626'));

          return pw.TableRow(
            decoration: pw.BoxDecoration(color: bg),
            children: [
              // Roll
              pw.Container(
                padding:
                    const pw.EdgeInsets.symmetric(horizontal: 2, vertical: 3.5),
                alignment: pw.Alignment.center,
                child: BanglaTextRenderer.fromBytes(
                  rendered[student.rollId],
                  student.rollId.isNotEmpty ? student.rollId : '-',
                  fontSize: 7.5,
                  bold: true,
                  textAlign: pw.TextAlign.center,
                ),
              ),

              // Name
              pw.Container(
                padding:
                    const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 3.5),
                alignment: pw.Alignment.centerLeft,
                child: BanglaTextRenderer.fromBytes(
                  rendered[student.user?.name ?? ''],
                  student.user?.name ?? 'N/A',
                  fontSize: 7.5,
                  bold: true,
                  textAlign: pw.TextAlign.left,
                ),
              ),

              // Subject Columns
              ...sheetSubjects.map((s) {
                final r = sResults[s.id];
                if (r == null) {
                  return pw.Container(
                    padding: const pw.EdgeInsets.symmetric(
                        horizontal: 2, vertical: 3.5),
                    alignment: pw.Alignment.center,
                    child: pw.Text(
                      '-',
                      style: const pw.TextStyle(
                        fontSize: 7.5,
                        color: PdfColors.grey500,
                      ),
                      textAlign: pw.TextAlign.center,
                    ),
                  );
                }

                final marks = r.marksObtained;
                final marksStr = marks % 1 == 0
                    ? marks.toInt().toString()
                    : marks.toStringAsFixed(1);
                final isFail =
                    r.totalMarks > 0 && (marks / r.totalMarks) < 0.33;

                return pw.Container(
                  padding: const pw.EdgeInsets.symmetric(
                      horizontal: 2, vertical: 3.5),
                  alignment: pw.Alignment.center,
                  child: pw.Text(
                    marksStr,
                    style: pw.TextStyle(
                      fontSize: 7.5,
                      fontWeight:
                          isFail ? pw.FontWeight.bold : pw.FontWeight.normal,
                      color: isFail
                          ? PdfColor.fromHex('#DC2626')
                          : PdfColor.fromHex('#1E293B'),
                    ),
                    textAlign: pw.TextAlign.center,
                  ),
                );
              }),

              // Total
              pw.Container(
                padding:
                    const pw.EdgeInsets.symmetric(horizontal: 2, vertical: 3.5),
                alignment: pw.Alignment.center,
                child: pw.Text(
                  total % 1 == 0
                      ? total.toInt().toString()
                      : total.toStringAsFixed(1),
                  style: pw.TextStyle(
                    fontSize: 7.5,
                    fontWeight: pw.FontWeight.bold,
                    color: primaryColor,
                  ),
                  textAlign: pw.TextAlign.center,
                ),
              ),

              // Percentage
              pw.Container(
                padding:
                    const pw.EdgeInsets.symmetric(horizontal: 2, vertical: 3.5),
                alignment: pw.Alignment.center,
                child: pw.Text(
                  '${pct.toStringAsFixed(1)}%',
                  style: const pw.TextStyle(fontSize: 7.5),
                  textAlign: pw.TextAlign.center,
                ),
              ),

              // Grade
              pw.Container(
                padding:
                    const pw.EdgeInsets.symmetric(horizontal: 2, vertical: 3.5),
                alignment: pw.Alignment.center,
                child: pw.Text(
                  grade,
                  style: pw.TextStyle(
                    fontSize: 7.5,
                    fontWeight: pw.FontWeight.bold,
                    color: grade == 'F'
                        ? PdfColor.fromHex('#DC2626')
                        : primaryColor,
                  ),
                  textAlign: pw.TextAlign.center,
                ),
              ),

              // Rank
              pw.Container(
                padding:
                    const pw.EdgeInsets.symmetric(horizontal: 2, vertical: 3.5),
                alignment: pw.Alignment.center,
                child: pw.Text(
                  _getOrdinal(rank),
                  style: pw.TextStyle(
                    fontSize: 7.5,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColor.fromHex('#B45309'),
                  ),
                  textAlign: pw.TextAlign.center,
                ),
              ),

              // Status
              pw.Container(
                padding:
                    const pw.EdgeInsets.symmetric(horizontal: 2, vertical: 3.5),
                alignment: pw.Alignment.center,
                child: pw.Text(
                  statusText,
                  style: pw.TextStyle(
                    fontSize: 7,
                    fontWeight: pw.FontWeight.bold,
                    color: statusColor,
                  ),
                  textAlign: pw.TextAlign.center,
                ),
              ),
            ],
          );
        }),

        // ── Class Average Row ─────────────────────────────────────────────────
        pw.TableRow(
          decoration: pw.BoxDecoration(color: PdfColor.fromHex('#EEF2F6')),
          children: [
            pw.Container(
              padding:
                  const pw.EdgeInsets.symmetric(horizontal: 2, vertical: 4),
              alignment: pw.Alignment.center,
              child: pw.Text(''),
            ),
            pw.Container(
              padding:
                  const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 4),
              alignment: pw.Alignment.centerLeft,
              child: pw.Text(
                'CLASS AVERAGE',
                style: pw.TextStyle(
                  fontSize: 7.5,
                  fontWeight: pw.FontWeight.bold,
                  color: primaryColor,
                ),
              ),
            ),
            ...sheetSubjects.map((s) {
              final avg = subjectAverages[s.id] ?? 0.0;
              return pw.Container(
                padding:
                    const pw.EdgeInsets.symmetric(horizontal: 2, vertical: 4),
                alignment: pw.Alignment.center,
                child: pw.Text(
                  avg > 0 ? avg.toStringAsFixed(1) : '-',
                  style: pw.TextStyle(
                    fontSize: 7.5,
                    fontWeight: pw.FontWeight.bold,
                    color: primaryColor,
                  ),
                  textAlign: pw.TextAlign.center,
                ),
              );
            }),
            // Total Average
            pw.Container(
              padding:
                  const pw.EdgeInsets.symmetric(horizontal: 2, vertical: 4),
              alignment: pw.Alignment.center,
              child: pw.Text(
                classAvgTotal.toStringAsFixed(1),
                style: pw.TextStyle(
                  fontSize: 7.5,
                  fontWeight: pw.FontWeight.bold,
                  color: primaryColor,
                ),
                textAlign: pw.TextAlign.center,
              ),
            ),
            // Perc Average
            pw.Container(
              padding:
                  const pw.EdgeInsets.symmetric(horizontal: 2, vertical: 4),
              alignment: pw.Alignment.center,
              child: pw.Text(
                '-',
                style:
                    const pw.TextStyle(fontSize: 7.5, color: PdfColors.grey600),
                textAlign: pw.TextAlign.center,
              ),
            ),
            // Grade
            pw.Container(
              padding:
                  const pw.EdgeInsets.symmetric(horizontal: 2, vertical: 4),
              alignment: pw.Alignment.center,
              child: pw.Text('-',
                  style: const pw.TextStyle(
                      fontSize: 7.5, color: PdfColors.grey600)),
            ),
            // Rank
            pw.Container(
              padding:
                  const pw.EdgeInsets.symmetric(horizontal: 2, vertical: 4),
              alignment: pw.Alignment.center,
              child: pw.Text('-',
                  style: const pw.TextStyle(
                      fontSize: 7.5, color: PdfColors.grey600)),
            ),
            // Status
            pw.Container(
              padding:
                  const pw.EdgeInsets.symmetric(horizontal: 2, vertical: 4),
              alignment: pw.Alignment.center,
              child: pw.Text('-',
                  style: const pw.TextStyle(
                      fontSize: 7.5, color: PdfColors.grey600)),
            ),
          ],
        ),
      ],
    );
  }

  pw.Widget _buildTableHeaderCell(
    String title, {
    pw.TextAlign align = pw.TextAlign.center,
  }) {
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(horizontal: 3, vertical: 5),
      alignment: align == pw.TextAlign.left
          ? pw.Alignment.centerLeft
          : pw.Alignment.center,
      child: pw.Text(
        title,
        style: pw.TextStyle(
          color: PdfColors.white,
          fontWeight: pw.FontWeight.bold,
          fontSize: 7.5,
        ),
        textAlign: align,
      ),
    );
  }

  pw.Widget _buildClassStatisticsCard({
    required int totalStudents,
    required int passedCount,
    required int failedCount,
    required double passRate,
    required double highestTotal,
    required double classAvgTotal,
  }) {
    final primaryColor = PdfColor.fromHex('#1E1B4B');
    final borderColor = PdfColor.fromHex('#CBD5E1');

    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: pw.BoxDecoration(
        color: PdfColor.fromHex('#F8FAFC'),
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
        border: pw.Border.all(color: borderColor, width: 0.8),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
        children: [
          _buildStatItem('TOTAL STUDENTS', '$totalStudents', primaryColor),
          _buildStatDivider(),
          _buildStatItem(
            'PASSED',
            '$passedCount (${passRate.toStringAsFixed(1)}%)',
            PdfColor.fromHex('#15803D'),
          ),
          _buildStatDivider(),
          _buildStatItem('FAILED', '$failedCount', PdfColor.fromHex('#DC2626')),
          _buildStatDivider(),
          _buildStatItem(
            'HIGHEST SCORE',
            highestTotal % 1 == 0
                ? highestTotal.toInt().toString()
                : highestTotal.toStringAsFixed(1),
            PdfColor.fromHex('#B45309'),
          ),
          _buildStatDivider(),
          _buildStatItem(
            'CLASS AVERAGE',
            classAvgTotal.toStringAsFixed(1),
            primaryColor,
          ),
        ],
      ),
    );
  }

  pw.Widget _buildStatItem(String label, String value, PdfColor valueColor) {
    return pw.Column(
      mainAxisSize: pw.MainAxisSize.min,
      children: [
        pw.Text(
          label,
          style: const pw.TextStyle(
            fontSize: 6.5,
            color: PdfColors.grey600,
          ),
        ),
        pw.SizedBox(height: 2),
        pw.Text(
          value,
          style: pw.TextStyle(
            fontSize: 9.5,
            fontWeight: pw.FontWeight.bold,
            color: valueColor,
          ),
        ),
      ],
    );
  }

  pw.Widget _buildStatDivider() {
    return pw.Container(
      width: 1,
      height: 20,
      color: PdfColor.fromHex('#CBD5E1'),
    );
  }

  pw.Widget _buildResultSheetSignatures() {
    final primaryColor = PdfColor.fromHex('#1E1B4B');

    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(horizontal: 20),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          _buildSignatureColumn('Exam Controller / Prepared By', primaryColor),
          _buildSignatureColumn('Class Teacher', primaryColor),
          _buildSignatureColumn('Headmaster / Principal', primaryColor),
        ],
      ),
    );
  }

  pw.Widget _buildSignatureColumn(String title, PdfColor titleColor) {
    return pw.Column(
      mainAxisSize: pw.MainAxisSize.min,
      children: [
        pw.Container(
          width: 170,
          decoration: const pw.BoxDecoration(
            border: pw.Border(
              top: pw.BorderSide(color: PdfColors.grey500, width: 0.8),
            ),
          ),
          padding: const pw.EdgeInsets.only(top: 4),
          child: pw.Column(
            children: [
              pw.Text(
                title,
                style: pw.TextStyle(
                  fontSize: 8,
                  fontWeight: pw.FontWeight.bold,
                  color: titleColor,
                ),
                textAlign: pw.TextAlign.center,
              ),
              pw.SizedBox(height: 2),
              pw.Text(
                'Date: ........................',
                style: const pw.TextStyle(
                  fontSize: 6.5,
                  color: PdfColors.grey600,
                ),
                textAlign: pw.TextAlign.center,
              ),
            ],
          ),
        ),
      ],
    );
  }

  pw.Widget _buildReportCardSinglePage({
    required pw.Context pwContext,
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
    Map<String, Uint8List?> rendered = const {},
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
    final String className = _resolveClassName(
      student,
      _selectedClassId,
      allClasses,
      widget.exam.assignments,
    );
    final String sectionName = _resolveSectionName(
      student,
      _selectedSectionId,
      allSections,
      widget.exam.assignments,
    );

    final primaryColor = PdfColor.fromHex('#1E1B4B'); // Deep Navy
    final accentColor = PdfColor.fromHex('#4338CA'); // Indigo Accent
    final goldColor = PdfColor.fromHex('#D97706'); // Amber Gold
    final bgTint = PdfColor.fromHex('#F8FAFC'); // Slate Tint
    final borderTint = PdfColor.fromHex('#E2E8F0'); // Subtle Border

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
                    BanglaTextRenderer.fromBytes(
                      rendered[schoolName],
                      schoolName.toUpperCase(),
                      fontSize: 15,
                      bold: true,
                    ),
                    pw.SizedBox(height: 2),
                    if (schoolAddress.isNotEmpty)
                      BanglaTextRenderer.fromBytes(
                        rendered[schoolAddress],
                        schoolAddress,
                        fontSize: 8,
                      ),
                    if (schoolPhone.isNotEmpty || schoolEmail.isNotEmpty)
                      pw.Text(
                        [
                          if (schoolPhone.isNotEmpty) 'Phone: $schoolPhone',
                          if (schoolEmail.isNotEmpty) 'Email: $schoolEmail',
                        ].join(' | '),
                        style: pw.TextStyle(
                          fontSize: 8,
                          color: PdfColors.grey600,
                        ),
                      ),
                  ],
                ),
              ),
              pw.Container(
                padding: const pw.EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: pw.BoxDecoration(
                  color: bgTint,
                  border: pw.Border.all(color: borderTint),
                  borderRadius: const pw.BorderRadius.all(
                    pw.Radius.circular(4),
                  ),
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
                      style: pw.TextStyle(
                        fontSize: 6.5,
                        color: PdfColors.grey600,
                      ),
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
                BanglaTextRenderer.fromBytes(
                  rendered[widget.exam.name],
                  widget.exam.name.toUpperCase(),
                  fontSize: 10,
                  bold: true,
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
                      _buildProfileRow(
                        'Student Name',
                        student.user?.name ?? 'N/A',
                        isBold: true,
                        renderedValueBytes: rendered[student.user?.name ?? ''],
                      ),
                      pw.SizedBox(height: 4),
                      _buildProfileRow(
                        'Roll Number',
                        student.rollId.isNotEmpty ? student.rollId : 'N/A',
                        renderedValueBytes: rendered[student.rollId],
                      ),
                      pw.SizedBox(height: 4),
                      _buildProfileRow(
                        'Class & Sec',
                        '$className - $sectionName',
                        renderedValueBytes: rendered['$className - $sectionName'],
                      ),
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
                      _buildProfileRow(
                        'Total Subjects',
                        '${results.length} Subjects',
                      ),
                      pw.SizedBox(height: 4),
                      _buildProfileRow(
                        'Result Status',
                        percentage >= 40 ? 'PASSED' : 'NEEDS ATTENTION',
                        isBold: true,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          pw.SizedBox(height: 10),

          // 4. MARKS TABLE — uses pw.Table so Bengali subject names render correctly
          pw.Table(
            border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
            columnWidths: const {
              0: pw.FlexColumnWidth(3),
              1: pw.FlexColumnWidth(1.5),
              2: pw.FlexColumnWidth(1.5),
              3: pw.FlexColumnWidth(1.5),
              4: pw.FlexColumnWidth(1),
              5: pw.FlexColumnWidth(2),
            },
            children: [
              // Header row
              pw.TableRow(
                decoration: pw.BoxDecoration(color: primaryColor),
                children: ['SUBJECT','MAX MARKS','PASS MARKS','OBTAINED','GRADE','REMARKS'].map((h) =>
                  pw.Container(
                    padding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 5),
                    child: pw.Text(h, style: pw.TextStyle(color: PdfColors.white, fontWeight: pw.FontWeight.bold, fontSize: 8)),
                  ),
                ).toList(),
              ),
              // Data rows
              ...results.asMap().entries.map((entry) {
                final idx = entry.key;
                final r = entry.value;
                final pct = r.totalMarks > 0 ? (r.marksObtained / r.totalMarks) * 100 : 0.0;
                final grade = _calculateGrade(pct);
                final passMarks = (r.totalMarks * 0.4).toStringAsFixed(0);
                final bg = idx.isEven ? PdfColors.white : PdfColors.grey50;

                String subjectName = r.subject?.name ?? '';
                if (subjectName.isEmpty || subjectName == 'Unknown') {
                  try {
                    subjectName = widget.exam.assignments.firstWhere((a) => a.subjectId == r.subjectId).subjectName;
                  } catch (_) {}
                }
                if (subjectName.isEmpty || subjectName == 'Unknown') {
                  try {
                    subjectName = allSubjects.firstWhere((s) => s.id == r.subjectId).name;
                  } catch (_) {}
                }
                if (subjectName.isEmpty) subjectName = AppLocalizations.of(context)!.subjectName;

                final remarkText = r.remarks.isNotEmpty ? r.remarks : '-';

                pw.Widget cell(pw.Widget child, {bool center = false}) => pw.Container(
                  padding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 3),
                  color: bg,
                  alignment: center ? pw.Alignment.center : pw.Alignment.centerLeft,
                  child: child,
                );

                return pw.TableRow(children: [
                  cell(BanglaTextRenderer.fromBytes(rendered[subjectName], subjectName, fontSize: 8)),
                  cell(pw.Text(r.totalMarks.toStringAsFixed(0), style: const pw.TextStyle(fontSize: 8)), center: true),
                  cell(pw.Text(passMarks, style: const pw.TextStyle(fontSize: 8)), center: true),
                  cell(pw.Text(r.marksObtained.toStringAsFixed(1), style: const pw.TextStyle(fontSize: 8)), center: true),
                  cell(pw.Text(grade, style: const pw.TextStyle(fontSize: 8)), center: true),
                  cell(BanglaTextRenderer.fromBytes(rendered[remarkText], remarkText, fontSize: 8)),
                ]);
              }),
            ],
          ),

          pw.SizedBox(height: 10),

          // 5. SUMMARY STATS CARDS
          pw.Row(
            children: [
              _buildMetricCard(
                'Total Score',
                '${marksObtainedAll.toStringAsFixed(1)} / ${totalMarksAll.toStringAsFixed(0)}',
                primaryColor,
              ),
              pw.SizedBox(width: 8),
              _buildMetricCard(
                'Percentage',
                '${percentage.toStringAsFixed(2)}%',
                accentColor,
              ),
              pw.SizedBox(width: 8),
              _buildMetricCard('Overall Grade', overallGrade, goldColor),
              pw.SizedBox(width: 8),
              _buildMetricCard(
                'Class Rank',
                _getOrdinal(rank),
                rank == 1 ? goldColor : primaryColor,
              ),
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
                    borderRadius: const pw.BorderRadius.all(
                      pw.Radius.circular(4),
                    ),
                  ),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        'GRADING SCALE',
                        style: pw.TextStyle(
                          fontSize: 7.5,
                          fontWeight: pw.FontWeight.bold,
                          color: primaryColor,
                        ),
                      ),
                      pw.SizedBox(height: 4),
                      pw.Text(
                        'A+: 90-100% | A: 80-89% | B: 70-79%\nC: 60-69%   | D: 50-59% | F: <50%',
                        style: const pw.TextStyle(
                          fontSize: 7,
                          color: PdfColors.grey800,
                        ),
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
                    borderRadius: const pw.BorderRadius.all(
                      pw.Radius.circular(4),
                    ),
                  ),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        'CLASS TEACHER\'S REMARKS',
                        style: pw.TextStyle(
                          fontSize: 7.5,
                          fontWeight: pw.FontWeight.bold,
                          color: primaryColor,
                        ),
                      ),
                      pw.SizedBox(height: 4),
                      pw.Text(
                        _getTeacherComment(percentage),
                        style: pw.TextStyle(
                          fontSize: 7.5,
                          fontStyle: pw.FontStyle.italic,
                          color: PdfColors.grey800,
                        ),
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
              border: pw.Border(
                top: pw.BorderSide(color: PdfColors.grey400, width: 0.8),
              ),
            ),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Column(
                  children: [
                    pw.Container(width: 120, height: 1, color: PdfColors.black),
                    pw.SizedBox(height: 3),
                    pw.Text(
                      'Class Teacher Signature',
                      style: pw.TextStyle(
                        fontSize: 8,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                pw.Column(
                  children: [
                    pw.Container(
                      width: 100,
                      height: 1,
                      color: PdfColors.grey400,
                    ),
                    pw.SizedBox(height: 3),
                    pw.Text(
                      'Official Seal',
                      style: const pw.TextStyle(
                        fontSize: 7.5,
                        color: PdfColors.grey600,
                      ),
                    ),
                  ],
                ),
                pw.Column(
                  children: [
                    pw.Container(width: 120, height: 1, color: PdfColors.black),
                    pw.SizedBox(height: 3),
                    pw.Text(
                      'Principal Signature',
                      style: pw.TextStyle(
                        fontSize: 8,
                        fontWeight: pw.FontWeight.bold,
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

  pw.Widget _buildProfileRow(
    String label,
    String value, {
    bool isBold = false,
    Uint8List? renderedValueBytes,
  }) {
    return pw.Row(
      children: [
        pw.SizedBox(
          width: 75,
          child: pw.Text(
            '$label:',
            style: pw.TextStyle(
              fontSize: 8,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.grey700,
            ),
          ),
        ),
        pw.Expanded(
          child: BanglaTextRenderer.fromBytes(
            renderedValueBytes,
            value,
            fontSize: 8.5,
            bold: isBold,
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
              style: pw.TextStyle(
                fontSize: 6.5,
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.grey700,
              ),
            ),
            pw.SizedBox(height: 2),
            pw.Text(
              value,
              style: pw.TextStyle(
                fontSize: 11,
                fontWeight: pw.FontWeight.bold,
                color: color,
              ),
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
        return assignments
            .firstWhere((a) => a.classId == selectedClassId)
            .className;
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
      return assignments
          .firstWhere((a) => a.classId == student.classId)
          .className;
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
                .sectionName ??
            'N/A';
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
              .sectionName ??
          'N/A';
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
