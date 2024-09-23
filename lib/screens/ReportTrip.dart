import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:gpspro/arguments/ReportArgumnets.dart';
import 'package:gpspro/screens/CommonMethod.dart';
import 'package:gpspro/theme/CustomColor.dart';

import '../../traccar_gennissi.dart';
import '../ExcelExport/Exceltrips.dart';
import '../ExcelExport/Pdftrips.dart';
import '../widgets/FloatingDownload.dart';

class ReportTripPage extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => new _ReportTripPageState();
}

class _ReportTripPageState extends State<ReportTripPage> {
  ReportArguments? args;
  List<Trip> _tripList = [];
  late StreamController<int> _postsController;
  late Timer _timer;
  bool isLoading = true;
  ExcelExporterTrips excelExporterTrips=new ExcelExporterTrips();
  @override
  void initState() {
    _postsController = new StreamController();
    getReport();
    super.initState();
  }

  getReport() {
    _timer = new Timer.periodic(Duration(seconds: 1), (timer) {
      if (args != null) {
        _timer.cancel();
        Traccar.getTrip(args!.id.toString(), args!.from, args!.to)
            .then((value) => {
                  _tripList.addAll(value!),
                  _postsController.add(1),
                  isLoading = false,
                  setState(() {})
                });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    args = ModalRoute.of(context)?.settings.arguments as ReportArguments;

    return Scaffold(
      appBar: AppBar(
        title: Text(args!.name,
            style: TextStyle(color: CustomColor.secondaryColor)),
        iconTheme: IconThemeData(
          color: CustomColor.secondaryColor, //change your color here
        ),
      ),
      body: StreamBuilder<int>(
          stream: _postsController.stream,
          builder: (BuildContext context, AsyncSnapshot<int> snapshot) {
            // if (snapshot.hasData) {
            //   return loadReport();
            // } else if (isLoading) {
            //   return Center(
            //     child: CircularProgressIndicator(),
            //   );
            // } else {
            //   return Center(
            //     child: Text(('noData').tr),
            //   );
            // }
            if (isLoading) {
              return Center(
                child: CircularProgressIndicator(),
              );
            } else if (_tripList.isEmpty) {
              return Center(
                child: Text(('noData')
                    .tr), // Replace with your actual localization logic
              );
            } else {
              return loadReport();
            }
          }),
      floatingActionButton: FloatingButtonWithMenu(
        onExcel: () {
          excelExporterTrips.exceltrips(_tripList, args!.name);
      },
        onPdf: () {
          PdfExporterTrips().pdfTrips(_tripList, args!.name);
        },),
    );
  }

  Widget loadReport() {
    return ListView.builder(
      itemCount: _tripList.length,
      itemBuilder: (context, index) {
        final trip = _tripList[index];
        return reportRow(trip);
      },
    );
  }

  Widget reportRow(Trip t) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6,horizontal: 2),
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
                          style: TextStyle(color:CustomColor.onColor)),
                      Text(("reportEndTime").tr,
                          style: TextStyle(color: Colors.red))
                    ],
                  ),
                  Divider(),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      Expanded(
                          child: Text(
                        formatTime(t.startTime!),
                        style: TextStyle(fontSize: 11),
                      )),
                      Expanded(
                          child: Text(
                        formatTime(t.endTime!),
                        style: TextStyle(fontSize: 11),
                      )),
                    ],
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      Expanded(
                          child: Text(
                        ("positionOdometer").tr +
                            ": " +
                            convertDistance(t.startOdometer!),
                        style: TextStyle(fontSize: 11),
                      )),
                      Expanded(
                          child: Text(
                        ("positionOdometer").tr +
                            ": " +
                            convertDistance(t.endOdometer!),
                        style: TextStyle(fontSize: 11),
                      )),
                    ],
                  ),
                  Divider(),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      Expanded(
                          child: Text(
                        ("positionDistance").tr +
                            ": " +
                            convertDistance(t.distance!),
                        style: TextStyle(fontSize: 11),
                      )),
                      Expanded(
                          child: Text(
                        ("reportAverageSpeed").tr +
                            ": " +
                            convertSpeed(t.averageSpeed!),
                        style: TextStyle(fontSize: 11),
                      )),
                      Expanded(
                          child: Text(
                        ("reportMaximumSpeed").tr +
                            ": " +
                            convertSpeed(t.maxSpeed!),
                        style: TextStyle(fontSize: 11),
                      )),
                    ],
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      Expanded(
                          child: Text(
                        ("reportDuration").tr +
                            ": " +
                            convertDuration(t.duration!),
                        style: TextStyle(fontSize: 11),
                      )),
                      // Expanded(
                      //     child: Text(
                      //   ('reportSpentFuel').tr + ": " + t.spentFuel.toString(),
                      //   style: TextStyle(fontSize: 11),
                      // )),
                    ],
                  ),
                  t.startAddress != null
                      ? Row(
                          children: [
                            Expanded(
                                child: Text(
                              ('reportStartAddress').tr +
                                  ": " +
                                  utf8.decode(t.startAddress!.codeUnits),
                              style: TextStyle(fontSize: 11),
                            )),
                          ],
                        )
                      : new Container(),
                  t.endAddress != null
                      ? Row(
                          children: [
                            Expanded(
                                child: Text(
                              ('reportEndAddress').tr +
                                  ": " +
                                  utf8.decode(t.endAddress!.codeUnits),
                              style: TextStyle(fontSize: 11),
                            )),
                          ],
                        )
                      : new Container(),
                ],
              ))),
    );
  }
}
