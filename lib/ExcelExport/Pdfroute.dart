import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:open_file/open_file.dart';
import 'package:gpspro/traccar_gennissi.dart'; // Update path as necessary

import '../screens/CommonMethod.dart'; // Ensure this is correctly imported

class PdfExporterRoute {
  Future<void> pdfRoute(List<RouteReport> routeList, String vehiclesNo) async {
    final pdf = pw.Document();

    // Page size parameters
    final int maxRowsPerPage = 30; // Adjust based on your content size
    final int totalRows = routeList.length;

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
                pw.Text('Route', style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold)),
                pw.SizedBox(height: 10),
                pw.Text('Device Name: $vehiclesNo'),
                pw.Text('From: ${formatTime(routeList.first.fixTime!)}'),
                pw.Text('To: ${formatTime(routeList.last.fixTime!)}'),
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
                      pw.Text('Fix Time', style: pw.TextStyle(fontSize: 10)),
                      pw.Text('Latitude', style: pw.TextStyle(fontSize: 10)),
                      pw.Text('Longitude', style: pw.TextStyle(fontSize: 10)),
                      pw.Text('Speed', style: pw.TextStyle(fontSize: 10)),
                      pw.Text('Address', style: pw.TextStyle(fontSize: 10)),
                    ],
                  ),
                  // Add data rows for the current page
                  ...routeList.sublist(startIndex, endIndex).map((route) => pw.TableRow(
                    children: [
                      pw.Text(formatTime(route.fixTime!), style: pw.TextStyle(fontSize: 10)),
                      pw.Text((route.latitude!).toString(), style: pw.TextStyle(fontSize: 10)),
                      pw.Text((route.longitude!).toString(), style: pw.TextStyle(fontSize: 10)),
                      pw.Text(convertSpeedNOTkM(route.speed!), style: pw.TextStyle(fontSize: 10)),
                      pw.Text(route.address ?? "", style: pw.TextStyle(fontSize: 10)),
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
      final sanitizedDate = formatDate(routeList.first.fixTime!).replaceAll(RegExp(r'[^\w\s]'), '_'); // Sanitize date
      final path = '${directory.path}/$sanitizedVehiclesNo-Route-$sanitizedDate.pdf';
      final file = File(path);
      await file.writeAsBytes(await pdf.save());
      OpenFile.open(path);
    } catch (e) {
      print('Error exporting to PDF: $e');
    }
  }
}
