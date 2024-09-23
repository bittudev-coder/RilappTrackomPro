import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:gpspro/arguments/DeviceArguments.dart';
import 'package:gpspro/screens/CommonMethod.dart';
import 'package:gpspro/theme/CustomColor.dart';
import 'package:gpspro/widgets/CustomText.dart';

import '../../traccar_gennissi.dart';

class DeviceInfo extends StatefulWidget {
  @override
  _DeviceInfoState createState() => _DeviceInfoState();
}

class _DeviceInfoState extends State<DeviceInfo> {
  DeviceArguments? args;

  @override
  initState() {
    Timer.periodic(Duration(seconds: 1), (timer) {
      if (args != null) {
        timer.cancel();
        setState(() {

        });
      }
    });
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    args = ModalRoute.of(context)!.settings.arguments as DeviceArguments;

    return Scaffold(
      appBar: AppBar(
        title: Text(args!.name,
            style: TextStyle(color: CustomColor.secondaryColor)),
        iconTheme: IconThemeData(
          color: CustomColor.secondaryColor, //change your color here
        ),
      ),
      body: args != null ? SingleChildScrollView(child: loadDevice()) : Center(child: CircularProgressIndicator()),
    );
  }

  Widget loadDevice() {
    Device? d = args!.device;
    String iconPath = "images/marker_default_offline.png";

    // String status;
    //
    // if (d.status == "unknown") {
    //   status = 'static';
    // } else {
    //   status = d.status!;
    // }

    String _CARoFF_on() {
      try{
        if (args!.positionModel!.speed! >= 2.7 && d.status == 'online') {
          return "online";
        } else {
          return "offline";
        }
      }catch(e){}
      return "offline";
    }

    if (d.category != null) {
      iconPath = "images/marker_" + d.category! + "_" + _CARoFF_on() + ".png";
    } else {
      iconPath = "images/marker_default" + "_" + _CARoFF_on() + ".png";
    }
    return new Column(
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: new Container(
            child: new Container(
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
              child: Padding(
                padding: const EdgeInsets.only(left: 8),
                child: Center(
                  child:
                    Row(
                      children: <Widget>[
                    Container(
                      width: 45,
                      height: 70,
                      child: Image.asset(iconPath),
                    ),
                    Container(
                        padding: EdgeInsets.only(top: 5.0, left: 5.0),
                        child: CustomText(TxtName:
                          (d.status!).tr,Txtsize: 25,
                        )),
                                        ],
                    ),
                ),
              ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(left: 15,top: 6,bottom: 6),
          child: Container(child: CustomText(TxtName: "Basic Details", )),
        ),
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Container(
              child: positionDetails()),
        ),
        Padding(
          padding: const EdgeInsets.only(left: 15,top: 6,bottom: 6),
          child: Container(child: CustomText(TxtName: "Sensors", )),
        ),
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Container(
              child: sensorInfo()),
        ),
        SizedBox(height: 20,)
      ],
    );
  }

  Widget positionDetails() {
    if (args!.positionModel != null) {
      return Container(
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
        child: Column(children: <Widget>[
          Container(
              child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              Container(
                  padding: EdgeInsets.only(top: 10.0, left: 5.0),
                  child: Row(
                    children: <Widget>[
                      Container(
                        padding: EdgeInsets.only(left: 3.0),
                        child: Icon(Icons.bookmark,
                            color: CustomColor.primaryColor, size: 25.0),
                      ),
                      Container(
                        padding: EdgeInsets.only(left: 3.0),
                        child: Text(('deviceType').tr),
                      ),
                    ],
                  )),
              Container(
                  padding: EdgeInsets.only(top: 10.0, left: 5.0, right: 10.0),
                  child: Text(args!.device.model == null
                      ? ('noData').tr
                      : args!.device.model!)),
            ],
          )),
          SizedBox(height: 5.0),
          Container(
              child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              Container(
                  padding: EdgeInsets.only(top: 3.0, left: 5.0),
                  child: Row(
                    children: <Widget>[
                      Container(
                        padding: EdgeInsets.only(left: 3.0),
                        child: Icon(Icons.gps_fixed,
                            color: CustomColor.primaryColor, size: 25.0),
                      ),
                      Container(
                          padding: EdgeInsets.only(left: 3.0),
                          child: Text(('positionLatitude').tr)),
                    ],
                  )),
              Container(
                  padding: EdgeInsets.only(top: 10.0, left: 5.0, right: 10.0),
                  child: Text(args!.positionModel!.latitude!.toStringAsFixed(5))),
            ],
          )),
          SizedBox(height: 5.0),
          Container(
              child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              Container(
                  padding: EdgeInsets.only(top: 3.0, left: 5.0),
                  child: Row(
                    children: <Widget>[
                      Container(
                        padding: EdgeInsets.only(left: 3.0),
                        child: Icon(Icons.gps_fixed,
                            color: CustomColor.primaryColor, size: 25.0),
                      ),
                      Container(
                        padding: EdgeInsets.only(left: 3.0),
                        child: Text(('positionLongitude').tr),
                      ),
                    ],
                  )),
              Container(
                  padding: EdgeInsets.only(top: 10.0, left: 5.0, right: 10.0),
                  child: Text(args!.positionModel!.longitude!.toStringAsFixed(5))),
            ],
          )),
          SizedBox(height: 5.0),
          Container(
              child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              Container(
                  padding: EdgeInsets.only(top: 3.0, left: 5.0),
                  child: Row(
                    children: <Widget>[
                      Container(
                        padding: EdgeInsets.only(left: 3.0),
                        child: Icon(Icons.av_timer,
                            color: CustomColor.primaryColor, size: 25.0),
                      ),
                      Container(
                          padding: EdgeInsets.only(left: 3.0),
                          child: Text(('positionSpeed').tr))
                    ],
                  )),
              Container(
                  padding: EdgeInsets.only(top: 10.0, left: 5.0, right: 10.0),
                  child: Text(convertSpeed(args!.positionModel!.speed!))),
            ],
          )),
          SizedBox(height: 5.0),
          Container(
              child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              Container(
                  padding: EdgeInsets.only(top: 3.0, left: 5.0),
                  child: Row(
                    children: <Widget>[
                      Container(
                        padding: EdgeInsets.only(left: 3.0),
                        child: Icon(Icons.directions,
                            color: CustomColor.primaryColor, size: 25.0),
                      ),
                      Container(
                          padding: EdgeInsets.only(left: 3.0),
                          child: Text(('positionCourse').tr))
                    ],
                  )),
              Container(
                  padding: EdgeInsets.only(top: 10.0, left: 5.0, right: 10.0),
                  child: Text(convertCourse(args!.positionModel!.course!))),
            ],
          )),
          SizedBox(height: 5.0),
          args!.positionModel!.address != null
              ? Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: <Widget>[
                    Container(
                      padding: EdgeInsets.only(left: 5.0),
                      child: Icon(Icons.location_on_outlined,
                          color: CustomColor.primaryColor, size: 25.0),
                    ),
                    Expanded(
                      child: Column(
                          mainAxisAlignment: MainAxisAlignment.start,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(
                                padding: EdgeInsets.only(
                                    top: 10.0, left: 5.0, right: 0),
                                child: Text(
                                  utf8.decode(args!.positionModel!.address!.codeUnits),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                )),
                          ]),
                    )
                  ],
                )
              : new Container(),
          SizedBox(height: 5.0),
        ]),
      );
    } else {
      return Container(
        child: Text(('noData').tr),
      );
    }
  }

  Widget sensorInfo() {
    if (args!.positionModel != null) {
      Map<String, dynamic> attributes = args!.positionModel!.attributes!;
      List<Widget> keyList = [];

      for (var entry in attributes.entries) {
        if (entry.key == "totalDistance" || entry.key == "distance") {
          keyList.add(new Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              new Expanded(
                  child: Text((entry.key).tr)),
              new Expanded(child: Text(convertDistance(entry.value)))
            ],
          ));
        } else if (entry.key == "hours") {
          keyList.add(new Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              new Expanded(
                  child: Text((entry.key).tr)),
              new Expanded(child: Text(convertDuration(entry.value)))
            ],
          ));
        } else if (entry.key == "ignition") {
          keyList.add(new Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              new Expanded(
                  child: Text((entry.key).tr)),
              new Expanded(
                  child: Text((entry.value.toString().tr)))
            ],
          ));
        } else {
          keyList.add(new Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              new Expanded(
                  child: Text((entry.key).tr)),
              new Expanded(child: Text(entry.value.toString()))
            ],
          ));
        }
      }
      return new Container(
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
          child: Padding(
              padding: const EdgeInsets.all(10.0),
              child: Column(children: keyList)));
    } else {
      return new Container();
    }
  }
}
