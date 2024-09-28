import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:get/get.dart';
import 'package:gpspro/arguments/DeviceArguments.dart';
import 'package:gpspro/model/PinInformation.dart';
import 'package:gpspro/theme/CustomColor.dart';
import 'package:gpspro/widgets/CustomText.dart';
import 'package:jiffy/jiffy.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../traccar_gennissi.dart';
import '../screens/CommonMethod.dart';

class MapPinPillComponent extends StatefulWidget {
  double pinPillPosition;
  PinInformation currentlySelectedPin;
  String totalDistance;

  MapPinPillComponent({
    required this.pinPillPosition,
    required this.currentlySelectedPin,
    required this.totalDistance,
  });

  @override
  State<StatefulWidget> createState() => MapPinPillComponentState();
}

class MapPinPillComponentState extends State<MapPinPillComponent> {
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

  String _CARoFF_on() {
    double speed = double.tryParse(_extractSpeed()) ?? 0.0; // Default to 0.0 if parsing fails
    if (speed >= 2.7 && widget.currentlySelectedPin.status == 'online') {
      return "online";
    } else {
      return "offline";
    }
  }

  @override
  Widget build(BuildContext context) {
    String fLastUpdate = ('noData').tr;
    if (widget.currentlySelectedPin.device?.lastUpdate != null) {
      fLastUpdate = formatTime(widget.currentlySelectedPin.device!.lastUpdate!);
    }

    String Categ = "null";
    if (widget.currentlySelectedPin.device?.category != null) {
      Categ = widget.currentlySelectedPin.device!.category!;
    }

    return AnimatedPositioned(
      bottom: widget.pinPillPosition,
      right: 0,
      left: 0,
      duration: Duration(milliseconds: 200),
      child: Align(
        alignment: Alignment.bottomLeft,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
        Container(
        margin: EdgeInsets.fromLTRB(6, 0, 6, 40),
        padding: EdgeInsets.only(bottom: 5,left: 10,right: 10),
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
                  width: 35,
                  height: 60,
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
                          Icon(Icons.radio_button_checked, size: 18.0),
                          Padding(padding: EdgeInsets.fromLTRB(5, 0, 0, 0)),
                          Container(
                            width: MediaQuery.of(context).size.width * 0.40,
                            child:Text(utf8.decode(widget.currentlySelectedPin.name?.codeUnits ?? []),
                              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          Icon(Icons.timelapse, color: Colors.grey,size: 18,),
                          Text(widget.currentlySelectedPin.device?.lastUpdate != null
                              ? Jiffy.parse(fLastUpdate, pattern: 'dd-MM-yyyy hh:mm:ss aa').fromNow()
                              : "-", style: TextStyle(fontSize: 14)),
                        ],
                      ),
                      Row(
                        children: [
                          Icon(Icons.access_time, color: Colors.grey,size: 18,),
                          Text('${widget.currentlySelectedPin.updatedTime}', style: TextStyle(fontSize: 12)),
                        ],
                      ),
                    ],
                  ),
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

              ],
            ),
            widget.currentlySelectedPin.address != null ? Row(
              children: <Widget>[
                Icon(Icons.location_on_rounded, color: CustomColor.primaryColor, size: 16.0),
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
            Divider(),
            Row(
              children: [
                Container(
                  width: 110,
                  padding: EdgeInsets.all(4.0),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12.0),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.blueGrey.withOpacity(0.3),
                        spreadRadius: 2,
                        blurRadius: 6,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Image.asset(
                        'images/road.png',
                        height: 20,
                        width: 15,
                        color: Colors.blueGrey,
                      ),
                      SizedBox(width: 8.0),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            CustomText(
                              TxtName: ('drivenToday').tr,
                              Txtsize: 11,
                            ),
                            Text(
                              '${DrivenCalculate(widget.totalDistance, getTotalDistance())}',
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.blueGrey,
                                fontWeight: FontWeight.w600,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(width: 10),
                Container(
                  width: 115,
                  padding: EdgeInsets.all(4.0),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12.0),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.blueGrey.withOpacity(0.3),
                        spreadRadius: 2,
                        blurRadius: 6,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Image.asset(
                        'images/road.png',
                        height: 20,
                        width: 15,
                        color: Colors.blueGrey,
                      ),
                      SizedBox(width: 8.0),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            CustomText(
                              TxtName: ('Away From You').tr,
                              Txtsize: 11,
                            ),
                            Text(
                              '${widget.currentlySelectedPin.calcTotalDist}',
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.blueGrey,
                                fontWeight: FontWeight.w600,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(width: 10),
                Row(
                  children: <Widget>[
                    widget.currentlySelectedPin.ignition != null
                        ? Icon(Icons.vpn_key,
                        color: widget.currentlySelectedPin.ignition! ? CustomColor.onColor : CustomColor.offColor,
                        size: 20.0)
                        : Icon(Icons.vpn_key, color: CustomColor.offColor),
                    Icon(
                        widget.currentlySelectedPin.charging != null
                            ? widget.currentlySelectedPin.charging!
                            ? Icons.battery_charging_full
                            : Icons.battery_std
                            : Icons.battery_std,
                        color: widget.currentlySelectedPin.charging != null
                            ? widget.currentlySelectedPin.charging!
                            ? CustomColor.onColor
                            : CustomColor.offColor
                            : CustomColor.offColor,
                        size: 20.0),
                    Text(
                      widget.currentlySelectedPin.batteryLevel ?? 'N/A',
                      style: TextStyle(color: widget.currentlySelectedPin.labelColor),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
          ],
        ),
      ),
    );
  }

  double getTotalDistance() {
    var totalDistance = widget.currentlySelectedPin.positionModel?.attributes?['totalDistance'];
    if (totalDistance is double) {
      return totalDistance;
    } else {
      return 0;
    }
  }

  Future<void> _showEngineOnOFF() async {
    Widget cancelButton = TextButton(
      child: Text(('cancel').tr),
      onPressed: () {
        Navigator.pop(context);
      },
    );

    Widget onButton = TextButton(
      child: Text(('on').tr),
      onPressed: () {
        sendCommand('engineResume');
      },
    );
    Widget offButton = TextButton(
      child: Text(('off').tr),
      onPressed: () {
        sendCommand('engineStop');
      },
    );

    AlertDialog alert = AlertDialog(
      title: Text(('fuelCutOff').tr),
      content: Text(('areYouSure').tr),
      actions: [
        cancelButton,
        onButton,
        offButton,
      ],
    );

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return alert;
      },
    );
  }

  void sendCommand(String commandTxt) {
    Command command = Command();
    command.deviceId = widget.currentlySelectedPin.deviceId.toString();
    command.type = commandTxt;

    String request = json.encode(command.toJson());
    print(request);

    Traccar.sendCommands(request).then((res) {
      print(res.body);
      if (res.statusCode == 200) {
        Fluttertoast.showToast(
            msg: ('command_sent').tr,
            toastLength: Toast.LENGTH_SHORT,
            gravity: ToastGravity.CENTER,
            timeInSecForIosWeb: 1,
            backgroundColor: Colors.green,
            textColor: Colors.white,
            fontSize: 16.0);
        Navigator.of(context).pop();
      } else {
        Fluttertoast.showToast(
            msg: ('errorMsg').tr,
            toastLength: Toast.LENGTH_SHORT,
            gravity: ToastGravity.CENTER,
            timeInSecForIosWeb: 1,
            backgroundColor: Colors.black54,
            textColor: Colors.white,
            fontSize: 16.0);
        Navigator.of(context).pop();
      }
    });
  }
}
