// ignore_for_file: file_names

import 'dart:async';
import 'dart:convert';

import 'package:get/get.dart';
import 'package:gpspro/traccar_gennissi.dart';
import 'package:web_socket_channel/io.dart';

class DataController extends GetxController {
  RxMap<int, Device> devices = <int, Device>{}.obs;
  RxMap<int, PositionModel> positions = <int, PositionModel>{}.obs;

  RxList<Event> events = <Event>[].obs;
  var counter = 0.obs;
  RxBool isLoading = true.obs;
  RxBool isEventLoading = true.obs;
  IOWebSocketChannel? socketChannel;

  @override
  Future<void> onInit() async {
    super.onInit();
    getDevices();
  }

  @override
  Future<void> onReady() async {
    super.onReady();
  }

  void getDevices() {
    Traccar.getDevices().then((List<Device>? value) {
      initSocket();
      value!.forEach((element) {
        devices.putIfAbsent(element.id!, () => element);
        devices.update(element.id!, (value) => element);
      });
    });
  }

  void initSocket() {
    var uri = Uri.parse(Traccar.serverURL!);
    String socketScheme, socketURL;
    if (uri.scheme == "http") {
      socketScheme = "ws://";
    } else {
      socketScheme = "wss://";
    }

    if (uri.hasPort) {
      socketURL =
          socketScheme + uri.host + ":" + uri.port.toString() + "/api/socket";
    } else {
      socketURL = socketScheme + uri.host + "/api/socket";
    }

    socketChannel =
    new IOWebSocketChannel.connect(socketURL, headers: Traccar.headers);

    try {
      socketChannel!.stream.listen(
            (event) {
          var data = json.decode(event);
          print(data);
          if (data["events"] != null) {
            Iterable events = data["events"];
            events.map((model) => Event.fromJson(model)).toList();
          }

          if (data["positions"] != null) {
            Iterable pos = data["positions"];
            List<PositionModel> posList =
            pos.map((model) => PositionModel.fromJson(model)).toList();
            posList.forEach((PositionModel element) {
              positions.putIfAbsent(element.deviceId!, () => element);
              positions.update(element.deviceId!, (value) => element);
            });
          }

          if (data["devices"] != null) {
            Iterable events = data["devices"];
            List<Device> deviceList =
            events.map((model) => Device.fromJson(model)).toList();
            deviceList.forEach((Device element) {
              devices.putIfAbsent(element.id!, () => element);
              devices.update(element.id!, (value) => element);
            });
          }
          isLoading.value = false;
        },
        onDone: () {
          isLoading.value = false;
          socketChannel!.sink.close();
        },
        onError: (error) {
          isLoading.value = false;
          socketChannel!.sink.close();
          print('ws error $error');
        },
      );
    } catch (error) {
      isLoading.value = false;
      socketChannel!.sink.close();
      print('ws error $error');
    }
  }
}
