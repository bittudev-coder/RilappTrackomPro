import 'dart:collection';
import 'dart:convert';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:gpspro/arguments/ReportEventArguments.dart';
import 'package:gpspro/screens/CommonMethod.dart';
import 'package:gpspro/storage/dataController/DataController.dart';
import 'package:gpspro/theme/CustomColor.dart';
import 'package:gpspro/widgets/CustomButton.dart';
import '../../traccar_gennissi.dart';
import '../Config.dart';
import '../theme/ConstColor.dart';
import 'LineChart.dart';
import 'defaultGraphLine.dart';

class DashboardPage extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => new _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> with SingleTickerProviderStateMixin {

  String selectedIndex = "all";
  User? user;
  List<Event> eventList = [];
  Map<int, Device> devices = new HashMap();
  Map<int, PositionModel> positions = {};
  var deviceId = [];
  var positionId = [];
  bool isLoading = true;
  bool isEventLoading = true;
  String StatusPositon='';
  late Locale myLocale;
  String defaultValue = "";
  String defaultName = "Select Device";
  int online = 0, offline = 0,All=0,moving=0,stopped=0,egnOn=0,egnOff=0;
  GlobalKey<ScaffoldState> _drawerKey = GlobalKey();
  TextEditingController _searchController = new TextEditingController();

  TextEditingController textEditingController = new TextEditingController();
  List<Device> _searchResult = [];
  List<Device> _graph_searchResult = [];
  List<Device> devicesList = [];
  List<PositionModel> positionList=[];
  List<Device> filteredSearch=[];
  List<Device> _OthersearchResult=[];
  late int Total=0;
  void getDevice(DataController controller) {
    All=devicesList.length;
    devicesList.forEach((device) {
      try {
        final status = device.status;
        final position = positions[device.id];

        if (status == 'online') {
          online++;
          if (position != null && position.speed! >= 2.7) {
            moving++;
          } else {
            stopped++;
          }
        } else if (status == 'unknown' || status == 'offline') {
          offline++;
        }

        // Handle ignition state
        if (position != null) {
          final isIgnitionOn = position.attributes!["ignition"];
          if (isIgnitionOn) {
            egnOn++;
          } else {
            egnOff++;
          }
        }
      } catch (e) {
        // Handle exceptions, if necessary
      }
    });
  }









  late AnimationController _animationController;
  late Animation<double> _animation;

  List<String> get dataLabels {
    return [
      "All\n $All ",
      "Moving\n $moving",
      "Stopped\n $stopped",
      "Engine\n On $egnOn",
      "Engine\n Off $egnOff",
      "Offline\n $offline",
      "Online\n $online" // Use a dynamic variable if needed
    ];
  }



  List<Color> colorList = [
    Color(0xFFf68080),
    Color(0xFF2A9D8F),
    Color(0xFF72bad5),
    Color(0xFFfa7aa6),
    Color(0xFF03324e),
    Color(0xFFb5c6e0),
    Color(0xFF066839),
  ];

