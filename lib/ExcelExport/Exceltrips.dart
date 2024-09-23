import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:syncfusion_flutter_xlsio/xlsio.dart';
import 'package:open_file/open_file.dart';
import 'package:gpspro/traccar_gennissi.dart';

import '../screens/CommonMethod.dart'; // Ensure this import is correct

class ExcelExporterTrips {
  Future<void> exceltrips(List<Trip> _tripList, String VehiclesNo) async {
    final Workbook workbook = Workbook();
    final Worksheet sheet = workbook.worksheets[0];

    sheet.getRangeByName('A1').cellStyle.bold = true;
    sheet.getRangeByName('A2').cellStyle.bold = true;
    sheet.getRangeByName('A3').cellStyle.bold = true;
    sheet.getRangeByName('A1').setText("Report");
    sheet.getRangeByName('A2').setText("Device Name");
    sheet.getRangeByName('A3').setText("From");
    sheet.getRangeByName('A4').setText("To:");
    sheet.getRangeByName('B1').setText("Trips");
    sheet.getRangeByName('B2').setText(VehiclesNo);
    sheet.getRangeByName('B3').setText(formatTime(_tripList.first.startTime!));
    sheet.getRangeByName('B4').setText(formatTime(_tripList.last.endTime!));

    final headerStyle = workbook.styles.add('headerStyle');
    headerStyle.fontSize = 12;
    headerStyle.bold = true;
    headerStyle.hAlign = HAlignType.center;
    headerStyle.vAlign = VAlignType.center;
    headerStyle.backColor = '#BFBFBF';

    sheet.getRangeByName('A6').setText("Start Time");
    sheet.getRangeByName('B6').setText("Start Address");
    sheet.getRangeByName('C6').setText("End Time");
    sheet.getRangeByName('D6').setText("End Address");
    sheet.getRangeByName('E6').setText("Duration");
    sheet.getRangeByName('F6').setText("Distance");
    sheet.getRangeByName('G6').setText("Avg Speed");
    sheet.getRangeByName('H6').setText("Max Speed");
    sheet.getRangeByName('A6').cellStyle = headerStyle;
    sheet.getRangeByName('B6').cellStyle = headerStyle;
    sheet.getRangeByName('C6').cellStyle = headerStyle;
    sheet.getRangeByName('D6').cellStyle = headerStyle;
    sheet.getRangeByName('E6').cellStyle = headerStyle;
    sheet.getRangeByName('F6').cellStyle = headerStyle;
    sheet.getRangeByName('G6').cellStyle = headerStyle;
    sheet.getRangeByName('H6').cellStyle = headerStyle;

    // Add trip data to the Excel sheet
    for (int i = 0; i < _tripList.length; i++) {
      sheet.getRangeByIndex(i + 7, 1).setText(formatTime(_tripList[i].startTime!));
      sheet.getRangeByIndex(i + 7, 2).setValue(_tripList[i].startAddress);
      sheet.getRangeByIndex(i + 7, 3).setText(formatTime(_tripList[i].endTime!));
      sheet.getRangeByIndex(i + 7, 4).setValue(_tripList[i].endAddress);
      sheet.getRangeByIndex(i + 7, 5).setText(convertDuration(_tripList[i].duration!));
      sheet.getRangeByIndex(i + 7, 6).setValue(convertDistanceNOTKM(_tripList[i].distance!));
      sheet.getRangeByIndex(i + 7, 7).setValue(convertSpeedNOTkM(_tripList[i].averageSpeed!));
      sheet.getRangeByIndex(i + 7, 8).setText(convertSpeedNOTkM(_tripList[i].maxSpeed!));
    }

    // Auto-fit columns
    for (int colIndex = 1; colIndex <= 8; colIndex++) {
      sheet.autoFitColumn(colIndex);
    }

    final List<int> bytes = workbook.saveAsStream();
    workbook.dispose();

    try {
      final Directory appSupportDir = await getApplicationSupportDirectory();
      final String sanitizedVehicleNo = VehiclesNo.replaceAll(RegExp(r'[^\w\s]'), '_'); // Sanitize filename
      final String sanitizedDate = formatDate(_tripList.first.startTime!).replaceAll(RegExp(r'[^\w\s]'), '_'); // Sanitize date
      final String path = '${appSupportDir.path}/Trips/$sanitizedVehicleNo';
      final Directory summaryDir = Directory(path);

      // Create directory if it doesn't exist
      if (!await summaryDir.exists()) {
        await summaryDir.create(recursive: true);
      }

      final String filename = '$path/${sanitizedVehicleNo}-Trips-${sanitizedDate}.xlsx';
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
