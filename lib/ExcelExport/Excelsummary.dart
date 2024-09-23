import 'dart:io';
import 'package:gpspro/screens/CommonMethod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:syncfusion_flutter_xlsio/xlsio.dart';
import 'package:open_file/open_file.dart';
import 'package:gpspro/traccar_gennissi.dart';

class ExcelExporterSummary {
  Future<void> excelsummary( List<Summary> _summaryList,String VehiclesNo,String From,String To) async {
    final Workbook workbook = Workbook();
    final Worksheet sheet = workbook.worksheets[0];

    sheet.getRangeByName('A1').cellStyle.bold;
    sheet.getRangeByName('A2').cellStyle.bold;
    sheet.getRangeByName('A3').cellStyle.bold;
    // Merge cells in A1:B1 and set text
    // sheet.mergeCells(CellRange(1, 1, 1, 2)); // A1:B1
    sheet.getRangeByName('A1').setText("Report");
    sheet.getRangeByName('A2').setText("Device Name");
    sheet.getRangeByName('A3').setText("From");
    sheet.getRangeByName('A4').setText("To:");
    sheet.getRangeByName('B1').setText("Summary");
    sheet.getRangeByName('B2').setText(VehiclesNo);
    sheet.getRangeByName('B3').setText(formatTime(From));
    sheet.getRangeByName('B4').setText(formatTime(To));

    final headerStyle = workbook.styles.add('headerStyle');
    headerStyle.fontSize = 12;
    headerStyle.bold = true;
    headerStyle.hAlign = HAlignType.center;
    headerStyle.vAlign = VAlignType.center;

    sheet.getRangeByName('A6').setText("Distance");
    sheet.getRangeByName('A7').setText("Odometer Start");
    sheet.getRangeByName('A8').setText("Odometer End");
    sheet.getRangeByName('A9').setText("Avg Speed");
    sheet.getRangeByName('A10').setText("Max Speed");
    sheet.getRangeByName('A11').setText("Engine Hours");



    sheet.getRangeByName('A6').cellStyle=headerStyle;
    sheet.getRangeByName('A7').cellStyle=headerStyle;
    sheet.getRangeByName('A8').cellStyle=headerStyle;
    sheet.getRangeByName('A9').cellStyle=headerStyle;
    sheet.getRangeByName('A10').cellStyle=headerStyle;
    sheet.getRangeByName('A11').cellStyle=headerStyle;
    //

    sheet.getRangeByName('B6').setText(convertDistanceNOTKM(_summaryList.single.distance!));
    sheet.getRangeByName('B7').setText(convertDistanceNOTKM(_summaryList.single.startOdometer!));
    sheet.getRangeByName('B8').setText(convertDistanceNOTKM(_summaryList.single.endOdometer!));
    sheet.getRangeByName('B9').setText(convertSpeedNOTkM(_summaryList.single.averageSpeed!));
    sheet.getRangeByName('B10').setText(convertSpeedNOTkM(_summaryList.single.maxSpeed!));
    sheet.getRangeByName('B11').setText(convertDuration(_summaryList.single.engineHours!));



    // Auto-fit columns
    for (int colIndex = 1; colIndex <= 2; colIndex++) {
      sheet.autoFitColumn(colIndex);
    }

    final List<int> bytes = workbook.saveAsStream();
    workbook.dispose();

    try {
      final Directory appSupportDir = await getApplicationSupportDirectory();
      final String sanitizedVehicleNo = VehiclesNo.replaceAll(RegExp(r'[^\w\s]'), '_'); // Sanitize filename
      final String sanitizedDate = formatDate(From).replaceAll(RegExp(r'[^\w\s]'), '_'); // Sanitize date
      final Directory summaryDir = Directory('${appSupportDir.path}/Summary/$sanitizedVehicleNo');

      // Create directory if it doesn't exist
      if (!await summaryDir.exists()) {
        await summaryDir.create(recursive: true);
      }

      final String filename = '${summaryDir.path}/${sanitizedVehicleNo}-Summary-${sanitizedDate}.xlsx';
      final File file = File(filename);

      // Write bytes to file
      await file.writeAsBytes(bytes, flush: true);
      // Open the file
      OpenFile.open(filename);

      print('File saved and opened successfully: $filename');
    } catch (e) {
      print('Error exporting to Excel: $e');
    }
  }
}
