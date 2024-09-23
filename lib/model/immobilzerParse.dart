import 'dart:convert';
import 'Immobilizer.dart';

List<DeviceCommand> parseCommands(String responseBody) {
  final parsed = jsonDecode(responseBody).cast<Map<String, dynamic>>();
  return parsed.map<DeviceCommand>((json) => DeviceCommand.fromJson(json)).toList();
}

final String jsonString = '''
[
    {
        "Model": "VT1",
        "StopCommand": "#6666#CF#",
        "startCommand": "#6666#OF#"
    },
    {
        "Model": "VT2",
        "StopCommand": "RELAY,1#",
        "startCommand": "RELAY,0#"
    },
    {
        "Model": "VT3",
        "StopCommand": "DYD#",
        "startCommand": "HFYD#"
    },
    {
        "Model": "R-Locator",
        "StopCommand": "@SET##OP1,@@<CL><LF>",
        "startCommand": "@CLR##OP1,@@<CL><LF>"
    }
]
''';

List<DeviceCommand> commands = parseCommands(jsonString);
