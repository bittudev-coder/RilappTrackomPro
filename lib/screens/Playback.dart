//playback
import 'dart:async';
import 'dart:convert';
import 'package:custom_info_window/custom_info_window.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:gpspro/arguments/ReportArgumnets.dart';
import 'package:gpspro/theme/CustomColor.dart';
import 'package:gpspro/widgets/AlertDialogCustom.dart';
import 'package:gpspro/widgets/CustomProgressIndicatorWidget.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../traccar_gennissi.dart';
import '../ui/custom_icon.dart';
import '../widgets/ConfigurableRectangleButton.dart';
import 'CommonMethod.dart';
import 'dart:ui' as ui;
import 'dart:ui';
import 'package:flutter/material.dart' as m;
import 'package:flutter/services.dart';
class PlaybackPage extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => new _PlaybackPageState();
}

class _PlaybackPageState extends State<PlaybackPage> {
  bool _geofenceEnabled = false;
  late SharedPreferences prefs;
  Color _geofenceForegroundButtonColor = CustomColor.primaryColor;
  Color _geofenceBackgroundColor = CustomColor.secondaryColor;
  Color _trafficBackgroundButtonColor = CustomColor.secondaryColor;
  Color _mapTypeBackgroundColor = CustomColor.secondaryColor;
  Color _trafficForegroundButtonColor = CustomColor.primaryColor;
  Color _mapTypeForegroundColor = CustomColor.primaryColor;
  late User user;
  List<GeofenceModel> fenceList = [];
  late int deleteFenceId;
  bool deleteFenceVisible = false;
  Set<Circle> _circles = Set<Circle>();
  CustomInfoWindowController _customInfoWindowController =
  CustomInfoWindowController();
  bool playPause=true;
  Completer<GoogleMapController> _controller = Completer();
  late GoogleMapController mapController;
  bool _isPlaying = false;
  var _isPlayingIcon = Icons.play_circle_outline;
  bool _trafficEnabled = false;
  MapType _currentMapType = MapType.normal;
  Set<Marker> _markers = Set<Marker>();
  double currentZoom = 12.0;
  late StreamController<PositionModel> _postsController;
  late Timer _timer;
  Timer? timerPlayBack;
  late ReportArguments args;
  List<PositionModel> routeList = [];
  late bool isLoading;
  int _sliderValue = 0;
  int _sliderValueMax = 0;
  int playbackTime = 200;
  List<LatLng> polylineCoordinates = [];
  Map<PolylineId, Polyline> polylines = {};
  List<Choice> choices = [];
  List<Stop> _stopList = [];

  late Choice _selectedChoice; // The app's "state".

  bool hide = true;
  bool _showText = false; // Variable to control text visibility
  String _mapStatusText = ''; // Variable to hold text to be shown
  bool _trafficShowText = false; // Variable to control text visibility
  String _trafficStatusText = ''; // Variable to hold text to be shown
  bool _geofenceShowText = false; // Variable to control text visibility
  String _geofenceStatusText = ''; // Variable to hold text to be shown

  void _toggleContainer() {
    if(hide){
      setState(() {
        hide = !hide;
      });
    }
  }



  void _select(Choice choice) {
    setState(() {
      _selectedChoice = choice;
    });

    if (_selectedChoice.title == ('slow').tr) {
      playbackTime = 400;
      timerPlayBack!.cancel();
      playRoute();
    } else if (_selectedChoice.title == ('medium').tr) {
      playbackTime = 200;
      timerPlayBack!.cancel();
      playRoute();
    } else if (_selectedChoice.title == ('fast').tr) {
      playbackTime = 100;
      timerPlayBack!.cancel();
      playRoute();
    }
  }

  @override
  initState() {
    _postsController = new StreamController();
    getUser();
    getReport();
    super.initState();
  }

  Timer interval(Duration duration, func) {
    Timer function() {
      Timer timer = new Timer(duration, function);

      func(timer);

      return timer;
    }

    return new Timer(duration, function);
  }

