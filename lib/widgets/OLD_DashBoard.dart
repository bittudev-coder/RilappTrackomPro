import 'dart:collection';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:gpspro/arguments/ReportEventArguments.dart';
import 'package:gpspro/screens/CommonMethod.dart';
import 'package:gpspro/storage/dataController/DataController.dart';
import 'package:gpspro/theme/CustomColor.dart';
import 'package:jiffy/jiffy.dart';
import 'package:percent_indicator/circular_percent_indicator.dart';

import '../../traccar_gennissi.dart';

class DashboardPage extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => new _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  late User user;
  List<Event> eventList = [];
  Map<int, Device> devices = new HashMap();
  var deviceId = [];
  bool isLoading = true;
  bool isEventLoading = true;
  late Locale myLocale;

  int online = 0, offline = 0, unknown = 0;

  @override
  initState() {
    super.initState();
  }

  void getDevice(DataController controller) {
    if (devices.isEmpty) {
      controller.devices.forEach((key, element) {
        devices.putIfAbsent(element.id!, () => element);
        deviceId.add(element.id.toString());
        if (element.status == "online") {
          online++;
        } else if (element.status == "offline") {
          offline++;
        } else if (element.status == "unknown") {
          unknown++;
        }
      });
      isLoading = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Text(('dashboard').tr,
              style: TextStyle(color: CustomColor.secondaryColor)),
        ),
        body: GetX<DataController>(
            init: DataController(),
            builder: (controller) {
              getDevice(controller);
              return loadView(controller);
            })


    );
  }

  Widget loadView(DataController controller) {
    return Column(
      children: <Widget>[
        Padding(padding: EdgeInsets.all(5)),
        Text(("deviceStatus").tr, style: TextStyle(fontSize: 17)),
        IntrinsicHeight(
          child: Container(
            width: MediaQuery.of(context).size.width / 1,
            child: chart(),
          ),
        ),
        new Divider(height: 0.1),
        Padding(padding: EdgeInsets.all(5)),
        Text(("recentEvents").tr, style: TextStyle(fontSize: 17)),
        Padding(padding: EdgeInsets.all(5)),
        controller.events.length > 0
            ? Expanded(child: loadEvents(controller))
            : Container()
      ],
    );
  }

  Widget loadEvents(DataController controller) {
    if (controller.events.isNotEmpty) {
      return ListView.builder(
          scrollDirection: Axis.vertical,
          itemCount: controller.events.length,
          itemBuilder: (context, index) {
            final eventItem = controller.events[index];
            String result;
            if (eventItem.attributes!.containsKey("result")) {
              result = eventItem.attributes!["result"];
            } else {
              result = "";
            }

            if (eventItem.type! == "alarm") {
              result = eventItem.attributes!["alarm"];
            }

            if (eventItem.type != "deviceOffline" &&
                eventItem.type != "deviceOnline" &&
                eventItem.type != "deviceUnknown") {
              return new InkWell(
                  onTap: () {
                    Navigator.pushNamed(context, "/notificationMap",
                        arguments: ReportEventArgument(
                            eventItem.id!,
                            eventItem.positionId!,
                            eventItem.attributes!,
                            eventItem.type!,
                            controller.devices[eventItem.deviceId]!.name!));
                  },
                  child: Card(
                    elevation: 3.0,
                    child: Column(
                      children: <Widget>[
                        eventItem.deviceId != 0
                            ? new ListTile(
                          title: Row(
                            mainAxisAlignment:
                            MainAxisAlignment.spaceBetween,
                            children: <Widget>[
                              new Text(
                                  controller
                                      .devices[eventItem.deviceId]!.name!,
                                  style: TextStyle(
                                    fontSize: 13.0,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis),
                              Container(
                                  width:
                                  MediaQuery.of(context).size.width *
                                      0.60,
                                  child: new Text(
                                      formatTime(eventItem.eventTime!),
                                      style: TextStyle(fontSize: 10))),
                            ],
                          ),
                          subtitle: eventItem.type! != " alarm"
                              ? new Text(
                            (eventItem.type!).tr + result,
                            style: TextStyle(fontSize: 12.0),
                            maxLines: 2,
                          )
                              : new Text(
                            eventItem.attributes!["alarm"],
                            style: TextStyle(fontSize: 12.0),
                            maxLines: 2,
                          ),
                        )
                            : new ListTile(
                          title: Row(
                            mainAxisAlignment:
                            MainAxisAlignment.spaceBetween,
                            children: <Widget>[
                              new Text(
                                (eventItem.type!).tr,
                                style: TextStyle(
                                    fontSize: 13.0,
                                    fontWeight: FontWeight.bold),
                                maxLines: 2,
                              ),
                              // new Text(eventItem.eventTime!,
                              //     style: TextStyle(fontSize: 10)),
                            ],
                          ),
                        )
                      ],
                    ),
                  ));
            } else {
              return Container();
            }
          });
    } else {
      return new Container();
    }
  }

  Widget chart() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: <Widget>[
        Container(
            width: MediaQuery.of(context).size.width / 8,
            child: CircularPercentIndicator(
              radius: 90.0,
              lineWidth: 13.0,
              animation: true,
              percent: 0.7,
              center: new Text(
                online.toString(),
                style:
                new TextStyle(fontWeight: FontWeight.bold, fontSize: 15.0),
              ),
              footer: new Text(
                ("online").tr,
                style:
                new TextStyle(fontWeight: FontWeight.bold, fontSize: 15.0),
              ),
              circularStrokeCap: CircularStrokeCap.round,
              progressColor: Colors.green,
            )),
        Container(
            width: MediaQuery.of(context).size.width / 8,
            child: CircularPercentIndicator(
              radius: 90.0,
              lineWidth: 13.0,
              animation: true,
              percent: 0.7,
              center: new Text(
                unknown.toString(),
                style:
                new TextStyle(fontWeight: FontWeight.bold, fontSize: 15.0),
              ),
              footer: new Text(
                ("unknown").tr,
                style:
                new TextStyle(fontWeight: FontWeight.bold, fontSize: 15.0),
              ),
              circularStrokeCap: CircularStrokeCap.round,
              progressColor: Colors.yellow,
            )),
        Container(
            width: MediaQuery.of(context).size.width / 8,
            child: CircularPercentIndicator(
              radius: 90.0,
              lineWidth: 13.0,
              animation: true,
              percent: 0.7,
              center: new Text(
                offline.toString(),
                style:
                new TextStyle(fontWeight: FontWeight.bold, fontSize: 15.0),
              ),
              footer: new Text(
                ("offline").tr,
                style:
                new TextStyle(fontWeight: FontWeight.bold, fontSize: 15.0),
              ),
              circularStrokeCap: CircularStrokeCap.round,
              progressColor: Colors.red,
            )),
      ],
    );
  }
}

class Task {
  String task;
  int taskvalue;
  Color colorval;

  Task(this.task, this.taskvalue, this.colorval);
}
