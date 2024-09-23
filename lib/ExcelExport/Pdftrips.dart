import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:open_file/open_file.dart';
import 'package:gpspro/traccar_gennissi.dart'; // Update path as necessary
import '../screens/CommonMethod.dart'; // Ensure this is correctly imported

class PdfExporterTrips {
  Future<void> pdfTrips(List<Trip> _tripList, String vehiclesNo) async {
    final pdf = pw.Document();

    // Page size parameters
    final int maxRowsPerPage = 30; // Adjust based on your content size
    final int totalRows = _tripList.length;

    // Calculate number of pages needed
    final int numPages = (totalRows / maxRowsPerPage).ceil();

    for (int pageIndex = 0; pageIndex < numPages; pageIndex++) {
      final int startIndex = pageIndex * maxRowsPerPage;
      final int endIndex = (startIndex + maxRowsPerPage) > totalRows ? totalRows : (startIndex + maxRowsPerPage);

      pdf.addPage(
        pw.Page(
          build: (pw.Context context) => pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              if (pageIndex == 0) ...[
                pw.Text('Report', style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold)),
                pw.SizedBox(height: 6),
                pw.Text('Trips', style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold)),
                pw.SizedBox(height: 10),
                pw.Text('Device Name: $vehiclesNo'),
                pw.Text('From: ${formatTime(_tripList.first.startTime!)}'),
                pw.Text('To: ${formatTime(_tripList.last.endTime!)}'),
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
                      pw.Text('Start Address', style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold)),
                      pw.Text('End Time', style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold)),
                      pw.Text('End Address', style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold)),
                      pw.Text('Duration', style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold)),
                      pw.Text('Distance', style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold)),
                      pw.Text('Avg Speed', style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold)),
                      pw.Text('Max Speed', style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold)),
                    ],
                  ),
                  // Add data rows for the current page
                  ..._tripList.sublist(startIndex, endIndex).map((trip) => pw.TableRow(
                    children: [
                      pw.Text(formatTime(trip.startTime!), style: pw.TextStyle(fontSize: 10)),
                      pw.Text(utf8.decode(trip.startAddress!.codeUnits), style: pw.TextStyle(fontSize: 10)),
                      pw.Text(formatTime(trip.endTime!), style: pw.TextStyle(fontSize: 10)),
                      pw.Text(utf8.decode(trip.endAddress!.codeUnits), style: pw.TextStyle(fontSize: 10)),
                      pw.Text(convertDuration(trip.duration!), style: pw.TextStyle(fontSize: 10)),
                      pw.Text(convertDistanceNOTKM(trip.distance!), style: pw.TextStyle(fontSize: 10)),
                      pw.Text(convertSpeedNOTkM(trip.averageSpeed!), style: pw.TextStyle(fontSize: 10)),
                      pw.Text(convertSpeedNOTkM(trip.maxSpeed!), style: pw.TextStyle(fontSize: 10)),
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
      final sanitizedDate = formatDate(_tripList.first.endTime!).replaceAll(RegExp(r'[^\w\s]'), '_'); // Sanitize date
      final path = '${directory.path}/$sanitizedVehiclesNo-Trips-$sanitizedDate.pdf';
      final file = File(path);
      await file.writeAsBytes(await pdf.save());
      OpenFile.open(path);
    } catch (e) {
      print('Error exporting to PDF: $e');
    }
  }
}
