
class VehicleData {
  int? id;
  Map<String, dynamic>? attributes;
  int? groupId;
  String? name;
  String? uniqueId;
  String? status;
  String? lastUpdate;
  String? geofenceIds;
  int? positionId;
  String? phone;
  String? model;
  String? contact;
  String? category;
  bool? disabled;
  String? expirationTime;

  VehicleData({
    this.id,
    this.attributes,
    this.groupId,
    this.name,
    this.uniqueId,
    this.status,
    this.lastUpdate,
    this.geofenceIds,
    this.positionId,
    this.phone,
    this.model,
    this.contact,
    this.category,
    this.disabled,
    this.expirationTime,
  });

  factory VehicleData.fromJson(Map<String, dynamic> json) {
    return VehicleData(
      id: json["id"],
      attributes: json["attributes"],
      groupId: json["groupId"],
      name: json["name"],
      uniqueId: json["uniqueId"],
      status: json["status"],
      lastUpdate: json["lastUpdate"],
      geofenceIds: json["geofenceIds"],
      positionId: json["positionId"],
      phone: json["phone"],
      model: json["model"],
      contact: json["contact"],
      category: json["category"],
      disabled: json["disabled"],
      expirationTime: json["expirationTime"],
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'attributes': attributes,
    'groupId': groupId,
    'name': name,
    'uniqueId': uniqueId,
    'status': status,
    'lastUpdate': lastUpdate,
    'geofenceIds': geofenceIds,
    'positionId': positionId,
    'phone': phone,
    'model': model,
    'contact': contact,
    'category': category,
    'disabled': disabled,
    'expirationTime': expirationTime
  };
}
