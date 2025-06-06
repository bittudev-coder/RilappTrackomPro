import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:gpspro/arguments/ReportArgumnets.dart';
import 'package:gpspro/arguments/ReportEventArguments.dart';
import 'package:gpspro/screens/CommonMethod.dart';
import 'package:gpspro/theme/CustomColor.dart';

import '../../traccar_gennissi.dart';
import '../ExcelExport/Excelevent.dart';
import '../ExcelExport/Pdfevents.dart';
import '../widgets/FloatingDownload.dart';

class ReportEventPage extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => new _ReportEventPageState();
}

class _ReportEventPageState extends State<ReportEventPage> {
  late ReportArguments args;
  List<Event> _eventList = [];
  late StreamController<int> _postsController;
  late Timer _timer;
  bool isLoading = true;
  late GoogleMapController mapController;
  ExcelExporterEvent excelExporterEvent=new ExcelExporterEvent();

  @override
  void initState() {
    _postsController = new StreamController();
    getReport();
    super.initState();
  }

  void check(CameraUpdate u, GoogleMapController c) async {
    c.animateCamera(u);
    mapController.animateCamera(u);
    LatLngBounds l1 = await c.getVisibleRegion();
    LatLngBounds l2 = await c.getVisibleRegion();
    if (l1.southwest.latitude == -90 || l2.southwest.latitude == -90)
      check(u, c);
  }

  getReport() {
    _timer = new Timer.periodic(Duration(seconds: 1), (timer) {
      // ignore: unnecessary_null_comparison
      if (args != null) {
        _timer.cancel();
        Traccar.getEvents(args.id.toString(), args.from, args.to)
            .then((value) => {
                  _eventList.addAll(value!),
                  _postsController.add(1),
                  isLoading = false,
                  setState(() {})
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
            // if (snapshot.hasData) {
            //   return loadReportView();
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
            } else if (_eventList.isEmpty) {
              return Center(
                child: Text(('noData')
                    .tr), // Replace with your actual localization logic
              );
            } else {
              return loadReportView();
            }
          }),
      floatingActionButton: FloatingButtonWithMenu(onExcel: () {
        excelExporterEvent.excelEvent(_eventList, args.name);
      }, onPdf: () {
        PdfExporterEvent().pdfEvent(_eventList, args.name);
      },)
    );
  }

  Widget loadReportView() {
    // Filter out events with type "deviceOnline" or "deviceOffline"
    List<Event> filteredEvents = _eventList
        .where((event) =>
            event.type != "deviceOnline" && event.type != "deviceOffline")
        .toList();

    return ListView.builder(
      itemCount: filteredEvents.length,
      itemBuilder: (context, index) {
        final event = filteredEvents[index];
        return reportRow(event, context);
      },
    );
  }

  Widget reportRow(Event e, BuildContext context) {
    return InkWell(
        onTap: () {
          Navigator.pushNamed(context, "/eventMap",
              arguments: ReportEventArgument(
                  e.id!, e.positionId!, e.attributes!, e.type!, args.name));
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4,horizontal: 8),
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
                  padding: EdgeInsets.all(5),
                  child: Column(
                    children: <Widget>[
                      Row(
                        children: [
                          Container(
                              padding: EdgeInsets.only(top: 3.0, left: 5.0),
                              child: Row(
                                children: <Widget>[
                                  Container(
                                    padding: EdgeInsets.only(left: 3.0),
                                    child: Icon(Icons.event_note,
                                        color: CustomColor.primaryColor,
                                        size: 20.0),
                                  ),
                                ],
                              )),
                          Container(
                              padding: EdgeInsets.only(
                                  top: 5.0, left: 5.0, right: 10.0),
                              child: Text((e.type!).tr)),
                        ],
                      ),
                      Row(
                        children: [
                          Container(
                              padding: EdgeInsets.only(top: 3.0, left: 5.0),
                              child: Row(
                                children: <Widget>[
                                  Container(
                                    padding: EdgeInsets.only(left: 5.0),
                                    child: Icon(Icons.access_time_outlined,
                                        color: CustomColor.primaryColor,
                                        size: 15.0),
                                  ),
                                ],
                              )),
                          Container(
                              padding: EdgeInsets.only(
                                  top: 5.0, left: 5.0, right: 10.0),
                              child: Text(
                                formatTime(e.eventTime!),
                                style: TextStyle(fontSize: 11),
                              )),
                        ],
                      ),
                    ],
                  ))),
        ));
  }


}
