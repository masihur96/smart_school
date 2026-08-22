import 'dart:typed_data';

import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:smart_school/models/school_models.dart' hide Teacher;
import 'package:smart_school/models/teacher_model.dart';

enum RoutinePdfLayout { dayByDay, weeklyGrid }

class ClassSectionRoutineGroup {
  final String className;
  final String? sectionName;
  final List<RoutineEntry> entries;

  ClassSectionRoutineGroup({
    required this.className,
    required this.sectionName,
    required this.entries,
  });
}

class ClassRoutinePdfHelper {
  static const List<String> weekDays = [
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
    'Sunday',
  ];

  /// Generates the PDF document as bytes for one or multiple class & section groups.
  static Future<Uint8List> generateRoutinePdfBytes({
    required School? school,
    required List<ClassSectionRoutineGroup> groups,
    required List<Subject> subjects,
    required List<Teacher> teachers,
    RoutinePdfLayout layout = RoutinePdfLayout.dayByDay,
    bool isAllClassesMode = false,
    String? sectionFilterName,
    String? academicYear,
  }) async {
    final pdf = pw.Document();

    final font = await PdfGoogleFonts.robotoRegular();
    final boldFont = await PdfGoogleFonts.robotoBold();
    final italicFont = await PdfGoogleFonts.robotoItalic();
    final mediumFont = await PdfGoogleFonts.robotoMedium();

    pw.Font? bengaliFont;
    pw.Font? bengaliBold;
    try {
      bengaliFont = await PdfGoogleFonts.hindSiliguriRegular();
      bengaliBold = await PdfGoogleFonts.hindSiliguriBold();
    } catch (_) {}

    final theme = pw.ThemeData.withFont(
      base: font,
      bold: boldFont,
      italic: italicFont,
      boldItalic: boldFont,
      fontFallback: [
        if (bengaliFont != null) bengaliFont,
        if (bengaliBold != null) bengaliBold,
        mediumFont,
      ],
    );

    pw.ImageProvider? schoolLogo;
    if (school?.avatar != null && school!.avatar.isNotEmpty) {
      try {
        schoolLogo = await networkImage(school.avatar);
      } catch (_) {
        schoolLogo = null;
      }
    }

    if (layout == RoutinePdfLayout.weeklyGrid) {
      if (isAllClassesMode) {
        // ── ALL CLASSES MASTER WEEKLY GRID (Unified Classes as Rows, Periods as Columns, No weekday/section)
        _buildAllClassesWeeklyGridDocument(
          pdf: pdf,
          theme: theme,
          school: school,
          schoolLogo: schoolLogo,
          groups: groups,
          subjects: subjects,
          teachers: teachers,
          academicYear: academicYear,
        );
      } else {
        // ── SINGLE CLASS WEEKLY GRID (Rows: Days, Cols: Periods)
        _buildSingleClassWeeklyGridDocument(
          pdf: pdf,
          theme: theme,
          school: school,
          schoolLogo: schoolLogo,
          groups: groups,
          subjects: subjects,
          teachers: teachers,
          academicYear: academicYear,
        );
      }
    } else {
      // ── DAY-BY-DAY DETAILED SCHEDULE
      _buildDayByDayDocument(
        pdf: pdf,
        theme: theme,
        school: school,
        schoolLogo: schoolLogo,
        groups: groups,
        subjects: subjects,
        teachers: teachers,
        academicYear: academicYear,
      );
    }

    return pdf.save();
  }

  /// Convenience method for a single class & section
  static Future<Uint8List> generateSingleRoutinePdfBytes({
    required School? school,
    required String className,
    required String? sectionName,
    required List<RoutineEntry> entries,
    required List<Subject> subjects,
    required List<Teacher> teachers,
    RoutinePdfLayout layout = RoutinePdfLayout.dayByDay,
    String? academicYear,
  }) {
    return generateRoutinePdfBytes(
      school: school,
      groups: [
        ClassSectionRoutineGroup(
          className: className,
          sectionName: sectionName,
          entries: entries,
        ),
      ],
      subjects: subjects,
      teachers: teachers,
      layout: layout,
      isAllClassesMode: false,
      academicYear: academicYear,
    );
  }

  // ───────────────────────────────────────────────────────────────────────────
  // 1. ALL CLASSES MASTER WEEKLY GRID LAYOUT (Landscape A4)
  // Unified Weekly Timetable: Rows = Classes, Columns = Periods (1st, 2nd, 3rd, 4th, 5th...)
  // Times formatted as HH:MM AM/PM (No seconds).
  // ───────────────────────────────────────────────────────────────────────────

