import 'dart:typed_data';

import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:smart_school/core/utils/bangla_text_renderer.dart';

class TeacherAttendancePdfHelper {
  static Future<void> generateAttendancePdf({
    required List<dynamic> attendanceList,
    DateTime? startDate,
    DateTime? endDate,
    required String schoolName,
  }) async {
    // ── Collect all strings that may contain Bengali ─────────────────────────
    final strings = <String>{schoolName};
    for (final record in attendanceList) {
      final name = record['teacher']?['name'] ??
          record['teacherName'] ??
          record['name'] ??
          '';
      if (name.isNotEmpty) strings.add(name.toString());
    }

    // ── Pre-render Bengali text via Flutter's shaping engine ─────────────────
    final rendered = await BanglaTextRenderer.preRenderBatch(
      strings,
      fontSize: 10,
      maxWidth: 300,
    );

    final pdf = pw.Document();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context context) {
          return [
            _buildHeader(
              schoolName: schoolName,
              startDate: startDate,
              endDate: endDate,
              rendered: rendered,
            ),
            pw.SizedBox(height: 20),
            _buildAttendanceTable(attendanceList, rendered),
          ];
        },
        footer: (pw.Context context) => _buildFooter(context),
      ),
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
      name: 'Teacher_Attendance_Report_${DateFormat('yyyyMMdd').format(DateTime.now())}.pdf',
    );
  }

  static pw.Widget _buildHeader({
    required String schoolName,
    DateTime? startDate,
    DateTime? endDate,
    Map<String, Uint8List?> rendered = const {},
  }) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        BanglaTextRenderer.fromBytes(
          rendered[schoolName],
          schoolName,
          fontSize: 24,
          bold: true,
        ),
        pw.SizedBox(height: 8),
        pw.Text(
          'Teacher Attendance Report',
          style: pw.TextStyle(
            fontSize: 18,
            fontWeight: pw.FontWeight.bold,
            color: PdfColors.grey700,
          ),
        ),
        pw.Divider(thickness: 2),
        pw.SizedBox(height: 10),
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: []),
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.end,
              children: [
                pw.Text('Date: ${DateFormat('MMM dd, yyyy').format(DateTime.now())}'),
                if (startDate != null && endDate != null)
                  pw.Text(
                    'Period: ${DateFormat('MMM dd, yyyy').format(startDate)} - ${DateFormat('MMM dd, yyyy').format(endDate)}',
                  ),
                pw.SizedBox(height: 4),
              ],
            ),
          ],
        ),
      ],
    );
  }

  static pw.Widget _buildAttendanceTable(
    List<dynamic> attendanceList,
    Map<String, Uint8List?> rendered,
  ) {
    pw.Widget headerCell(String text) => pw.Container(
          padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 6),
          child: pw.Text(
            text,
            style: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.white, fontSize: 10),
          ),
        );

    pw.Widget cell(pw.Widget child, {bool center = false}) => pw.Container(
          padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 5),
          height: 30,
          alignment: center ? pw.Alignment.center : pw.Alignment.centerLeft,
          child: child,
        );

    return pw.Table(
      border: pw.TableBorder.all(color: PdfColors.grey300),
      columnWidths: const {
        0: pw.FlexColumnWidth(2),
        1: pw.FlexColumnWidth(3),
        2: pw.FlexColumnWidth(1.5),
        3: pw.FlexColumnWidth(1.5),
        4: pw.FlexColumnWidth(1.5),
      },
      children: [
        pw.TableRow(
          decoration: const pw.BoxDecoration(color: PdfColors.indigo600),
          children: [
            headerCell('Date'),
            headerCell('Teacher Name'),
            headerCell('In Time'),
            headerCell('Out Time'),
            headerCell('Status'),
          ],
        ),
        ...attendanceList.asMap().entries.map((entry) {
          final idx = entry.key;
          final record = entry.value;
          final bg = idx.isEven ? PdfColors.white : PdfColors.grey50;

          final inTime = record['startTime'];
          final outTime = record['endTime'];

          String formattedDate = 'N/A';
          String formattedInTime = '--:--';
          String formattedOutTime = '--:--';

          if (inTime != null && inTime.toString().isNotEmpty) {
            try {
              final parsedIn = DateTime.parse(inTime.toString()).toLocal();
              formattedDate = DateFormat('dd MMM yyyy').format(parsedIn);
              formattedInTime = DateFormat('hh:mm a').format(parsedIn);
            } catch (_) {
              formattedInTime = inTime.toString();
            }
          }

          if (outTime != null && outTime.toString().isNotEmpty) {
            try {
              final parsedOut = DateTime.parse(outTime.toString()).toLocal();
              formattedOutTime = DateFormat('hh:mm a').format(parsedOut);
            } catch (_) {
              formattedOutTime = outTime.toString();
            }
          }

          final teacherNameRaw = record['teacher']?['name'] ??
              record['teacherName'] ??
              record['name'] ??
              'Unknown Teacher';
          final teacherName = teacherNameRaw.toString();
          final status = record['status']?.toString().toUpperCase() ?? 'N/A';

          return pw.TableRow(
            decoration: pw.BoxDecoration(
              color: bg,
              border: const pw.Border(
                bottom: pw.BorderSide(color: PdfColors.grey300, width: 0.5),
              ),
            ),
            children: [
              cell(pw.Text(formattedDate, style: const pw.TextStyle(fontSize: 10))),
              cell(BanglaTextRenderer.fromBytes(rendered[teacherName], teacherName, fontSize: 10)),
              cell(pw.Text(formattedInTime, style: const pw.TextStyle(fontSize: 10)), center: true),
              cell(pw.Text(formattedOutTime, style: const pw.TextStyle(fontSize: 10)), center: true),
              cell(pw.Text(status, style: const pw.TextStyle(fontSize: 10)), center: true),
            ],
          );
        }),
      ],
    );
  }

  static pw.Widget _buildFooter(pw.Context context) {
    return pw.Container(
      alignment: pw.Alignment.centerRight,
      margin: const pw.EdgeInsets.only(top: 20),
      child: pw.Text(
        'Page ${context.pageNumber} of ${context.pagesCount}',
        style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey),
      ),
    );
  }
}
