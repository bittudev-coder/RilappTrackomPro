import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:syncfusion_flutter_xlsio/xlsio.dart';
import 'package:open_file/open_file.dart';
import 'package:gpspro/traccar_gennissi.dart';

import '../screens/CommonMethod.dart'; // Ensure this import is correct

class ExcelExporterStops {
  Future<void> excelstops(List<Stop> _stopList, String VehiclesNo) async {
    final Workbook workbook = Workbook();
    final Worksheet sheet = workbook.worksheets[0];

    // Set bold style for header cells
    final headerStyle = workbook.styles.add('headerStyle');
    headerStyle.fontSize = 12;
    headerStyle.bold = true;
    headerStyle.hAlign = HAlignType.center;
    headerStyle.vAlign = VAlignType.center;
    headerStyle.backColor = '#BFBFBF';

    // Set titles and headers
    sheet.getRangeByName('A1').setText("Report");
    sheet.getRangeByName('A2').setText("Device Name");
    sheet.getRangeByName('A3').setText("From");
    sheet.getRangeByName('A4').setText("To:");
    sheet.getRangeByName('B1').setText("Stops");
    sheet.getRangeByName('B2').setText(VehiclesNo);
    sheet.getRangeByName('B3').setText(formatTime(_stopList.first.startTime!));
    sheet.getRangeByName('B4').setText(formatTime(_stopList.last.endTime!));

    sheet.getRangeByName('A6').setText("Start Time");
    sheet.getRangeByName('B6').setText("End Time");
    sheet.getRangeByName('C6').setText("Address");
    sheet.getRangeByName('D6').setText("Duration");

    // Apply header style
    sheet.getRangeByName('A6').cellStyle = headerStyle;
    sheet.getRangeByName('B6').cellStyle = headerStyle;
    sheet.getRangeByName('C6').cellStyle = headerStyle;
    sheet.getRangeByName('D6').cellStyle = headerStyle;

    // Add data to the sheet
    for (int i = 0; i < _stopList.length; i++) {
      final stop = _stopList[i];
      sheet.getRangeByIndex(i + 7, 1).setText(formatTime(stop.startTime!));
      sheet.getRangeByIndex(i + 7, 2).setText(formatTime(stop.endTime!));
      sheet.getRangeByIndex(i + 7, 3).setText(stop.address ?? ''); // Use default if address is null
      sheet.getRangeByIndex(i + 7, 4).setText(convertDuration(stop.duration!));
    }

    // Auto-fit columns
    for (int colIndex = 1; colIndex <= 4; colIndex++) {
      sheet.autoFitColumn(colIndex);
    }

    final List<int> bytes = workbook.saveAsStream();
    workbook.dispose();

    try {
      final Directory appSupportDir = await getApplicationSupportDirectory();
      final String sanitizedVehicleNo = VehiclesNo.replaceAll(RegExp(r'[^\w\s]'), '_'); // Sanitize filename
      final String sanitizedDate = formatDate(_stopList.first.startTime!).replaceAll(RegExp(r'[^\w\s]'), '_'); // Sanitize date
      final String path = '${appSupportDir.path}/Stops/$sanitizedVehicleNo';
      final Directory summaryDir = Directory(path);

      // Create directory if it doesn't exist
      if (!await summaryDir.exists()) {
        await summaryDir.create(recursive: true);
      }

      final String filename = '$path/${sanitizedVehicleNo}-Stops-${sanitizedDate}.xlsx';
      final File file = File(filename);

      // Write bytes to file
      await file.writeAsBytes(bytes, flush: true);
      OpenFile.open(filename);

      print('File saved and opened successfully: $filename');
    } catch (e) {
      print('Error exporting to Excel: $e');
    }
  }
}
