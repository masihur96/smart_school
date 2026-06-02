import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:smart_school/models/period_attendance_model.dart';

class StudentAttendancePdfHelper {
  static Future<void> generateAttendancePdf({
    required List<PeriodAttendance> attendanceList,
    String? className,
    String? sectionName,
    String? subjectName,
    DateTime? startDate,
    DateTime? endDate,
    required String schoolName,
  }) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context context) {
          return [
            _buildHeader(
              schoolName: schoolName,
              className: className,
              sectionName: sectionName,
              subjectName: subjectName,
              startDate: startDate,
              endDate: endDate,
            ),
            pw.SizedBox(height: 20),
            _buildAttendanceTable(attendanceList),
            pw.SizedBox(height: 20),
            _buildFooter(context),
          ];
        },
      ),
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
      name: 'Attendance_Report_${DateFormat('yyyyMMdd').format(DateTime.now())}.pdf',
    );
  }

  static pw.Widget _buildHeader({
    required String schoolName,
    String? className,
    String? sectionName,
    String? subjectName,
    DateTime? startDate,
    DateTime? endDate,
  }) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          schoolName,
          style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold),
        ),
        pw.SizedBox(height: 8),
        pw.Text(
          'Student Attendance Report',
          style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold, color: PdfColors.grey700),
        ),
        pw.Divider(thickness: 2),
        pw.SizedBox(height: 10),
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                if (className != null) pw.Text('Class: $className'),
                if (sectionName != null) pw.Text('Section: $sectionName'),
                if (subjectName != null) pw.Text('Subject: $subjectName'),
              ],
            ),
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.end,
              children: [
                pw.Text('Date: ${DateFormat('MMM dd, yyyy').format(DateTime.now())}'),
                if (startDate != null && endDate != null)
                  pw.Text('Period: ${DateFormat('MMM dd').format(startDate)} - ${DateFormat('MMM dd, yyyy').format(endDate)}'),
                pw.SizedBox(height: 4),
              ],
            ),
          ],
        ),
      ],
    );
  }

  static pw.Widget _buildAttendanceTable(List<PeriodAttendance> attendanceList) {
    final headers = ['Date', 'Student Name', 'Subject', 'Teacher', 'Status'];

    return pw.TableHelper.fromTextArray(
      headers: headers,
      data: attendanceList.map((record) {
        String formattedDate = record.date;
        try {
          final parsedDate = DateTime.parse(record.date).toLocal();
          formattedDate = DateFormat('dd MMM yyyy').format(parsedDate);
        } catch (e) {
          // Keep as is
        }

        return [
          formattedDate,
          record.studentName,
          record.subjectInfo?.name ?? 'N/A',
          record.teacherInfo?.name ?? 'N/A',
          record.status.toUpperCase(),
        ];
      }).toList(),
      border: pw.TableBorder.all(color: PdfColors.grey300),
      headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.white),
      headerDecoration: const pw.BoxDecoration(color: PdfColors.indigo600),
      cellHeight: 30,
      cellAlignments: {
        0: pw.Alignment.centerLeft,
        1: pw.Alignment.centerLeft,
        2: pw.Alignment.centerLeft,
        3: pw.Alignment.centerLeft,
        4: pw.Alignment.center,
      },
      cellStyle: const pw.TextStyle(fontSize: 10),
      rowDecoration: const pw.BoxDecoration(
        border: pw.Border(bottom: pw.BorderSide(color: PdfColors.grey300, width: 0.5)),
      ),
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
