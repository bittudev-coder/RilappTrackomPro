import 'dart:async';
import 'dart:collection';
import 'dart:convert';
import 'dart:math' show cos, sqrt, asin;
import 'dart:ui' as ui;
import 'dart:ui';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/material.dart' as m;
import 'package:flutter/services.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:gpspro/model/PinInformation.dart';
import 'package:gpspro/screens/CommonMethod.dart';
import 'package:gpspro/storage/dataController/DataController.dart';
import 'package:gpspro/theme/CustomColor.dart';
import 'package:gpspro/widgets/MapPinPillComponent.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../traccar_gennissi.dart';
import '../src/model/CommandModel.dart';
import '../src/model/DrivenTodayModel.dart';
import '../theme/ConstColor.dart';
import '../ui/custom_icon.dart';
import '../widgets/ConfigurableRectangleButton.dart';
import '../widgets/RectangularFloatingActionButton.dart';

class MapPage extends StatefulWidget {

  final bool updateLive;

  MapPage({required this.updateLive});

  @override
  State<StatefulWidget> createState() => new _MapPageState();
}

class _MapPageState extends State<MapPage> {
  double _progress = 0.0;
  bool _isProgressVisible = false; // Flag to control the visibility of the progress indicator// Total duration in milliseconds (5 seconds)
  Timer? _progressTimer;
  int _TimerSecond=2;
  late User user;
  List<GeofenceModel> fenceList = [];
  bool isLoading = false;
  late int deleteFenceId;
  bool deleteFenceVisible = false;
  Set<Circle> _circles = Set<Circle>();
  Completer<GoogleMapController> _controller = Completer();
  GlobalKey<ScaffoldState> _drawerKey = GlobalKey();
  TextEditingController _searchController = new TextEditingController();
  final Map<String, Widget> segmentMap = new LinkedHashMap();
  late GoogleMapController mapController;
  Set<Marker> _markers = Set<Marker>();
  MapType _currentMapType = MapType.normal;
  bool _trafficEnabled = false;
  bool _geofenceEnabled = false;
  Color _trafficBackgroundButtonColor = CustomColor.secondaryColor;
  Color _mapTypeBackgroundColor = CustomColor.secondaryColor;
  Color _trafficForegroundButtonColor = CustomColor.primaryColor;
  Color _mapTypeForegroundColor = CustomColor.primaryColor;
  Color _geofenceForegroundButtonColor = CustomColor.primaryColor;
  Color _geofenceBackgroundColor = CustomColor.secondaryColor;
  bool _showText = false; // Variable to control text visibility
  String _mapStatusText = ''; // Variable to hold text to be shown
  bool _trafficShowText = false; // Variable to control text visibility
  String _trafficStatusText = ''; // Variable to hold text to be shown
  bool _geofenceShowText = false; // Variable to control text visibility
  String _geofenceStatusText = ''; // Variable to hold text to be shown
  bool _reloadShowText = false;

  int _selectedDeviceId = 0;
  bool deviceSelected = false;
  double pinPillPosition = -200;
  late LatLng _location;
  PinInformation currentlySelectedPin = PinInformation(
      location: LatLng(0, 0),
      name: '',
      status: '',
      charging: false,
      ignition: false,
      batteryLevel: "",
      labelColor: Colors.grey,
      deviceId: 0,
      calcTotalDist: "0 Km",
      blocked: false,
      speed: '',
      updatedTime: null,
      address: null,
      device: null,
      positionModel: null
  );
  late PinInformation sourcePinInfo;
  late PinInformation destinationPinInfo;
  double currentZoom = 14;
  List<Device> devicesList = [];
  List<Device> _searchResult = [];
  String selectedIndex = "all";
  late Timer _timer;
  bool first = true;
  bool streetView = false;
  late SharedPreferences prefs;
  List<LatLng> polylineCoordinates = [];
  Map<PolylineId, Polyline> polylines = {};
  List<String> _commands = <String>[];
  double _dialogCommandHeight = 150.0;
  int _selectedCommand = 0;
  final TextEditingController _customCommand = new TextEditingController();
  List<CommandModel> savedCommand = [];
  CommandModel _selectedSavedCommand = new CommandModel();
  DataController? controller;
  bool seccond=false;
  List<Device> _OthersearchResult = [];
  Set<Marker> _copymarkers = Set<Marker>();
  var model;



  @override
  initState() {
    DrivenData();
    getUser();
    checkPreference();
    super.initState();
    _startTimer();
      getRangeNumber();
    Timer( Duration(seconds: _TimerSecond+2), () {
      _reloadDirectMap(controller!);
    });
  }


  @override
  void dispose() {
    _progressTimer?.cancel(); // Cancel the timer if the widget is disposed
    super.dispose();
  }

  void _simulateProgress(int TimeX) {
    _progressTimer?.cancel();
    setState(() {
      _progress = 0.0;
      _isProgressVisible = true;
    });
    _progressTimer = Timer.periodic(Duration(milliseconds: 50), (timer) {
      double progressIncrement = 50 / ((TimeX)*900) ; // Total ticks: 100 (5000ms / 50ms)

      if (_progress >= 1.0) {
        setState(() {
          _progress = 1.0; // Ensure it does not exceed 1.0
          _isProgressVisible = false; // Hide the progress indicator when done
        });
        timer.cancel(); // Stop the timer when progress is complete
      } else {
        setState(() {
          _progress += progressIncrement;
        });
      }
    });
  }


  void _startTimer() {
    _timer = Timer.periodic(Duration(seconds: _TimerSecond*3), (Timer timer) {
      seccond=true;
    });
  }
  void checkPreference() async {
    prefs = await SharedPreferences.getInstance();
    setState(() {});
  }

