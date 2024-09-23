class GeofencePermModel extends Object {
  int? deviceId;
  int? geofenceId;

  GeofencePermModel({deviceId, geofenceId});

  GeofencePermModel.fromJson(Map<String, dynamic> json) {
    deviceId = json["deviceId"];
    geofenceId = json["geofenceId"];
  }

  Map<String, dynamic> toJson() => {
    'deviceId': deviceId,
    'geofenceId': geofenceId,
  };
}

class NotificationPermModel extends Object {
  int? deviceId;
  int? notificationId;

  NotificationPermModel({deviceId, notificationId});

  NotificationPermModel.fromJson(Map<String, dynamic> json) {
    deviceId = json["deviceId"];
    notificationId = json["notificationId"];
  }

  Map<String, dynamic> toJson() => {
    'deviceId': deviceId,
    'notificationId': notificationId,
  };
}
