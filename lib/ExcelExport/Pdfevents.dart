import 'dart:io';
import 'package:get/get.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:open_file/open_file.dart';
import 'package:gpspro/traccar_gennissi.dart'; // Update path as necessary

import '../screens/CommonMethod.dart'; // Ensure this is correctly imported

class PdfExporterEvent {
  Future<void> pdfEvent(List<Event> _eventList, String vehiclesNo) async {
    final pdf = pw.Document();

    // Page size parameters
    final int maxRowsPerPage = 30; // Adjust based on your content size
    final int totalRows = _eventList.length;

    // Calculate number of pages needed
    final int numPages = (totalRows / maxRowsPerPage).ceil();

    for (int pageIndex = 0; pageIndex < numPages; pageIndex++) {
      final int startIndex = pageIndex * maxRowsPerPage;
      final int endIndex = (startIndex + maxRowsPerPage) > totalRows ? totalRows : (startIndex + maxRowsPerPage);

      pdf.addPage(
        pw.Page(
          build: (pw.Context context) => pw.Column(
            children: [
              if (pageIndex == 0) ...[
                pw.Text('Report', style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold)),
                pw.SizedBox(height: 6),
                pw.Text('Events', style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold)),
                pw.SizedBox(height: 10),
                pw.Text('Device Name: $vehiclesNo'),
                pw.Text('From: ${formatTime(_eventList.first.eventTime!)}'),
                pw.Text('To: ${formatTime(_eventList.last.eventTime!)}'),
                pw.SizedBox(height: 20),
              ],
              pw.Table(
                border: pw.TableBorder.all(), // Optional: adds borders to the table
                children: [
                  // Add header row (same for each page)
                  pw.TableRow(
                    decoration: pw.BoxDecoration(
                      color: PdfColors.grey300,
                    ),
                    children: [
                      pw.Text('Time', style: pw.TextStyle(fontSize: 10)),
                      pw.Text('Event', style: pw.TextStyle(fontSize: 10)),

                    ],
                  ),
                  // Add data rows for the current page
                  ..._eventList.sublist(startIndex, endIndex).map((event) => pw.TableRow(
                    children: [
                      pw.Text(formatTime(event.eventTime!), style: pw.TextStyle(fontSize: 10)),
                      pw.Text((event.type)!.tr, style: pw.TextStyle(fontSize: 10)),
                    ],
                  )),
                ],
              ),
            ],
          ),
        ),
      );
    }

    try {
      final directory = await getApplicationSupportDirectory();
      final sanitizedVehiclesNo = vehiclesNo.replaceAll(RegExp(r'[^\w\s]'), '_'); // Sanitize filename
      final sanitizedDate = formatDate(_eventList.first.eventTime!).replaceAll(RegExp(r'[^\w\s]'), '_'); // Sanitize date
      final path = '${directory.path}/$sanitizedVehiclesNo-Events-$sanitizedDate.pdf';
      final file = File(path);
      await file.writeAsBytes(await pdf.save());
      OpenFile.open(path);
    } catch (e) {
      print('Error exporting to PDF: $e');
    }
  }
}
