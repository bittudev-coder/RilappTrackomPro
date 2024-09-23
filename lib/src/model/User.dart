
import 'package:json_annotation/json_annotation.dart';
part 'User.g.dart';

@JsonSerializable()
class User{

  int? id;
  Map<String, dynamic>? attributes;
  String? name;
 String? login;
  String? email;
  String? phone;
  bool? readonly;
 bool? administrator;
  String? map;
  double? latitude;
  double? longitude;
  int? zoom;
  String? coordinateFormat;
  bool? disabled;
  String? expirationTime;
  int? deviceLimit;
  int? userLimit;
  bool? deviceReadonly;
  bool? limitCommands;
  String? poiLayer;
   String? password;

  User(
      {this.id,
        this.attributes,
        this.name,
        this.login,
        this.email,
        this.phone,
        this.readonly,
        this.administrator,
        this.map,
        this.latitude,
        this.longitude,
        this.zoom,
        this.coordinateFormat,
        this.disabled,
        this.expirationTime,
        this.deviceLimit,
        this.userLimit,
        this.deviceReadonly,
       this.limitCommands,
       this.poiLayer,
         this.password
      });

  factory User.fromJson(Map<String,dynamic> data) => _$UserFromJson(data);

  Map<String,dynamic> toJson() => _$UserToJson(this);

}
