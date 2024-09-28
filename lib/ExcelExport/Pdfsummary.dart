import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:open_file/open_file.dart';
import 'package:gpspro/traccar_gennissi.dart'; // Update path as necessary

import '../screens/CommonMethod.dart'; // Ensure this is correctly imported

class PdfExporterSummary {
  Future<void> pdfsummary( List<Summary> _summaryList,String VehiclesNo,String From,String To) async {
    final pdf = pw.Document();
    pdf.addPage(
      pw.Page(
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text('Report', style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 6),
              pw.Text('Summary', style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 10),
              pw.Text('Device Name: $VehiclesNo'),
              pw.Text('From: ${formatTime(From)}'),
              pw.Text('To: ${formatTime(To)}'),
              pw.SizedBox(height: 20),
              pw.Table(
                border: pw.TableBorder.all(),
                children: [
                  pw.TableRow(
                    decoration: pw.BoxDecoration(
                      color: PdfColors.grey300,
                    ),
                    children: [
                      pw.Text('Distance', style: pw.TextStyle(fontSize: 15, fontWeight: pw.FontWeight.bold)),
                      pw.Text('Odometer Start', style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold)),
                      pw.Text('Odometer End', style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold)),
                      pw.Text('Avg Speed', style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold)),
                      pw.Text('Max Speed', style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold)),
                      pw.Text('Engine Hours', style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold)),


          ],
                  ),
                    pw.TableRow(
                      children: [
                        pw.Text(convertDistanceNOTKM(_summaryList.single.distance!), style: pw.TextStyle(fontSize: 10)),
                        pw.Text(convertDistanceNOTKM(_summaryList.single.startOdometer!), style: pw.TextStyle(fontSize: 10)),
                        pw.Text(convertDistanceNOTKM(_summaryList.single.endOdometer!), style: pw.TextStyle(fontSize: 10)),
                        pw.Text(convertSpeedNOTkM(_summaryList.single.averageSpeed!), style: pw.TextStyle(fontSize: 10)),
                        pw.Text(convertSpeedNOTkM(_summaryList.single.maxSpeed!), style: pw.TextStyle(fontSize: 10)),
                        pw.Text(convertDuration(_summaryList.single.engineHours!), style: pw.TextStyle(fontSize: 10)),


                      ],
                    ),

                ],
              ),
            ],
          );
        },
      ),
    );

    try {
      final Directory appSupportDir = await getApplicationSupportDirectory();
      final String sanitizedVehicleNo = VehiclesNo.replaceAll(RegExp(r'[^\w\s]'), '_'); // Sanitize filename
      final String sanitizedDate = formatDate(From).replaceAll(RegExp(r'[^\w\s]'), '_'); // Sanitize date
      final Directory summaryDir = Directory('${appSupportDir.path}/Summary/$sanitizedVehicleNo');
      if (!await summaryDir.exists()) {
        await summaryDir.create(recursive: true);
      }

      final String filename = '${summaryDir.path}/${sanitizedVehicleNo}-Summary-${sanitizedDate}.pdf';
      final file = File(filename);
      await file.writeAsBytes(await pdf.save());
      OpenFile.open(filename);
    } catch (e) {
      print('Error exporting to PDF: $e');
    }
  }
}