  int? _tappedIndex;
  List<int> _animatedIndices = []; // To keep track of animated indices

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _animation = Tween<double>(begin: 1.0, end: 1.2).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));

    // Start sequential animation after widget build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _startSequentialAnimation();
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _startSequentialAnimation() async {
    for (int i = 0; i < dataLabels.length; i++) {
      await Future.delayed(const Duration(milliseconds: 80 ));
      setState(() {
        _animatedIndices.add(i);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          '${SPLASH_SCREEN_TEXT2
          }'.tr,
          style: TextStyle(
            color: CustomColor.secondaryColor,
            fontWeight: FontWeight.w600,
          ),
        ),
        automaticallyImplyLeading: false,
      ),
      body: GetX<DataController>(
        init: DataController(),
        builder: (controller) {
          devicesList = controller.devices.values.toList();
          positions = controller.positions;
          return SingleChildScrollView(
            child: Column(
              children: [
                SizedBox(height: 10),
                SizedBox(
                  height: 250,
                  width: MediaQuery.of(context).size.width * 0.98,
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.blue.withOpacity(0.2),
                          spreadRadius: 2,
                          blurRadius: 12,
                          offset: Offset(0, 6),
                        ),
                      ],
                    ),
                    alignment: Alignment.center,
                    padding: const EdgeInsets.all(12),
                    child:

                         loadView(controller), // Your existing loadView logic
                  ),
                ),
                SizedBox(height: 10),
                SizedBox(
                  height: 300,
                  width: MediaQuery.of(context).size.width * 0.97,
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.blue.withOpacity(0.2),
                          spreadRadius: 2,
                          blurRadius: 12,
                          offset: Offset(0, 6),
                        ),
                      ],
                    ),
                    alignment: Alignment.center,
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Last 7 days KM Run'.toUpperCase(),
                              style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                            ),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Icon(Icons.directions_car_filled),
                                InkWell(
                                  onTap: () {
                                    _searchController.text="";
                                    _drawerKey.currentState!.openDrawer();
                                    setState(() {});
                                  },
                                  child: Container(
                                    height: 40,
                                    width: 120,
                                    decoration: BoxDecoration(
                                      border: Border.all(
                                        color: CustomColor.backgroundOffColor,
                                        width: 1.0,
                                      ),
                                      borderRadius: BorderRadius.circular(8.0),
                                    ),
                                    alignment: Alignment.center,
                                    child: Text(
                                      defaultName,
                                      style: TextStyle(
                                        color: Colors.black,
                                        fontSize: 16,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        Divider(
                          thickness: 2,
                          color: Colors.grey[300],
                        ),
                        Expanded(
                          child: ChartLine(context), // Ensure this widget is defined
                        ),

                      ],
                    ),
                  ),
                ),
                SizedBox(height: 80)
              ],
            ),
          );
        },
      )
        ,
      key: _drawerKey,
      drawer:  Center(child: Container(
        child: SizedBox(width: 250, height:400,child:  navDrawer()),))
    );
  }

  Widget loadView(DataController controller) {
     online = 0; offline = 0;All=0;moving=0;stopped=0;egnOn=0;egnOff=0;
    getDevice(controller);
    final double valuePerSection = 100.0 / dataLabels.length;
    return Column(
      children: <Widget>[
        SizedBox(
          height: 220,
          child: AnimatedBuilder(
            animation: _animation,
            builder: (context, child) {
              return PieChart(
                PieChartData(
                  sections: dataLabels.asMap().entries.map((entry) {
                    final index = entry.key;
                    final label = entry.value;
                    final colorIndex = index % colorList.length;
                    bool isTapped = _tappedIndex != null && _tappedIndex == index;
                    bool isVisible = _animatedIndices.contains(index);
                    return isVisible
                        ? PieChartSectionData(
                      color: colorList[colorIndex],
                      value: valuePerSection,
                      title: label,
                      radius: isTapped ? 60 * _animation.value : 65,
                      titleStyle: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.white),
                    )
                        : PieChartSectionData(
                      color: Colors.transparent, // Hide the section until animated
                      value: 0,
                      title: '',
                      radius: 0,
                    );
                  }).toList(),
                  borderData: FlBorderData(
                    show: true,
                    border: Border.all(color: Colors.black, width: 20, style: BorderStyle.solid),
                  ),
                  sectionsSpace: 0,
                  centerSpaceRadius: 50,
                  pieTouchData: PieTouchData(
                    touchCallback: (FlTouchEvent event, pieTouchResponse) {
                      if (event is FlTapUpEvent && pieTouchResponse != null && pieTouchResponse.touchedSection != null) {
                        final sectionIndex = pieTouchResponse.touchedSection!.touchedSectionIndex;
                        setState(() {
                          _tappedIndex = sectionIndex;
                          _animationController.forward().then((_) {
                            _animationController.reverse();
                            deviceListFilter(sectionIndex);
                          });
                        });
                      }
                    },
                  ),
                ),
              );
            },
          ),
        )
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
  ChartLine(BuildContext context) {
    DateTime today = DateTime.now();
    DateTime yesterday = today.subtract(Duration(days: 0));
    DateTime sevenDaysBeforeYesterday = yesterday.subtract(Duration(days: 7));

    String yesterdayStr = formatDate(yesterday);
    String sevenDaysBeforeYesterdayStr = formatDate(sevenDaysBeforeYesterday);

      if(defaultValue==""){
    return LineChartSample();}
      else{
        return LineChartSample5(defaultValue,sevenDaysBeforeYesterdayStr,yesterdayStr,"distance");
      }
  }
  String formatDate(DateTime date) {
    String year = date.year.toString().padLeft(4, '0');
    String month = date.month.toString().padLeft(2, '0');
    String day = date.day.toString().padLeft(2, '0');
    return '$year-$month-$day';
  }
  void showPieChartDialog(BuildContext context, String label) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Pie Chart Section'),
          content: Text('You selected: $label'),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close the dialog
              },
              child: Text('Close'),
            ),
          ],
        );
      },
    );
  }

  graph_onSearchTextChanged(String text) async {
    _graph_searchResult.clear();
      devicesList.forEach((device) {
        if (device.name!.toLowerCase().contains(text.toLowerCase())) {
          _graph_searchResult.add(device);
        }
      });
    setState(() {});
  }

  Widget navDrawer() {
    return Drawer(
        child: new Column(children: <Widget>[
          new Container(
            color:color[900],
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
                    onChanged: graph_onSearchTextChanged,
                  ),
                  trailing: new IconButton(
                    icon: new Icon(Icons.cancel),
                    onPressed: () {
                      _searchController.clear();
                      graph_onSearchTextChanged('');
                    },
                  ),
                ),
              ),
            ),
          ),
          new Expanded(
              child: _graph_searchResult.length != 0 || _searchController.text.isNotEmpty
                  ? new ListView.builder(
                itemCount: _graph_searchResult.length,
                itemBuilder: (context, index) {
                  final device = _graph_searchResult[index];
                  return deviceCard(device, context);
                },
              )
                  : selectedIndex == "all"
                  ? new ListView.builder(
                  itemCount: devicesList.length,
                  itemBuilder: (context, index) {
                    final device = devicesList[index];
                    return deviceCard(device, context);
                  })
                  : new ListView.builder(
                  itemCount: 0,
                  itemBuilder: (context, index) {
                    return Text(("noDeviceFound").tr);
                  }))
        ]));
  }

  Widget deviceCard(Device device, BuildContext context) {

    return new Card(
      elevation: 2.0,
      child: Padding(
        padding: new EdgeInsets.all(1.0),
        child: ListTile(
          title: Center(child: Text(device.name!,style: TextStyle(fontSize: 16,fontWeight: FontWeight.w600),)),
          onTap: () => {
          setState(() {
          }),
            defaultValue=device.id.toString(),
            defaultName=device.name!,
          _drawerKey.currentState!.closeDrawer(),
            setState(() {}),
          },
        ),
      ),
    );

  }

   deviceListFilter(int sectionIndex) {
     _searchResult.clear();
     _OthersearchResult.clear();
     textEditingController.text="";
     if (sectionIndex == 0) {
       showReportDialog(context, devicesList);
     }

     if (sectionIndex != 0) {
       devicesList.forEach((device) {
       if (sectionIndex == 6) {
         if (device.status == 'online') {
           _searchResult.add(device);
           _OthersearchResult.add(device);
           online++;
         }
       }
       else if (sectionIndex == 5) {
         if (device.status == "unknown" || device.status == "offline") {
           _searchResult.add(device);
           _OthersearchResult.add(device);
           offline++;
         }
       }

         else if (sectionIndex == 1) {
           try{
             if (device.status!.contains("online")) {
               if (device.status == "online" &&
                   positions[device.id]!.speed! >= 2.7) {
                    _searchResult.add(device);
                 _OthersearchResult.add(device);
                 moving++;
               }
             }
           }catch(e){
           }

       }
         else if (sectionIndex == 2) {
         try{
           if (device.status!.contains("online")) {
             if (device.status == "online" &&
                 positions[device.id]!.speed! <= 2.7) {
               _searchResult.add(device);
               _OthersearchResult.add(device);
               stopped++;
             }
           }
         }catch(e){

         }
       }

         else if (sectionIndex == 3) {
         try{

           if (positions[device.id]!.attributes!["ignition"]) {
             _searchResult.add(device);
             _OthersearchResult.add(device);
             egnOff++;
           }
         }catch(e){}
       } else if (sectionIndex == 4) {
         try{
           if (positions[device.id]!.attributes!["ignition"]) {
           } else {
             _searchResult.add(device);
             _OthersearchResult.add(device);
             egnOff++;
           }
         }catch(e){}

       }
     });
       showReportDialog(context, _searchResult);
     }
   }

  void showReportDialog(BuildContext context, List<Device> devicesList) {
    Dialog simpleDialog = Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.0),
      ),
      child: StatefulBuilder(
        builder: (BuildContext context, StateSetter setState) {
          return Scaffold(body: Container(
            height: MediaQuery.of(context).size.height,
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height,
            ),
            child:  Column(
              children: [
                Container(
                  color: CustomColor.backgroundOffColor,
                  child: Padding(
                    padding: const EdgeInsets.all(1.0),
                    child: Card(
                      child: ListTile(
                        leading: Icon(Icons.search),
                        title: TextField(
                          controller: textEditingController,
                          decoration: InputDecoration(
                              hintText: 'Search', border: InputBorder.none),
                          onChanged: (text) {
                            onSearchTextChanged(text);
                            setState(() {}); // Refresh the widget
                          },
                        ),
                        trailing: user != null
                            ? user!.deviceReadonly!
                            ? IconButton(
                          icon: Icon(Icons.cancel),
                          onPressed: () {
                            textEditingController.clear();
                            onSearchTextChanged('');
                            setState(() {});
                          },
                        )
                            : FloatingActionButton(
                          heroTag: "addButton",
                          onPressed: () {
                            Navigator.pushNamed(context, "/addDevice");
                          },
                          mini: true,
                          child: Icon(Icons.add),
                          backgroundColor: CustomColor.primaryColor,
                        )
                            : IconButton(
                          icon: Icon(Icons.cancel),
                          onPressed: () {
                            textEditingController.clear();
                            onSearchTextChanged('');
                            setState(() {});
                          },
                        ),
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: _searchResult.isNotEmpty || textEditingController.text.isNotEmpty
                      ? ListView.builder(
                    itemCount: _searchResult.length,
                    itemBuilder: (context, index) {
                      final device = _searchResult[index];
                      return Pie_deviceCard(device, context,index);
                    },
                  )
                      : ListView.builder(
                    itemCount: devicesList.length,
                    itemBuilder: (context, index) {
                      final device = devicesList[index];
                      return Pie_deviceCard(device, context,index);
                    },
                  ),
                ),

              ],
            ),
          ),
            floatingActionButton: Padding(
              padding: const EdgeInsets.only(left: 180), // Adjust top padding here
              child: Align(
                alignment: Alignment.bottomLeft,
                child: CustomButton(text:"Close",onTap:Navigator.of(context).pop)
              ),
            ),
          );
        },
      ),
    );

    showDialog(
      context: context,
      builder: (BuildContext context) => simpleDialog,
    );
  }
  Widget Pie_deviceCard(Device device, BuildContext context,int index) {
    final gradientIndex = index % gradients.length;
    String fLastUpdate = ('noData').tr;
    if (device.lastUpdate != null) {
      fLastUpdate = formatTime(device.lastUpdate!);
    }
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
        padding: EdgeInsets.all(12.0),
        child: Column(
          children: <Widget>[
            Column(
              children: [
                Container(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Row(
                        children: <Widget>[
                          Icon(Icons.radio_button_checked, size: 18.0),
                          Container(
                            width: MediaQuery.of(context).size.width * 0.60,
                            child: Text(
                              device.name != null
                                  ? utf8.decode(device.name!.codeUnits, allowMalformed: true)
                                  : 'No Name',
                              style: TextStyle(fontSize: title, fontWeight: FontWeight.bold),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      Divider(thickness: 1),
                      Row(
                        children: [

                          SizedBox(width: 5,),
                          // Information column
                          Expanded(
                            child:Row(
                              children: [
                       Text("Last Update:" ,style: TextStyle(fontSize: 12),),
                                SizedBox(width: 5),
                                Text(
                                  fLastUpdate,
                                  style: TextStyle(fontSize: 12),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

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


}

