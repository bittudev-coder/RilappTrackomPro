import 'dart:async';
import 'dart:convert';
import 'dart:ui';
import 'package:custom_info_window/custom_info_window.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:gpspro/arguments/ReportArgumnets.dart';
import 'package:gpspro/screens/CommonMethod.dart';
import 'package:gpspro/theme/CustomColor.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../traccar_gennissi.dart';
import '../ExcelExport/Excelroute.dart';
import '../ExcelExport/Pdfroute.dart';
import '../ui/custom_icon.dart';
import '../widgets/ConfigurableRectangleButton.dart';
import '../widgets/FloatingDownload.dart';
import 'Playback.dart';
import 'dart:ui' as ui;
import 'dart:ui';
import 'package:flutter/material.dart' as m;
import 'package:flutter/services.dart';


class ReportRoutePage extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => new _ReportRoutePageState();
}

class _ReportRoutePageState extends State<ReportRoutePage> {
  late SharedPreferences prefs;
  bool _geofenceEnabled = false;
  Color _geofenceForegroundButtonColor = CustomColor.primaryColor;
  Color _geofenceBackgroundColor = CustomColor.secondaryColor;
  late User user;
  List<GeofenceModel> fenceList = [];
  late int deleteFenceId;
  bool deleteFenceVisible = false;
  Set<Circle> _circles = Set<Circle>();
  Completer<GoogleMapController> _controller = Completer();
  CustomInfoWindowController _customInfoWindowController =
  CustomInfoWindowController();
  late GoogleMapController mapController;
  ReportArguments? args;
  List<RouteReport> _routeList = [];
  late StreamController<int> _postsController;
  late Timer _timer;
  MapType _currentMapType = MapType.normal;
  List<LatLng> polylineCoordinates = [];
  Map<PolylineId, Polyline> polylines = {};
  Set<Marker> _markers = Set<Marker>();
  bool isLoading = true;
  List<Map<String, String>> dropDownListData = [
    {"title": "Excel", "value": "1"},
    {"title": "Pdf", "value": "2"},
  ];

  String? defaultValue; // Use nullable String for defaultValue
  String secondDropDown = "";

  final ExcelExporterRoute excelExporter = ExcelExporterRoute();
 final PdfExporterRoute pdfExporterRoute=new PdfExporterRoute();
  bool _geofenceShowText = false; // Variable to control text visibility
  String _geofenceStatusText = ''; // Variable to hold text to be shown

  @override
  void initState() {
    _postsController = new StreamController();
    getUser();
    getReport();
    super.initState();
  }

  static final CameraPosition _initialRegion = CameraPosition(
    target: LatLng(0, 0),
    zoom: 0,
  );

  getReport() {
    _timer = new Timer.periodic(Duration(seconds: 1), (timer) {
      if (args != null) {
        _timer.cancel();
        Traccar.getRoute(args!.id.toString(), args!.from, args!.to)
            .then((value) => {
          _routeList.addAll(value!),
          value.forEach((element) {
            polylineCoordinates
                .add(LatLng(element.latitude!, element.longitude!));
          }),
          fitBound(),
          setState(() {})
        });
      }
    });
  }

  void fitBound() {
    if (_routeList.isNotEmpty) {
      _postsController.add(1);
      isLoading = false;
      LatLngBounds bound = boundsFromLatLngList(_routeList);
      addMarkers();
      drawPolyline();
      Future.delayed(const Duration(milliseconds: 2000), () {
        // ignore: unnecessary_null_comparison
        if (this.mapController != null) {
          CameraUpdate u2 = CameraUpdate.newLatLngBounds(bound, 50);
          this.mapController.animateCamera(u2).then((void v) {
            check(u2, this.mapController);
          });
        }
      });
    } else {
      isLoading = false;
    }
  }

