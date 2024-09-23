import 'dart:collection';
import 'dart:convert';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/material.dart' as m;
import 'package:fluttertoast/fluttertoast.dart';
import 'package:get/get.dart';
import 'package:gpspro/arguments/DeviceArguments.dart';
import 'package:gpspro/arguments/ReportArgumnets.dart';
import 'package:gpspro/src/model/CommandModel.dart';
import 'package:gpspro/src/model/MaintenanceModel.dart';
import 'package:gpspro/model/bottomMenu.dart';
import 'package:gpspro/screens/CommonMethod.dart';
import 'package:gpspro/src/model/MaintenancePermModel.dart';
import 'package:gpspro/storage/dataController/DataController.dart';
import 'package:gpspro/theme/CustomColor.dart';
import 'package:gpspro/widgets/CustomText.dart';
import 'package:jiffy/jiffy.dart';
import '../../traccar_gennissi.dart';
import '../model/Immobilizer.dart';
import '../model/immobilzerParse.dart';
import 'package:share_plus/share_plus.dart';
import '../src/model/DrivenTodayModel.dart';
import '../theme/ConstColor.dart';
import '../widgets/CustomButton.dart';
class DevicePage extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => new _DevicePageState();
}

class _DevicePageState extends State<DevicePage> {
  bool _isSearchVisible = false;
  DateTime _selectedFromDate = DateTime.now();
  DateTime _selectedToDate =
  DateTime.now(); // Initial value is 1 day after _selectedFromDate
  TimeOfDay _selectedFromTime = TimeOfDay(hour: 00, minute: 00);
  TimeOfDay _selectedToTime = TimeOfDay(hour: 23, minute: 59);
  int _gradientIndex = 0;
  List<DeviceCommand> commands = []; // List of device commands
  DeviceCommand? selectedCommand; // Selected device command
  String selectedCommandType =
      'Start'; // Selected command type ('Stop', 'Start', 'Custom')

  TextEditingController customCommandController = TextEditingController();
  // ----------------------
  TextEditingController textEditingController = new TextEditingController();
  List<Device> _searchResult = [];
  late Locale myLocale;

  final TextEditingController _customCommand = new TextEditingController();
  List<String> _commands = <String>[];
  int _selectedCommand = 0;
  int _selectedperiod = 0;
  double _dialogHeight = 250.0;
  double _dialogCommandHeight = 150.0;
  double _dialogImmodHeight = 300.0;
  List<Device> _OthersearchResult = [];

  List<CommandModel> savedCommand = [];
  CommandModel _selectedSavedCommand = new CommandModel();

  List<BottomMenu> bottomMenu = [];
  User? user;
  String selectedIndex = "all";

  List<MaintenanceModel> selectedMaintenance = [];
  List<MaintenanceModel> maintenanceList = [];


  final Map<String, Widget> segmentMap = new LinkedHashMap();

  List<Device> devicesList = [];
  Map<int, PositionModel> positions = {};
  var model;

 initState()  {
    super.initState();
    DrivenData();
    fillBottomList();
    commands = parseCommands(jsonString); // Parse JSON data
    selectedCommand =
        commands.first; // Initialize selected command with the first item
  }

  @override
  void dispose() {
    // TODO: implement dispose
    super.dispose();
    customCommandController.dispose();
  }

  void fillBottomList() {
    bottomMenu.add(new BottomMenu(
        title: "liveTracking",
        img: "icons/tracking.png",
        tapPath: "/trackDevice"));
    bottomMenu.add(new BottomMenu(
        title: "info", img: "icons/car.png", tapPath: "/deviceInfo"));
    bottomMenu.add(new BottomMenu(
        title: "playback", img: "icons/route.png", tapPath: "playback"));
    bottomMenu.add(new BottomMenu(
        title: "alarmGeofence",
        img: "icons/fence.png",
        tapPath: "/geofenceList"));
    bottomMenu.add(new BottomMenu(
        title: "report", img: "icons/report.png", tapPath: "report"));
    bottomMenu.add(new BottomMenu(
        title: "Graph", img: "icons/graph.png", tapPath: "/Graph"));
    // bottomMenu.add(new BottomMenu(
    //     title: "commandTitle", img: "icons/command.png", tapPath: "command"));
    // bottomMenu.add(new BottomMenu(
    //     title: "alarmLock", img: "icons/lock.png", tapPath: "lock"));
    // bottomMenu.add(new BottomMenu(
    //     title: "savedCommand",
    //     img: "icons/command.png",
    //     tapPath: "savedCommand"));
    // bottomMenu.add(new BottomMenu(title: "info", img: "icons/tracking.png", tapPath: ""));
    bottomMenu.add(new BottomMenu(
        title: "assignMaintenance",
        img: "icons/settings.png",
        tapPath: "assignMaintenance"));
    bottomMenu.add(new BottomMenu(
        title: "Immobilizer",
        img: "icons/command.png",
        tapPath: "/Immobilizer"));
  }

  void setLocale(locale) async {
    await Jiffy.setLocale(locale);
  }

