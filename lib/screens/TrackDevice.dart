import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart' as m;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:get/get_state_manager/src/rx_flutter/rx_getx_widget.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:gpspro/arguments/DeviceArguments.dart';
import 'package:gpspro/model/PinInformation.dart';
import 'package:gpspro/screens/CommonMethod.dart';
import 'package:gpspro/storage/dataController/DataController.dart';
import 'package:gpspro/theme/CustomColor.dart';
import 'package:gpspro/ui/custom_icon.dart';
import 'package:gpspro/widgets/CustomProgressIndicatorWidget.dart';
import 'package:gpspro/widgets/TrackMapPinPillComponent.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../traccar_gennissi.dart';
import '../widgets/ConfigurableRectangleButton.dart';

class TrackDevicePage extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => _TrackDeviceState();
}

class _TrackDeviceState extends State<TrackDevicePage> {
  late GoogleMapController mapController;
  late User user;
  List<GeofenceModel> fenceList = [];
  late int deleteFenceId;
  bool deleteFenceVisible = false;
  Set<Circle> _circles = Set<Circle>();
  late DeviceArguments args;
  Set<Marker> _markers = Set<Marker>();
  late bool isLoading;
  MapType _currentMapType = MapType.normal;
  double currentZoom = 14.0;
  bool _trafficEnabled = false;
  Color _trafficBackgroundButtonColor = CustomColor.secondaryColor;
  Color _mapTypeBackgroundColor = CustomColor.secondaryColor;
  Color _trafficForegroundButtonColor = CustomColor.primaryColor;
  Color _mapTypeForegroundColor = CustomColor.primaryColor;
  bool _geofenceEnabled = false;
  Color _geofenceForegroundButtonColor = CustomColor.primaryColor;
  Color _geofenceBackgroundColor = CustomColor.secondaryColor;
  PinInformation currentlySelectedPin = PinInformation(
      speed: '',
      status: 'loading....',
      location: LatLng(0, 0),
      updatedTime: 'Loading....',
      name: 'Loading....',
      charging: false,
      ignition: false,
      batteryLevel: "",
      address: null,
      labelColor: Colors.grey,
      blocked: null,
      calcTotalDist: null,
      deviceId: 0,
      device: null,
      positionModel: null);
  late PinInformation sourcePinInfo;
  late PinInformation destinationPinInfo;
  double pinPillPosition = 0;
  Device device = Device();
  PositionModel position = PositionModel();
  bool pageDestoryed = false;
  late SharedPreferences prefs;
  List<LatLng> polylineCoordinates = [];
  Map<PolylineId, Polyline> polylines = {};
  bool _showText = false; // Variable to control text visibility
  String _mapStatusText = ''; // Variable to hold text to be shown
  bool _trafficShowText = false; // Variable to control text visibility
  String _trafficStatusText = ''; // Variable to hold text to be shown
  bool _geofenceShowText = false; // Variable to control text visibility
  String _geofenceStatusText = ''; // Variable to hold text to be shown

