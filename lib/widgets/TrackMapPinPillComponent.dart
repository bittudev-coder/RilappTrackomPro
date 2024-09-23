import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:gpspro/arguments/DeviceArguments.dart';
import 'package:gpspro/model/PinInformation.dart';
import 'package:gpspro/theme/CustomColor.dart';
import 'package:jiffy/jiffy.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../traccar_gennissi.dart';
import '../screens/CommonMethod.dart';
import 'CustomText.dart';

// ignore: must_be_immutable
class TrackMapPinPillComponent extends StatefulWidget {
  double pinPillPosition;
  PinInformation currentlySelectedPin;

  TrackMapPinPillComponent(
      {required this.pinPillPosition, required this.currentlySelectedPin});

  @override
  State<StatefulWidget> createState() => TrackMapPinPillComponentState();
}

class TrackMapPinPillComponentState extends State<TrackMapPinPillComponent> {

  @override
  Widget build(BuildContext context) {
    String _extractSpeed() {
      String speedString = widget.currentlySelectedPin.speed ?? '0 km/hr'; // Default if null
      List<String> parts = speedString.split(' ');
      return parts.isNotEmpty ? parts[0] : '0'; // Returns '66'
    }

    String _extractUnit() {
      String speedString = widget.currentlySelectedPin.speed ?? '0 km/hr'; // Default if null
      List<String> parts = speedString.split(' ');
      return parts.length > 1 ? parts[1] : 'km/hr'; // Returns 'km/hr'
    }
    String Categ = "null";
    if (widget.currentlySelectedPin.device?.category != null) {
      Categ = widget.currentlySelectedPin.device!.category!;
    }
    String _CARoFF_on() {
      double speed = double.tryParse(_extractSpeed()) ?? 0.0; // Default to 0.0 if parsing fails
      if (speed >= 2.7 && widget.currentlySelectedPin.status == 'online') {
        return "online";
      } else {
        return "offline";
      }
    }
    String fLastUpdate = ('noData').tr;
    if (widget.currentlySelectedPin.device?.lastUpdate != null) {
      fLastUpdate = formatTime(widget.currentlySelectedPin.device!.lastUpdate!);
    }
    Color color;

    if (widget.currentlySelectedPin.status == "online") {
      color = Colors.green;
    } else if (widget.currentlySelectedPin.status == "unknown") {
      color = Colors.yellow;
    } else {
      color = Colors.red;
    }

    Widget addressLoad(String lat, String lng) {
      return FutureBuilder<String>(
          future: Traccar.geocode(lat, lng),
          builder: (context, AsyncSnapshot<String> snapshot) {
            if (snapshot.hasData) {
              return Text(
                snapshot.data!.replaceAll('"', ''),
                style: TextStyle(
                    color: Colors.black,
                    fontFamily: "Popins",
                    fontSize: 12,
                    fontWeight: FontWeight.bold),

              );
            } else {
              return Container();
            }
          });
    }

    return Positioned(
      bottom: 0,
      right: 0,
      left: 0,
      child: Align(
        alignment: Alignment.bottomCenter,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Expanded(
              child: Container(
                margin: EdgeInsets.fromLTRB(6, 0, 6, 20),
                padding: EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12.0),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.blue.withOpacity(0.5),
                      spreadRadius: 2,
                      blurRadius: 8,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          width: 45,
                          height: 70,
                          decoration: BoxDecoration(
                            color: Colors.blue.shade50,
                            borderRadius: BorderRadius.circular(12.0),
                          ),
                          child: Image.asset('images/marker_${Categ}_${_CARoFF_on()}.png'),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // CustomText(TxtName: utf8.decode(widget.currentlySelectedPin.name?.codeUnits ?? []),
                              //
                              // ),

                              Row(
                                children: <Widget>[
                                  Padding(padding: EdgeInsets.fromLTRB(5, 0, 0, 0)),
                                  Container(
                                    width: MediaQuery.of(context).size.width * 0.40,
                                    child: Text(utf8.decode(widget.currentlySelectedPin.name?.codeUnits ?? []),
                                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  )
                                ],
                              ),
                              Row(
                                children: [
                                  Icon(Icons.timelapse, color: Colors.grey),
                                  Text(widget.currentlySelectedPin.device?.lastUpdate != null
                                      ? Jiffy.parse(fLastUpdate, pattern: 'dd-MM-yyyy hh:mm:ss aa').fromNow()
                                      : "-"),
                                ],
                              ),
                              Row(
                                children: [
                                  Icon(Icons.access_time, color: Colors.grey),
                                  Text('${widget.currentlySelectedPin.updatedTime}', style: TextStyle(fontSize: 12)),
                                ],
                              ),
                            ],
                          ),
                        ),
                        Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Padding(padding: EdgeInsets.fromLTRB(5, 0, 0, 0)),
                            InkWell(
                              child: Icon(Icons.info, color: CustomColor.primaryColor, size: 35.0),
                              onTap: () {
                                Navigator.pushNamed(context, "/deviceInfo",
                                    arguments: DeviceArguments(
                                        widget.currentlySelectedPin.deviceId!,
                                        widget.currentlySelectedPin.name!,
                                        widget.currentlySelectedPin.device!,
                                        widget.currentlySelectedPin.positionModel
                                    ));
                              },
                            ),
                            Padding(padding: EdgeInsets.fromLTRB(5, 0, 0, 0)),
                            InkWell(
                              child: Icon(Icons.directions, color: CustomColor.primaryColor, size: 35.0),
                              onTap: () async {
                                String origin = '${widget.currentlySelectedPin.location?.latitude ?? ''},${widget.currentlySelectedPin.location?.longitude ?? ''}';
                                var url = '';
                                var urlAppleMaps = '';
                                if (Platform.isAndroid) {
                                  String query = Uri.encodeComponent(origin);
                                  url = "https://www.google.com/maps/search/?api=1&query=$query";
                                  await launch(url);
                                } else {
                                  urlAppleMaps = 'https://maps.apple.com/?q=$origin';
                                  url = "comgooglemaps://?saddr=&daddr=$origin&directionsmode=driving";
                                  if (await canLaunch(url)) {
                                    await launch(url);
                                  } else if (await canLaunch(urlAppleMaps)) {
                                    await launch(urlAppleMaps);
                                  } else {
                                    throw 'Could not launch $url';
                                  }
                                }
                              },
                            ),
                            // Padding(padding: EdgeInsets.fromLTRB(5, 0, 0, 0)),
                            // InkWell(
                            //   child: Image.asset("images/engine.png", width: 30, height: 30),
                            //   onTap: () {
                            //     _showEngineOnOFF();
                            //   },
                            // ),
                          ],
                        ),
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Row(
                            children: [
                              Container(
                                width: 50,
                                height: 50,
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.blue.withOpacity(0.5),
                                      spreadRadius: 2,
                                      blurRadius: 8,
                                      offset: Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: Center(
                                  child: Padding(
                                    padding: const EdgeInsets.all(8.0),
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        CustomText(TxtName: _extractSpeed(), Txtsize: 18),
                                        CustomText(TxtName: _extractUnit(), Txtsize: 10),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    widget.currentlySelectedPin.address != null ? Row(
                      children: <Widget>[
                        Icon(Icons.location_on_rounded, color: CustomColor.primaryColor, size: 20.0),
                        Padding(padding: EdgeInsets.fromLTRB(5, 0, 0, 0)),
                        Expanded(
                          child: GestureDetector(
                            child: Text(
                              '${widget.currentlySelectedPin.address}',
                              style: TextStyle(fontSize: 13, color: Colors.black),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ),
                      ],
                    ) : Container(),

                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