  static void _buildAllClassesWeeklyGridDocument({
    required pw.Document pdf,
    required pw.ThemeData theme,
    required School? school,
    required pw.ImageProvider? schoolLogo,
    required List<ClassSectionRoutineGroup> groups,
    required List<Subject> subjects,
    required List<Teacher> teachers,
    String? academicYear,
  }) {
    final primaryColor = PdfColor.fromHex('#1E1B4B');
    final accentColor = PdfColor.fromHex('#4F46E5');
    final bgTint = PdfColor.fromHex('#F8FAFC');
    final borderTint = PdfColor.fromHex('#CBD5E1');

    if (groups.isEmpty) {
      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4.landscape,
          margin: const pw.EdgeInsets.all(32),
          theme: theme,
          build: (context) => pw.Center(
            child: pw.Column(
              mainAxisAlignment: pw.MainAxisAlignment.center,
              children: [
                _buildInstitutionalHeader(
                  school: school,
                  schoolLogo: schoolLogo,
                  primaryColor: primaryColor,
                  accentColor: accentColor,
                  bgTint: bgTint,
                  borderTint: borderTint,
                  isLandscape: true,
                  customSubtitle: 'WEEKLY MASTER TIMETABLE',
                ),
                pw.SizedBox(height: 40),
                pw.Text(
                  'No Routine Entries Scheduled',
                  style: pw.TextStyle(
                    fontSize: 16,
                    fontWeight: pw.FontWeight.bold,
                    color: primaryColor,
                  ),
                ),
                pw.SizedBox(height: 6),
                pw.Text(
                  'No routine entries found matching the selected classes.',
                  style: const pw.TextStyle(
                    fontSize: 11,
                    color: PdfColors.grey600,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
      return;
    }

    // Group entries by unique Class Name
    final Map<String, List<RoutineEntry>> classEntriesMap = {};
    for (final group in groups) {
      final name = group.className.trim();
      classEntriesMap.putIfAbsent(name, () => []).addAll(group.entries);
    }

    final classNames = classEntriesMap.keys.toList();

    // Extract all distinct formatted time slots across all classes, sorted chronologically
    final timeSlotSet = <String>{};
    for (final entries in classEntriesMap.values) {
      for (final e in entries) {
        if (e.startTime.isNotEmpty && e.endTime.isNotEmpty) {
          final slotStr = formatSlotDisplay(e.startTime, e.endTime);
          if (slotStr.isNotEmpty) {
            timeSlotSet.add(slotStr);
          }
        }
      }
    }

    final sortedTimeSlots = timeSlotSet.toList()
      ..sort((a, b) {
        final startA = a.split('-').first.trim();
        final startB = b.split('-').first.trim();
        return _parseTimeToMinutes(
          startA,
        ).compareTo(_parseTimeToMinutes(startB));
      });

    // Split classes into chunks of 8 per page to maintain optimal spacing
    const int chunkSize = 8;
    final int totalChunks = (classNames.length / chunkSize).ceil().clamp(
      1,
      999,
    );

    for (int chunkIndex = 0; chunkIndex < totalChunks; chunkIndex++) {
      final startIdx = chunkIndex * chunkSize;
      final endIdx = (startIdx + chunkSize).clamp(0, classNames.length);
      final currentChunkClasses = classNames.sublist(startIdx, endIdx);

      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4.landscape,
          margin: const pw.EdgeInsets.symmetric(horizontal: 22, vertical: 18),
          theme: theme,
          build: (pw.Context context) {
            return pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.stretch,
              children: [
                // 1. Institution Header
                _buildInstitutionalHeader(
                  school: school,
                  schoolLogo: schoolLogo,
                  primaryColor: primaryColor,
                  accentColor: accentColor,
                  bgTint: bgTint,
                  borderTint: borderTint,
                  isLandscape: true,
                  customSubtitle: 'WEEKLY MASTER TIMETABLE',
                ),
                pw.SizedBox(height: 6),

                // 2. Clean Master Metadata Banner
                _buildMasterTimetableBanner(
                  totalClassesCount: classNames.length,
                  periodsCount: sortedTimeSlots.length,
                  academicYear: academicYear,
                  pageChunkInfo: totalChunks > 1
                      ? 'Part ${chunkIndex + 1} of $totalChunks'
                      : null,
                  primaryColor: primaryColor,
                  accentColor: accentColor,
                  bgTint: bgTint,
                  borderTint: borderTint,
                ),
                pw.SizedBox(height: 8),

                // 3. The Master All-Class Matrix Grid Table
                if (sortedTimeSlots.isEmpty)
                  pw.Expanded(
                    child: pw.Center(
                      child: pw.Text(
                        'No periods scheduled for the selected classes.',
                        style: pw.TextStyle(
                          fontSize: 13,
                          fontWeight: pw.FontWeight.bold,
                          color: primaryColor,
                        ),
                      ),
                    ),
                  )
                else
                  pw.Expanded(
                    child: pw.Table(
                      border: pw.TableBorder.all(color: borderTint, width: 0.8),
                      columnWidths: {
                        0: const pw.FlexColumnWidth(2.0), // Class column
                        for (int i = 0; i < sortedTimeSlots.length; i++)
                          (i + 1): const pw.FlexColumnWidth(2.6),
                      },
                      children: [
                        // ── HEADER ROW: CLASS / 1ST PERIOD / 2ND PERIOD / 3RD PERIOD...
                        pw.TableRow(
                          decoration: pw.BoxDecoration(color: primaryColor),
                          children: [
                            pw.Container(
                              padding: const pw.EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 6,
                              ),
                              alignment: pw.Alignment.center,
                              child: pw.Column(
                                mainAxisAlignment: pw.MainAxisAlignment.center,
                                children: [
                                  pw.Text(
                                    'CLASS',
                                    style: pw.TextStyle(
                                      color: PdfColors.white,
                                      fontWeight: pw.FontWeight.bold,
                                      fontSize: 8.5,
                                    ),
                                  ),
                                  pw.SizedBox(height: 1),
                                  pw.Text(
                                    'শ্রেণি',
                                    style: const pw.TextStyle(
                                      color: PdfColors.grey300,
                                      fontSize: 6.5,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            ...sortedTimeSlots.asMap().entries.map((slotItem) {
                              final pIndex = slotItem.key;
                              final slotStr = slotItem.value;
                              return pw.Container(
                                padding: const pw.EdgeInsets.symmetric(
                                  horizontal: 4,
                                  vertical: 5,
                                ),
                                alignment: pw.Alignment.center,
                                child: pw.Column(
                                  mainAxisAlignment:
                                      pw.MainAxisAlignment.center,
                                  children: [
                                    pw.Text(
                                      _getPeriodOrdinal(pIndex).toUpperCase(),
                                      style: pw.TextStyle(
                                        color: PdfColors.white,
                                        fontWeight: pw.FontWeight.bold,
                                        fontSize: 8,
                                      ),
                                    ),
                                    pw.SizedBox(height: 1),
                                    pw.Text(
                                      slotStr,
                                      style: const pw.TextStyle(
                                        color: PdfColors.grey300,
                                        fontSize: 6.5,
                                      ),
                                      textAlign: pw.TextAlign.center,
                                    ),
                                  ],
                                ),
                              );
                            }),
                          ],
                        ),

                        // ── DATA ROWS: EACH CLASS
                        ...currentChunkClasses.asMap().entries.map((rowItem) {
                          final rowIdx = rowItem.key;
                          final clsName = rowItem.value;
                          final clsEntries = classEntriesMap[clsName] ?? [];
                          final isEvenRow = rowIdx % 2 == 0;

                          return pw.TableRow(
                            children: [
                              // Class Name Column
                              pw.Container(
                                padding: const pw.EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 6,
                                ),
                                alignment: pw.Alignment.center,
                                decoration: pw.BoxDecoration(
                                  color: isEvenRow
                                      ? PdfColor.fromHex('#F1F5F9')
                                      : PdfColor.fromHex('#E2E8F0'),
                                ),
                                child: pw.Text(
                                  clsName,
                                  style: pw.TextStyle(
                                    fontWeight: pw.FontWeight.bold,
                                    fontSize: 9,
                                    color: primaryColor,
                                  ),
                                  textAlign: pw.TextAlign.center,
                                  maxLines: 2,
                                ),
                              ),

                              // Period Cells for this Class
                              ...sortedTimeSlots.map((slot) {
                                final slotStartMin = _parseTimeToMinutes(
                                  slot.split('-').first.trim(),
                                );

                                final matchingEntries = clsEntries
                                    .where(
                                      (e) =>
                                          formatSlotDisplay(
                                                e.startTime,
                                                e.endTime,
                                              ) ==
                                              slot ||
                                          _parseTimeToMinutes(e.startTime) ==
                                              slotStartMin,
                                    )
                                    .toList();

                                if (matchingEntries.isEmpty) {
                                  return pw.Container(
                                    padding: const pw.EdgeInsets.all(4),
                                    alignment: pw.Alignment.center,
                                    decoration: pw.BoxDecoration(
                                      color: isEvenRow
                                          ? PdfColors.white
                                          : bgTint,
                                    ),
                                    child: pw.Text(
                                      '--',
                                      style: const pw.TextStyle(
                                        color: PdfColors.grey400,
                                        fontSize: 9,
                                      ),
                                    ),
                                  );
                                }

                                final subList = <String>[];
                                final teachList = <String>[];
                                final roomList = <String>[];

                                for (final m in matchingEntries) {
                                  final s = _resolveSubjectName(m, subjects);
                                  final t = _resolveTeacherName(m, teachers);
                                  if (s.isNotEmpty && !subList.contains(s)) {
                                    subList.add(s);
                                  }
                                  if (t.isNotEmpty &&
                                      t != 'Not Assigned' &&
                                      !teachList.contains(t)) {
                                    teachList.add(t);
                                  }
                                  if (m.roomNumber != null &&
                                      m.roomNumber!.isNotEmpty &&
                                      !roomList.contains(m.roomNumber)) {
                                    roomList.add(m.roomNumber!);
                                  }
                                }

                                final subText = subList.isNotEmpty
                                    ? subList.join(' / ')
                                    : 'Subject';
                                final teachText = teachList.isNotEmpty
                                    ? teachList.join(' / ')
                                    : 'Teacher';

                                return pw.Container(
                                  padding: const pw.EdgeInsets.symmetric(
                                    horizontal: 4,
                                    vertical: 4,
                                  ),
                                  decoration: pw.BoxDecoration(
                                    color: isEvenRow ? PdfColors.white : bgTint,
                                  ),
                                  child: pw.Column(
                                    mainAxisAlignment:
                                        pw.MainAxisAlignment.center,
                                    crossAxisAlignment:
                                        pw.CrossAxisAlignment.center,
                                    children: [
                                      // Subject Name (Line 1, Bold)
                                      pw.Text(
                                        subText,
                                        style: pw.TextStyle(
                                          fontSize: 7.5,
                                          fontWeight: pw.FontWeight.bold,
                                          color: primaryColor,
                                        ),
                                        textAlign: pw.TextAlign.center,
                                        maxLines: 2,
                                      ),
                                      pw.SizedBox(height: 2),
                                      // Teacher Name (Line 2)
                                      pw.Text(
                                        teachText,
                                        style: const pw.TextStyle(
                                          fontSize: 6.5,
                                          color: PdfColors.grey800,
                                        ),
                                        textAlign: pw.TextAlign.center,
                                        maxLines: 1,
                                      ),
                                      // Room Number (Optional, Line 3)
                                      if (roomList.isNotEmpty) ...[
                                        pw.SizedBox(height: 1.5),
                                        pw.Container(
                                          padding:
                                              const pw.EdgeInsets.symmetric(
                                                horizontal: 3.5,
                                                vertical: 1,
                                              ),
                                          decoration: pw.BoxDecoration(
                                            color: PdfColor.fromHex('#E2E8F0'),
                                            borderRadius:
                                                const pw.BorderRadius.all(
                                                  pw.Radius.circular(2),
                                                ),
                                          ),
                                          child: pw.Text(
                                            'Rm ${roomList.join(", ")}',
                                            style: pw.TextStyle(
                                              fontSize: 5.5,
                                              color: PdfColors.grey800,
                                              fontWeight: pw.FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                );
                              }),
                            ],
                          );
                        }),
                      ],
                    ),
                  ),

                pw.SizedBox(height: 6),

                // 4. Signatures Area
                _buildSignaturesBlock(
                  primaryColor: primaryColor,
                  isLandscape: true,
                ),

                pw.SizedBox(height: 2),

                // 5. Footer
                _buildFooter(context, primaryColor),
              ],
            );
          },
        ),
      );
    }
  }

  // ───────────────────────────────────────────────────────────────────────────
  // 2. SINGLE CLASS WEEKLY GRID LAYOUT (Landscape A4)
  // Rows = Days, Columns = Periods
  // ───────────────────────────────────────────────────────────────────────────

  static void _buildSingleClassWeeklyGridDocument({
    required pw.Document pdf,
    required pw.ThemeData theme,
    required School? school,
    required pw.ImageProvider? schoolLogo,
    required List<ClassSectionRoutineGroup> groups,
    required List<Subject> subjects,
    required List<Teacher> teachers,
    String? academicYear,
  }) {
    final primaryColor = PdfColor.fromHex('#1E1B4B');
    final accentColor = PdfColor.fromHex('#4F46E5');
    final bgTint = PdfColor.fromHex('#F8FAFC');
    final borderTint = PdfColor.fromHex('#CBD5E1');

    for (final group in groups) {
      final className = group.className;
      final sectionName = group.sectionName;
      final entries = group.entries;

      final timeSlotSet = <String>{};
      for (final e in entries) {
        final slotStr = formatSlotDisplay(e.startTime, e.endTime);
        if (slotStr.isNotEmpty) {
          timeSlotSet.add(slotStr);
        }
      }
      final sortedTimeSlots = timeSlotSet.toList()
        ..sort((a, b) {
          final startA = a.split('-').first.trim();
          final startB = b.split('-').first.trim();
          return _parseTimeToMinutes(
            startA,
          ).compareTo(_parseTimeToMinutes(startB));
        });

      final activeDays = weekDays.where((day) {
        return entries.any((e) => e.day.toLowerCase() == day.toLowerCase());
      }).toList();

      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4.landscape,
          margin: const pw.EdgeInsets.all(22),
          theme: theme,
          build: (pw.Context context) {
            return pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.stretch,
              children: [
                _buildInstitutionalHeader(
                  school: school,
                  schoolLogo: schoolLogo,
                  primaryColor: primaryColor,
                  accentColor: accentColor,
                  bgTint: bgTint,
                  borderTint: borderTint,
                  isLandscape: true,
                ),
                pw.SizedBox(height: 8),
                _buildMetadataBanner(
                  className: className,
                  sectionName: sectionName,
                  academicYear: academicYear,
                  totalWeeklyClasses: entries.length,
                  activeDaysCount: activeDays.length,
                  totalSubjectsCount: subjects.length,
                  primaryColor: primaryColor,
                  accentColor: accentColor,
                  bgTint: bgTint,
                  borderTint: borderTint,
                  isCompact: true,
                ),
                pw.SizedBox(height: 10),
                if (sortedTimeSlots.isEmpty)
                  pw.Expanded(
                    child: pw.Center(
                      child: pw.Text(
                        'No routine entries found for $className.',
                        style: pw.TextStyle(
                          fontSize: 13,
                          fontWeight: pw.FontWeight.bold,
                          color: primaryColor,
                        ),
                      ),
                    ),
                  )
                else
                  pw.Expanded(
                    child: pw.Table(
                      border: pw.TableBorder.all(color: borderTint, width: 0.8),
                      children: [
                        pw.TableRow(
                          decoration: pw.BoxDecoration(color: primaryColor),
                          children: [
                            pw.Container(
                              padding: const pw.EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 6,
                              ),
                              alignment: pw.Alignment.center,
                              child: pw.Text(
                                'DAY / TIME',
                                style: pw.TextStyle(
                                  color: PdfColors.white,
                                  fontWeight: pw.FontWeight.bold,
                                  fontSize: 8,
                                ),
                              ),
                            ),
                            ...sortedTimeSlots.asMap().entries.map((slotItem) {
                              final pIdx = slotItem.key;
                              final slotStr = slotItem.value;
                              return pw.Container(
                                padding: const pw.EdgeInsets.symmetric(
                                  horizontal: 4,
                                  vertical: 6,
                                ),
                                alignment: pw.Alignment.center,
                                child: pw.Column(
                                  children: [
                                    pw.Text(
                                      _getPeriodOrdinal(pIdx).toUpperCase(),
                                      style: pw.TextStyle(
                                        color: PdfColors.white,
                                        fontWeight: pw.FontWeight.bold,
                                        fontSize: 7.5,
                                      ),
                                    ),
                                    pw.SizedBox(height: 1),
                                    pw.Text(
                                      slotStr,
                                      style: const pw.TextStyle(
                                        color: PdfColors.grey300,
                                        fontSize: 6.5,
                                      ),
                                      textAlign: pw.TextAlign.center,
                                    ),
                                  ],
                                ),
                              );
                            }),
                          ],
                        ),
                        ...activeDays.map((day) {
                          final dayColor = _getDayPdfColor(day);
                          return pw.TableRow(
                            children: [
                              pw.Container(
                                padding: const pw.EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 6,
                                ),
                                alignment: pw.Alignment.center,
                                decoration: pw.BoxDecoration(color: dayColor),
                                child: pw.Text(
                                  day.substring(0, 3).toUpperCase(),
                                  style: pw.TextStyle(
                                    color: PdfColors.white,
                                    fontWeight: pw.FontWeight.bold,
                                    fontSize: 9,
                                  ),
                                ),
                              ),
                              ...sortedTimeSlots.map((slot) {
                                final slotStartMin = _parseTimeToMinutes(
                                  slot.split('-').first.trim(),
                                );

                                final slotEntry = entries.firstWhere(
                                  (e) =>
                                      e.day.toLowerCase() ==
                                          day.toLowerCase() &&
                                      (formatSlotDisplay(
                                                e.startTime,
                                                e.endTime,
                                              ) ==
                                              slot ||
                                          _parseTimeToMinutes(e.startTime) ==
                                              slotStartMin),
                                  orElse: () => RoutineEntry(
                                    day: '',
                                    startTime: '',
                                    endTime: '',
                                    subjectId: '',
                                    teacherId: '',
                                  ),
                                );

                                if (slotEntry.subjectId.isEmpty) {
                                  return pw.Container(
                                    padding: const pw.EdgeInsets.all(4),
                                    alignment: pw.Alignment.center,
                                    decoration: pw.BoxDecoration(color: bgTint),
                                    child: pw.Text(
                                      '--',
                                      style: const pw.TextStyle(
                                        color: PdfColors.grey400,
                                        fontSize: 9,
                                      ),
                                    ),
                                  );
                                }

                                final subName = _resolveSubjectName(
                                  slotEntry,
                                  subjects,
                                );
                                final teachName = _resolveTeacherName(
                                  slotEntry,
                                  teachers,
                                );

                                return pw.Container(
                                  padding: const pw.EdgeInsets.all(4),
                                  decoration: const pw.BoxDecoration(
                                    color: PdfColors.white,
                                  ),
                                  child: pw.Column(
                                    mainAxisAlignment:
                                        pw.MainAxisAlignment.center,
                                    crossAxisAlignment:
                                        pw.CrossAxisAlignment.center,
                                    children: [
                                      pw.Text(
                                        subName,
                                        style: pw.TextStyle(
                                          fontSize: 8,
                                          fontWeight: pw.FontWeight.bold,
                                          color: primaryColor,
                                        ),
                                        textAlign: pw.TextAlign.center,
                                        maxLines: 2,
                                      ),
                                      pw.SizedBox(height: 2),
                                      pw.Text(
                                        teachName,
                                        style: const pw.TextStyle(
                                          fontSize: 6.5,
                                          color: PdfColors.grey700,
                                        ),
                                        textAlign: pw.TextAlign.center,
                                        maxLines: 1,
                                      ),
                                      if (slotEntry.roomNumber != null &&
                                          slotEntry.roomNumber!.isNotEmpty) ...[
                                        pw.SizedBox(height: 2),
                                        pw.Container(
                                          padding:
                                              const pw.EdgeInsets.symmetric(
                                                horizontal: 4,
                                                vertical: 1,
                                              ),
                                          decoration: pw.BoxDecoration(
                                            color: bgTint,
                                            border: pw.Border.all(
                                              color: borderTint,
                                              width: 0.5,
                                            ),
                                            borderRadius:
                                                const pw.BorderRadius.all(
                                                  pw.Radius.circular(2),
                                                ),
                                          ),
                                          child: pw.Text(
                                            'Rm ${slotEntry.roomNumber}',
                                            style: const pw.TextStyle(
                                              fontSize: 5.5,
                                              color: PdfColors.grey800,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                );
                              }),
                            ],
                          );
                        }),
                      ],
                    ),
                  ),
                pw.SizedBox(height: 8),
                _buildSignaturesBlock(
                  primaryColor: primaryColor,
                  isLandscape: true,
                ),
                pw.SizedBox(height: 4),
                _buildFooter(context, primaryColor),
              ],
            );
          },
        ),
      );
    }
  }

  // ───────────────────────────────────────────────────────────────────────────
  // 3. DAY-BY-DAY DETAILED SCHEDULE LAYOUT (MultiPage)
  // ───────────────────────────────────────────────────────────────────────────

  static void _buildDayByDayDocument({
    required pw.Document pdf,
    required pw.ThemeData theme,
    required School? school,
    required pw.ImageProvider? schoolLogo,
    required List<ClassSectionRoutineGroup> groups,
    required List<Subject> subjects,
    required List<Teacher> teachers,
    String? academicYear,
  }) {
    final primaryColor = PdfColor.fromHex('#1E1B4B');
    final accentColor = PdfColor.fromHex('#4F46E5');
    final bgTint = PdfColor.fromHex('#F8FAFC');
    final borderTint = PdfColor.fromHex('#E2E8F0');

    if (groups.isEmpty) {
      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(32),
          theme: theme,
          build: (context) => pw.Center(
            child: pw.Column(
              mainAxisAlignment: pw.MainAxisAlignment.center,
              children: [
                _buildInstitutionalHeader(
                  school: school,
                  schoolLogo: schoolLogo,
                  primaryColor: primaryColor,
                  accentColor: accentColor,
                  bgTint: bgTint,
                  borderTint: borderTint,
                ),
                pw.SizedBox(height: 40),
                pw.Text(
                  'No Routine Entries Scheduled',
                  style: pw.TextStyle(
                    fontSize: 16,
                    fontWeight: pw.FontWeight.bold,
                    color: primaryColor,
                  ),
                ),
                pw.SizedBox(height: 6),
                pw.Text(
                  'No routine entries were found matching the selected class criteria.',
                  style: const pw.TextStyle(
                    fontSize: 11,
                    color: PdfColors.grey600,
                  ),
                  textAlign: pw.TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      );
      return;
    }

    for (final group in groups) {
      final className = group.className;
      final sectionName = group.sectionName;
      final entries = group.entries;

      final dayEntriesMap = <String, List<RoutineEntry>>{};
      for (final day in weekDays) {
        final dayList = entries
            .where((e) => e.day.toLowerCase() == day.toLowerCase())
            .toList();
        dayList.sort(
          (a, b) => _parseTimeToMinutes(
            a.startTime,
          ).compareTo(_parseTimeToMinutes(b.startTime)),
        );
        if (dayList.isNotEmpty) {
          dayEntriesMap[day] = dayList;
        }
      }

      final totalWeeklyClasses = entries.length;
      final activeDaysCount = dayEntriesMap.keys.length;

      final distinctSubjects = <String>{};
      for (final e in entries) {
        final name = _resolveSubjectName(e, subjects);
        distinctSubjects.add(name);
      }

      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.symmetric(horizontal: 28, vertical: 24),
          theme: theme,
          header: (pw.Context context) {
            if (context.pageNumber > 1) {
              return pw.Container(
                margin: const pw.EdgeInsets.only(bottom: 12),
                padding: const pw.EdgeInsets.only(bottom: 6),
                decoration: const pw.BoxDecoration(
                  border: pw.Border(
                    bottom: pw.BorderSide(color: PdfColors.grey300, width: 0.5),
                  ),
                ),
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text(
                      '${school?.name ?? 'Smart School'} - Class Routine',
                      style: pw.TextStyle(
                        fontSize: 9,
                        fontWeight: pw.FontWeight.bold,
                        color: primaryColor,
                      ),
                    ),
                    pw.Text(
                      'Class: $className',
                      style: const pw.TextStyle(
                        fontSize: 9,
                        color: PdfColors.grey700,
                      ),
                    ),
                  ],
                ),
              );
            }
            return pw.SizedBox.shrink();
          },
          footer: (pw.Context context) => _buildFooter(context, primaryColor),
          build: (pw.Context context) {
            return [
              _buildInstitutionalHeader(
                school: school,
                schoolLogo: schoolLogo,
                primaryColor: primaryColor,
                accentColor: accentColor,
                bgTint: bgTint,
                borderTint: borderTint,
              ),
              pw.SizedBox(height: 12),
              _buildMetadataBanner(
                className: className,
                sectionName: sectionName,
                academicYear: academicYear,
                totalWeeklyClasses: totalWeeklyClasses,
                activeDaysCount: activeDaysCount,
                totalSubjectsCount: distinctSubjects.length,
                primaryColor: primaryColor,
                accentColor: accentColor,
                bgTint: bgTint,
                borderTint: borderTint,
              ),
              pw.SizedBox(height: 16),
              if (dayEntriesMap.isEmpty)
                pw.Container(
                  padding: const pw.EdgeInsets.all(28),
                  alignment: pw.Alignment.center,
                  decoration: pw.BoxDecoration(
                    color: bgTint,
                    border: pw.Border.all(color: borderTint),
                    borderRadius: const pw.BorderRadius.all(
                      pw.Radius.circular(8),
                    ),
                  ),
                  child: pw.Column(
                    children: [
                      pw.Text(
                        'No Routine Entries Scheduled for $className',
                        style: pw.TextStyle(
                          fontSize: 13,
                          fontWeight: pw.FontWeight.bold,
                          color: primaryColor,
                        ),
                      ),
                      pw.SizedBox(height: 4),
                      pw.Text(
                        'There are currently no class routine entries added.',
                        style: const pw.TextStyle(
                          fontSize: 10,
                          color: PdfColors.grey600,
                        ),
                      ),
                    ],
                  ),
                )
              else
                ...dayEntriesMap.entries.map((entry) {
                  final dayName = entry.key;
                  final dayEntries = entry.value;
                  final dayColor = _getDayPdfColor(dayName);

                  return pw.Container(
                    margin: const pw.EdgeInsets.only(bottom: 14),
                    decoration: pw.BoxDecoration(
                      border: pw.Border.all(color: borderTint, width: 0.8),
                      borderRadius: const pw.BorderRadius.all(
                        pw.Radius.circular(6),
                      ),
                    ),
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.stretch,
                      children: [
                        pw.Container(
                          padding: const pw.EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: pw.BoxDecoration(
                            color: dayColor,
                            borderRadius: const pw.BorderRadius.vertical(
                              top: pw.Radius.circular(5),
                            ),
                          ),
                          child: pw.Row(
                            mainAxisAlignment:
                                pw.MainAxisAlignment.spaceBetween,
                            children: [
                              pw.Text(
                                dayName.toUpperCase(),
                                style: pw.TextStyle(
                                  fontSize: 10,
                                  fontWeight: pw.FontWeight.bold,
                                  color: PdfColors.white,
                                  letterSpacing: 0.5,
                                ),
                              ),
                              pw.Text(
                                '${dayEntries.length} ${dayEntries.length == 1 ? 'Period' : 'Periods'}',
                                style: pw.TextStyle(
                                  fontSize: 9,
                                  fontWeight: pw.FontWeight.bold,
                                  color: PdfColors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                        pw.Table(
                          border: pw.TableBorder(
                            horizontalInside: pw.BorderSide(
                              color: borderTint,
                              width: 0.5,
                            ),
                          ),
                          columnWidths: const {
                            0: pw.FlexColumnWidth(1.0),
                            1: pw.FlexColumnWidth(2.5),
                            2: pw.FlexColumnWidth(3.8),
                            3: pw.FlexColumnWidth(3.5),
                            4: pw.FlexColumnWidth(1.8),
                            5: pw.FlexColumnWidth(1.6),
                          },
                          children: [
                            pw.TableRow(
                              decoration: pw.BoxDecoration(color: bgTint),
                              children: [
                                _buildTableHeaderCell(
                                  '#',
                                  align: pw.TextAlign.center,
                                ),
                                _buildTableHeaderCell(
                                  'TIME SLOT',
                                  align: pw.TextAlign.left,
                                ),
                                _buildTableHeaderCell(
                                  'SUBJECT',
                                  align: pw.TextAlign.left,
                                ),
                                _buildTableHeaderCell(
                                  'TEACHER',
                                  align: pw.TextAlign.left,
                                ),
                                _buildTableHeaderCell(
                                  'ROOM',
                                  align: pw.TextAlign.center,
                                ),
                                _buildTableHeaderCell(
                                  'DURATION',
                                  align: pw.TextAlign.right,
                                ),
                              ],
                            ),
                            ...dayEntries.asMap().entries.map((rowItem) {
                              final idx = rowItem.key;
                              final r = rowItem.value;
                              final isEven = idx % 2 == 0;
                              final subjectName = _resolveSubjectName(
                                r,
                                subjects,
                              );
                              final teacherName = _resolveTeacherName(
                                r,
                                teachers,
                              );
                              final duration = _calculateDuration(
                                r.startTime,
                                r.endTime,
                              );

                              return pw.TableRow(
                                decoration: pw.BoxDecoration(
                                  color: isEven ? PdfColors.white : bgTint,
                                ),
                                children: [
                                  _buildTableCell(
                                    '${idx + 1}',
                                    align: pw.TextAlign.center,
                                    isBold: true,
                                    textColor: PdfColors.grey700,
                                  ),
                                  _buildTableCell(
                                    formatSlotDisplay(r.startTime, r.endTime),
                                    isBold: true,
                                    textColor: primaryColor,
                                  ),
                                  _buildTableCell(
                                    subjectName,
                                    isBold: true,
                                    textColor: PdfColors.grey900,
                                  ),
                                  _buildTableCell(
                                    teacherName,
                                    textColor: PdfColors.grey800,
                                  ),
                                  _buildTableCell(
                                    r.roomNumber != null &&
                                            r.roomNumber!.isNotEmpty
                                        ? r.roomNumber!
                                        : '-',
                                    align: pw.TextAlign.center,
                                    isTag:
                                        r.roomNumber != null &&
                                        r.roomNumber!.isNotEmpty,
                                  ),
                                  _buildTableCell(
                                    duration.isNotEmpty ? duration : '-',
                                    align: pw.TextAlign.right,
                                    textColor: PdfColors.grey600,
                                  ),
                                ],
                              );
                            }),
                          ],
                        ),
                      ],
                    ),
                  );
                }),
              pw.SizedBox(height: 12),
              if (distinctSubjects.isNotEmpty) ...[
                _buildSubjectFacultySummary(
                  entries: entries,
                  subjects: subjects,
                  teachers: teachers,
                  primaryColor: primaryColor,
                  accentColor: accentColor,
                  bgTint: bgTint,
                  borderTint: borderTint,
                ),
                pw.SizedBox(height: 14),
              ],
              _buildInstructionsBox(
                primaryColor: primaryColor,
                bgTint: bgTint,
                borderTint: borderTint,
              ),
              pw.SizedBox(height: 24),
              _buildSignaturesBlock(primaryColor: primaryColor),
            ];
          },
        ),
      );
    }
  }

  // ───────────────────────────────────────────────────────────────────────────
  // COMPONENT BUILDERS
  // ───────────────────────────────────────────────────────────────────────────

  static pw.Widget _buildInstitutionalHeader({
    required School? school,
    required pw.ImageProvider? schoolLogo,
    required PdfColor primaryColor,
    required PdfColor accentColor,
    required PdfColor bgTint,
    required PdfColor borderTint,
    bool isLandscape = false,
    String? customSubtitle,
  }) {
    final schoolName = school?.name.isNotEmpty == true
        ? school!.name
        : 'SMART SCHOOL MANAGEMENT';
    final address = school?.address ?? '';
    final phone = school?.phone ?? '';
    final email = school?.email ?? '';

    return pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.center,
      children: [
        // Logo / Emblem
        if (schoolLogo != null)
          pw.Container(
            height: isLandscape ? 38 : 46,
            width: isLandscape ? 38 : 46,
            margin: const pw.EdgeInsets.only(right: 10),
            child: pw.Image(schoolLogo),
          )
        else
          pw.Container(
            height: isLandscape ? 36 : 44,
            width: isLandscape ? 36 : 44,
            margin: const pw.EdgeInsets.only(right: 10),
            decoration: pw.BoxDecoration(
              gradient: pw.LinearGradient(
                colors: [primaryColor, accentColor],
                begin: pw.Alignment.topLeft,
                end: pw.Alignment.bottomRight,
              ),
              shape: pw.BoxShape.circle,
            ),
            child: pw.Center(
              child: pw.Text(
                schoolName.isNotEmpty ? schoolName[0].toUpperCase() : 'S',
                style: pw.TextStyle(
                  color: PdfColors.white,
                  fontSize: isLandscape ? 16 : 20,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
            ),
          ),

        // School Information
        pw.Expanded(
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                schoolName.toUpperCase(),
                style: pw.TextStyle(
                  fontWeight: pw.FontWeight.bold,
                  fontSize: isLandscape ? 12.5 : 14.5,
                  color: primaryColor,
                  letterSpacing: 0.3,
                ),
              ),
              if (address.isNotEmpty) ...[
                pw.SizedBox(height: 1),
                pw.Text(
                  address,
                  style: const pw.TextStyle(
                    fontSize: 7.5,
                    color: PdfColors.grey700,
                  ),
                ),
              ],
              if (phone.isNotEmpty || email.isNotEmpty) ...[
                pw.SizedBox(height: 1),
                pw.Text(
                  [
                    if (phone.isNotEmpty) 'Tel: $phone',
                    if (email.isNotEmpty) 'Email: $email',
                  ].join('  |  '),
                  style: const pw.TextStyle(
                    fontSize: 7.5,
                    color: PdfColors.grey600,
                  ),
                ),
              ],
            ],
          ),
        ),

        // Official Routine Document Badge
        pw.Container(
          padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: pw.BoxDecoration(
            color: bgTint,
            border: pw.Border.all(color: accentColor, width: 1),
            borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
          ),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.end,
            children: [
              pw.Text(
                'ACADEMIC TIMETABLE',
                style: pw.TextStyle(
                  fontSize: 7.5,
                  fontWeight: pw.FontWeight.bold,
                  color: primaryColor,
                ),
              ),
              pw.Text(
                customSubtitle ?? 'OFFICIAL CLASS ROUTINE',
                style: pw.TextStyle(
                  fontSize: 6.5,
                  fontWeight: pw.FontWeight.bold,
                  color: accentColor,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  static pw.Widget _buildMasterTimetableBanner({
    required int totalClassesCount,
    required int periodsCount,
    required String? academicYear,
    required String? pageChunkInfo,
    required PdfColor primaryColor,
    required PdfColor accentColor,
    required PdfColor bgTint,
    required PdfColor borderTint,
  }) {
    final effectiveYear =
        academicYear ?? DateFormat('yyyy').format(DateTime.now());
    final effectiveDate = DateFormat('dd MMMM yyyy').format(DateTime.now());

    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 5),
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
              pw.Container(
                padding: const pw.EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 3.5,
                ),
                decoration: pw.BoxDecoration(
                  color: primaryColor,
                  borderRadius: const pw.BorderRadius.all(
                    pw.Radius.circular(3),
                  ),
                ),
                child: pw.Text(
                  'ALL CLASSES MASTER ROUTINE',
                  style: pw.TextStyle(
                    fontSize: 8.5,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.white,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
              if (pageChunkInfo != null) ...[
                pw.SizedBox(width: 6),
                pw.Text(
                  '($pageChunkInfo)',
                  style: const pw.TextStyle(
                    fontSize: 7.5,
                    color: PdfColors.grey700,
                  ),
                ),
              ],
            ],
          ),

          pw.Row(
            children: [
              _buildMetaPill(
                'Total Classes',
                '$totalClassesCount Classes',
                borderTint,
              ),
              pw.SizedBox(width: 6),
              _buildMetaPill('Periods', '$periodsCount Slots', borderTint),
              pw.SizedBox(width: 6),
              _buildMetaPill('Session', effectiveYear, borderTint),
              pw.SizedBox(width: 6),
              _buildMetaPill('Date', effectiveDate, borderTint),
            ],
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildMetadataBanner({
    required String className,
    required String? sectionName,
    required String? academicYear,
    required int totalWeeklyClasses,
    required int activeDaysCount,
    required int totalSubjectsCount,
    required PdfColor primaryColor,
    required PdfColor accentColor,
    required PdfColor bgTint,
    required PdfColor borderTint,
    bool isCompact = false,
  }) {
    final effectiveYear =
        academicYear ?? DateFormat('yyyy').format(DateTime.now());
    final effectiveDate = DateFormat('dd MMMM yyyy').format(DateTime.now());

    return pw.Container(
      padding: pw.EdgeInsets.all(isCompact ? 6 : 8),
      decoration: pw.BoxDecoration(
        color: bgTint,
        border: pw.Border.all(color: borderTint, width: 0.8),
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(5)),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Container(
            padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: pw.BoxDecoration(
              color: primaryColor,
              borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
            ),
            child: pw.Text(
              'CLASS: $className',
              style: pw.TextStyle(
                fontSize: 8.5,
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.white,
              ),
            ),
          ),
          pw.Row(
            children: [
              _buildMetaPill('Academic Year', effectiveYear, borderTint),
              pw.SizedBox(width: 6),
              _buildMetaPill(
                'Total Periods',
                '$totalWeeklyClasses/wk',
                borderTint,
              ),
              pw.SizedBox(width: 6),
              _buildMetaPill(
                'Active Days',
                '$activeDaysCount Days',
                borderTint,
              ),
              pw.SizedBox(width: 6),
              _buildMetaPill('Issued Date', effectiveDate, borderTint),
            ],
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildMetaPill(
    String label,
    String value,
    PdfColor borderTint,
  ) {
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: pw.BoxDecoration(
        color: PdfColors.white,
        border: pw.Border.all(color: borderTint, width: 0.5),
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(3)),
      ),
      child: pw.Row(
        mainAxisSize: pw.MainAxisSize.min,
        children: [
          pw.Text(
            '$label: ',
            style: const pw.TextStyle(fontSize: 7, color: PdfColors.grey600),
          ),
          pw.Text(
            value,
            style: pw.TextStyle(
              fontSize: 7,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.grey900,
            ),
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildTableHeaderCell(
    String text, {
    pw.TextAlign align = pw.TextAlign.left,
  }) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      child: pw.Text(
        text,
        textAlign: align,
        style: pw.TextStyle(
          fontSize: 7.5,
          fontWeight: pw.FontWeight.bold,
          color: PdfColors.grey700,
        ),
      ),
    );
  }

  static pw.Widget _buildTableCell(
    String text, {
    pw.TextAlign align = pw.TextAlign.left,
    bool isBold = false,
    PdfColor? textColor,
    bool isTag = false,
  }) {
    if (isTag) {
      return pw.Padding(
        padding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 4),
        child: pw.Center(
          child: pw.Container(
            padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: pw.BoxDecoration(
              color: PdfColor.fromHex('#EEF2F6'),
              borderRadius: const pw.BorderRadius.all(pw.Radius.circular(3)),
            ),
            child: pw.Text(
              text,
              style: pw.TextStyle(
                fontSize: 7.5,
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.grey800,
              ),
            ),
          ),
        ),
      );
    }

    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      child: pw.Text(
        text,
        textAlign: align,
        style: pw.TextStyle(
          fontSize: 8,
          fontWeight: isBold ? pw.FontWeight.bold : pw.FontWeight.normal,
          color: textColor ?? PdfColors.grey900,
        ),
      ),
    );
  }

  static pw.Widget _buildSubjectFacultySummary({
    required List<RoutineEntry> entries,
    required List<Subject> subjects,
    required List<Teacher> teachers,
    required PdfColor primaryColor,
    required PdfColor accentColor,
    required PdfColor bgTint,
    required PdfColor borderTint,
  }) {
    final summaryMap = <String, Map<String, dynamic>>{};
    for (final e in entries) {
      final subName = _resolveSubjectName(e, subjects);
      final teachName = _resolveTeacherName(e, teachers);

      if (!summaryMap.containsKey(subName)) {
        summaryMap[subName] = {
          'teacher': teachName,
          'count': 0,
          'room': e.roomNumber ?? '-',
        };
      }
      summaryMap[subName]!['count'] =
          (summaryMap[subName]!['count'] as int) + 1;
      if (e.roomNumber != null && e.roomNumber!.isNotEmpty) {
        summaryMap[subName]!['room'] = e.roomNumber!;
      }
    }

    return pw.Container(
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: borderTint, width: 0.8),
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.stretch,
        children: [
          pw.Container(
            padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: pw.BoxDecoration(
              color: primaryColor,
              borderRadius: const pw.BorderRadius.vertical(
                top: pw.Radius.circular(5),
              ),
            ),
            child: pw.Text(
              'SUBJECT & FACULTY ALLOCATION SUMMARY',
              style: pw.TextStyle(
                fontSize: 8.5,
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.white,
              ),
            ),
          ),
          pw.Table(
            border: pw.TableBorder(
              horizontalInside: pw.BorderSide(color: borderTint, width: 0.5),
            ),
            columnWidths: const {
              0: pw.FlexColumnWidth(3.5),
              1: pw.FlexColumnWidth(4.0),
              2: pw.FlexColumnWidth(2.0),
              3: pw.FlexColumnWidth(2.0),
            },
            children: [
              pw.TableRow(
                decoration: pw.BoxDecoration(color: bgTint),
                children: [
                  _buildTableHeaderCell('SUBJECT'),
                  _buildTableHeaderCell('ASSIGNED TEACHER'),
                  _buildTableHeaderCell(
                    'DEFAULT ROOM',
                    align: pw.TextAlign.center,
                  ),
                  _buildTableHeaderCell(
                    'PERIODS / WEEK',
                    align: pw.TextAlign.right,
                  ),
                ],
              ),
              ...summaryMap.entries.map((entry) {
                final sub = entry.key;
                final data = entry.value;
                return pw.TableRow(
                  children: [
                    _buildTableCell(sub, isBold: true),
                    _buildTableCell(data['teacher'] as String),
                    _buildTableCell(
                      data['room'] as String,
                      align: pw.TextAlign.center,
                    ),
                    _buildTableCell(
                      '${data['count']} Periods',
                      align: pw.TextAlign.right,
                      isBold: true,
                      textColor: accentColor,
                    ),
                  ],
                );
              }),
            ],
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildInstructionsBox({
    required PdfColor primaryColor,
    required PdfColor bgTint,
    required PdfColor borderTint,
  }) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(8),
      decoration: pw.BoxDecoration(
        color: bgTint,
        border: pw.Border.all(color: borderTint, width: 0.8),
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(5)),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'IMPORTANT ACADEMIC GUIDELINES & INSTRUCTIONS',
            style: pw.TextStyle(
              fontSize: 7.5,
              fontWeight: pw.FontWeight.bold,
              color: primaryColor,
            ),
          ),
          pw.SizedBox(height: 3),
          pw.Text(
            '1. Students must occupy their designated classrooms at least 5 minutes before the first period commences.\n'
            '2. Practical and laboratory periods require proper equipment, lab manuals, and safety compliance.\n'
            '3. Any changes, teacher substitutes, or room shifts are updated instantly on the SchoolCare mobile application.',
            style: const pw.TextStyle(
              fontSize: 7,
              color: PdfColors.grey700,
              height: 1.3,
            ),
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildSignaturesBlock({
    required PdfColor primaryColor,
    bool isLandscape = false,
  }) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      crossAxisAlignment: pw.CrossAxisAlignment.end,
      children: [
        _buildSignatureLine('Routine In-Charge', isLandscape: isLandscape),
        _buildSignatureLine('Academic Coordinator', isLandscape: isLandscape),
        _buildSignatureLine(
          'Principal / Headmaster',
          hasSeal: true,
          isLandscape: isLandscape,
        ),
      ],
    );
  }

  static pw.Widget _buildSignatureLine(
    String title, {
    bool hasSeal = false,
    bool isLandscape = false,
  }) {
    final lineWidth = isLandscape ? 120.0 : 130.0;
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.center,
      children: [
        if (hasSeal) ...[
          pw.Container(
            height: isLandscape ? 22 : 28,
            width: isLandscape ? 50 : 60,
            alignment: pw.Alignment.center,
            decoration: pw.BoxDecoration(
              border: pw.Border.all(
                color: PdfColors.grey400,
                style: pw.BorderStyle.dashed,
                width: 0.5,
              ),
              borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
            ),
            child: pw.Text(
              '[ Official Seal ]',
              style: const pw.TextStyle(fontSize: 6, color: PdfColors.grey500),
            ),
          ),
          pw.SizedBox(height: 3),
        ] else
          pw.SizedBox(height: isLandscape ? 25 : 32),
        pw.Container(width: lineWidth, height: 0.8, color: PdfColors.grey800),
        pw.SizedBox(height: 3),
        pw.Text(
          title,
          style: pw.TextStyle(
            fontSize: 7.5,
            fontWeight: pw.FontWeight.bold,
            color: PdfColors.grey900,
          ),
        ),
      ],
    );
  }

  static pw.Widget _buildFooter(pw.Context context, PdfColor primaryColor) {
    final formattedNow = DateFormat(
      'dd MMM yyyy, hh:mm a',
    ).format(DateTime.now());
    return pw.Container(
      margin: const pw.EdgeInsets.only(top: 6),
      padding: const pw.EdgeInsets.only(top: 4),
      decoration: const pw.BoxDecoration(
        border: pw.Border(
          top: pw.BorderSide(color: PdfColors.grey300, width: 0.5),
        ),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            'Generated on $formattedNow  |  SchoolCare Smart School System',
            style: const pw.TextStyle(fontSize: 6.5, color: PdfColors.grey600),
          ),
          pw.Text(
            'Page ${context.pageNumber} of ${context.pagesCount}',
            style: const pw.TextStyle(fontSize: 6.5, color: PdfColors.grey600),
          ),
        ],
      ),
    );
  }

  // ───────────────────────────────────────────────────────────────────────────
  // TIME & HELPER UTILITIES
  // ───────────────────────────────────────────────────────────────────────────

  /// Formats a time string into 12-Hour format (HH:mm AM/PM) without seconds.
  /// Examples:
  /// - "09:00:00" -> "09:00 AM"
  /// - "14:30:00" -> "02:30 PM"
  /// - "09:00:00 AM" -> "09:00 AM"
  /// - "02:45:00 PM" -> "02:45 PM"
  static String formatTimeDisplay(String timeStr) {
    if (timeStr.isEmpty) return '';
    try {
      final clean = timeStr.trim();
      final upper = clean.toUpperCase();
      final isPm = upper.contains('PM');
      final isAm = upper.contains('AM');

      final numOnly = clean.replaceAll(RegExp(r'[^\d:]'), '').trim();
      final parts = numOnly.split(':');
      if (parts.isEmpty || parts[0].isEmpty) return timeStr;

      int hour = int.parse(parts[0]);
      int minute = parts.length > 1 ? int.parse(parts[1]) : 0;

      String period = '';
      if (isPm || isAm) {
        period = isPm ? 'PM' : 'AM';
        if (hour > 12) hour -= 12;
        if (hour == 0) hour = 12;
      } else {
        if (hour >= 12) {
          period = 'PM';
          if (hour > 12) hour -= 12;
        } else {
          period = 'AM';
          if (hour == 0) hour = 12;
        }
      }

      final hStr = hour.toString().padLeft(2, '0');
      final mStr = minute.toString().padLeft(2, '0');

      return '$hStr:$mStr $period';
    } catch (_) {
      return timeStr;
    }
  }

  /// Formats a start and end time pair into a clean time slot (e.g. "09:00 AM - 09:45 AM").
  static String formatSlotDisplay(String startTime, String endTime) {
    final start = formatTimeDisplay(startTime);
    final end = formatTimeDisplay(endTime);
    if (start.isNotEmpty && end.isNotEmpty) {
      return '$start - $end';
    } else if (start.isNotEmpty) {
      return start;
    }
    return '';
  }

  static String _getPeriodOrdinal(int index) {
    final n = index + 1;
    if (n == 1) return '1st Period';
    if (n == 2) return '2nd Period';
    if (n == 3) return '3rd Period';
    if (n == 4) return '4th Period';
    if (n == 5) return '5th Period';
    if (n == 6) return '6th Period';
    if (n == 7) return '7th Period';
    if (n == 8) return '8th Period';
    return '${n}th Period';
  }

  static int _parseTimeToMinutes(String timeStr) {
    if (timeStr.isEmpty) return 0;
    try {
      final clean = timeStr.trim();
      final upper = clean.toUpperCase();
      final isPm = upper.contains('PM');
      final isAm = upper.contains('AM');

      final numOnly = clean.replaceAll(RegExp(r'[^\d:]'), '').trim();
      final parts = numOnly.split(':');
      if (parts.isEmpty || parts[0].isEmpty) return 0;

      int h = int.parse(parts[0]);
      int m = parts.length > 1 ? int.parse(parts[1]) : 0;

      if (isPm && h < 12) h += 12;
      if (isAm && h == 12) h = 0;

      return h * 60 + m;
    } catch (_) {
      return 0;
    }
  }

  static String _calculateDuration(String start, String end) {
    final startMin = _parseTimeToMinutes(start);
    final endMin = _parseTimeToMinutes(end);
    if (endMin > startMin && startMin > 0) {
      final diff = endMin - startMin;
      final hrs = diff ~/ 60;
      final mins = diff % 60;
      if (hrs > 0 && mins > 0) return '${hrs}h ${mins}m';
      if (hrs > 0) return '${hrs}h';
      return '$mins mins';
    }
    return '';
  }

  static String _resolveSubjectName(
    RoutineEntry entry,
    List<Subject> subjects,
  ) {
    if (entry.subjectEntity?.name.isNotEmpty == true) {
      return entry.subjectEntity!.name;
    }
    final found = subjects.firstWhere(
      (s) => s.id == entry.subjectId,
      orElse: () => Subject(id: '', name: ''),
    );
    if (found.name.isNotEmpty) return found.name;
    return entry.subjectId.isNotEmpty ? entry.subjectId : 'Subject';
  }

  static String _resolveTeacherName(
    RoutineEntry entry,
    List<Teacher> teachers,
  ) {
    if (entry.teacherEntity?.name.isNotEmpty == true) {
      return entry.teacherEntity!.name;
    }
    final found = teachers.firstWhere(
      (t) => t.userId == entry.teacherId,
      orElse: () =>
          Teacher(userId: '', designation: '', classId: '', sectionId: ''),
    );
    if (found.user?.name.isNotEmpty == true) return found.user!.name;
    return 'Not Assigned';
  }

  static PdfColor _getDayPdfColor(String day) {
    switch (day.toLowerCase()) {
      case 'monday':
        return PdfColor.fromHex('#4F46E5'); // Indigo
      case 'tuesday':
        return PdfColor.fromHex('#2563EB'); // Blue
      case 'wednesday':
        return PdfColor.fromHex('#0D9488'); // Teal
      case 'thursday':
        return PdfColor.fromHex('#D97706'); // Amber
      case 'friday':
        return PdfColor.fromHex('#E11D48'); // Rose
      case 'saturday':
        return PdfColor.fromHex('#0284C7'); // Sky
      case 'sunday':
        return PdfColor.fromHex('#7C3AED'); // Purple
      default:
        return PdfColor.fromHex('#4F46E5');
    }
  }
}
