import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:gpspro/arguments/ReportArgumnets.dart';
import 'package:gpspro/screens/CommonMethod.dart';
import 'package:gpspro/theme/CustomColor.dart';
import '../../traccar_gennissi.dart';
import '../ExcelExport/Excelstop.dart';
import '../ExcelExport/Pdfstop.dart';
import '../widgets/FloatingDownload.dart';

class ReportStopPage extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => new _ReportStopPageState();
}

class _ReportStopPageState extends State<ReportStopPage> {
  late ReportArguments args;
  List<Stop> _stopList = [];
  late StreamController<int> _postsController;
  late Timer _timer;
  bool isLoading = true;
  ExcelExporterStops excelExporterStops=new ExcelExporterStops();

  @override
  void initState() {
    _postsController = new StreamController();
    getReport();
    super.initState();
  }

  getReport() {
    _timer = new Timer.periodic(Duration(seconds: 1), (timer) {
      // ignore: unnecessary_null_comparison
      if (args != null) {
        _timer.cancel();
        Traccar.getStops(args.id.toString(), args.from, args.to)
            .then((value) => {
                  _stopList.addAll(value!),
                  _postsController.add(1),
                  isLoading = false,
                  setState(() {}),
                });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    args = ModalRoute.of(context)!.settings.arguments as ReportArguments;

    return Scaffold(
      appBar: AppBar(
        title: Text(args.name,
            style: TextStyle(color: CustomColor.secondaryColor)),
        iconTheme: IconThemeData(
          color: CustomColor.secondaryColor, //change your color here
        ),
      ),
      body: StreamBuilder<int>(
        stream: _postsController.stream,
        builder: (BuildContext context, AsyncSnapshot<int> snapshot) {
          if (isLoading) {
            return Center(
              child: CircularProgressIndicator(),
            );
          } else if (_stopList.isEmpty) {
            return Center(
              child: Text(
                  ('noData').tr), // Replace with your actual localization logic
            );
          } else {
            return loadReport();
          }
        },
      ),
      floatingActionButton: FloatingButtonWithMenu(
        onExcel: () {
        excelExporterStops.excelstops(_stopList, args.name);
      }, onPdf: () {
        PdfExporterStop().pdfStop(_stopList, args.name);
      },),
    );
  }

  Widget loadReport() {
    return ListView.builder(
      itemCount: _stopList.length,
      itemBuilder: (context, index) {
        final stop = _stopList[index];
        return reportRow(stop);
      },
    );
  }

  Widget reportRow(Stop s) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6,horizontal: 8),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white, // Set the background color
          borderRadius: BorderRadius.circular(12.0),
          boxShadow: [
            BoxShadow(
              color: Colors.blue.withOpacity(0.5), // Blue shadow
              spreadRadius: 2,
              blurRadius: 8,
              offset: Offset(0, 4), // Shadow offset (horizontal, vertical)
            ),
          ],
        ),
        child: Container(
          padding: EdgeInsets.all(10),
          child: Column(
            children: <Widget>[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  Text(("reportStartTime").tr,
                      style: TextStyle(color: Colors.green)),
                  Text(("reportEndTime").tr, style: TextStyle(color: Colors.red)),
                ],
              ),
              Divider(),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  Expanded(
                    child: Text(
                      formatTime(s.startTime!),
                      style: TextStyle(fontSize: 11),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      formatTime(s.endTime!),
                      style: TextStyle(fontSize: 11),
                    ),
                  ),
                ],
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  Expanded(
                    child: Text(
                      ('positionOdometer').tr +
                          ": " +
                          convertDistance(s.startOdometer!),
                      style: TextStyle(fontSize: 11),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      ('positionOdometer').tr +
                          ": " +
                          convertDistance(s.endOdometer!),
                      style: TextStyle(fontSize: 11),
                    ),
                  ),
                ],
              ),
              Divider(),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  Expanded(
                    child: Text(
                      ('reportDuration').tr + ": " + convertDuration(s.duration!),
                      style: TextStyle(fontSize: 11),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      ('reportEngineHours').tr +
                          ": " +
                          convertDuration(s.engineHours!),
                      style: TextStyle(fontSize: 11),
                    ),
                  ),
                  // Expanded(
                  //   child: Text(
                  //     ('reportSpentFuel').tr + ": " + s.spentFuel.toString(),
                  //     style: TextStyle(fontSize: 11),
                  //   ),
                  // ),
                ],
              ),
              if (s.address != null)
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        ('positionAddress').tr +
                            ": " +
                            utf8.decode(s.address!.codeUnits),
                        style: TextStyle(fontSize: 11),
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }
}