  @override
  initState() {
    checkPreference();
    getUser();
    super.initState();
    drawPolyline();
    sourcePinInfo = PinInformation(
        name: "",
        location: LatLng(0, 0),
        address: '',
        speed: '',
        status: '',
        updatedTime: '',
        charging: false,
        ignition: false,
        batteryLevel: "",
        deviceId: 0,
        labelColor: Colors.blueAccent,
        blocked: false,
        device: null,
        calcTotalDist: null,
        positionModel: null);
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

  void checkPreference() async {
    prefs = await SharedPreferences.getInstance();
    setState(() {});
  }

  Completer<GoogleMapController> _controller = Completer();
  static final CameraPosition _initialRegion = CameraPosition(
    target: LatLng(0, 0),
    zoom: 0,
  );

  void updateMarker(PositionModel pos) async {
    var iconPath;

    // if (device.category != null) {
    //   if (device.status == "unknown") {
    //     iconPath = "images/marker_" + device.category! + "_static.png";
    //   } else {
    //     iconPath =
    //         "images/marker_" + device.category! + "_" + device.status! + ".png";
    //   }
    // } else {
    //   if (device.status == "unknown") {
    //     iconPath = "images/marker_default_static.png";
    //   } else {
    //     iconPath = "images/marker_default_" + device.status! + ".png";
    //   }
    // }
    // update ---------------------------------------
    print(pos.speed);
    if (device.category != null ) {
      if (device.status == "online" && pos.speed! >= 2.7 ) {
        iconPath = "images/marker_" + device.category! + "_online.png";
      } else {
        iconPath = "images/marker_" + device.category! + "_offline.png";
      }
    } else {
      if (device.status == "unknown") {
        iconPath = "images/marker_default_static.png";
      } else {
        iconPath = "images/marker_default_" + device.status! + ".png";
      }
    }
    // update ---------------------------------------

    final Uint8List markerIcon = await getBytesFromAsset(iconPath, 100);

    CameraPosition cPosition = CameraPosition(
      target: LatLng(pos.latitude!, pos.longitude!),
      zoom: currentZoom,
    );

    final GoogleMapController controller = await _controller.future;
    controller.moveCamera(CameraUpdate.newCameraPosition(cPosition));

    // _markers = Set<Marker>();

    var pinPosition = LatLng(pos.latitude!, pos.longitude!);
    _markers.removeWhere((m) => m.markerId.value == pos.deviceId.toString());

    _markers.add(Marker(
      markerId: MarkerId(pos.deviceId.toString()),
      position: pinPosition,
      rotation: pos.course!,
      icon: BitmapDescriptor.fromBytes(markerIcon),
    ));
    polylineCoordinates.add(pinPosition);
    String fLastUpdate = formatTime(device.lastUpdate!);

    bool chargingStatus = false, ignitionStatus = false;
    String batteryLevelValue = "";

    if (pos.attributes!.containsKey("charge")) {
      chargingStatus = pos.attributes!["charge"];
    }

    if (pos.attributes!.containsKey("ignition")) {
      ignitionStatus = pos.attributes!["ignition"];
    }

    if (pos.attributes!.containsKey("batteryLevel")) {
      batteryLevelValue = pos.attributes!["batteryLevel"].toString() + "%";
    }

    sourcePinInfo = PinInformation(
        name: device.name,
        location: LatLng(pos.latitude!, pos.longitude!),
        address: pos.address,
        status: device.status,
        speed: convertSpeed(pos.speed!),
        updatedTime: fLastUpdate,
        charging: chargingStatus,
        ignition: ignitionStatus,
        batteryLevel: batteryLevelValue,
        deviceId: device.id,
        labelColor: CustomColor.primaryColor,
        calcTotalDist: null,
        blocked: false,
        device: device,
        positionModel:pos

    );

    currentlySelectedPin = sourcePinInfo;
    if (_markers != null) {
      if (isLoading) {
        _showProgress(false);
        isLoading = false;
        setState(() {});
      }
    }
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

  Future<Uint8List> getBytesFromAsset(String path, int width) async {
    ByteData data = await rootBundle.load(path);
    ui.Codec codec = await ui.instantiateImageCodec(data.buffer.asUint8List(),
        targetWidth: width);
    ui.FrameInfo fi = await codec.getNextFrame();
    return (await fi.image.toByteData(format: ui.ImageByteFormat.png))!
        .buffer
        .asUint8List();
  }

  currentMapStatus(CameraPosition position) {
    currentZoom = position.zoom;
  }

  @override
  void dispose() {
    pageDestoryed = true;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    args = ModalRoute.of(context)!.settings.arguments as DeviceArguments;

    return Scaffold(
        appBar: AppBar(
          title: Text(args.name,
              style: TextStyle(color: CustomColor.secondaryColor)),
          iconTheme: IconThemeData(
            color: CustomColor.secondaryColor, //change your color here
          ),
        ),
        body: GetX<DataController>(
            init: DataController(),
            builder: (controller) {
              return !controller.isLoading.value
                  ? buildMap(controller)
                  : CircularProgressIndicator();
            })

    );

  }

  Widget buildMap(DataController controller) {
    device = controller.devices[args.id] as Device;
    if (controller.positions.containsKey(args.id)) {
      if (!pageDestoryed) {
        updateMarker(controller.positions[args.id] as PositionModel);
      }
      return Stack(
        children: <Widget>[
          Container(
            child: GoogleMap(
              mapType: _currentMapType,
              initialCameraPosition: _initialRegion,
              onCameraMove: currentMapStatus,
              trafficEnabled: _trafficEnabled,
              myLocationButtonEnabled: false,
              onMapCreated: (GoogleMapController controller) {
                _controller.complete(controller);
                CustomProgressIndicatorWidget()
                    .showProgressDialog(context, ('sharedLoading').tr);
                isLoading = true;
                mapController = controller;
              },

              polylines: Set<Polyline>.of(polylines.values),
              mapToolbarEnabled: false,
              zoomControlsEnabled: false,
              markers: _markers,
              circles: _circles,
            ),
          ),
          TrackMapPinPillComponent(
              pinPillPosition: pinPillPosition,
              currentlySelectedPin: currentlySelectedPin),
          Padding(
            padding: const EdgeInsets.fromLTRB(0, 50, 5, 0),
            child: Align(
              alignment: Alignment.topRight,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
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
                ],
              ),
            ),
          ),
        ],
      );
    } else {
      return Center(
        child: Text("No data"),
      );
    }
  }

  Future<void> _showProgress(bool status) async {
    if (status) {
      return showDialog<void>(
        context: context,
        barrierDismissible: false, // user must tap button!
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
