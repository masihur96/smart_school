import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class TeacherAttendancePdfHelper {
  static Future<void> generateAttendancePdf({
    required List<dynamic> attendanceList,
    DateTime? startDate,
    DateTime? endDate,
    required String schoolName,
  }) async {
    final pdf = pw.Document();
    
    // Use a standard font to avoid null-check issues in default font lookup
    final font = await PdfGoogleFonts.robotoRegular();
    final boldFont = await PdfGoogleFonts.robotoBold();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        theme: pw.ThemeData.withFont(
          base: font,
          bold: boldFont,
        ),
        build: (pw.Context context) {
          return [
            _buildHeader(
              schoolName: schoolName,
              startDate: startDate,
              endDate: endDate,
            ),
            pw.SizedBox(height: 20),
            _buildAttendanceTable(attendanceList),
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
          'Teacher Attendance Report',
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
              ],
            ),
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

  static pw.Widget _buildAttendanceTable(List<dynamic> attendanceList) {
    final headers = ['Date', 'Teacher Name', 'In Time', 'Out Time', 'Status'];

    return pw.TableHelper.fromTextArray(
      headers: headers,
      data: attendanceList.map((record) {
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
           } catch(e) {
              formattedInTime = inTime.toString();
           }
        }

        if (outTime != null && outTime.toString().isNotEmpty) {
           try {
              final parsedOut = DateTime.parse(outTime.toString()).toLocal();
              formattedOutTime = DateFormat('hh:mm a').format(parsedOut);
           } catch(e) {
              formattedOutTime = outTime.toString();
           }
        }

        final teacherName = record['teacher']?['name'] ??
            record['teacherName'] ??
            record['name'] ??
            'Unknown Teacher';
            
        final status = record['status']?.toString().toUpperCase() ?? 'N/A';

        return [
          formattedDate,
          teacherName,
          formattedInTime,
          formattedOutTime,
          status,
        ];
      }).toList(),
      border: pw.TableBorder.all(color: PdfColors.grey300),
      headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.white),
      headerDecoration: const pw.BoxDecoration(color: PdfColors.indigo600),
      cellHeight: 30,
      cellAlignments: {
        0: pw.Alignment.centerLeft,
        1: pw.Alignment.centerLeft,
        2: pw.Alignment.center,
        3: pw.Alignment.center,
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
