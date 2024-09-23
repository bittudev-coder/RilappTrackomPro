import 'dart:io';
import 'package:gpspro/screens/CommonMethod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:syncfusion_flutter_xlsio/xlsio.dart';
import 'package:open_file/open_file.dart';
import 'package:gpspro/traccar_gennissi.dart';

class ExcelExporterRoute {
  Future<void> excelroute(List<RouteReport> routeList,String VehiclesNo) async {
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
    sheet.getRangeByName('B1').setText("Route");
    sheet.getRangeByName('B2').setText(VehiclesNo);
    sheet.getRangeByName('B3').setText(formatTime(routeList.first.fixTime!));
    sheet.getRangeByName('B4').setText(formatTime(routeList.last.fixTime!));

    final headerStyle = workbook.styles.add('headerStyle');
    headerStyle.fontSize = 12;
    headerStyle.bold = true;
    headerStyle.hAlign = HAlignType.center;
    headerStyle.vAlign = VAlignType.center;
    headerStyle.backColor = '#BFBFBF';

    sheet.getRangeByName('A6').setText("Time");
    sheet.getRangeByName('B6').setText("Latitude");
    sheet.getRangeByName('C6').setText("Longitude");
    sheet.getRangeByName('D6').setText("Speed");
    sheet.getRangeByName('E6').setText("Address");
    sheet.getRangeByName('A6').cellStyle=headerStyle;
    sheet.getRangeByName('B6').cellStyle=headerStyle;
    sheet.getRangeByName('C6').cellStyle=headerStyle;
    sheet.getRangeByName('D6').cellStyle=headerStyle;
    sheet.getRangeByName('E6').cellStyle=headerStyle;


    // Add headers or any other data to the Excel sheet
    for (int i = 0; i < routeList.length; i++) {
      sheet.getRangeByIndex(i + 7, 1).setText(formatTime(routeList[i].fixTime!));
      sheet.getRangeByIndex(i + 7, 2).setValue(routeList[i].latitude);
      sheet.getRangeByIndex(i + 7, 3).setValue(routeList[i].longitude);
      sheet.getRangeByIndex(i + 7, 4).setValue(convertSpeedNOTkM(routeList[i].speed!));
      sheet.getRangeByIndex(i + 7, 5).setText(routeList[i].address ?? "");
      ;
    }

    // for (int colIndex = 1; colIndex <= 5; colIndex++) {
    //   sheet.getRangeByIndex(i + 2, colIndex).cellStyle
    //       .horizontalAlignment = HorizontalAlignType.center;
    // }
    //


    // Auto-fit columns
    // for (int colIndex = 1; colIndex <= 5; colIndex++) {
    //   sheet.autoFitColumn(colIndex);
    // }

    final List<int> bytes = workbook.saveAsStream();
    workbook.dispose();

    try {
      final Directory appSupportDir = await getApplicationSupportDirectory();
      final String sanitizedVehicleNo = VehiclesNo.replaceAll(RegExp(r'[^\w\s]'), '_'); // Sanitize filename
      final String sanitizedDate = formatDate(routeList.first.fixTime!).replaceAll(RegExp(r'[^\w\s]'), '_'); // Sanitize date
      final Directory summaryDir = Directory('${appSupportDir.path}/Events/$sanitizedVehicleNo');
      if (!await summaryDir.exists()) {
        await summaryDir.create(recursive: true);
      }

      final String filename = '${summaryDir.path}/${sanitizedVehicleNo}-Events-${sanitizedDate}.xlsx';

      final File file = File(filename);

      // Write bytes to file
      await file.writeAsBytes(bytes, flush: true);
      print('File saved to: $filename');

      // Open the file
      final result = await OpenFile.open(filename);
      if (result.type == ResultType.error) {
        print('Failed to open file: ${result.message}');
      } else {
        print('File opened successfully');
      }
    } catch (e) {
      print('Error exporting to Excel: $e');
    }
  }

}
