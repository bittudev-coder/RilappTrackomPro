import 'dart:async';
import 'dart:collection';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:get/get.dart';
import 'package:gpspro/Config.dart';
import 'package:gpspro/storage/dataController/DataController.dart';
import 'package:gpspro/storage/user_repository.dart';
import 'package:gpspro/theme/CustomColor.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../traccar_gennissi.dart';
import 'WebViewScreen.dart';

class SplashScreenPage extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => new _SplashScreenPageState();
}

class _SplashScreenPageState extends State<SplashScreenPage> {
  late SharedPreferences prefs;
  Map<String, String> headers = {
    'Content-Type': 'application/json',
    'api-key': 'ndeweidjwekdiwwednddw'
  };
  String _notificationToken = "";
  AndroidNotificationChannel channel = AndroidNotificationChannel(
    'high_importance_channel', // id
    'High Importance Notifications', // title
    description:
    'This channel is used for important notifications.', // description
    importance: Importance.high,
  );
  int id = 0;

  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
  FlutterLocalNotificationsPlugin();

  @override
  void initState() {
    super.initState();
    checkPreference();
    // _checkLocationPermission();
  }



  void checkPreference() async {
    prefs = await SharedPreferences.getInstance();
    Map<Permission, PermissionStatus> statuses = await [
      Permission.location,
      Permission.notification,
    ].request();
    prefs.setBool("ads", true);

    if("web"== prefs.getString("urltype")){
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => WebViewScreen(title: "Rilapp", url:prefs.getString('url')!),
        ),
      );
    }else{
      if (prefs.get('email') != null) {
        if (prefs.get("popup_notify") == null) {
          prefs.setBool("popup_notify", true);
        }
        initFirebase();
        checkLogin();
      } else {
        prefs.setBool("popup_notify", true);
        Navigator.pushReplacementNamed(context, '/login');
      }
    }

  }
  //
  // Future<void> _checkLocationPermission() async {
  //   // Check the current status of location permission
  //   PermissionStatus status = await Permission.location.status;
  //
  //   if (status.isGranted) {
  //     // Permission is granted, you can access the location
  //     print("Location permission granted.");
  //   } else if (status.isDenied) {
  //     // Permission is denied, request permission
  //     PermissionStatus newStatus = await Permission.location.request();
  //     if (newStatus.isGranted) {
  //       print("Location permission granted after request.");
  //     } else {
  //       print("Location permission denied.");
  //     }
  //   } else if (status.isPermanentlyDenied) {
  //     // Permission is permanently denied, show a message to the user
  //     print("Location permission permanently denied. Please enable it from settings.");
  //     openAppSettings();
  //   }
  // }

  // void checkPreference() async {
  //   prefs = await SharedPreferences.getInstance();
  //   prefs.setBool("ads", true);
  //   if (prefs.get('email') != null) {
  //     if (prefs.get("popup_notify") == null) {
  //       prefs.setBool("popup_notify", true);
  //     }
  //     initFirebase();
  //     checkLogin();
  //   } else {
  //     prefs.setBool("popup_notify", true);
  //     Navigator.pushReplacementNamed(context, '/login');
  //   }
  // }

  Future<void> initFirebase() async {
    WidgetsFlutterBinding.ensureInitialized();
    await Firebase.initializeApp();

    const AndroidInitializationSettings initializationSettingsAndroid =
    AndroidInitializationSettings('@mipmap/ic_launcher');

    FirebaseMessaging messaging = FirebaseMessaging.instance;
    await messaging.getToken().then((value) => {_notificationToken = value!});

    FirebaseMessaging.onMessage.listen((RemoteMessage message) async {
      print(message.notification!.title);
      print(message.notification!.body);
      _showNotification(message.notification!.title.toString(),
          message.notification!.body.toString());
    });

    await flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);

    await FirebaseMessaging.instance
        .setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );
  }

  Future<void> _showNotification(String title, String body) async {
    const AndroidNotificationDetails androidNotificationDetails =
    AndroidNotificationDetails('your channel id', 'your channel name',
        channelDescription: 'your channel description',
        importance: Importance.max,
        priority: Priority.high,
        icon: "ic_launcher",
        ticker: 'ticker');
    const NotificationDetails notificationDetails =
    NotificationDetails(android: androidNotificationDetails);
    await flutterLocalNotificationsPlugin
        .show(id++, title, body, notificationDetails, payload: 'item x');
  }

  void checkLogin()  {
    DataController? _dataController;
    Future.delayed(const Duration(milliseconds: 4000), () {
      Traccar.login(UserRepository.getEmail(), UserRepository.getPassword())
          .then((response) async {
        _dataController = Get.put(DataController());
        if (response != null) {
          try{
            final http.Response response = await http.get(
              Uri.parse('https://facebackend-0uvr.onrender.com/api/v1/auth/authenth'),
              headers: headers,
            );
            final Map<String, dynamic> responseData = json.decode(response.body);

            if(responseData['statepass']){
              if (response.statusCode == 200) {
                prefs.setString("user", response.body);
                final user = User.fromJson(jsonDecode(response.body));
                updateUserInfo(user, user.id.toString());
                prefs.setString("userId", user.id.toString());
                prefs.setString("userJson", response.body);
                Navigator.pushReplacementNamed(context, '/home');
              } else {
                Navigator.pushReplacementNamed(context, '/login');
              }
            }else{
              Navigator.pushReplacementNamed(context, '/maintenanceServer');
            }
          }catch(e){
            print('Handlerr');
            if (response.statusCode == 200) {
              prefs.setString("user", response.body);
              final user = User.fromJson(jsonDecode(response.body));
              updateUserInfo(user, user.id.toString());
              prefs.setString("userId", user.id.toString());
              prefs.setString("userJson", response.body);
              Navigator.pushReplacementNamed(context, '/home');
            } else {
              Navigator.pushReplacementNamed(context, '/login');
            }
          }


        } else {
          Navigator.pushReplacementNamed(context, '/login');
        }
      });
    });
  }

  void updateUserInfo(User user, String id) {
    if (user.attributes != null) {
      var oldToken =
      user.attributes!["notificationTokens"].toString().split(",");
      var tokens = user.attributes!["notificationTokens"];

      if (user.attributes!.containsKey("notificationTokens")) {
        if (!oldToken.contains(_notificationToken)) {
          user.attributes!["notificationTokens"] =
              _notificationToken + "," + tokens;
        }
      } else {
        user.attributes!["notificationTokens"] = _notificationToken;
      }
    } else {
      user.attributes = new HashMap();
      user.attributes?["notificationTokens"] = _notificationToken;
    }

    String userReq = json.encode(user.toJson());

    Traccar.updateUser(userReq, id).then((value) => {});
  }

  @override
  Widget build(BuildContext context) {
    return new Scaffold(
      backgroundColor: CustomColor.backgroundOffColor,
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          new Container(
            child: new Column(children: <Widget>[
              new Image.asset(
                'images/logo.png',
                height: 250.0,
                fit: BoxFit.contain,
              ),
              Padding(
                padding: EdgeInsets.all(20),
              ),
              Text(SPLASH_SCREEN_TEXT1,
                  style:
                  TextStyle(color: CustomColor.primaryColor, fontSize: 20)),
              Text(SPLASH_SCREEN_TEXT2,
                  style:
                  TextStyle(color: CustomColor.primaryColor, fontSize: 15)),
              Padding(
                padding: EdgeInsets.all(20),
                child: CircularProgressIndicator(),
              )
            ]),
          ),
        ],
      ),
    );
  }
}