  void _onMapCreated() async {
    Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high);
    setState(() {
      _location = LatLng(position.latitude, position.longitude);
    });
  }

  void drawPolyline() async {
    PolylineId id = PolylineId("poly");
    Polyline polyline = Polyline(
        width: 3,
        polylineId: id,
        color: Colors.black87,
        points: polylineCoordinates);
    polylines[id] = polyline;
    setState(() {});
  }

  void addMarker(DataController controller) {
    _markers = Set<Marker>();

    controller.positions.forEach((key, value) async {
      var iconPath;

      if (controller.devices[value.deviceId]!.category != null) {
        if (controller.devices[value.deviceId]!.status == "online" && controller.positions[value.deviceId]!.speed!>=2.7) {
          iconPath = "images/marker_" +
              controller.devices[value.deviceId]!.category! +
              "_online.png";
        } else {
          iconPath = "images/marker_" +
              controller.devices[value.deviceId]!.category! +
              "_offline.png";
        }
      } else {
        if (controller.devices[value.deviceId]!.status == "unknown") {
          iconPath = "images/marker_default_static.png";
        } else {
          iconPath = "images/marker_default_" +
              controller.devices[value.deviceId]!.status! +
              ".png";
        }
      }

      final Uint8List? markerIcon = await getBytesFromAsset(iconPath, 100);

      sourcePinInfo = PinInformation(
          name: "",
          location: LatLng(0, 0),
          speed: "",
          address: "",
          updatedTime: "",
          labelColor: CustomColor.primaryColor,
          deviceId: value.deviceId,
          blocked: value.blocked,
          status: controller.devices[value.deviceId]!.status,
          device: controller.devices[value.deviceId],
          positionModel: controller.positions[value.deviceId],
          calcTotalDist: "0 Km",
          charging: null,
          batteryLevel: '',
          ignition: null);

      createCustomMarkerBitmap(controller.devices[value.deviceId]!.name!)
          .then((BitmapDescriptor bitmapDescriptor) {
        _markers.add(Marker(
          markerId: MarkerId("t_" + value.deviceId.toString()),
          position: LatLng(value.latitude!, value.longitude!),
          anchor: const Offset(0.4, 0.4),
          // updated position
          icon: bitmapDescriptor,
          onTap: () {
            mapController.getZoomLevel().then((value) {
              if (value < 14) {
                currentZoom = 16;
              }
            });

            CameraPosition cPosition = CameraPosition(
              target: LatLng(value.latitude!, value.longitude!),
              zoom: currentZoom,
            );
            mapController.moveCamera(CameraUpdate.newCameraPosition(cPosition));
            _selectedDeviceId = value.deviceId!;
            setState(() {
              currentlySelectedPin = sourcePinInfo;
              pinPillPosition = 30;
              streetView = true;
              polylines.clear();
              polylineCoordinates.clear();
              drawPolyline();
              updateMarkerInfo(value.deviceId!, iconPath, controller);
            });
          },
        ));
      });

      _markers.add(Marker(
        markerId: MarkerId(value.deviceId.toString()),
        position: LatLng(value.latitude!, value.longitude!),
        // updated position
        rotation: value.course!,
        icon: BitmapDescriptor.fromBytes(markerIcon!),
        onTap: () {
          mapController.getZoomLevel().then((value) => {
            if (value < 14)
              {
                currentZoom = 16,
              }
          });

          CameraPosition cPosition = CameraPosition(
            target: LatLng(value.latitude!, value.longitude!),
            zoom: currentZoom,
          );
          mapController.moveCamera(CameraUpdate.newCameraPosition(cPosition));
          _selectedDeviceId = value.deviceId!;
          setState(() {
            currentlySelectedPin = sourcePinInfo;
            pinPillPosition = 30;
            streetView = true;
            polylines.clear();
            polylineCoordinates.clear();
            drawPolyline();
            updateMarkerInfo(value.deviceId!, iconPath, controller);
          });
        },
        // infoWindow: InfoWindow(
        //   title: widget.model.devices[value.deviceId].name,
        // )),
      ));
    });




    LatLngBounds bound = boundsFromLatLngList(controller.positions.values.toList());

    _timer = new Timer.periodic(Duration(seconds: 1), (timer) {
      CameraUpdate u2 = CameraUpdate.newLatLngBounds(bound, 50);
      this.mapController.animateCamera(u2).then((void v) {
        check(u2, this.mapController);
      });
      _timer.cancel();
      _geofenceEnabledPressed();
      setState(() {});
    });

  }

  Future<BitmapDescriptor> createCustomMarkerBitmap(title) async {
    PictureRecorder recorder = new PictureRecorder();
    Canvas c = new Canvas(recorder);

    /* Do your painting of the custom icon here, including drawing text, shapes, etc. */
    TextSpan span = new TextSpan(
        style: new TextStyle(
            color: Colors.white,
            fontSize: 25.0,
            fontWeight: FontWeight.bold,
            backgroundColor: CustomColor.primaryColor),
        text: title);

    TextPainter tp = new TextPainter(
      text: span,
      textAlign: TextAlign.center,
      textDirection: m.TextDirection.ltr,
    );
    tp.layout();
    tp.paint(c, new Offset(20.0, 10.0));

    Picture p = recorder.endRecording();
    ByteData? pngBytes =
    await (await p.toImage(tp.width.toInt() + 40, tp.height.toInt() + 20))
        .toByteData(format: ImageByteFormat.png);

    Uint8List data = Uint8List.view(pngBytes!.buffer);

    return BitmapDescriptor.fromBytes(data);
  }

  Future<ui.Image> getImageFromPath(String imagePath) async {
    //String fullPathOfImage = await getFileData(imagePath);

    //File imageFile = File(fullPathOfImage);
    ByteData bytes = await rootBundle.load(imagePath);
    Uint8List imageBytes = bytes.buffer.asUint8List();
    //Uint8List imageBytes = imageFile.readAsBytesSync();

    final Completer<ui.Image> completer = new Completer();

    ui.decodeImageFromList(imageBytes, (ui.Image img) {
      return completer.complete(img);
    });
    return completer.future;
  }

  void check(CameraUpdate u, GoogleMapController c) async {
    c.animateCamera(u);
    mapController.animateCamera(u);
    LatLngBounds l1 = await c.getVisibleRegion();
    LatLngBounds l2 = await c.getVisibleRegion();
    if (l1.southwest.latitude == -90 || l2.southwest.latitude == -90)
      check(u, c);
  }

  void updateMarker(DataController controller) async {
    var iconPath;

    controller.positions.forEach((key, pos) async {


      if (controller.devices[pos.deviceId]!.category != null) {

        if (controller.devices[pos.deviceId]!.status == "online" && controller.positions[pos.deviceId]!.speed!>=2.7) {
          iconPath = "images/marker_" +
              controller.devices[pos.deviceId]!.category! +
              "_online.png";
        } else {
          iconPath = "images/marker_" +
              controller.devices[pos.deviceId]!.category! +
              "_offline.png";
        }
      } else {
        if (controller.devices[pos.deviceId]!.status! == "unknown") {
          iconPath = "images/marker_default_static.png";
        } else {
          iconPath = "images/marker_default_" +
              controller.devices[pos.deviceId]!.status! +
              ".png";
        }
      }
      // ignore: unused_local_variable
      bool blocked = false;
      if (pos.blocked != null) {
        blocked = pos.blocked!;
      }

      var pinPosition = LatLng(pos.latitude!, pos.longitude!);

      final Uint8List? markerIcon = await getBytesFromAsset(iconPath, 100);

      _markers.removeWhere((m) => m.markerId.value == pos.deviceId.toString());
      _markers.removeWhere(
              (m) => "t_" + m.markerId.value == "t_" + pos.deviceId.toString());

createCustomMarkerBitmap(controller.devices[pos.deviceId]!.name)
          .then((BitmapDescriptor bitmapDescriptor) {
        _markers.add(Marker(
          markerId: MarkerId("t_" + pos.deviceId.toString()),
          position: pinPosition,
          icon: bitmapDescriptor,
          onTap: () {
            mapController.getZoomLevel().then((value) =>
            {
              if (value < 14)
                {
                  currentZoom = 16,
                }
            });

            CameraPosition cPosition = CameraPosition(
              target: LatLng(pos.latitude!, pos.longitude!),
              zoom: currentZoom,
            );
            mapController.moveCamera(CameraUpdate.newCameraPosition(cPosition));
            //mapController.moveCamera(cameraUpdate);
            _selectedDeviceId = pos.deviceId!;
            setState(() {
              currentlySelectedPin = sourcePinInfo;
              pinPillPosition = 30;
              streetView = true;
              polylines.clear();
              polylineCoordinates.clear();
              drawPolyline();
              updateMarkerInfo(pos.deviceId!, iconPath, controller);
            });
          },
        ));
      });


      _markers.add(Marker(
        markerId: MarkerId(pos.deviceId.toString()),
        position: pinPosition,
        icon: BitmapDescriptor.fromBytes(markerIcon!),
        rotation: pos.course!,
        onTap: () {
          mapController.getZoomLevel().then((value) => {
            if (value < 14)
              {
                currentZoom = 16,
              }
          });

          CameraPosition cPosition = CameraPosition(
            target: LatLng(pos.latitude!, pos.longitude!),
            zoom: currentZoom,
          );
          mapController.moveCamera(CameraUpdate.newCameraPosition(cPosition));
          //mapController.moveCamera(cameraUpdate);
          _selectedDeviceId = pos.deviceId!;
          setState(() {
            currentlySelectedPin = sourcePinInfo;
            pinPillPosition = 30;
            streetView = true;
            polylines.clear();
            polylineCoordinates.clear();
            drawPolyline();
            updateMarkerInfo(pos.deviceId!, iconPath, controller);
          });
        },
      ));

      updateMarkerInfo(pos.deviceId!, iconPath, controller);
    });
  }

  void updateMarkerInfo(int deviceId, var iconPath, controller) {
    if (_selectedDeviceId == deviceId) {
      String fLastUpdate =
      formatTime(controller.devices![_selectedDeviceId]!.lastUpdate!);
      polylineCoordinates.add(LatLng(
          controller.positions![_selectedDeviceId]!.latitude!,
          controller.positions![_selectedDeviceId]!.longitude!));
      bool chargingStatus = false, ignitionStatus = false;
      String batteryLevelValue = "";

      if (controller.positions![_selectedDeviceId]!.attributes!
          .containsKey("charge")) {
        chargingStatus =
        controller.positions![_selectedDeviceId]!.attributes!["charge"];
      }

      if (controller.positions![_selectedDeviceId]!.attributes!
          .containsKey("ignition")) {
        ignitionStatus =
        controller.positions![_selectedDeviceId]!.attributes!["ignition"];
      }

      if (controller.positions![_selectedDeviceId]!.attributes!
          .containsKey("batteryLevel")) {
        batteryLevelValue = controller.positions![_selectedDeviceId]!
            .attributes!["batteryLevel"]
            .toString() +
            "%";
      }

      bool blocked = false;
      if (controller.positions![_selectedDeviceId]!.blocked != null) {
        blocked = controller.positions![_selectedDeviceId]!.blocked!;
      }
      double calcDist;
      // ignore: unnecessary_null_comparison
      if (_location != null) {
        calcDist = calculateDistance(
            controller.positions![_selectedDeviceId]!.latitude,
            controller.positions![_selectedDeviceId]!.longitude,
            _location.latitude,
            _location.longitude);
      } else {
        calcDist = 0.0;
      }
      sourcePinInfo = PinInformation(
          name: controller.devices![_selectedDeviceId]!.name,
          location: LatLng(
              controller.positions![_selectedDeviceId]!.latitude!,
              controller.positions![_selectedDeviceId]!.longitude!),
          speed:
          convertSpeed(controller.positions![_selectedDeviceId]!.speed!),
          address: controller.positions![_selectedDeviceId]!.address,
          status: controller.devices![_selectedDeviceId]!.status,
          updatedTime: fLastUpdate,
          charging: chargingStatus,
          ignition: ignitionStatus,
          batteryLevel: batteryLevelValue,
          deviceId: _selectedDeviceId,
          blocked: blocked,
          labelColor: CustomColor.primaryColor,
          device: controller.devices![_selectedDeviceId],
          positionModel: controller.positions![_selectedDeviceId],
          calcTotalDist: calcDist.toStringAsFixed(1) + " Km");

      currentlySelectedPin = sourcePinInfo;
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



  double calculateDistance(lat1, lon1, lat2, lon2) {
    var p = 0.017453292519943295;
    var c = cos;
    var a = 0.5 -
        c((lat2 - lat1) * p) / 2 +
        c(lat1 * p) * c(lat2 * p) * (1 - c((lon2 - lon1) * p)) / 2;
    return 12742 * asin(sqrt(a));
  }

  void _reloadMap(DataController controller) {
    _reloadShowText = true;
    Timer(const Duration(seconds: 1), () {
      setState(() {
        _reloadShowText = false; // Hide text after 1 second
      });
    });

    LatLngBounds bound =
    boundsFromLatLngList(controller.positions.values.toList());


    CameraUpdate u2 = CameraUpdate.newLatLngBounds(bound, 50);
    this.mapController.animateCamera(u2).then((void v) {
      check(u2, this.mapController);
    });
    pinPillPosition = -200;
    polylines.clear();
    polylineCoordinates.clear();
    setState(() {});
    // Fluttertoast.showToast(
    //     msg: ("showingAllDevices").tr,
    //     toastLength: Toast.LENGTH_SHORT,
    //     gravity: ToastGravity.CENTER,
    //     timeInSecForIosWeb: 1,
    //     backgroundColor: Colors.black54,
    //     textColor: Colors.white,
    //     fontSize: 16.0);
  }

  void _reloadDirectMap(DataController controller) {
    var validPositions = controller.positions.values.where((position) =>
    position.latitude != null && position.longitude != null &&
        position.latitude != 0.0 && position.longitude != 0.0).toList();
    LatLngBounds bound = boundsFromLatLngList(validPositions);

    CameraUpdate u2 = CameraUpdate.newLatLngBounds(bound, 50);
    this.mapController.animateCamera(u2).then((void v) {
      check(u2, this.mapController);
    });

    pinPillPosition = -200;
    polylines.clear();
    polylineCoordinates.clear();
    setState(() {});
  }
  void _streetView(DataController controller) {
    launch("https://www.google.com/maps/@?api=1&map_action=pano&viewpoint=" +
        controller.positions[_selectedDeviceId]!.latitude.toString() +
        "," +
        controller.positions[_selectedDeviceId]!.longitude.toString() + "&heading=0&pitch=0&fov=80");
  }

  void moveToMarker(Device device) {
    if (controller!.positions[device.id]!.latitude != null) {
      CameraPosition cPosition = CameraPosition(
        target: LatLng(controller!.positions[device.id]!.latitude!,
            controller!.positions[device.id]!.longitude!),
        zoom: currentZoom,
      );
      mapController.moveCamera(CameraUpdate.newCameraPosition(cPosition));
      _selectedDeviceId = device.id!;
      polylines.clear();
      polylineCoordinates.clear();
      setState(() {
        currentlySelectedPin = sourcePinInfo;
        currentlySelectedPin = sourcePinInfo;
        pinPillPosition = 30;
        streetView = true;
        updateMarkerInfo(device.id!, null, controller);
      });
      Navigator.pop(context);
    }
  }

  static final CameraPosition _initialRegion = CameraPosition(
    target: LatLng(0, 0),
    zoom: 0,
  );

  onSearchTextChanged(String text) async {
    String lowerCaseText = text.toLowerCase();
    if (lowerCaseText.isEmpty) {
      // If the search text is empty, reset to the original list
      if (_OthersearchResult.isNotEmpty) {
        _searchResult = List.from(_OthersearchResult);
      } else {
        _searchResult = List.from(devicesList);
      }
    } else {
      _searchResult = [];
      List<Device> listToSearch = _OthersearchResult.isNotEmpty ? _OthersearchResult : devicesList;

      for (var device in listToSearch) {
        if (device.name != null && device.name!.toLowerCase().contains(lowerCaseText)) {
          _searchResult.add(device);
        }
      }
    }
    setState(() {});
  }

  Widget build(BuildContext context) {

    segmentMap.putIfAbsent(
        "all",
            () => Text(
          ("all").tr,
          style: TextStyle(fontSize: 9),
        ));

    segmentMap.putIfAbsent(
        "moving",
            () => Text(
          ("Moving").tr,
          style: TextStyle(fontSize: 9),
        ));
    segmentMap.putIfAbsent(
        "stopped",
            () => Text(
          ("Stopped").tr,
          style: TextStyle(fontSize: 9),
        ));
    segmentMap.putIfAbsent(
        "IgnitionOn",
            () => Text(
          ("Engine On").tr,
          style: TextStyle(fontSize: 9),
        ));
    segmentMap.putIfAbsent(
        "IgnitionOff",
            () => Text(
          ("Engine Off").tr,
          style: TextStyle(fontSize: 9),
        ));
    segmentMap.putIfAbsent(
        "online",
            () => Text(
          ("online").tr,
          style: TextStyle(fontSize: 9),
        ));
    segmentMap.putIfAbsent(
        "offline_Unknown",
            () => Text(
          ("offline").tr,
          style: TextStyle(fontSize: 9),
        ));



    deviceListFilter(String filterVal) async {

      updateMarker(controller!);
      _searchResult.clear();
      _OthersearchResult.clear();
      _markers.addAll(_copymarkers);
      if (filterVal == "all") {
        _simulateProgress(1);
        _markers.addAll(_copymarkers);
        _OthersearchResult.addAll(devicesList);
        setState(() {});
      }else{
        _simulateProgress(_TimerSecond+1);
      }
      Timer( Duration(seconds: _TimerSecond+1), () {
        devicesList.forEach((device) {
          if (filterVal == "moving") {
            if (device.status!.contains("online")) {
              if (device.status == "online" &&
                  controller!.positions[device.id]!.speed! >= 2.7) {
                _searchResult.add(device);
                _OthersearchResult.add(device);

              }
            }
            if (!(device.status!.contains("online") &&
                controller!.positions[device.id]!.speed! >= 2.7)) {
              // Device does not meet the criteria, so remove it from search results
              _searchResult.remove(device);
              _OthersearchResult.remove(device);

              // Ensure _copymarkers is populated
              if (_copymarkers.isEmpty) {
                _copymarkers.addAll(_markers);
              }

              // Remove markers related to this device
              _markers.removeWhere((m) =>
              m.markerId.value == device.id.toString() ||
                  m.markerId.value == "t_" + device.id.toString());

              setState(() {});
            }







            if (device.status!.contains("online")) {
              if (device.status == "online" &&
                  controller!.positions[device.id]!.speed! <= 2.7) {
                if (_copymarkers.isEmpty) {
                  _copymarkers.addAll(_markers);
                }
                _markers.removeWhere((m) =>
                m.markerId.value == device.id.toString());
                _markers.removeWhere((m) =>
                m.markerId.value == "t_" + device.id.toString());
                setState(() {});
              }
            }























          }
          else if (filterVal == "stopped") {
            if (device.status!.contains("online")) {
              if (device.status == "online" &&
                  controller!.positions[device.id]!.speed! <= 2.7) {
                _searchResult.add(device);
                _OthersearchResult.add(device);
              }
            }


            if (device.status!.contains("online")) {
              if (device.status == "online" &&
                  controller!.positions[device.id]!.speed! >= 2.7) {
                if (_copymarkers.isEmpty) {
                  _copymarkers.addAll(_markers);
                }
                _markers.removeWhere((m) =>
                m.markerId.value == device.id.toString());
                _markers.removeWhere((m) =>
                m.markerId.value == "t_" + device.id.toString());
                setState(() {});
              }
            }



          }




          else if (filterVal == "IgnitionOn") {
            if (controller!.positions[device.id]!.attributes!["ignition"]) {
              _searchResult.add(device);
              _OthersearchResult.add(device);
            }
            if (!controller!.positions[device.id]!.attributes!["ignition"]) {
              if(_copymarkers.isEmpty){
                _copymarkers.addAll(_markers);
              }
              _markers.removeWhere((m) => m.markerId.value == device.id.toString());
              _markers.removeWhere((m) => m.markerId.value == "t_"+device.id.toString());
              setState(() {
              });
            }
          }

          else if (filterVal == "IgnitionOff") {

            if (!controller!.positions[device.id]!.attributes!["ignition"]) {
              _searchResult.add(device);
              _OthersearchResult.add(device);
            }
            if (controller!.positions[device.id]!.attributes!["ignition"]) {
              if(_copymarkers.isEmpty){
                _copymarkers.addAll(_markers);
              }
              _markers.removeWhere((m) => m.markerId.value == device.id.toString());
              _markers.removeWhere((m) => m.markerId.value == "t_"+device.id.toString());
              setState(() {
              });
            }

          }

          else if (filterVal == "online") {

            if (device.status == filterVal) {
              _searchResult.add(device);
              _OthersearchResult.add(device);
            }
            if (!(device.status == filterVal)) {
              if(_copymarkers.isEmpty){
                _copymarkers.addAll(_markers);
              }
              _markers.removeWhere((m) => m.markerId.value == device.id.toString());
              _markers.removeWhere((m) => m.markerId.value == "t_"+device.id.toString());
              setState(() {

              });
            }
          }

          else if (filterVal == "offline_Unknown") {
            if (!(device.status == "online")) {
              _searchResult.add(device);
              _OthersearchResult.add(device);
            }
            if (device.status == "online") {
              if(_copymarkers.isEmpty){
                _copymarkers.addAll(_markers);
              }
              _markers.removeWhere((m) => m.markerId.value == device.id.toString());
              _markers.removeWhere((m) => m.markerId.value == "t_"+device.id.toString());
              setState(() {
              });
            }
          }
        });
      });


      setState(() {});
    }

    return Scaffold(
      backgroundColor: CustomColor.backgroundOffColor,
      key: _drawerKey,
      drawer: SizedBox(width: 250, child: navDrawer()),
      body: Column(
        children: <Widget>[
          SizedBox(height: 5,),
          SizedBox(
            width: MediaQuery.of(context).size.width,
            child: CupertinoSegmentedControl<String>(
              children: segmentMap,
              selectedColor: CustomColor.primaryColor,
              unselectedColor: CustomColor.secondaryColor,
              groupValue: selectedIndex,
              onValueChanged: (String val) {
                setState(() {
                  selectedIndex = val;
                  deviceListFilter(val);
                });
              },
            ),
          ),
          SizedBox(height: 5,),
          PreferredSize(
            preferredSize: Size.fromHeight(1.0),
            child: _isProgressVisible
                ? LinearProgressIndicator(
              value: _progress,
              backgroundColor: Colors.transparent,
              valueColor: AlwaysStoppedAnimation<Color>(CustomColor.primaryColor), // Customize the color
            )
                : SizedBox.shrink(), // Empty widget when progress is not visible
          ),
          Expanded(
            child: GetX<DataController>(
                init: DataController(),
                builder: (dataCtrl) {
                  controller = dataCtrl;
                  devicesList = dataCtrl.devices.values.toList();
                  if (dataCtrl.positions.isNotEmpty) {
                    if (first) {
                      addMarker(dataCtrl);

                      first = false;
                    }else if(widget.updateLive){
                      if(selectedIndex == "all"){
                        if(devicesList.length<=100){
                          updateMarker(dataCtrl);
                        }else{
                          if(seccond){
                            seccond=false;
                            if(selectedIndex == "all"){
                              updateMarker(dataCtrl);
                            }
                          }}
                      }
                    }
                    return buildMap(dataCtrl);
                  } else {
                    return Center(
                      child: CircularProgressIndicator(),
                    );
                  }
                }),
          ),
        ],
      ),
    );

  }

  Widget navDrawer() {
    return Drawer(
        child: new Column(children: <Widget>[
          new Container(
            decoration:   BoxDecoration(
              color: CustomColor.primaryColor,
              // Slightly larger radius for a smoother look
              boxShadow: [
                BoxShadow(
                  color: Colors.blue.withOpacity(0.2), // Darker shadow for a more noticeable effect
                  spreadRadius: 2, // Increased spread radius for a more pronounced shadow
                  blurRadius: 12, // Increased blur radius for a softer, more extended shadow
                  offset: Offset(0, 6), // Adjusted offset for a more noticeable shadow
                ),
              ],
            ),
            child: new Padding(
              padding: const EdgeInsets.fromLTRB(0, 10, 0, 0),
              child: new Card(
                child: new ListTile(
                  leading: new Icon(Icons.search),
                  title: new TextField(
                    controller: _searchController,
                    decoration: new InputDecoration(
                        hintText: ('search').tr,
                        border: InputBorder.none,
                        hintStyle: TextStyle(fontSize: 12)),
                    onChanged: onSearchTextChanged,
                  ),
                  trailing: new IconButton(
                    icon: new Icon(Icons.cancel),
                    onPressed: () {
                      _searchController.clear();
                      onSearchTextChanged('');
                    },
                  ),
                ),
              ),
            ),
          ),
          new Expanded(
              child: _searchResult.length != 0 || _searchController.text.isNotEmpty
                  ? new ListView.builder(
                itemCount: _searchResult.length,
                itemBuilder: (context, index) {
                  final device = _searchResult[index];
                  return deviceCard(device, context,index);
                },
              )
                  : selectedIndex == "all"
                  ? new ListView.builder(
                  itemCount: devicesList.length,
                  itemBuilder: (context, index) {
                    final device = devicesList[index];
                    return deviceCard(device, context,index);
                  })
                  : new ListView.builder(
                  itemCount: 0,
                  itemBuilder: (context, index) {
                    return Text(("noDeviceFound").tr);
                  }))
        ]));
  }

  Widget deviceCard(Device device, BuildContext context, int index) {
    final gradientIndex = index % gradients.length;
    Color color;

    if (device.status!.contains("online")) {
      if (device.status == "online" &&
          controller!.positions[device.id]!.speed! >= 2.7) {
        color = Colors.green;
      }else{
        color = Colors.red;
      }
    } else {
      color = Colors.red;
    }

    String speed;

    if (controller!.positions.containsKey(device.id)) {
      speed = convertSpeed(controller!.positions[device.id]!.speed!);
    } else {
      speed = "0.0 Km/hr";
    }

    return new Container(
      margin: EdgeInsets.symmetric(vertical: 4,horizontal: 8 ),
      decoration:   BoxDecoration(
        color: gradients[gradientIndex],
        borderRadius: BorderRadius.circular(12), // Slightly larger radius for a smoother look
        boxShadow: [
          BoxShadow(
            color: Colors.blue.withOpacity(0.2), // Darker shadow for a more noticeable effect
            spreadRadius: 2, // Increased spread radius for a more pronounced shadow
            blurRadius: 12, // Increased blur radius for a softer, more extended shadow
            offset: Offset(0, 6), // Adjusted offset for a more noticeable shadow
          ),
        ],
      ),
      child: Padding(
        padding: new EdgeInsets.all(1.0),
        child: ListTile(
          leading: Icon(
            Icons.radio_button_checked,
            color: color,
          ),
          title: Text(device.name!),
          subtitle: Text(speed),
          onTap: () => {moveToMarker(device)},
        ),
      ),
    );
  }

  void showCommandDialog(BuildContext context, Device device) {
    _commands.clear();

    Dialog simpleDialog = Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12.0),
        ),
        child: StatefulBuilder(
            builder: (BuildContext context, StateSetter setState) {
              Iterable list;
              try {
                Traccar.getSendCommands(device.id.toString()).then((value) => {
                  // ignore: unnecessary_null_comparison
                  if (value.body != null)
                    {
                      list = json.decode(value.body),
                      if (_commands.length == 0)
                        {
                          list.forEach((element) {
                            if (list.length == 1) {
                              _dialogCommandHeight = 200;
                            }
                            _commands.add(element["type"]);
                          })
                        }
                    }
                  else
                    {},
                  setState(() {})
                });
              } catch (e) {
                print(e);
              }
              return Container(
                height: _dialogCommandHeight,
                width: 300.0,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: <Widget>[
                    _commands.length > 0
                        ? Column(
                      children: <Widget>[
                        Padding(
                          padding: const EdgeInsets.only(
                              left: 10, right: 10, top: 20),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.start,
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: <Widget>[
                              new Row(
                                mainAxisAlignment:
                                MainAxisAlignment.spaceBetween,
                                children: <Widget>[
                                  new Text(('commandTitle').tr),
                                ],
                              ),
                              new Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: <Widget>[
                                    new DropdownButton<String>(
                                      hint: new Text(('select_command').tr),
                                      // ignore: unnecessary_null_comparison
                                      value: _selectedCommand == null
                                          ? null
                                          : _commands[_selectedCommand],
                                      items: _commands.map((String value) {
                                        return new DropdownMenuItem<String>(
                                          value: value,
                                          child: new Text((value).tr,
                                            style: TextStyle(),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        );
                                      }).toList(),
                                      onChanged: (value) {
                                        setState(() {
                                          if (value == "custom") {
                                            _dialogCommandHeight = 250.0;
                                          } else {
                                            _dialogCommandHeight = 150.0;
                                          }
                                          _selectedCommand =
                                              _commands.indexOf(value!);
                                        });
                                      },
                                    )
                                  ]),
                              _commands[_selectedCommand] == "custom"
                                  ? new Container(
                                child: new TextField(
                                  controller: _customCommand,
                                  decoration: new InputDecoration(
                                      labelText: ('commandCustom').tr),
                                ),
                              )
                                  : new Container(),
                              new Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: <Widget>[
                                  ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.red, // background
                                      foregroundColor: Colors.white, // foreground
                                    ),
                                    onPressed: () {
                                      Navigator.of(context).pop();
                                    },
                                    child: Text(('cancel').tr,
                                      style: TextStyle(
                                          fontSize: 18.0,
                                          color: Colors.white),
                                    ),
                                  ),
                                  SizedBox(
                                    width: 20,
                                  ),
                                  ElevatedButton(
                                    onPressed: () {
                                      sendCommand(device);
                                    },
                                    child: Text(('ok').tr,
                                      style: TextStyle(
                                          fontSize: 18.0,
                                          color: Colors.white),
                                    ),
                                  ),
                                ],
                              )
                            ],
                          ),
                        ),
                      ],
                    )
                        : new CircularProgressIndicator(),
                  ],
                ),
              );
            }));
    showDialog(
        context: context, builder: (BuildContext context) => simpleDialog);
  }

  void sendCommand(Device device) {
    Map<String, dynamic> attributes = new HashMap();
    if (_commands[_selectedCommand] == "custom") {
      attributes.putIfAbsent("data", () => _customCommand.text);
    } else {
      attributes.putIfAbsent("data", () => _commands[_selectedCommand]);
    }

    Command command = Command();
    command.deviceId = device.id.toString();
    command.type = _commands[_selectedCommand];
    command.attributes = attributes;

    String request = json.encode(command.toJson());

    Traccar.sendCommands(request).then((res) => {
      if (res.statusCode == 200)
        {
          Fluttertoast.showToast(
              msg: ('command_sent').tr,
              toastLength: Toast.LENGTH_SHORT,
              gravity: ToastGravity.CENTER,
              timeInSecForIosWeb: 1,
              backgroundColor: Colors.green,
              textColor: Colors.white,
              fontSize: 16.0),
          Navigator.of(context).pop()
        }
      else
        {
          Fluttertoast.showToast(
              msg: ('errorMsg').tr,
              toastLength: Toast.LENGTH_SHORT,
              gravity: ToastGravity.CENTER,
              timeInSecForIosWeb: 1,
              backgroundColor: Colors.black54,
              textColor: Colors.white,
              fontSize: 16.0),
          Navigator.of(context).pop()
        }
    });
  }

  Widget buildMap(DataController controller) {
    return Stack(
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.fromLTRB(5, 20, 5, 0),
        ),
        new GoogleMap(
          mapType: _currentMapType,
          initialCameraPosition: _initialRegion,
          trafficEnabled: _trafficEnabled,
          myLocationButtonEnabled: true,
          myLocationEnabled: true,
          onMapCreated: (GoogleMapController controller) {
            _controller.complete(controller);
            mapController = controller;
            _onMapCreated();
          },
          mapToolbarEnabled: false,
          zoomControlsEnabled: false,
          markers: _markers,
          polylines: Set<Polyline>.of(polylines.values),
          onTap: (LatLng latLng) {
            setState(() {
              pinPillPosition = -200;
              streetView = false;
            });
          },
          circles: _circles,
        ),
        MapPinPillComponent(

            pinPillPosition: pinPillPosition,
            currentlySelectedPin: currentlySelectedPin, totalDistance: getOdometer(),),
        Padding(
          padding: const EdgeInsets.fromLTRB(0, 55, 5, 0),
          child: Align(
            alignment: Alignment.topRight,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: <Widget>[

                // Row(
                //   mainAxisSize: MainAxisSize.min,
                //   children: [
                //     if (_showText) // Conditional rendering based on _showText
                //       Container(
                //         margin: EdgeInsets.symmetric(horizontal: 4.0),
                //         padding: EdgeInsets.all(8.0),
                //         decoration: BoxDecoration(
                //           gradient: LinearGradient(
                //             colors: [Color(0xffa8edea), Color(0xfffed6e3)],
                //             begin: Alignment.topLeft,
                //             end: Alignment.bottomRight,
                //           ),
                //           borderRadius: BorderRadius.circular(10),
                //           boxShadow: [
                //             BoxShadow(
                //               color: Colors.black.withOpacity(0.2),
                //               spreadRadius: 2,
                //               blurRadius: 5,
                //               offset: Offset(0, 3), // changes position of shadow
                //             ),
                //           ],
                //         ),
                //         child: Text(
                //           _mapStatusText,
                //           style: TextStyle(color: Colors.black, fontSize: 16.0),
                //         ),
                //       ),
                //     SizedBox(width: 3.0), // Space between text and button
                //     FloatingActionButton(
                //       heroTag: "mapType",
                //       mini: true,
                //       onPressed: _onMapTypeButtonPressed,
                //       materialTapTargetSize: MaterialTapTargetSize.padded,
                //       backgroundColor: _mapTypeBackgroundColor,
                //       foregroundColor: _mapTypeForegroundColor,
                //       child: const Icon(Icons.map, size: 30.0),
                //     ),
                //   ],
                // ),
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
                SizedBox(height: 6,),
                ConfigurableRectangleButton(
                  showText: _reloadShowText,
                  mapStatusText: "Showing All Devices",
                  mapTypeBackgroundColor: CustomColor.secondaryColor,
                  mapTypeForegroundColor: CustomColor.primaryColor,
                  onMapTypeButtonPressed:(){_reloadMap(controller);},
                  iconData: Icons.refresh,
                ),
                SizedBox(height: 6,),

                Visibility(
                  visible: streetView,
                  child: RectangularFloatingActionButton(
                    onPressed: () { _streetView(controller); },
                    backgroundColor: CustomColor.secondaryColor,
                    foregroundColor: CustomColor.primaryColor,
                    icon: Icons.streetview, heroTag: 'streetView',
                  ),
                  // child: FloatingActionButton(
                  //     heroTag: "streetView",
                  //     mini: true,
                  //     onPressed: (){_streetView(controller);},
                  //     backgroundColor: CustomColor.secondaryColor,
                  //     materialTapTargetSize: MaterialTapTargetSize.padded,
                  //     foregroundColor: CustomColor.primaryColor,
                  //     child: const Icon(Icons.streetview, size: 30.0)),
                ),
                SizedBox(height: 6,),
                Visibility(
                  visible: streetView,
                  child: RectangularFloatingActionButton(
                    onPressed: () {
                      showSavedCommandDialog(context, controller.devices[_selectedDeviceId]!);
                    },
                    backgroundColor: CustomColor.secondaryColor,
                    foregroundColor: CustomColor.primaryColor,
                    icon: Icons.send_to_mobile, heroTag: 'commands',
                  ),
                  // child: FloatingActionButton(
                  //     heroTag: "commands",
                  //     mini: true,
                  //     onPressed: (){
                  //       showSavedCommandDialog(context, controller.devices[_selectedDeviceId]!);
                  //     },
                  //     backgroundColor: CustomColor.secondaryColor,
                  //     materialTapTargetSize: MaterialTapTargetSize.padded,
                  //     foregroundColor: CustomColor.primaryColor,
                  //     child: const Icon(Icons.send_to_mobile, size: 30.0)),
                )
              ],
            ),
          ),
        ),



        Stack(
          children: [
            Positioned(
              left: 10,
              top: prefs.getBool('ads') != null ? 5 : 10,
               child:  RectangularFloatingActionButton(onPressed: (){
                          _drawerKey.currentState!.openDrawer();
                            setState(() {});
                        }, backgroundColor: CustomColor.secondaryColor,
                 foregroundColor: CustomColor.primaryColor,
                 icon:Icons.menu, heroTag: '',)  ,),
          ],
        )
      ],
    );
  }

  void showSavedCommandDialog(BuildContext context, device) {
    savedCommand.clear();
    Dialog simpleDialog = Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12.0),
        ),
        child: StatefulBuilder(
            builder: (BuildContext context, StateSetter setState) {
              try {
                Traccar.getSavedCommands(device.id.toString()).then((value) => {
                  if (value != null)
                    {
                      if (savedCommand.length == 0)
                        {
                          value.forEach((element) {
                            savedCommand.add(element);
                          }),
                          _selectedSavedCommand.description = savedCommand.first.description,
                        },
                    }
                  else
                    {},
                  setState(() {})
                });
              } catch (e) {
                print(e);
              }
              return Container(
                height: _dialogCommandHeight,
                width: 300.0,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: <Widget>[
                    savedCommand.length > 0 ?
                    Column(
                      children: <Widget>[
                        Padding(
                          padding:
                          const EdgeInsets.only(left: 10, right: 10, top: 20),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: <Widget>[
                              new Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: <Widget>[
                                  new Text(('commandTitle').tr),
                                ],
                              ),
                              new Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: <Widget>[
                                    new DropdownButton<CommandModel>(
                                      hint: new Text(_selectedSavedCommand.description != null ? _selectedSavedCommand.description! : ""),
                                      items: savedCommand.map((CommandModel value) {
                                        return new DropdownMenuItem<CommandModel>(
                                          value: value,
                                          child: new Text(
                                            value.description!,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        );
                                      }).toList(),
                                      onChanged: (value) {
                                        setState(() {
                                          _selectedSavedCommand = value!;
                                        });
                                      },
                                    )
                                  ]),
                              new Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: <Widget>[
                                  ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.red, // background
                                      foregroundColor: Colors.white, // foreground
                                    ),
                                    onPressed: () {
                                      Navigator.of(context).pop();
                                    },
                                    child: Text(('cancel').tr,
                                      style: TextStyle(
                                          fontSize: 18.0, color: Colors.white),
                                    ),
                                  ),
                                  SizedBox(
                                    width: 20,
                                  ),
                                  ElevatedButton(
                                    onPressed: () {
                                      sendSavedCommand(device);
                                    },
                                    child: Text(('ok').tr,
                                      style: TextStyle(
                                          fontSize: 18.0, color: Colors.white),
                                    ),
                                  ),
                                ],
                              )
                            ],
                          ),
                        ),
                      ],
                    ) : savedCommand.length < 0 ? Center(child: Text(('noData').tr)) :Center(child: Text(('noData').tr, style: TextStyle(color: CustomColor.primaryColor)))
                  ],
                ),
              );
            }));
    showDialog(
        context: context, builder: (BuildContext context) => simpleDialog);
  }

  void sendSavedCommand(Device device) {
    Command command = Command();
    command.deviceId = device.id.toString();
    command.type = "custom";
    command.attributes = _selectedSavedCommand.attributes;

    String request = json.encode(command.toJson());

    Traccar.sendCommands(request).then((res) => {
      if (res.statusCode == 200)
        {
          Fluttertoast.showToast(
              msg: ('command_sent').tr,
              toastLength: Toast.LENGTH_SHORT,
              gravity: ToastGravity.CENTER,
              timeInSecForIosWeb: 1,
              backgroundColor: Colors.green,
              textColor: Colors.white,
              fontSize: 16.0),
          Navigator.of(context).pop()
        }
      else
        {
          Fluttertoast.showToast(
              msg: ('errorMsg').tr,
              toastLength: Toast.LENGTH_SHORT,
              gravity: ToastGravity.CENTER,
              timeInSecForIosWeb: 1,
              backgroundColor: Colors.black54,
              textColor: Colors.white,
              fontSize: 16.0),
          Navigator.of(context).pop()
        }
    });
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

  void DrivenData()async {model = await getDrivenData();}
  String getOdometer() {
    var deviceId = currentlySelectedPin.device?.id.toString();
    if (deviceId != null && deviceId.isNotEmpty) {
      if (model != null) {
        return model!.getOdometerByDeviceId(deviceId).toString();
      } else {
        // Handle the case where model is null
        print("Model is null");
        return "0";
      }
    } else {
      // Return 0 if the device ID is null or empty
      return "0";
    }
  }

  void getRangeNumber() {
    if (devicesList.isEmpty) {
      print("Markers list is empty.");
      _TimerSecond = 2; // Handle as needed for empty list
      setState(() {});
      return;
    }

    // Define the range size
    const int rangeSize = 100;

    // Calculate the range number based on the number of markers
    // Determine the range number by integer division and add 1
    _TimerSecond = (devicesList.length ~/ rangeSize) + 1;

    // Print the result for debugging
    print("Number of Markers: ${_markers.length}");
    print("Range Size: $rangeSize");
    print("Range Number (Timer Second): $_TimerSecond");

    // Update the state
    setState(() {});
  }
}



