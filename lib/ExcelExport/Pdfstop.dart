import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:open_file/open_file.dart';
import 'package:gpspro/traccar_gennissi.dart'; // Update path as necessary
import '../screens/CommonMethod.dart'; // Ensure this is correctly imported

class PdfExporterStop {
  Future<void> pdfStop(List<Stop> _stopList, String vehiclesNo) async {
    final pdf = pw.Document();

    // Page size parameters
    final int maxRowsPerPage = 30; // Adjust based on your content size
    final int totalRows = _stopList.length;

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
                pw.Text('Stops', style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold)),
                pw.SizedBox(height: 10),
                pw.Text('Device Name: $vehiclesNo'),
                pw.Text('From: ${formatTime(_stopList.first.startTime!)}'),
                pw.Text('To: ${formatTime(_stopList.last.endTime!)}'),
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
                      pw.Text('Start Time', style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold)),
                      pw.Text('End Time', style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold)),
                      pw.Text('Address', style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold)),
                      pw.Text('Duration', style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold)),
                    ],
                  ),
                  // Add data rows for the current page
                  ..._stopList.sublist(startIndex, endIndex).map((stop) => pw.TableRow(
                    children: [
                      pw.Text(formatTime(stop.startTime!), style: pw.TextStyle(fontSize: 10)),
                      pw.Text(formatTime(stop.endTime!), style: pw.TextStyle(fontSize: 10)),
                      pw.Text(stop.address ?? '', style: pw.TextStyle(fontSize: 10)),
                      pw.Text(convertDuration(stop.duration!), style: pw.TextStyle(fontSize: 10)),
                    ],
                  )),
                ],
              ),
              if (numPages > 1) ...[
                pw.Spacer(),
                pw.Align(
                  alignment: pw.Alignment.bottomRight,
                  child: pw.Text(
                    'Page ${pageIndex + 1} of $numPages',
                    style: pw.TextStyle(fontSize: 10, color: PdfColors.grey),
                  ),
                ),
              ],
            ],
          ),
        ),
      );
    }

    try {
      final directory = await getApplicationSupportDirectory();
      final sanitizedVehiclesNo = vehiclesNo.replaceAll(RegExp(r'[^\w\s]'), '_'); // Sanitize filename
      final sanitizedDate = formatDate(_stopList.first.endTime!).replaceAll(RegExp(r'[^\w\s]'), '_'); // Sanitize date
      final path = '${directory.path}/$sanitizedVehiclesNo-Stops-$sanitizedDate.pdf';
      final file = File(path);

      // Create directory if it doesn't exist
      final fileDir = file.parent;
      if (!await fileDir.exists()) {
        await fileDir.create(recursive: true);
      }

      // Save the PDF file and log file details
      final pdfBytes = await pdf.save();
      await file.writeAsBytes(pdfBytes);
      print('PDF saved to: $path');
      print('File size: ${pdfBytes.length} bytes');

      // Attempt to open the file
      final result = await OpenFile.open(path);
      if (result.type != ResultType.done) {
        print('Error opening PDF file: ${result.message}');
      }
    } catch (e) {
      print('Error exporting to PDF: $e');
    }
  }
}