  void playRoute() async {
    var iconPath = "images/arrow.png";
    final Uint8List? icon = await getBytesFromAsset(iconPath, 80);
    final Uint8List? startIcon =
    await getBytesFromAsset("images/start.png", 80);
    final Uint8List? endIcon = await getBytesFromAsset("images/end.png", 80);

    _markers.add(
      Marker(
          markerId: MarkerId('start'),
          position:
          LatLng(routeList.first.latitude!, routeList.first.longitude!),
          icon: BitmapDescriptor.fromBytes(startIcon!),
          onTap: () {
            _customInfoWindowController.addInfoWindow!(
              Column(
                children: [
                  Expanded(
                    child: Container(
                      width: MediaQuery.of(context).size.width / 4,
                      decoration: BoxDecoration(
                        color: Colors.grey.withOpacity(0.7),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Center(
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Text("Started",
                              style: TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.green)),
                        ),
                      ),
                    ),
                  ),
                  ClipPath(
                    clipper: TriangleClipper(),
                    child: Container(
                      color: Colors.grey.withOpacity(0.7),
                      width: 20.0,
                      height: 10.0,
                    ),
                  ),
                ],
              ),
              LatLng(routeList.first.latitude!, routeList.first.longitude!),
            );
          }),
    );

    // Add end marker
    _markers.add(
      Marker(
          markerId: MarkerId('end'),
          position: LatLng(routeList.last.latitude!, routeList.last.longitude!),
          icon: BitmapDescriptor.fromBytes(endIcon!),
          onTap: () {
            _customInfoWindowController.addInfoWindow!(
              Column(
                children: [
                  Expanded(
                    child: Container(
                      width: MediaQuery.of(context).size.width / 4,
                      decoration: BoxDecoration(
                        color: Colors.grey.withOpacity(0.7),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Center(
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Text("Stopped",
                              style: TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.red)),
                        ),
                      ),
                    ),
                  ),
                  ClipPath(
                    clipper: TriangleClipper(),
                    child: Container(
                      color: Colors.grey.withOpacity(0.7),
                      width: 20.0,
                      height: 10.0,
                    ),
                  ),
                ],
              ),
              LatLng(routeList.last.latitude!, routeList.last.longitude!),
            );
          }),
    );
    setState(() {});
    interval(new Duration(milliseconds: playbackTime), (timer) {
      if (routeList.length != _sliderValue) {
        _sliderValue++;
      }
      timerPlayBack = timer;
      _markers.removeWhere((m) => m.markerId.value == args.id.toString());
      if (routeList.length - 1 == _sliderValue.toInt()) {
        timerPlayBack!.cancel();
      } else if (routeList.length != _sliderValue.toInt()) {
        moveCamera(routeList[_sliderValue.toInt()]);
        _markers.add(
          Marker(
            markerId:
            MarkerId(routeList[_sliderValue.toInt()].deviceId.toString()),
            position: LatLng(routeList[_sliderValue.toInt()].latitude!,
                routeList[_sliderValue.toInt()].longitude!),
            // updated position
            rotation: routeList[_sliderValue.toInt()].course!,
            icon: BitmapDescriptor.fromBytes(icon!),
          ),
        );
        if(playPause){
          timerPlayBack!.cancel();
        }
        setState(() {});
      } else {
        timerPlayBack!.cancel();
      }

    });


  }

  void playUsingSlider(int pos) async {
    var iconPath = "images/arrow.png";
    final Uint8List? icon = await getBytesFromAsset(iconPath, 80);
    _markers.removeWhere((m) => m.markerId.value == args.id.toString());
    if (routeList.length != _sliderValue.toInt()) {
      moveCamera(routeList[_sliderValue.toInt()]);
      _markers.add(
        Marker(
          markerId:
          MarkerId(routeList[_sliderValue.toInt()].deviceId.toString()),
          position: LatLng(routeList[_sliderValue.toInt()].latitude!,
              routeList[_sliderValue.toInt()].longitude!), // updated position
          rotation: routeList[_sliderValue.toInt()].course!,
          icon: BitmapDescriptor.fromBytes(icon!),
        ),
      );
      setState(() {});
    }
  }

  void moveCamera(PositionModel pos) async {
    CameraPosition cPosition = CameraPosition(
      target: LatLng(pos.latitude!, pos.longitude!),
      zoom: currentZoom,
    );

    if (isLoading) {
      _showProgress(false);
    }
    isLoading = false;
    final GoogleMapController controller = await _controller.future;
    controller.moveCamera(CameraUpdate.newCameraPosition(cPosition));
  }

  getReport() {
    _timer = new Timer.periodic(Duration(milliseconds: 1000), (timer) {
      // ignore: unnecessary_null_comparison
      if (args != null) {
        _timer.cancel();
        getStops();
        Traccar.getPositions(args.id.toString(), args.from, args.to)
            .then((value) {
          if (value!.isNotEmpty) {
            // Filter out elements with a speed of 0
            var filteredValue = value.where((element) => element.speed! >= 2.7).toList();

            if (filteredValue.isNotEmpty) {
              routeList.addAll(filteredValue);
              _sliderValueMax = filteredValue.length - 1;

              // Process each filtered element
              for (var element in filteredValue) {
                if (element.latitude != null && element.longitude != null) {
                  _postsController.add(element);
                  polylineCoordinates.add(LatLng(element.latitude!, element.longitude!));
                }
              }

              // Start playing the route and update the state
              playRoute();
              setState(() {});
            } else {
              // Handle the case where all elements had speed of 0
              if (isLoading) {
                _showProgress(false);
                isLoading = false;
              }

              AlertDialogCustom().showAlertDialog(
                context,
                ('noData').tr,
                ('failed').tr,
                ('ok').tr,
              );
            }
          } else {
            // Handle the case where the value list is empty
            if (isLoading) {
              _showProgress(false);
              isLoading = false;
            }

            AlertDialogCustom().showAlertDialog(
              context,
              ('noData').tr,
              ('failed').tr,
              ('ok').tr,
            );
          }
        });


        drawPolyline();
      }
    });
  }

  getStops() {
    _timer = new Timer.periodic(Duration(seconds: 1), (timer) {
      // ignore: unnecessary_null_comparison
      if (args != null) {
        _timer.cancel();
        Traccar.getStops(args.id.toString(), args.from, args.to)
            .then((value) => {
          _stopList.addAll(value!),
          _stopList.forEach((element) {
            addStopMarker(element);
          }),
          setState(() {})
        });
      }
    });
  }

  void addStopMarker(Stop ev) async {
    var iconPath = "images/route-stop.png";
    final Uint8List? icon = await getBytesFromAsset(iconPath, 80);
    _markers.add(
      Marker(
          markerId: MarkerId(ev.positionId.toString()),
          position: LatLng(ev.latitude!, ev.longitude!), // up
          icon: BitmapDescriptor.fromBytes(icon!),
          onTap: () {
            _customInfoWindowController.addInfoWindow!(
              Column(
                children: [
                  Expanded(
                    child: Container(
                        width: MediaQuery.of(context).size.width / 1.2,
                        decoration: BoxDecoration(
                          color: Colors.grey.withOpacity(0.7),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(4.0),
                          child: Column(
                            children: [
                              new Row(
                                children: [
                                  Icon(Icons.timer,
                                      color: CustomColor.primaryColor,
                                      size: 15.0),
                                  Padding(
                                    padding: const EdgeInsets.only(left: 2),
                                    child: Text(
                                      ParkingTime(ev.startTime, ev.endTime),
                                      style: TextStyle(fontSize: 12),
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(
                                height: 2,
                              ),
                              new Row(
                                children: [
                                  Icon(Icons.location_on_outlined,
                                      color: CustomColor.primaryColor,
                                      size: 20.0),
                                  Expanded(
                                    child: InkWell(
                                      onTap: () {
                                        print(
                                            MediaQuery.of(context).size.width);
                                      },
                                      child: Text(
                                        ev.address != null
                                            ? ev.address!
                                            : ev.latitude.toString() +
                                            "," +
                                            ev.longitude.toString(),
                                        style: TextStyle(fontSize: 12),
                                        maxLines: 2,
                                      ),
                                    ),
                                  ),
                                ],
                              )
                            ],
                          ),
                        )),
                  ),
                  ClipPath(
                    clipper: TriangleClipper(),
                    child: Container(
                      color: Colors.grey.withOpacity(0.7),
                      width: 20.0,
                      height: 10.0,
                    ),
                  ),
                ],
              ),
              LatLng(ev.latitude!, ev.longitude!),
            );
          }),
    );
    setState(() {});
  }

  void drawPolyline() async {
    PolylineId id = PolylineId("poly");
    Polyline polyline = Polyline(
        width: 3,
        polylineId: id,
        color: Colors.black,
        points: polylineCoordinates);
    polylines[id] = polyline;
    setState(() {});
  }

  void _onMapTypeButtonPressed() {

    setState(() {
      _currentMapType = _currentMapType == MapType.normal ? MapType.hybrid : MapType.normal;
      _mapTypeBackgroundColor = _currentMapType == MapType.normal
          ? CustomColor.secondaryColor
          : CustomColor.primaryColor;
      _mapStatusText = _currentMapType == MapType.normal ? "Normal Map" : "Hybrid Map";
      _mapTypeForegroundColor = _currentMapType == MapType.normal
          ? CustomColor.primaryColor
          : CustomColor.secondaryColor;
    });

    _showText = true;
    Timer(const Duration(seconds: 1), () {
      setState(() {
        _showText = false; // Hide text after 1 second
      });
    });
  }
  void _trafficEnabledPressed() {
    setState(() {
      _trafficEnabled = !_trafficEnabled;
      _trafficBackgroundButtonColor = _trafficEnabled
          ? CustomColor.primaryColor
          : CustomColor.secondaryColor;
      _trafficForegroundButtonColor = _trafficEnabled
          ? CustomColor.secondaryColor
          : CustomColor.primaryColor;
      _trafficStatusText = _trafficEnabled ? "Traffic On" : "Traffic Off";
    });

    _trafficShowText = true;
    Timer(const Duration(seconds: 1), () {
      setState(() {
        _trafficShowText = false; // Hide text after 1 second
      });
    });
  }

  void _playPausePressed() {
    _toggleContainer();
    setState(() {
      playPause=false;
      _isPlaying = _isPlaying == false ? true : false;
      if (_isPlaying) {
        playRoute();
      } else {
        timerPlayBack!.cancel();
      }
      _isPlayingIcon = _isPlaying == false
          ? Icons.play_circle_outline
          : Icons.pause_circle_outline;
    });
  }

  currentMapStatus(CameraPosition position) {
    currentZoom = position.zoom;
  }

  @override
  void dispose() {
    // ignore: unnecessary_null_comparison
    _customInfoWindowController.dispose();
    if (timerPlayBack != null) {
      if (timerPlayBack!.isActive) {
        timerPlayBack!.cancel();
      }
    }
    super.dispose();
  }

  static final CameraPosition _initialRegion = CameraPosition(
    target: LatLng(0, 0),
    zoom: 14,
  );

  @override
  Widget build(BuildContext context) {
    args = ModalRoute.of(context)!.settings.arguments as ReportArguments;
    choices = <Choice>[
      Choice(title: ('slow').tr, icon: Icons.directions_car),
      Choice(title: ('medium').tr, icon: Icons.directions_bike),
      Choice(title: ('fast').tr, icon: Icons.directions_boat),
    ];
    _selectedChoice = choices[0];
    return Scaffold(
      appBar: AppBar(
        title: Text(args.name,
            style: TextStyle(color: CustomColor.secondaryColor)),
        iconTheme: IconThemeData(
          color: CustomColor.secondaryColor, //change your color here
        ),
      ),
      body: Stack(children: <Widget>[
        GoogleMap(
          mapType: _currentMapType,
          initialCameraPosition: _initialRegion,
          trafficEnabled: _trafficEnabled,
          myLocationButtonEnabled: false,
          myLocationEnabled: true,
          onTap: (position) {
            _customInfoWindowController.hideInfoWindow!();
          },
          onCameraMove: (position) {
            currentMapStatus(position);
            _customInfoWindowController.onCameraMove!();
          },
          onMapCreated: (GoogleMapController controller) {
            _controller.complete(controller);
            _customInfoWindowController.googleMapController = controller;
            mapController = controller;
            CustomProgressIndicatorWidget()
                .showProgressDialog(context, ('sharedLoading').tr);
            isLoading = true;
          },
          markers: _markers,
          circles: _circles,
          polylines: Set<Polyline>.of(polylines.values),
        ),

//            TrackMapPinPillComponent(
//                pinPillPosition: pinPillPosition,
//                currentlySelectedPin: currentlySelectedPin
//            ),
        CustomInfoWindow(
          controller: _customInfoWindowController,
          height: 80,
          width: MediaQuery.of(context).size.width / 1.5,
          offset: 26,
        ),
        Padding(
          padding: const EdgeInsets.only(top: 6, right: 6),
          child: Align(
            alignment: Alignment.topRight,
            child: Column(        crossAxisAlignment: CrossAxisAlignment.end,
              children: <Widget>[
                ConfigurableRectangleButton(
                  showText: _showText,
                  mapStatusText: _mapStatusText,
                  mapTypeBackgroundColor: _mapTypeBackgroundColor,
                  mapTypeForegroundColor: _mapTypeForegroundColor,
                  onMapTypeButtonPressed:_onMapTypeButtonPressed,
                  iconData: Icons.map,
                ),
                SizedBox(height: 6,),
                ConfigurableRectangleButton(
                  showText: _trafficShowText,
                  mapStatusText: _trafficStatusText,
                  mapTypeBackgroundColor: _trafficBackgroundButtonColor,
                  mapTypeForegroundColor: _trafficForegroundButtonColor,
                  onMapTypeButtonPressed:_trafficEnabledPressed,
                  iconData: Icons.traffic,
                ),
                SizedBox(height: 6,),
                ConfigurableRectangleButton(
                  showText: _geofenceShowText,
                  mapStatusText: _geofenceStatusText,
                  mapTypeBackgroundColor: _geofenceBackgroundColor,
                  mapTypeForegroundColor: _geofenceForegroundButtonColor,
                  onMapTypeButtonPressed:_geofenceEnabledPressed,
                  iconData: Icons.circle_outlined,
                ),
                // FloatingActionButton(
                //   heroTag: "parking",
                //   onPressed: _parkEnabledPressed,
                //   materialTapTargetSize: MaterialTapTargetSize.padded,
                //   backgroundColor: _parkingButtonColor,
                //   mini: true,
                //   child: const Icon(Icons.local_parking, size: 30.0),
                // ),
              ],
            ),
          ),
        ),
        playBackControls(),
      ]),
    );
  }

  Widget playBackControls() {
    String fLastUpdate = 'noData'.tr;

    if (routeList.isNotEmpty && _sliderValue >= 0 && _sliderValue < routeList.length) {
      var currentItem = routeList[_sliderValue.toInt()];
      if (currentItem.deviceTime != null) {
        fLastUpdate = formatTime(currentItem.deviceTime!);
      }
    }

    return Positioned(
      bottom: 0,
      right: 0,
      left: 0,
      child: Align(
        alignment: Alignment.bottomCenter,
        child: Padding(
          padding: const EdgeInsets.all(8.0),
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
              )
            ,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.start,
              children: <Widget>[
                Container(
                  child: Row(
                    children: <Widget>[
                      Container(
                        padding: EdgeInsets.only(top: 5.0, left: 5.0),
                        child: InkWell(
                          child: Icon(
                            _isPlayingIcon,
                            color: CustomColor.primaryColor,
                            size: 35.0,
                          ),
                          onTap: () {
                            _playPausePressed();
                          },
                        ),
                      ),
                      Container(
                        padding: EdgeInsets.only(top: 5.0),
                        child: PopupMenuButton<Choice>(
                          onSelected: _select,
                          icon: Icon(
                            Icons.timer,
                            size: 25,
                            color: CustomColor.primaryColor,
                          ),
                          itemBuilder: (BuildContext context) {
                            return choices.map((Choice choice) {
                              return PopupMenuItem<Choice>(
                                value: choice,
                                child: Text(choice.title),
                              );
                            }).toList();
                          },
                        ),
                      ),
                      Container(
                        padding: EdgeInsets.only(top: 4.0, left: 0.0),
                        width: MediaQuery.of(context).size.width * 0.70,
                        child: Slider(
                          value: _sliderValue.toDouble(),
                          onChanged: (newSliderValue) {
                            setState(() {
                              _sliderValue = newSliderValue.toInt();
                            });
                            if (timerPlayBack != null && !timerPlayBack!.isActive) {
                              playUsingSlider(newSliderValue.toInt());
                            }
                          },
                          min: 0,
                          inactiveColor: color[500],
                          max: _sliderValueMax.toDouble(),
                        ),
                      ),
                    ],
                  ),
                ),
                if(hide)
                Container(
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Column(
                      children: [
                        _sliderValue.toInt() > 0 && routeList[_sliderValue.toInt()].address != null
                            ? Row(
                          children: <Widget>[
                            Container(
                                padding: EdgeInsets.only(left: 5.0),
                                child: Image.asset('images/start.png',scale: 3,)
                            ),
                            Expanded(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.start,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Padding(
                                    padding: EdgeInsets.only(top: 10.0, left: 5.0, right: 0),
                                    child: Text(
                                      utf8.decode(utf8.encode(routeList.first.address!)),
                                      maxLines: 2,
                                      style: TextStyle(fontSize: 12),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        )
                            : Container(),
                        _sliderValue.toInt() > 0 && routeList[_sliderValue.toInt()].address != null
                            ? Row(
                          children: <Widget>[
                            Container(
                                padding: EdgeInsets.only(left: 5.0),
                                child:Image.asset('images/end.png',scale: 3,)
                            ),
                            Expanded(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.start,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Padding(
                                    padding: EdgeInsets.only(top: 10.0, left: 5.0, right: 0),
                                    child: Text(
                                      utf8.decode(utf8.encode(routeList.last.address!)),
                                      maxLines: 2,
                                      style: TextStyle(fontSize: 12),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        )
                            : Container(),
                        _sliderValue.toInt() > 0 && routeList[_sliderValue.toInt()].attributes!['odometer'] != null
                            ? Row(
                          children: <Widget>[
                            Container(
                                padding: EdgeInsets.only(left: 5.0),
                                child:Image.asset('images/totaldistance.png',scale: 6,)
                            ),
                            Expanded(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.start,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Padding(
                                    padding: EdgeInsets.only(top: 10.0, left: 5.0, right: 0),
                                    child: Text(totalDistance(firstOdometer(routeList),
                                        lastOdometer(routeList)
                                        ),
                                      maxLines: 2,
                                      style: TextStyle(fontSize: 14,fontWeight: FontWeight.w700),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        )
                            : Container(),
                      ],
                    ),
                  ),
                )
                else
                Container(
                  child: Column(
                  children: [
                    _sliderValue.toInt() > 0 && routeList[_sliderValue.toInt()].address != null
                        ? Row(
                      children: <Widget>[
                        Container(
                          padding: EdgeInsets.only(left: 5.0),
                          child: Icon(
                            Icons.location_on_outlined,
                            color: CustomColor.primaryColor,
                            size: 12.0,
                          ),
                        ),
                        Expanded(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.start,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Padding(
                                padding: EdgeInsets.only(top: 10.0, left: 5.0, right: 0),
                                child: Text(
                                  utf8.decode(utf8.encode(routeList[_sliderValue.toInt()].address!)),
                                  maxLines: 2,
                                  style: TextStyle(fontSize: 12),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    )
                        : Container(),
                    Container(
                      margin: EdgeInsets.fromLTRB(5, 5, 0, 0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Row(
                            children: <Widget>[
                              Container(
                                padding: EdgeInsets.only(left: 5.0),
                                child: Icon(
                                  Icons.av_timer,
                                  color: CustomColor.primaryColor,
                                  size: 12.0,
                                ),
                              ),
                              Container(
                                padding: EdgeInsets.only(left: 5.0),
                                child: Text(fLastUpdate),
                              ),
                            ],
                          ),
                          Padding(
                            padding: const EdgeInsets.only(right: 20),
                            child: Icon(
                              routeList.isNotEmpty &&
                                  _sliderValue.toInt() >= 0 &&
                                  _sliderValue.toInt() < routeList.length &&
                                  routeList[_sliderValue.toInt()].attributes != null &&
                                  routeList[_sliderValue.toInt()].attributes!["ignition"] == true
                                  ? Icons.key
                                  : Icons.error,
                              color: routeList.isNotEmpty &&
                                  _sliderValue.toInt() >= 0 &&
                                  _sliderValue.toInt() < routeList.length &&
                                  routeList[_sliderValue.toInt()].attributes != null &&
                                  routeList[_sliderValue.toInt()].attributes!["ignition"] == true
                                  ? Colors.green
                                  : Colors.grey,
                              size: 20,
                            ),
                          ),
                        ],
                      ),
                    ),

                    Container(
                      margin: EdgeInsets.fromLTRB(5, 5, 0, 5),
                      child: Row(
                        children: <Widget>[
                          Container(
                            padding: EdgeInsets.only(left: 5.0),
                            child: Icon(
                              Icons.radio_button_checked,
                              color: CustomColor.primaryColor,
                              size: 12.0,
                            ),
                          ),
                          Container(
                            padding: EdgeInsets.only(left: 5.0),
                            child: Text(
                              routeList.isNotEmpty &&
                                  _sliderValue.toInt() >= 0 &&
                                  _sliderValue.toInt() < routeList.length
                                  ? convertSpeed(routeList[_sliderValue.toInt()].speed!)
                                  : 'N/A',
                              style: TextStyle(fontSize: 12),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),),
              ],
            ),
          ),
        ),
      ),
    );
  }




  String ParkingTime(var StartTime, var EndTime) {
    DateTime startTime = DateTime.parse(StartTime);
    DateTime endTime = DateTime.parse(EndTime);
    Duration difference = endTime.difference(startTime);
    String differenceFormatted = formatDuration(difference);
    return differenceFormatted;
  }

  String formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, "0");
    String hours = twoDigits(duration.inHours);
    String minutes = twoDigits(duration.inMinutes.remainder(60));
    String seconds = twoDigits(duration.inSeconds.remainder(60));
    return "$hours h $minutes m $seconds s";
  }

  Future<void> _showProgress(bool status) async {
    if (status) {
      return showDialog<void>(
        context: context,
        barrierDismissible: true, // user must tap button!
        builder: (BuildContext context) {
          return AlertDialog(
            content: new Row(
              children: [
                CircularProgressIndicator(),
                Container(
                    margin: EdgeInsets.only(left: 5),
                    child: Text(('sharedLoading').tr)),
              ],
            ),
          );
        },
      );
    } else {
      Navigator.pop(context);
    }
  }

  String totalDistance(String firstOdo, String lastOdo) {
    print('object6');
    print(firstOdo);
    print(lastOdo);
    try {
      double firstOdoValue = double.parse(firstOdo);
      double lastOdoValue = double.parse(lastOdo);
      double total = lastOdoValue - firstOdoValue;
      return convertDistance(total);
    } catch (e) {
      return "";
    }
  }

  Future<void> getUser() async {
    prefs = await SharedPreferences.getInstance();
    String? userJson = prefs.getString("user");

    if (userJson != null) {
      final parsed = json.decode(userJson);
      user = User.fromJson(parsed);
      try {
        final value = await Traccar.getGeoFencesByUserID(user.id.toString());
        if (value != null && value.isNotEmpty) {
          setState(() {
            fenceList.addAll(value);
          });
        } else {
          setState(() {
          });

        }
      } catch (error) {

      }
    } else {
    }
  }
  void removeFence(String id) {
    setState(() {
      _markers.removeWhere((marker) => marker.markerId.value == id);
      _circles.removeWhere((circle) => circle.circleId.value == id);
    });
  }
  void _geofenceEnabledPressed() async {
    setState(() {
      _geofenceEnabled = !_geofenceEnabled;
      if (_geofenceEnabled) {
        _geofenceBackgroundColor = CustomColor.primaryColor;
        _geofenceForegroundButtonColor = CustomColor.secondaryColor;
        _geofenceStatusText="Geofence Enabled";
      } else {
        _geofenceBackgroundColor = CustomColor.secondaryColor;
        _geofenceForegroundButtonColor = CustomColor.primaryColor;
        _geofenceStatusText="Geofence Disabled";
      }
    });
    _geofenceShowText = true;
    Timer(const Duration(seconds: 1), () {
      setState(() {
        _geofenceShowText = false; // Hide text after 1 second
      });
    });

    // Perform actions based on the new state
    if (_geofenceEnabled) {
      // Show geofences
      _circles.clear();
      // Clear markers as well

      for (var fence in fenceList) {
        String fenceArea = fence.area!
            .replaceAll("CIRCLE (", "")
            .replaceAll(",", "")
            .replaceAll(")", "");

        List<String> fenceSplit = fenceArea.split(" ");

        // Ensure that the list contains the expected number of elements
        if (fenceSplit.length >= 3) {
          double lat = double.parse(fenceSplit[0]);
          double lng = double.parse(fenceSplit[1]);
          double radius = double.parse(fenceSplit[2]);

          // Asynchronously load the marker icon
          BitmapDescriptor bitmapDescriptor = await _myPainterToBitmap(fence.name!, "marker");

          // Update the markers and circles
          setState(() {
            _markers.add(Marker(
              markerId: MarkerId(fence.id.toString()),
              position: LatLng(lat, lng),
              icon: bitmapDescriptor,
              onTap: () {
                mapController.animateCamera(CameraUpdate.newCameraPosition(
                  CameraPosition(
                    target: LatLng(lat, lng),
                    zoom: 12,
                  ),
                ));
                deleteFenceVisible = true;
                deleteFenceId = fence.id!;
              },
            ));

            _circles.add(Circle(
              circleId: CircleId(fence.id.toString()),
              fillColor: Color(0x40189ad3),
              strokeColor: Color(0),
              strokeWidth: 2,
              center: LatLng(lat, lng),
              radius: radius,
            ));
          });
        }
      }

      // Move the camera to the first geofence if any
      if (fenceList.isNotEmpty) {
        String firstFenceArea = fenceList.first.area!
            .replaceAll("CIRCLE (", "")
            .replaceAll(",", "")
            .replaceAll(")", "");

        List<String> firstFenceSplit = firstFenceArea.split(" ");
        double firstLat = double.parse(firstFenceSplit[0]);
        double firstLng = double.parse(firstFenceSplit[1]);

        mapController.animateCamera(CameraUpdate.newCameraPosition(
          CameraPosition(
            target: LatLng(firstLat, firstLng),
            zoom: 12,
          ),
        ));
      }
    } else {
      // Hide geofences
      for (var fence in fenceList) {
        removeFence(fence.id.toString());
      }
    }
  }
  Future<BitmapDescriptor> _myPainterToBitmap(String label, String icon) async {
    ui.PictureRecorder recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    CustomIcon myPainter = CustomIcon(label, icon);

    final textPainter = TextPainter(
        text: TextSpan(
          text: label,
          style: TextStyle(fontSize: 30, color: Colors.black),
        ),
        textDirection: m.TextDirection.ltr);
    textPainter.layout();

    myPainter.paint(canvas,
        Size(textPainter.size.width + 30, textPainter.size.height + 25));
    final ui.Image image = await recorder.endRecording().toImage(
        textPainter.size.width.toInt() + 30,
        textPainter.size.height.toInt() + 25 + 50);
    final ByteData? byteData =
    await image.toByteData(format: ui.ImageByteFormat.png);

    Uint8List data = byteData!.buffer.asUint8List();
    setState(() {});
    return BitmapDescriptor.fromBytes(data);
  }


}

String lastOdometer(List<PositionModel> routeList) {
  if (routeList.isEmpty) {
    return 'No data';
  }
  for (int i = routeList.length - 1; i >= 0; i--) {
    var odometerValue = routeList[i].attributes!['odometer'];
    if (odometerValue != null) {
      return odometerValue.toString();
    }
  }
  return 'null';
}
String firstOdometer(List<PositionModel> routeList) {
  if (routeList.isEmpty) {
    return 'No data';
  }

  for (int i = 0; i <= routeList.length-1; i++) {
    var odometerValue = routeList[i].attributes!['odometer'];
    if (odometerValue != null) {

      return odometerValue.toString();
    }
  }
  return 'null';
}


class TriangleClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();
    path.lineTo(size.width, 0.0);
    path.lineTo(size.width / 2, size.height);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(TriangleClipper oldClipper) => false;
}

class Choice {
  const Choice({required this.title, required this.icon});

  final String title;
  final IconData icon;
}