  void check(CameraUpdate u, GoogleMapController c) async {
    c.animateCamera(u);
    mapController.animateCamera(u);
    LatLngBounds l1 = await c.getVisibleRegion();
    LatLngBounds l2 = await c.getVisibleRegion();
    if (l1.southwest.latitude == -90 || l2.southwest.latitude == -90)
      check(u, c);
  }
  //
  // void addMarkers() async {
  //   var iconPath = "images/start.png";
  //   final Uint8List? startIcon = await getBytesFromAsset(iconPath, 70);
  //   var endIconPath = "images/end.png";
  //   final Uint8List? endIcon = await getBytesFromAsset(endIconPath, 70);
  //
  //   _markers = Set<Marker>();
  //   _markers.add(Marker(
  //     markerId: MarkerId(_routeList.first.deviceId.toString()),
  //     position: LatLng(_routeList.first.latitude!,
  //         _routeList.first.longitude!), // updated position
  //     icon: BitmapDescriptor.fromBytes(startIcon!),
  //   ));
  //
  //   _markers.add(Marker(
  //     markerId: MarkerId(_routeList.last.deviceId.toString()),
  //     position: LatLng(_routeList.last.latitude!,
  //         _routeList.last.longitude!), // updated position
  //     icon: BitmapDescriptor.fromBytes(endIcon!),
  //   ));
  //   setState(() {});
  // }

