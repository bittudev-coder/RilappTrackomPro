class DeviceCommand {
  final String model;
  final String stopCommand;
  final String startCommand;

  DeviceCommand({
    required this.model,
    required this.stopCommand,
    required this.startCommand,
  });

  factory DeviceCommand.fromJson(Map<String, dynamic> json) {
    return DeviceCommand(
      model: json['Model'],
      stopCommand: json['StopCommand'],
      startCommand: json['startCommand'],
    );
  }
}
