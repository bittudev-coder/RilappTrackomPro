import 'dart:convert';
import 'package:http/http.dart' as http;

import '../../Config.dart';
import '../../storage/user_repository.dart';

// Define the model for a single item
class DrivenTodayItem {
  final String deviceId;
  final String odometer;

  DrivenTodayItem({
    required this.deviceId,
    required this.odometer,
  });

  factory DrivenTodayItem.fromJson(Map<String, dynamic> json) {
    return DrivenTodayItem(
      deviceId: json['deviceid'],
      odometer: json['odometer'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'deviceid': deviceId,
      'odometer': odometer,
    };
  }
}

// Define the model for the whole response
class DrivenTodayModel {
  final List<DrivenTodayItem> items;
  DrivenTodayModel({
    required this.items,
  });

  factory DrivenTodayModel.fromJson(Map<String, dynamic> json) {
    List<dynamic> dataJson = json['data'];
    List<DrivenTodayItem> items = dataJson.map((item) => DrivenTodayItem.fromJson(item)).toList();
    return DrivenTodayModel(items: items);
  }

  List<dynamic> toJson() {
    return items.map((item) => item.toJson()).toList();
  }

  // Method to get odometer by deviceId
  String getOdometerByDeviceId(String deviceId) {
    for (var item in items) {
      if (item.deviceId == deviceId) {
        return item.odometer;
      }
    }
    return "0"; // Default value if deviceId is not found
  }
}

// Function to get the data
Future<DrivenTodayModel?> getDrivenData() async {
  Map<String, String> header = {
    'api-key': API_KEY,
  };
  final response = await http.get(
    Uri.parse(DRIVEN_TODAY+"${UserRepository.prefs.getString("userId")}"),
    headers: header,
  );

  if (response.statusCode == 200) {
    print(response.body);
    Map<String, dynamic> jsonResponse = json.decode(response.body);
    return DrivenTodayModel.fromJson(jsonResponse);
  } else {
    print('Error: ${response.statusCode}');
    return null;
  }
}

