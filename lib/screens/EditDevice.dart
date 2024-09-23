import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:gpspro/theme/CustomColor.dart';
import '../src/model/EditDevices.dart';
import '../storage/dataController/DataController.dart';
import '../theme/ConstColor.dart';
import '../traccar_gennissi.dart';
import '../widgets/AlertDialogCustom.dart';
import '../widgets/CustomButton.dart';
import '../widgets/CustomInputField.dart';
import '../widgets/CustomText.dart';
import 'CommonMethod.dart';

class DeviceEdit extends StatefulWidget {
  const DeviceEdit({super.key});

  @override
  State<DeviceEdit> createState() => _DeviceEditState();
}

class _DeviceEditState extends State<DeviceEdit> {
  final FocusNode _focusNode = FocusNode();
  final TextEditingController _DeviceNaneFilter = TextEditingController();
  final TextEditingController _DeviceSpeedFilter = TextEditingController();
   late bool isLoading;
  var _ImageIcon = [
    'images/marker_car_online.png',
    'images/marker_bus_online.png',
    'images/marker_tractor_online.png',
    'images/marker_motorcycle_online.png',
    'images/marker_truck_online.png',
    'images/marker_person_online.png',
  ];
  late String DataJson;
  int? selectedIndex;
  VehicleData? vehicle;
  double title = 14;
  double subtext = 13;
  String fLastUpdate = 'noData'.tr;
  @override
  void dispose() {
    _DeviceSpeedFilter.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Devices'),
      ),
      body: GetX<DataController>(
        init: DataController(),
        builder: (controller) {
          List<Device> devicesList = controller.devices.values.toList();
           isLoading = controller.isLoading.value;

          if (isLoading) {
            return Center(child: CircularProgressIndicator());
          }

          return devicesList.isNotEmpty
              ? ListView.builder(
            itemCount: devicesList.length,
            itemBuilder: (context, index) {
              final device = devicesList[index];
              return deviceList(device, context,index);
            },
          )
              : Center(
            child: Text("noDeviceFound".tr), // Ensure this is a valid translation key
          );
        },
      ),
    );
  }

  Widget deviceList(Device device, BuildContext context,int index) {
    final gradientIndex = index % gradients.length;
    if (device.lastUpdate != null) {
    }

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
            InkWell(
              onTap: () {
                FocusScope.of(context).unfocus();
                // onSheetShowContents(context, device);
              },
              child: Column(
                children: [
                  Container(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Row(
                              children: <Widget>[
                                Icon(Icons.radio_button_checked, size: 18.0),
                                Padding(padding: EdgeInsets.fromLTRB(5, 0, 0, 0)),
                                Container(
                                  width: MediaQuery.of(context).size.width * 0.60,
                                  child:Text(
                                      safeUtf8Decode(device.name?.codeUnits ?? []),
                                      style: TextStyle(fontSize: title, fontWeight: FontWeight.bold),
                                      overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                            InkWell(
                              onTap: () {
                                _fetchVehicleData(device.id.toString());
                              },
                              child: Icon(Icons.edit, color: CustomColor.primaryColor, size: 25.0),
                            ),
                          ],
                        ),
                        Divider(thickness: 1),
                        Row(
                          children: [
                            Image.asset('images/marker_${device.category}_online.png', scale: 3),
                            Expanded(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.start,
                                children: [
                                  Row(
                                    children: <Widget>[
                                      Expanded(
                                        child: Column(
                                          mainAxisAlignment: MainAxisAlignment.start,
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              "IMEI: ${device.uniqueId}",
                                              style: TextStyle(fontSize: 14.0), // Adjust as needed
                                              textAlign: TextAlign.left,
                                              maxLines: 2,
                                              overflow: TextOverflow.ellipsis, // Ensure text does not overflow
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: <Widget>[
                                      Text("Activation Date: ${formatDate(device.contact!)}"),
                                    ],
                                  ),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: <Widget>[
                                      Text("Mobile No: ${device.id}"),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text("Speed Limit", style: TextStyle(fontSize: 13)),
                                Row(
                                  children: <Widget>[
                                    Padding(padding: EdgeInsets.fromLTRB(5, 5, 0, 0)),
                                    Icon(Icons.speed, size: 18.0),
                                    SizedBox(width: 10),
                                    Text(roundSpeedLimit(device.attributes!['speedLimit'].toString()))
                                  ],
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
          ],
        ),
      ),
    );
  }

  String roundSpeedLimit(String? value) {
    if (value == null || value.isEmpty) {
      return '---';  // Return '0' for null or empty input
    }
    try {
      // Parse the string to double
      double parsedValue = double.parse(value)*1.852;

      // Round the double value
      int roundedValue = parsedValue.round();

      // Convert the rounded value to a string
      return roundedValue.toString();
    } catch (e) {
      // Handle any parsing errors
      print('Error parsing value: $e');
      return '---';  // Return '---' in case of any error
    }
  }




  void showReportDialog(BuildContext context) {
    Dialog simpleDialog = Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.0),
      ),
      child: StatefulBuilder(
        builder: (BuildContext context, StateSetter setState) {
          return Container(
            decoration: BoxDecoration(
              color: Colors.blue.shade50, // Set the background color
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
            height: 455,
            child: SingleChildScrollView(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                children: <Widget>[
                  Padding(
                    padding: const EdgeInsets.only(left: 10, right: 10, top: 5),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            CustomText(TxtName:  "Edit Device", ),
                          ],
                        ),
                        // Container(
                        //   child: TextField(
                        //     controller: _DeviceNaneFilter,
                        //     decoration: InputDecoration(labelText: 'Device Name'.tr),
                        //   ),
                        // ),
                        SizedBox(height: 20),
                        CustomInputField(
                          textEditingController: _DeviceNaneFilter,
                          labelText: 'Device Name'.tr,
                          icon: Icon(Icons.radio_button_checked),
                        ),
                        SizedBox(height: 25),
                        CustomInputField(
                          textEditingController: _DeviceSpeedFilter,
                          labelText: 'Device Speed Limit'.tr,
                          icon: Icon(Icons.speed),
                          keyboardType: TextInputType.number, focusNode: _focusNode,
                        ),

                        // Container(
                        //   child: TextField(
                        //     keyboardType:TextInputType.number ,
                        //     focusNode: _focusNode,
                        //     controller: _DeviceSpeedFilter,
                        //     decoration: InputDecoration(labelText: 'Device Speed Limit'.tr),
                        //   ),
                        // ),
                        SizedBox(height: 15),
                        CustomText(TxtName:  "Device Icon", ),
                        SizedBox(height: 10),
                        SizedBox(
                          height: 170, // Adjust height as needed
                          child: GridView.builder(
                            itemCount: _ImageIcon.length,
                            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 3,
                              crossAxisSpacing: 10.0,
                              mainAxisSpacing: 10.0,
                              childAspectRatio: 1.0,
                            ),
                            itemBuilder: (context, index) {
                              return GestureDetector(
                                onTap: () {
                                  setState(() {
                                    selectedIndex = index;
                                  });
                                },
                                child: Container(
                                  margin: EdgeInsets.all(4.0), // Margin around each item
                                  padding: EdgeInsets.all(8.0), // Padding inside each item
                                  decoration: BoxDecoration(
                                    color: Colors.white, // Background color
                                    border: Border.all(
                                      color: selectedIndex == index ? Colors.blue : Colors.transparent, // Conditional border color
                                      width: 2, // Border width
                                    ),
                                    borderRadius: BorderRadius.circular(8.0), // Rounded corners
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.1), // Shadow color
                                        spreadRadius: 2, // Shadow spread radius
                                        blurRadius: 5, // Shadow blur radius
                                        offset: Offset(0, 2), // Shadow offset
                                      ),
                                    ],
                                  ),
                                  child:Image.asset(_ImageIcon[index],),
                                ),
                              );
                            },
                          ),
                        ),
                        SizedBox(height:10),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: <Widget>[
                            Expanded(
                              child: SizedBox(
                                height: 40,
                                child: CustomButton2(
                                  onTap: () {
                                    Navigator.of(context).pop();
                                  },
                                  text: 'Cancel'.tr,
                                ),
                              ),
                            ),
                            SizedBox(width: 20), // Space between buttons
                            Expanded(
                              child: SizedBox(
                                height: 40,
                                child: CustomButton(
                                  onTap: () {
                                    if (vehicle != null && selectedIndex != null) {
                                      Map<String, dynamic> jsonData = json.decode(DataJson);
                                      jsonData['attributes']['speedLimit'] = OdometerFun(_DeviceSpeedFilter.text);
                                      jsonData['category'] = SelectedIcon(selectedIndex!);
                                      jsonData['name'] = _DeviceNaneFilter.text;
                                      Navigator.of(context).pop();
                                      updateDevices(jsonEncode(jsonData), vehicle!.id.toString());
                                    }
                                  },
                                  text: 'Update'.tr,
                                ),
                              ),
                            ),
                          ],
                        ),

                        SizedBox(height:10),
                      ],
                    ),
                  ),
                ],
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





  int SelectImageIcon(String vehicleCategory) {
    switch (vehicleCategory) {
      case 'car':
        return 0;
      case 'bus':
        return 1;
      case 'tractor':
        return 2;
      case 'motorcycle':
        return 3;
      case 'truck':
        return 4;
      default:
        return 5; // 'person' icon
    }
  }
  String SelectedIcon(int vehicleCategory) {
    switch (vehicleCategory) {
      case 0:
        return 'car';
      case 1:
        return 'bus';
      case 2:
        return 'tractor';
      case 3:
        return 'motorcycle';
      case 4:
        return 'truck';
      default:
        return 'person';
    }
  }

  void updateDevices(String data, String deviceId) {
    Traccar.updateDevices(data, deviceId);
    AlertDialogCustom().showHintDialog(
      context,
      'Device Updated Successfully'.tr,
      'Updated'.tr,
      'ok'.tr
    );
    Get.find<DataController>().getDevices();
    setState(() {});

  }


  void _fetchVehicleData(String id) {
    Traccar.getDeviceDataJson(id).then((responseBody) {
      if (responseBody != null) {
        DataJson=responseBody;
        try {
          Map<String, dynamic> jsonResponse = json.decode(responseBody);
          VehicleData vehicleData = VehicleData.fromJson(jsonResponse);
          selectedFiled();
          vehicle = vehicleData;
          print('Vehicle data fetched successfully: ${vehicle?.name}');
          _DeviceNaneFilter.text = vehicle?.name ?? '';
          _DeviceSpeedFilter.text = ShowTextSpeedLimit(roundSpeedLimit(vehicle?.attributes?['speedLimit'].toString() ?? ''));
          selectedIndex = SelectImageIcon(vehicle!.category!);
          showReportDialog(context);
        } catch (e) {
          print('Error parsing JSON: $e');
        }
      } else {
        print('No vehicle data found');
      }
    }).catchError((error) {
      print('Error fetching vehicle data: $error');
    });
  }


  String ShowTextSpeedLimit(String speed){
    if(speed=="---"){
      return "";
    }
    return speed;
  }
  void selectedFiled() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
      // Optionally, you can select all text
      _DeviceSpeedFilter.selection = TextSelection(
        baseOffset: 0,
        extentOffset: _DeviceSpeedFilter.text.length,
      );
    });
  }

  String OdometerFun(String speed) {
    if(speed=="" || speed=="0"){
      return "";
    }else{
      return convertOdometer(double.parse(speed));
    }
  }
  String safeUtf8Decode(List<int> bytes) {
    try {
      return utf8.decode(bytes, allowMalformed: true);
    } catch (e) {
      // Handle the decoding error or return a default value
      return "Invalid data";
    }
  }

}
