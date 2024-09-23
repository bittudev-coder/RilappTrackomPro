
import 'package:gpspro/traccar_gennissi.dart';

class DeviceArguments {
  final int id;
  final String name;
  final Device device;
  PositionModel? positionModel;
  DeviceArguments(this.id, this.name, this.device, this.positionModel);
}