  void maintenanceData(Device device, StateSetter setState) {
    try {
      Traccar.getMaintenanceByDeviceId(device.id.toString()).then((value) => {
        selectedMaintenance.addAll(value!),
        Traccar.getMaintenance().then((val) => {
          val!.forEach((element) {
            if (selectedMaintenance.isNotEmpty) {
              if (selectedMaintenance
                  .singleWhere((e) => element.id == e.id)
                  .id ==
                  element.id) {
                print("true");
                element.enabled = true;
              } else {
                element.enabled = false;
              }
            } else {
              element.enabled = false;
            }
            maintenanceList.add(element);
          }),

          setState(() {})
        })
      });
    } catch (e) {
      print(e);
    }
  }

  void updateMaintenance(MaintenanceModel m, Device d) {
    MaintenancePermModel mPM = MaintenancePermModel();
    mPM.deviceId = d.id;
    mPM.maintenanceId = m.id;

    var maintenancePerm = json.encode(mPM);
    Traccar.addPermission(maintenancePerm).then((value) => {});
  }

  void removeMaintenance(MaintenanceModel m, Device d) {
    Traccar.deleteMaintenancePermission(d.id, m.id).then((value) => {});
  }


  @override
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

    onSearchTextChanged(String text) async {
      String lowerCaseText = text.toLowerCase();
      if (lowerCaseText.isEmpty) {
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




    deviceListFilter(String filterVal) async {
      textEditingController.text="";
      _searchResult.clear();
      _OthersearchResult.clear();

      if (filterVal == "all") {
        setState(() {});
        return;
      }
      print("IgnitionIgnition");
      devicesList.forEach((device) {
        if (device.status!.contains(filterVal)) {
          if (device.status == filterVal) {
            _searchResult.add(device);
            _OthersearchResult.add(device);
          }
        } else if (filterVal == "offline_Unknown") {
          if (device.status == "unknown" || device.status == "offline") {
            _searchResult.add(device);
            _OthersearchResult.add(device);
          }
        } else if (filterVal == "moving") {
          if (device.status!.contains("online")) {
            if (device.status == "online" &&
                positions[device.id]!.speed! >= 2.7) {
              _searchResult.add(device);
              _OthersearchResult.add(device);
            }
          }
        } else if (filterVal == "stopped") {
          if (device.status!.contains("online")) {
            if (device.status == "online" &&
                positions[device.id]!.speed! <= 2.7) {
              _searchResult.add(device);
              _OthersearchResult.add(device);
            }
          }
        } else if (filterVal == "IgnitionOn") {
          try{


          if (positions[device.id]!.attributes!["ignition"]) {
            _searchResult.add(device);
            _OthersearchResult.add(device);
          }
          }catch(e){}
        } else if (filterVal == "IgnitionOff") {
          try{
           if (positions[device.id]!.attributes!["ignition"]) {
           } else {
             _searchResult.add(device);
             _OthersearchResult.add(device);
         }
          }catch(e){}

        }
      });

      setState(() {});
    }





    return Scaffold(
      backgroundColor: Colors.white,
        body: new Column(children: <Widget>[
          new Container(
        decoration: BoxDecoration(
          color: Colors.blue.shade50, // Background color
          borderRadius: BorderRadius.circular(12), // Rounded corners
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              spreadRadius: 2,
              blurRadius: 8,
              offset: Offset(0, 4), // Shadow position
            ),
          ],
        ),
        child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 12,right: 12,top: 8,bottom: 6),
            child:  AnimatedSwitcher(
              duration: Duration(milliseconds: 400), // Duration of the animation
              child: _isSearchVisible
                  ? Container(
                   height: 48,
                    child: new ListTile(
                      leading: new Icon(Icons.search),
                      title: new TextField(
                        controller: textEditingController,
                        decoration: new InputDecoration(
                            hintText: ('search').tr, border: InputBorder.none),
                        onChanged: onSearchTextChanged,
                      ),
                      trailing: user != null
                          ? user!.deviceReadonly!
                          ? new IconButton(
                        icon: new Icon(Icons.cancel),
                        onPressed: () {
                          textEditingController.clear();
                          onSearchTextChanged('');
                        },
                      )
                          : FloatingActionButton(
                        heroTag: "addButton",
                        onPressed: () {
                          Navigator.pushNamed(context, "/addDevice");
                        },
                        mini: true,
                        child: const Icon(Icons.add),
                        backgroundColor: CustomColor.primaryColor,
                      )
                          : new IconButton(
                        icon: new Icon(Icons.cancel),
                        onPressed: () {
                          textEditingController.clear();
                          onSearchTextChanged('');
                          _toggleSearchVisibility();
                        },
                      ),
                    ),
                  )
                  : Row(
                key: ValueKey<bool>(_isSearchVisible), // Ensure AnimatedSwitcher differentiates widgets
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                Row(
                  children: [
                    Center(
                        child:RichText(
                          text: TextSpan(
                            children: [
                              TextSpan(
                                text: '${(selectedIndex).tr} ',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold, // Example: make this part bold
                                  color:CustomColor.primaryColor, // Example: change color
                                ), // Apply default or custom style
                              ),
                              TextSpan(
                                text: 'Device Count: ',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold, // Example: make this part bold
                                  color: CustomColor.primaryColor, // Example: change color
                                ),
                              ),
                              TextSpan(
                                text: '${selectedIndex == 'all' ? devicesList.length : _searchResult.length}',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black
                                  // Example: make this part boldolor: CustomColor.primaryColor , // Example: change color
                                ),
                              ),
                            ],
                          ),
                        )
                    ),
                  ],
                ),
                  IconButton(
                    color: CustomColor.primaryColor,
                    onPressed: _toggleSearchVisibility,
                    icon: Icon(Icons.search, size: 32),
                  ),
                ],
              ),
            ),
          ),
          SingleChildScrollView(child: Padding(padding: EdgeInsets.all(3))),
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
          SizedBox(height: 15,)
        ],
      ),
    ),
          GetX<DataController>(
            init: DataController(),
            builder: (controller) {
              // Extract the data from the controller
              devicesList = controller.devices.values.toList();
              positions = controller.positions;

              // Handle the different states
              return controller.isLoading.value
                  ? Center(child: CircularProgressIndicator()) // Loading state
                  : _searchResult.isNotEmpty || textEditingController.text.isNotEmpty
                  ? Expanded(
                child: ListView.builder(
                  itemCount: _searchResult.length,
                  itemBuilder: (context, index) {
                    final device = _searchResult[index];
                    return deviceCard(device, context, index);
                  },
                ),
              )
                  : selectedIndex == "all"
                  ? Expanded(
                child: devicesList.isNotEmpty
                    ? ListView.builder(
                  itemCount: devicesList.length,
                  itemBuilder: (context, index) {
                    final device = devicesList[index];
                    return deviceCard(device, context, index);
                  },
                )
                    : Center(
                  child: Text(
                    'No devices found',
                    style: TextStyle(fontSize: 16, color: Colors.black,fontWeight: FontWeight.w700),
                  ),
                ),
              )
                  : Expanded(
                child: Center(
                  child: Text(
                    'No devices found',
                    style: TextStyle(fontSize: 16, color: Colors.black54),
                  ),
                ),
              );
            },
          )
        ]));
  }

  void _toggleSearchVisibility() {
    setState(() {
      _isSearchVisible = !_isSearchVisible;
    });
  }

  String safeUtf8Decode(List<int> bytes) {
    try {
      return utf8.decode(bytes, allowMalformed: true);
    } catch (e) {
      // Handle the decoding error or return a default value
      return "Invalid data";
    }
  }


  Widget deviceCard(Device device, BuildContext context, int index) {
    final gradientIndex = index % gradients.length;
    String fLastUpdate = ('noData').tr;
    if (device.lastUpdate != null) {
      fLastUpdate = formatTime(device.lastUpdate!);
    }

    double subtext = 13;
    double title = 14;

    return Container(
      margin: EdgeInsets.symmetric(horizontal: 8, vertical: 5),
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
        padding: EdgeInsets.all(10.0),
        child: Column(
          children: <Widget>[
            InkWell(
              onTap: () {
                FocusScope.of(context).unfocus();
                onSheetShowContents(context, device);
              },
              child: Column(
                children: [
                  Container(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: <Widget>[
                            Row(
                              children: <Widget>[
                                Icon(Icons.radio_button_checked, size: 18.0),
                                Padding(padding: EdgeInsets.fromLTRB(5, 0, 0, 0)),
                                Container(
                                  width: MediaQuery.of(context).size.width * 0.60,
                                  child: Text(
                                    safeUtf8Decode(device.name?.codeUnits ?? []),
                                    style: TextStyle(fontSize: title, fontWeight: FontWeight.bold),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                )
                              ],
                            ),
                            Row(
                              children: <Widget>[
                                Icon(Icons.speed, size: 18.0),
                                Padding(padding: EdgeInsets.fromLTRB(5, 5, 0, 0)),
                                positions.containsKey(device.id)
                                    ? Text(
                                  convertSpeed(positions[device.id]!.speed!),
                                  style: TextStyle(fontSize: subtext, fontWeight: FontWeight.w600),
                                  overflow: TextOverflow.ellipsis,
                                )
                                    : Text(
                                  device.status![0].toUpperCase() + device.status!.substring(1),
                                  style: TextStyle(fontSize: subtext),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ],
                        ),
                        Divider(thickness: 1,),
                        Row(
                          children: [
                            positions.containsKey(device.id) && positions[device.id]!.speed != null
                                ? Image.asset(
                              'images/marker_${device.category}_${_CARoFF_on(positions[device.id]!.speed, device.status)}.png',
                              scale: 3.5,
                            )
                                : Image.asset(
                              'images/marker_${device.category}_offline.png',
                              scale: 3.5,
                            ),
                            Expanded(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: <Widget>[
                                      Row(
                                        children: [
                                          Icon(Icons.timer_rounded, size: 18.0),
                                          Padding(padding: EdgeInsets.fromLTRB(5, 5, 0, 0)),
                                          Text(
                                            fLastUpdate,
                                            style: TextStyle(fontSize: subtext),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ],
                                      ),
                                      Text(
                                        device.lastUpdate != null
                                            ? Jiffy.parse(fLastUpdate, pattern: 'dd-MM-yyyy hh:mm:ss aa').fromNow()
                                            : "-",
                                        style: TextStyle(fontSize: 11),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ),
                                  SizedBox(height: 3,),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: <Widget>[
                                      model != null
                                          ? Row(
                                        children: [
                                          Icon(Icons.stacked_line_chart, size: 18.0),
                                          Padding(padding: EdgeInsets.fromLTRB(5, 5, 0, 0)),
                                          Text(
                                            ('drivenToday').tr +
                                                ": ${DrivenCalculate(
                                                    model.getOdometerByDeviceId(device.id.toString()),
                                                    positions[device.id]?.attributes?["totalDistance"] ?? 0
                                                )}",
                                            style: TextStyle(fontSize: subtext),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ],
                                      )
                                          : Container(),
                                    ],
                                  ),
                                  SizedBox(height: 3,),
                                  positions.containsKey(device.id) && positions[device.id]!.address != null
                                  && safeUtf8Decode(positions[device.id]!.address!.codeUnits)!=""
                                      ? Row(
                                    children: <Widget>[
                                      Icon(Icons.location_on_outlined, size: 18.0),
                                      Expanded(
                                        child: Column(
                                          mainAxisAlignment: MainAxisAlignment.start,
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Container(
                                              child: Text(
                                                safeUtf8Decode(positions[device.id]!.address!.codeUnits),
                                                style: TextStyle(fontSize: subtext),
                                                textAlign: TextAlign.left,
                                                maxLines: 2,
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
                          ],
                        ),
                        Divider(thickness: 2,),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            positions.containsKey(device.id)
                                ? positions[device.id]!.attributes!.containsKey("ignition")
                                ? positions[device.id]!.attributes!["ignition"]
                                ? Icon(Icons.vpn_key, color: CustomColor.onColor, size: 25.0)
                                : Icon(Icons.vpn_key, color: Colors.black.withOpacity(0.7), size: 25.0)
                                : Icon(Icons.vpn_key, color: CustomColor.offColor, size: 25)
                                : Icon(Icons.vpn_key, color: Colors.black.withOpacity(0.7), size: 25.0),
                            Icon(
                              device.status == 'online'
                                  ? Icons.cell_tower
                                  : Icons.cell_tower,
                              color: device.status == 'online' ? Colors.blue : Colors.black.withOpacity(0.7),
                            ),
                            Icon(Icons.car_crash, color: Colors.black.withOpacity(0.7)),
                            Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                positions.containsKey(device.id)
                                    ? positions[device.id]!.attributes!.containsKey("charge")
                                    ? positions[device.id]!.attributes!["charge"]
                                    ? Icon(Icons.battery_charging_full, color: CustomColor.onColor, size: 18.0)
                                    : Icon(Icons.battery_std, color: CustomColor.offColor, size: 18.0)
                                    : Icon(Icons.battery_std, color: CustomColor.offColor, size: 18.0)
                                    : Icon(Icons.battery_std, color: CustomColor.offColor, size: 18.0),
                                positions.containsKey(device.id)
                                    ? positions[device.id]!.attributes!.containsKey("batteryLevel")
                                    ? Container(
                                  width: 30,
                                  child: Text(
                                    positions[device.id]!.attributes!["batteryLevel"].toString() + "%",
                                    style: TextStyle(color: CustomColor.primaryColor, fontSize: 10),
                                    overflow: TextOverflow.ellipsis,
                                    textAlign: TextAlign.center,
                                  ),
                                )
                                    : Text("")
                                    : Container(),
                              ],
                            ),
                            InkWell(
                              onTap: () {
                                String mess = "Name:-${safeUtf8Decode(device.name?.codeUnits ?? [])}\nAddress:-${positions[device.id]?.address}\nLast Update:-${fLastUpdate}\nStatus:-${device.status}\nSpeed:-${convertSpeed(positions[device.id]!.speed!)}\n\nClick here:- \nhttp://maps.google.com/maps?q=loc:${positions[device.id]!.latitude},${positions[device.id]!.longitude}";
                                Share.share(mess);
                              },
                              child: Icon(Icons.share, color: Colors.blue),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }






  void showMaintenanceDialog(BuildContext context, Device device) {
    Dialog simpleDialog = Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12.0),
        ),
        child: StatefulBuilder(
            builder: (BuildContext context, StateSetter setState) {
              if (maintenanceList.isEmpty) {
                setState(() {
                  maintenanceData(device, setState);
                });
              }
              return new ListView.builder(
                itemCount: maintenanceList.length,
                itemBuilder: (context, index) {
                  final m = maintenanceList[index];
                  return maintenanceCard(m, context, setState, device);
                },
              );
            }));
    showDialog(
        context: context, builder: (BuildContext context) => simpleDialog);
  }

  Widget maintenanceCard(MaintenanceModel m, BuildContext context,
      StateSetter setState, Device device) {
    return ListTile(
      leading: Checkbox(
        value: m.enabled,
        onChanged: (val) {
          setState(() {
            m.enabled = val;
          });
          if (val!) {
            updateMaintenance(m, device);
          } else {
            removeMaintenance(m, device);
          }
        },
      ),
      title: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: <Widget>[
          new Text(m.name!,
              style: TextStyle(fontSize: 13.0, fontWeight: FontWeight.bold)),
          Divider()
        ],
      ),
    );
  }

  Widget bottomButton(Device device) {
    return GridView.count(

      crossAxisCount: 4,
      childAspectRatio: 1.0,
      padding: const EdgeInsets.all(1.0),
      mainAxisSpacing: 1.0,
      crossAxisSpacing: 1.0,
      children: List.generate(bottomMenu.length, (index) {
        final menu = bottomMenu[index];
        return GestureDetector(
            onTap: () {
              FocusScope.of(context).unfocus();
              if (menu.tapPath == "/trackDevice") {
                Navigator.pushNamed(context, menu.tapPath,
                    arguments: DeviceArguments(device.id!, device.name!, device,
                        positions[device.id]));
              } else if (menu.tapPath == "/deviceInfo") {
                Navigator.pushNamed(context, menu.tapPath,
                    arguments: DeviceArguments(device.id!, device.name!, device,
                        positions[device.id]));
              } else if (menu.tapPath == "playback") {
                showReportDialog(context, ('playback').tr, device);
              } else if (menu.tapPath == "/geofenceList") {
                Navigator.pushNamed(context, menu.tapPath,
                    arguments: ReportArguments(
                        device.id!, "", "", device.name!, device));
              } else if (menu.tapPath == "report") {
                showReportDialog(context, "report", device);
              }else if (menu.tapPath == "/Graph") {
                GraphShow(context, device);
              } else if (menu.tapPath == "command") {
                showCommandDialog(context, device);
              } else if (menu.tapPath == "lock") {
                _showEngineOnOFF(device);
              } else if (menu.tapPath == "savedCommand") {
                showSavedCommandDialog(context, device);
              } else if (menu.tapPath == "assignMaintenance") {
                if (maintenanceList.isNotEmpty) {
                  showMaintenanceDialog(context, device);
                } else {
                  Fluttertoast.showToast(
                      msg: ("noData").tr,
                      toastLength: Toast.LENGTH_SHORT,
                      gravity: ToastGravity.CENTER,
                      timeInSecForIosWeb: 1,
                      backgroundColor: Colors.green,
                      textColor: Colors.white,
                      fontSize: 16.0);
                }
              } else if (menu.tapPath == "/Immobilizer") {
                CommandImmobilizer(context, device);
              }
            },


            child: Container(
              margin: EdgeInsets.all(3.0), // Margin around the container
              padding: EdgeInsets.all(8.0), // Padding inside the container
              decoration: BoxDecoration(
                border: Border.all(
                  color: Colors.black54, // Border color
                  width: 1.0, // Border width
                ),
                borderRadius: BorderRadius.circular(12.0), // Rounded corners
              ),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min, // Ensure the column size fits the content
                  children: [
                    Image.asset(
                      menu.img,
                      width: 30,
                    ),
                    SizedBox(height: 7), // Space between the image and text
                    Expanded(
                      child: Center(
                        child: Text(
                          menu.title.tr,
                          style: TextStyle(fontSize: 10,fontWeight: FontWeight.w600),
                          overflow: TextOverflow.ellipsis, // Handle text overflow
                          textAlign: TextAlign.center, // Center text alignment
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            )



        );
      }),
    );
  }

  void GraphShow(BuildContext context, Device device){
    Navigator.pushReplacementNamed(context, '/graph',arguments: {"deviceid":device.id.toString(),"Name":device.name.toString()} as Map);
  }

  void CommandImmobilizer(BuildContext context, device) {
    savedCommand.clear();
    Dialog simpleDialog = Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12.0),
        ),
        child: StatefulBuilder(
            builder: (BuildContext context, StateSetter setState) {
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
                height: _dialogImmodHeight,
                // height: 350,
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CustomText(TxtName: 'Select a Model:',Txtsize: 15,),
                      SizedBox(
                        height: 50,
                        child: InputDecorator(
                          decoration: InputDecoration(
                            border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10.0)),
                            contentPadding: const EdgeInsets.all(10),
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<DeviceCommand>(
                              value: selectedCommand,
                              onChanged: (DeviceCommand? newValue) {
                                setState(() {
                                  selectedCommand = newValue!;
                                });
                              },
                              items: commands.map((DeviceCommand command) {
                                return DropdownMenuItem<DeviceCommand>(
                                  value: command,
                                  child: Text(command.model),
                                );
                              }).toList(),
                            ),
                          ),
                        ),
                      ),
                      SizedBox(height: 20.0),
                      CustomText(TxtName: 'Select Command Type:',Txtsize: 15,),
                      SizedBox(
                        height: 50,
                        child: InputDecorator(
                          decoration: InputDecoration(
                            border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(15.0)),
                            contentPadding: const EdgeInsets.all(10),
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              value: selectedCommandType,
                              onChanged: (String? newValue) {
                                setState(() {
                                  selectedCommandType = newValue!;
                                  customCommandController.clear();
                                  if (selectedCommandType == "Custom") {
                                    _dialogImmodHeight = 350;
                                  } else {
                                    _dialogImmodHeight = 300;
                                  }

                                  // Clear text field when changing command type
                                });
                              },
                              items: [
                                DropdownMenuItem<String>(
                                  value: 'Stop',
                                  child: Text('Stop Command'),
                                ),
                                DropdownMenuItem<String>(
                                  value: 'Start',
                                  child: Text('Start Command'),
                                ),
                                DropdownMenuItem<String>(
                                  value: 'Custom',
                                  child: Text('Custom Command'),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      SizedBox(height: 20.0),
                      if (selectedCommandType == 'Custom')
                        TextFormField(
                          controller: customCommandController,
                          decoration: InputDecoration(
                            labelText: 'Enter Custom Command',
                            border: OutlineInputBorder(),
                          ),
                        ),
                      if (selectedCommandType != 'Custom' &&
                          selectedCommand != null)

                        CustomText(TxtName: 'Selected Command: ${getSelectedCommandText()}',Txtsize: 15,),
                      SizedBox(height: 10,),
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: new Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: <Widget>[
                            Expanded(
                              child: SizedBox(
                                height: 40,
                                child: CustomButton2(
                                  onTap: () {
                                    Navigator.of(context).pop();
                                  },
                                  text: 'cancel'.tr,
                                ),
                              ),
                            ),
                            SizedBox(width: 20), // Space between buttons
                            Expanded(
                              child: SizedBox(
                                height: 40,
                                child: CustomButton(
                                  onTap: () {
                                    sendCommandImmoblizer(device.id.toString(), getSelectedCommandText());
                                  },
                                  text: 'Okay'.tr,
                                ),
                              ),
                            ),
                          ],
                        ),
                      )
                    ],
                  ),
                ),
              );
            }));
    showDialog(
        context: context, builder: (BuildContext context) => simpleDialog);
  }

  void sendCommandImmoblizer(var DeviceId, var ImmoblizerCommand) {
    var data = {
      'deviceId': DeviceId,
      'type': 'custom',
      'attributes': {
        'data': ImmoblizerCommand,
      },
    };
    String request = json.encode(data);
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

  String getSelectedCommandText() {
    if (selectedCommandType == 'Stop') {
      return selectedCommand!.stopCommand;
    } else if (selectedCommandType == 'Start') {
      return selectedCommand!.startCommand;
    } else {
      return customCommandController.text;
    }
  }


  void onSheetShowContents(BuildContext context, Device device) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.40,
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
        child: bottomSheetContent(device),
      ),
    );
  }
  Widget bottomSheetContent(Device device) {
    return SafeArea(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          Padding(padding: EdgeInsets.all(5)),
          Center(
            child: Container(
              width: 100,
              padding: EdgeInsets.fromLTRB(0, 7, 0, 0),
              decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(12)),
            ),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(10, 10, 0, 0),
            child: Row(
              children: [
                Icon(
                  Icons.radio_button_checked,
                  size: 20,
                  color: CustomColor.primaryColor,
                ),
                Container(
                    alignment: Alignment.topLeft,
                    padding: EdgeInsets.fromLTRB(10, 10, 0, 0),
                    child: Text(
                      device.name!,
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold,),
                      textAlign: TextAlign.start,
                    )),
              ],
            ),
          ),
          positions[device.id] != null
              ? Container(
              alignment: Alignment.topLeft,
              padding: EdgeInsets.fromLTRB(10, 10, 0, 0),
              child: Row(
                children: [
                  Icon(
                    Icons.location_on,
                    size: 20,
                    color: CustomColor.primaryColor,
                  ),
                  SizedBox(width: 5,),
                  Container(
                      width: MediaQuery.of(context).size.width / 1.3,
                      child: addressLoad(
                          positions[device.id]!.latitude.toString(),
                          positions[device.id]!.longitude.toString()))
                ],
              ))
              : Container(),
          Divider(thickness: 2,),
          Padding(padding: EdgeInsets.all(3)),
          // ConstrainedBox(
          //   constraints: BoxConstraints.tightFor(width: 250, height: 40),
          //   child: ElevatedButton.icon(
          //     icon: Icon(
          //       Icons.my_location_sharp,
          //       size: 15,
          //     ),
          //     onPressed: () {
          //       FocusScope.of(context).unfocus();
          //       Navigator.pushNamed(context, "/trackDevice",
          //           arguments:
          //               DeviceArguments(device.id!, device.name!, device));
          //     },
          //     label:
          //         Text(AppLocalizations.of(context)!.translate('trackDevice')),
          //   ),
          // ),
          Flexible(child: bottomButton(device))
        ],
      ),
    );
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
                          _selectedSavedCommand.description =
                              savedCommand.first.description,
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
                    savedCommand.length > 0
                        ? Column(
                      children: <Widget>[
                        Padding(
                          padding: const EdgeInsets.only(
                              left: 10, right: 10, top: 20),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.center,
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
                                    new DropdownButton<CommandModel>(
                                      hint: new Text(_selectedSavedCommand
                                          .description !=
                                          null
                                          ? _selectedSavedCommand.description!
                                          : ""),
                                      items: savedCommand
                                          .map((CommandModel value) {
                                        return new DropdownMenuItem<
                                            CommandModel>(
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
                                      foregroundColor:
                                      Colors.red, // background
                                      backgroundColor:
                                      Colors.white, // foreground
                                    ),
                                    onPressed: () {
                                      Navigator.of(context).pop();
                                    },
                                    child: Text(
                                      ('cancel').tr,
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
                                      sendSavedCommand(device);
                                    },
                                    child: Text(
                                      ('ok').tr,
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
                        : savedCommand.length < 0
                        ? Center(child: Text(("noData").tr))
                        : Center(
                        child: Text(("noData").tr,
                            style:
                            TextStyle(color: CustomColor.primaryColor)))
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

  void showReportDialog(BuildContext context, String heading, Device device) {
    Dialog simpleDialog = Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.0),
      ),
      child: StatefulBuilder(
        builder: (BuildContext context, StateSetter setState) {
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
            height: _dialogHeight,
            width: 300.0,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              children: <Widget>[
                Column(
                  children: <Widget>[
                    Padding(
                      padding:
                      const EdgeInsets.only(left: 10, right: 10, top: 20),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.start,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: <Widget>[
                          new Row(
                            mainAxisAlignment: MainAxisAlignment.start,
                            children: <Widget>[
                              new Radio(
                                value: 0,
                                groupValue: _selectedperiod,
                                onChanged: (value) {
                                  setState(() {
                                    _selectedperiod =
                                        int.parse(value.toString());
                                    _dialogHeight = 250.0;
                                  });
                                },
                              ),
                              new Text(
                                ('reportToday').tr,
                                style: new TextStyle(fontSize: 16.0),
                              ),
                            ],
                          ),
                          new Row(
                            mainAxisAlignment: MainAxisAlignment.start,
                            children: <Widget>[
                              new Radio(
                                value: 1,
                                groupValue: _selectedperiod,
                                onChanged: (value) {
                                  setState(() {
                                    _selectedperiod =
                                        int.parse(value.toString());
                                    _dialogHeight = 250.0;
                                  });
                                },
                              ),
                              new Text(
                                ('reportYesterday').tr,
                                style: new TextStyle(fontSize: 16.0),
                              ),
                            ],
                          ),
                          new Row(
                            mainAxisAlignment: MainAxisAlignment.start,
                            children: <Widget>[
                              new Radio(
                                value: 3,
                                groupValue: _selectedperiod,
                                onChanged: (value) {
                                  setState(() {
                                    _dialogHeight = 350.0;
                                    _selectedperiod =
                                        int.parse(value.toString());
                                  });
                                },
                              ),
                              new Text(
                                ('reportCustom').tr,
                                style: new TextStyle(fontSize: 16.0),
                              ),
                            ],
                          ),
                          _selectedperiod == 3
                              ? new Container(
                              child: new Column(
                                children: <Widget>[
                                  Row(
                                    mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                    children: <Widget>[
                                      ElevatedButton(
                                        onPressed: () => _selectFromDate(
                                            context, setState),
                                        child: Text(
                                            formatReportDate(
                                                _selectedFromDate),
                                            style: TextStyle(
                                                color: Colors.white)),
                                      ),
                                      ElevatedButton(
                                        onPressed: () => _selectFromTime(
                                            context, setState),
                                        child: Text(
                                            formatReportTime(
                                                _selectedFromTime),
                                            style: TextStyle(
                                                color: Colors.white)),
                                      ),
                                    ],
                                  ),
                                  Row(
                                    mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                    children: <Widget>[
                                      ElevatedButton(
                                        onPressed: () =>
                                            _selectToDate(context, setState),
                                        child: Text(
                                            formatReportDate(_selectedToDate),
                                            style: TextStyle(
                                                color: Colors.white)),
                                      ),
                                      ElevatedButton(
                                        onPressed: () =>
                                            _selectToTime(context, setState),
                                        child: Text(
                                            formatReportTime(_selectedToTime),
                                            style: TextStyle(
                                                color: Colors.white)),
                                      ),
                                    ],
                                  )
                                ],
                              ))
                              : new Container(),
                          SizedBox(height: 10,),
                          Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: new Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: <Widget>[
                                Expanded(
                                  child: SizedBox(
                                    height: 40,
                                    child: CustomButton2(
                                      onTap: () {
                                        Navigator.of(context).pop();
                                      },
                                      text: 'cancel'.tr,
                                    ),
                                  ),
                                ),
                                SizedBox(width: 20), // Space between buttons
                                Expanded(
                                  child: SizedBox(
                                    height: 40,
                                    child: CustomButton(
                                      onTap: () {
                                        showReport(heading, device);      },
                                      text: 'Okay'.tr,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),


                          // new Row(
                          //   mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          //   children: <Widget>[
                          //     ElevatedButton(
                          //       style: ElevatedButton.styleFrom(
                          //         foregroundColor: Colors.red, // background
                          //         backgroundColor: Colors.white, // foreground
                          //       ),
                          //       onPressed: () {
                          //         Navigator.of(context).pop();
                          //       },
                          //       child: Text(
                          //         ('cancel').tr,
                          //         style: TextStyle(
                          //             fontSize: 18.0, color: Colors.red),
                          //       ),
                          //     ),
                          //     SizedBox(
                          //       width: 20,
                          //     ),
                          //     ElevatedButton(
                          //       onPressed: () {
                          //         showReport(heading, device);
                          //       },
                          //       child: Text(
                          //         ('ok').tr,
                          //         style: TextStyle(
                          //             fontSize: 18.0, color: Colors.white),
                          //       ),
                          //     ),
                          //   ],
                          // )
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
    showDialog(
        context: context, builder: (BuildContext context) => simpleDialog);
  }

  Future<void> _selectFromDate(
      BuildContext context, StateSetter setState) async {
    DateTime currentDate = DateTime.now();
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedFromDate,
      firstDate: DateTime(2015, 8),
      lastDate: currentDate,
    );

    if (picked != null && picked != _selectedFromDate) {
      setState(() {
        _selectedToDate = currentDate;
      });
      // Calculate the maximum selectable date (7 days after picked date)
      DateTime maxDate = picked.add(Duration(days: 0));

      // Check if _selectedToDate exceeds maxDate
      if (_selectedToDate.isAfter(maxDate)) {
        setState(() {
          _selectedToDate = maxDate;
        });
      }

      setState(() {
        _selectedFromDate = picked;
      });
    }
  }

  Future<void> _selectToDate(BuildContext context, StateSetter setState) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedToDate,
      firstDate: _selectedFromDate,
      lastDate: _selectedFromDate.add(Duration(days: 7)),
    );

    if (picked != null && picked != _selectedToDate) {
      setState(() {
        _selectedToDate = picked;
      });
    }
  }

  Future<void> _selectFromTime(
      BuildContext context, StateSetter setState) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _selectedFromTime,
      builder: (BuildContext context, Widget? child) {
        return Directionality(
          textDirection: m.TextDirection.rtl,
          child: child != null ? child : new Container(),
        );
      },
    );
    if (picked != null && picked != _selectedFromTime)
      setState(() {
        _selectedFromTime = picked;
      });
  }

  Future<void> _selectToTime(BuildContext context, setState) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
      builder: (BuildContext context, Widget? child) {
        return Directionality(
          textDirection: m.TextDirection.rtl,
          child: child != null ? child : new Container(),
        );
      },
    );
    if (picked != null && picked != _selectedToTime)
      setState(() {
        _selectedToTime = picked;
      });
  }

  void showCommandDialog(BuildContext context, Device device) {
    _commands.clear();

    // if (_commands[_selectedCommand] == "custom") {
    //   _dialogCommandHeight = 220.0;
    // }

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
                                          child: new Text(
                                            (value).tr,
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
                                      foregroundColor:
                                      Colors.red, // background
                                      backgroundColor:
                                      Colors.white, // foreground
                                    ),
                                    onPressed: () {
                                      Navigator.of(context).pop();
                                    },
                                    child: Text(
                                      ('cancel').tr,
                                      style: TextStyle(
                                          fontSize: 18.0, color: Colors.red),
                                    ),
                                  ),
                                  SizedBox(
                                    width: 20,
                                  ),
                                  ElevatedButton(
                                    onPressed: () {
                                      sendCommand(device);
                                    },
                                    child: Text(
                                      ('ok').tr,
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

  void showReport(String heading, Device device) {
    String from;
    String to;

    DateTime current = DateTime.now().toUtc();

    String month;
    String day;
    if (current.month < 10) {
      month = "0" + current.month.toString();
    } else {
      month = current.month.toString();
    }

    if (current.day < 10) {
      day = "0" + current.day.toString();
    } else {
      day = current.day.toString();
    }

    if (_selectedperiod == 0) {
      var date = DateTime.parse("${current.year}-"
          "$month-"
          "$day "
          "00:00:00");
      from = date.toUtc().toIso8601String();
      to = DateTime.now().toUtc().toIso8601String();
    } else if (_selectedperiod == 1) {
      String yesterday;

      int dayCon = current.day - 1;
      if (current.day <= 10) {
        yesterday = "0" + dayCon.toString();
      } else {
        yesterday = dayCon.toString();
      }

      var start = DateTime.parse("${current.year}-"
          "$month-"
          "$yesterday "
          "00:00:00");

      var end = DateTime.parse("${current.year}-"
          "$month-"
          "$yesterday "
          "24:00:00");

      from = start.toUtc().toIso8601String();
      to = end.toUtc().toIso8601String();
    } else if (_selectedperiod == 2) {
      from = current.subtract(Duration(days: 7)).toIso8601String();
      to = current.toIso8601String();
    } else {
      // Ensure selectedFromDate and selectedToDate are not null before parsing
      DateTime? selectedFromDateTime = _selectedFromDate != null
          ? DateTime(
          _selectedFromDate.year,
          _selectedFromDate.month,
          _selectedFromDate.day,
          _selectedFromTime.hour,
          _selectedFromTime.minute)
          : null;

      DateTime? selectedToDateTime = _selectedToDate != null
          ? DateTime(_selectedToDate.year, _selectedToDate.month,
          _selectedToDate.day, _selectedToTime.hour, _selectedToTime.minute)
          : null;

      if (selectedFromDateTime != null && selectedToDateTime != null) {
        from = selectedFromDateTime.toUtc().toIso8601String();
        to = selectedToDateTime.toUtc().toIso8601String();
      } else {



        print('Error: selectedFromDate or selectedToDate is null');
        return;
      }
    }

    Navigator.pop(context);
    if (heading == "report") {
      Navigator.pushNamed(context, "/reportList",
          arguments:
          ReportArguments(device.id!, from, to, device.name!, device));
    } else {
      Navigator.pushNamed(context, "/playback",
          arguments:
          ReportArguments(device.id!, from, to, device.name!, device));
    }
  }

  Future<void> _showEngineOnOFF(Device device) async {
    Widget cancelButton = TextButton(
      child: Text(('cancel').tr),
      onPressed: () {
        Navigator.pop(context);
      },
    );

    Widget onButton = TextButton(
      child: Text(('on').tr),
      onPressed: () {
        sendLockCommand('engineResume', device);
      },
    );
    Widget offButton = TextButton(
      child: Text(('off').tr),
      onPressed: () {
        sendLockCommand('engineStop', device);
      },
    );
    // set up the AlertDialog
    AlertDialog alert = AlertDialog(
      title: Text(('fuelCutOff').tr),
      content: Text(('areYouSure').tr),
      actions: [
        cancelButton,
        onButton,
        offButton,
      ],
    );

    // show the dialog
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return alert;
      },
    );
  }

  void sendLockCommand(String commandTxt, Device device) {
    Command command = Command();
    command.deviceId = device.id.toString();
    command.type = commandTxt;

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

  String _CARoFF_on(double? speed,String? status) {

    if(speed! >= 2.7 && status=='online'){
      return "online";
    }else{
      return "offline";
    }
  }

  void DrivenData()async {model = await getDrivenData();}
}