  void addMarkers() async {
    var startIconPath = "images/start.png";
    var endIconPath = "images/end.png";
    // Clear existing markers and add new markers
    _markers = Set<Marker>();

    final Uint8List? startIcon =
    await getBytesFromAsset("images/start.png", 80);
    final Uint8List? endIcon = await getBytesFromAsset("images/end.png", 80);

    _markers.add(
      Marker(
          markerId: MarkerId('start'),
          position:
          LatLng(_routeList.first.latitude!, _routeList.first.longitude!),
          icon: BitmapDescriptor.fromBytes(startIcon!),
          onTap: () {
            _customInfoWindowController.addInfoWindow!(
              Column(
                children: [
                  Container(
                    width: MediaQuery.of(context).size.width / 4,
                    decoration: BoxDecoration(
                      color: Colors.grey.withOpacity(0.7),
                      borderRadius: BorderRadius.circular(10),
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
              LatLng(_routeList.first.latitude!, _routeList.first.longitude!),
            );
          }),
    );

    // Add end marker
    _markers.add(
      Marker(
          markerId: MarkerId('end'),
          position:
          LatLng(_routeList.last.latitude!, _routeList.last.longitude!),
          icon: BitmapDescriptor.fromBytes(endIcon!),
          onTap: () {
            _customInfoWindowController.addInfoWindow!(
              Column(
                children: [
                  Container(
                    width: MediaQuery.of(context).size.width / 4,
                    decoration: BoxDecoration(
                      color: Colors.grey.withOpacity(0.7),
                      borderRadius: BorderRadius.circular(10),
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
              LatLng(_routeList.last.latitude!, _routeList.last.longitude!),
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

  @override
  Widget build(BuildContext context) {
    args = ModalRoute.of(context)!.settings.arguments as ReportArguments;
    return SafeArea(
        child: Scaffold(
            appBar: AppBar(
              title: Text(
                args!.name,
                style: TextStyle(color: CustomColor.secondaryColor),
                overflow: TextOverflow.ellipsis,
              ),
              iconTheme: IconThemeData(
                color: CustomColor.secondaryColor, //change your color here
              ),
            ),
            body: loadReport()));
  }

  Widget loadReport() {
    return StreamBuilder<int>(
        stream: _postsController.stream,
        builder: (BuildContext context, AsyncSnapshot<int> snapshot) {
          if (snapshot.hasData) {
            return loadMap();
          } else if (isLoading) {
            return Center(
              child: CircularProgressIndicator(),
            );
          } else {
            return Center(
              child: Text(
                  ('noData').tr), // Assuming ('noData').tr is for localization
            );
          }
        });
  }

  Widget loadMap() {
    return Stack(
      children: <Widget>[
        GoogleMap(
          mapType: _currentMapType,
          initialCameraPosition: _initialRegion,
          myLocationButtonEnabled: false,
          myLocationEnabled: true,
          onMapCreated: (GoogleMapController controller) {
            _controller.complete(controller);
            mapController = controller;
          },
          markers: _markers,
          circles: _circles,
          polylines: Set<Polyline>.of(polylines.values),
          onTap: (LatLng latLng) {},
        ),
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Align(
              alignment: Alignment.bottomLeft,
              child: Row(mainAxisSize: MainAxisSize.min, children: <Widget>[
                Builder(
                  builder: (context) => FloatingActionButton(
                      child: Icon(Icons.article, size: 36.0),
                      backgroundColor: CustomColor.primaryColor,
                      onPressed: () {
                        onSheetShowContents(context);
                      }),
                ),
              ])),
        ),
        Padding(
          padding: const EdgeInsets.only(top: 6, right: 6),
          child: Align(
            alignment: Alignment.topRight,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: <Widget>[
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
  }

  Widget loadReportView() {
    return ListView.builder(
      itemCount: _routeList.length,
      itemBuilder: (context, index) {
        final report = _routeList[index];
        return reportRow(report, context);
      },
      
    );
  }

  Widget reportRow(RouteReport r, BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4,horizontal: 6),
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
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Container(
                child: Column(
                  children: <Widget>[
                    r.address != null
                        ? Row(
                      children: <Widget>[
                        Container(
                          padding: EdgeInsets.only(left: 3.0),
                          child: Icon(Icons.location_on_outlined,
                              color: CustomColor.primaryColor, size: 20.0),
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
                                      utf8.decode(r.address!.codeUnits),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    )),
                              ]),
                        )
                      ],
                    )
                        : new Container(),
                    Row(
                      children: [
                        Container(
                            padding: EdgeInsets.only(top: 3.0, left: 3.0),
                            child: Row(
                              children: <Widget>[
                                Container(
                                  child: Icon(Icons.location_on_outlined,
                                      color: CustomColor.primaryColor, size: 20.0),
                                ),
                              ],
                            )),
                        Container(
                            padding: EdgeInsets.only(top: 5.0, left: 3.0, right: 10.0),
                            child: Text("Lat: " +
                                r.latitude!.toStringAsFixed(5) +
                                " Lng: " +
                                r.longitude!.toStringAsFixed(5))),
                      ],
                    ),
                    Row(
                      children: [
                        Container(
                            padding: EdgeInsets.only(top: 3.0, left: 5.0),
                            child: Row(
                              children: <Widget>[
                                Container(
                                  child: Icon(Icons.speed,
                                      color: CustomColor.primaryColor, size: 17.0),
                                ),
                              ],
                            )),
                        Container(
                            padding: EdgeInsets.only(top: 5.0, left: 5.0, right: 10.0),
                            child: Text(convertSpeed(r.speed!))),
                      ],
                    ),
                    Row(
                      children: [
                        Container(
                            padding: EdgeInsets.only(top: 3.0, left: 5.0),
                            child: Row(
                              children: <Widget>[
                                Container(
                                  child: Icon(Icons.access_time_outlined,
                                      color: CustomColor.primaryColor, size: 15.0),
                                ),
                              ],
                            )),
                        Container(
                            padding: EdgeInsets.only(top: 5.0, left: 5.0, right: 10.0),
                            child: Text(
                              formatTime(r.fixTime!),
                              style: TextStyle(fontSize: 11),
                            )),
                      ],
                    ),
                  ],
                )),
          )),
    );
  }

  void onSheetShowContents(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.80,
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
        child: Center(
          child: bottomSheetContent(),
        ),
      ),
    );
  }

  Widget bottomSheetContent() {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            children: [
              Center(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Padding(
                        padding: EdgeInsets.fromLTRB(10, 5, 10, 0),
                        child:  Container(
                          width: MediaQuery.of(context).size.width * 0.60,
                          child: Text(args!.name,
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                            overflow: TextOverflow.ellipsis,
                          ),
                        )

                    ),
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: Row(
                        children: [
                          InkWell(
                            child: Icon(
                              Icons.close,
                              size: 30,
                            ),
                            onTap: () => {Navigator.pop(context)},
                          ),

                        ],
                      ),
                    )
                  ],

                ),
              ),
              Divider(),
              Expanded(child: loadReportView()),
            ],
          ),
        ),
      
      ),
      floatingActionButton: FloatingButtonWithMenu(onExcel: () async{
        await excelExporter.excelroute(_routeList,args!.name);
      }, onPdf: () {
        pdfExporterRoute.pdfRoute(_routeList, args!.name);
      },),
    );
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





