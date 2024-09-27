import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_phoenix/flutter_phoenix.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:get/get.dart';
import 'package:gpspro/Config.dart';
import 'package:gpspro/theme/CustomColor.dart';
import 'package:gpspro/widgets/CustomButton.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../traccar_gennissi.dart';
import '../src/model/MobileAppURL.dart';
import '../theme/ConstColor.dart';
import '../widgets/CustomText.dart';
import 'WebViewScreen.dart';
class LoginPage extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => new _LoginPageState();
}

enum FormType { login, register }

class _LoginPageState extends State<LoginPage> {
  late SharedPreferences prefs;
  List<MobileAppUrl> serverList=[];
  final TextEditingController _emailFilter = new TextEditingController();
  final TextEditingController _passwordFilter = new TextEditingController();
  // final TextEditingController _serverFilter = new TextEditingController();
  String _serverFilter = "";
  int? selectedIndex=0;
  String? dropdownValue;
  String _email = "";
  String _password = "";
  String _notificationToken = "";
  FormType _form = FormType
      .login; // our default setting is to login, and we should switch to creating an account when the user chooses to

  AndroidNotificationChannel channel = AndroidNotificationChannel(
    'high_importance_channel', // id
    'High Importance Notifications', // title
    description:
    'This channel is used for important notifications.', // description
    importance: Importance.high,
  );

  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
  FlutterLocalNotificationsPlugin();

  @override
  void initState() {
    fetchAndAddServers();
    //_serverFilter.addListener(_urlListen);
    _emailFilter.addListener(_emailListen);
    _passwordFilter.addListener(_passwordListen);

    Permission _permission2 = Permission.notification;
    _permission2.request();

    checkPreference();
    initFirebase();
    super.initState();
  }

  Future<void> fetchAndAddServers() async {
    try {
      final http.Response response = await http.get(
        Uri.parse('https://ip1.rilapp.com/vts/mobileAppURL.json'),
      );
      // print(response.body);
      if (response.statusCode == 200) {
        final List<dynamic> jsonData = json.decode(response.body);
        setState(() {
          serverList = jsonData.map((data) => MobileAppUrl.fromJson(data)).toList();
        });
      } else {
        print("Failed to load data: ${response.statusCode}");
      }
    } catch (e) {
      print("An error occurred: $e");
    }
    print(serverList[0].serverName);
  }



  Future<void> initFirebase() async {
    WidgetsFlutterBinding.ensureInitialized();
    await Firebase.initializeApp();

    FirebaseMessaging messaging = FirebaseMessaging.instance;
    await messaging.getToken().then((value) => {_notificationToken = value!});
    FirebaseMessaging.onMessage.listen((RemoteMessage message) async {
      print(message.notification!.title);
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

  void checkPreference() async {
    prefs = await SharedPreferences.getInstance();

    if (prefs.getString("language") != null) {
      if (prefs.getString("language") == "es") {
        dropdownValue = "Español";
      } else if (prefs.getString("language") == "en") {
        dropdownValue = "English";
      } else if (prefs.getString("language") == "pt") {
        dropdownValue = "Português";
      } else if (prefs.getString("language") == "fr") {
        dropdownValue = "Français";
      } else if (prefs.getString("language") == "ar") {
        dropdownValue = "العربية";
      } else if (prefs.getString("language") == "fa") {
        dropdownValue = "فارسی";
      } else if (prefs.getString("language") == "pl") {
        dropdownValue = "Polski";
      } else if (prefs.getString("language") == "tr") {
        dropdownValue = "Türkçe";
      }
    } else {
      dropdownValue = "English";
    }

    if (prefs.get('url') != null) {
      _serverFilter = prefs.getString('url')!;
    } else {
      _serverFilter = "http://ip.trackom.com:8082";
      prefs.setString("url", _serverFilter);

    }

    if (prefs.get('email') != null) {
      _emailFilter.text = prefs.getString('email')!;
      _passwordFilter.text = prefs.getString('password')!;
      _serverFilter = prefs.getString('url')!;
      _loginPressed();
    } else {
      setState(() {});
    }
  }
  //
  // void _urlListen() {
  //   if (_serverFilter.text.isEmpty) {
  //     _url = "";
  //   } else {
  //     _url = _serverFilter.text;
  //   }
  // }

  void _emailListen() {
    if (_emailFilter.text.isEmpty) {
      _email = "";
    } else {
      _email = _emailFilter.text;
    }
  }

  void _passwordListen() {
    if (_passwordFilter.text.isEmpty) {
      _password = "";
    } else {
      _password = _passwordFilter.text;
    }
  }

  // Swap in between our two forms, registering and logging in
  void _formChange() async {
    setState(() {
      if (_form == FormType.register) {
        _form = FormType.login;
      } else {
        _form = FormType.register;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return new Scaffold(
      backgroundColor: CustomColor.primaryColor,
      appBar: new AppBar(
        elevation: 0,
        title: new Text(('Trackom Pro GPS Tracking').tr,
            style: TextStyle(color: CustomColor.secondaryColor)),
        centerTitle: true,
        actions: [
          Padding(
            padding: EdgeInsets.fromLTRB(10, 0, 10, 0),
            child: GestureDetector(
                onTap: () {
                  showServerDialog(context);
                },
                child: Icon(Icons.settings)),
          )
        ],
      ),
      body: new Container(
          padding: EdgeInsets.all(16.0),
          child: ListView(
              shrinkWrap: true,
              padding: EdgeInsets.all(15.0),
              children: <Widget>[
                Column(
                  children: <Widget>[_buildTextFields()],
                )
              ])),
    );
  }

  List dropDownListData = [
    {"title": "Trackom Server 1", "value": "http://ip.trackom.com:8082"},
    {"title": "Trackom Server 2", "value": "http://ip2.trackom.com:8082"},
    {"title": "Trackom Server 3", "value": "http://ip3.trackom.com:8082"},
  ];

  String secondDropDown = "";

  void showServerDialog(BuildContext context) {
    Dialog simpleDialog = Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(3.0),
      ),
      child: StatefulBuilder(
        builder: (BuildContext context, StateSetter setState) {
          return Container(
            decoration: BoxDecoration(
              color: Colors.white, // Set the background color
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
            child: Padding(
              padding: const EdgeInsets.all(10.0),
              child: Column( // Use Column instead of ListView
                mainAxisSize: MainAxisSize.min, // To prevent infinite height
                children: [
                  Text(
                    "Select Server",
                    style: TextStyle(
                      fontSize: 20,
                      color: Colors.indigo,
                      fontFamily: 'OpenSans-Bold.ttf',
                    ),
                  ),
                  const SizedBox(height: 10),
                  Divider(thickness: 2,),
                  const SizedBox(height: 10),
                  serverList.isEmpty
                      ? Center(child: CircularProgressIndicator()) // Show loading indicator
                      : SizedBox(
                    height: 300, // Set a fixed height for the ListView
                    child: ListView.builder(
                      itemCount: serverList.length,
                      itemBuilder: (context, index) {
                        final URL = serverList[index];
                        return GestureDetector(
                          onTap: () {
                            setState(() {
                              prefs.setString("url", URL.serverUrl);

                              prefs.setInt("URLINDEX", index);
                              selectedIndex = prefs.getInt("URLINDEX");
                              Navigator.pop(context);
                            });
                            Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(
                                builder: (context) => WebViewScreen(title: URL.serverName, url: _serverFilter ),
                              ),
                            );
                          },
                          child: Container(
                          // Padding inside each item
                            decoration: BoxDecoration(
                              color: Colors.white, // Background color
                              border: Border.all(
                                color: selectedIndex == index ? Colors.blue : Colors.transparent, // Conditional border color
                                width: 2, // Border width
                              ),
                              borderRadius: BorderRadius.circular(8.0), // Rounded corners

                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(6.0),
                              child: urlCard(URL, context, index),
                            ),
                          ),
                        );
                      },
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

  Widget urlCard(MobileAppUrl url, BuildContext context, int index) {
    return Container(
      decoration:   BoxDecoration(
        color: Colors.white,
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
        padding: EdgeInsets.all(20.0),
        child: Column(
          children: <Widget>[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                CustomText(TxtName:url.serverName,),
                url.serverType=='app'?
                Icon(Icons.mobile_friendly):Icon(Icons.web),
              ],
            ),
          ],
        ),
      ),
    );
  }


  Widget _buildTextFields() {
    return new Container(
      width: MediaQuery.of(context).size.width,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
      ),
      padding: EdgeInsets.all(50.0),
      child: new Column(
        children: <Widget>[
          new Container(
            child: Image.asset(
              'images/logo.png',
              width: 200,
              height: 200,
            ),
          ),
          new Container(
              child: DropdownButton<String>(
                value: dropdownValue,
                elevation: 16,
                style: TextStyle(color: CustomColor.primaryColor),
                underline: Container(
                  height: 2,
                  color: CustomColor.primaryColor,
                ),
                onChanged: (String? newValue) {
                  setState(() {
                    dropdownValue = newValue!;
                    print(dropdownValue);
                    if (newValue == "Français") {
                      prefs.setString("language", "fr");
                      Get.updateLocale(Locale("fr", ''));
                    } else if (newValue == "Español") {
                      prefs.setString("language", "es");
                      Get.updateLocale(Locale("es", ''));
                    } else if (newValue == "English") {
                      prefs.setString("language", "en");
                      Get.updateLocale(Locale("en", ''));
                    } else if (newValue == "Português") {
                      prefs.setString("language", "pt");
                      Get.updateLocale(Locale("pt", ''));
                    } else if (newValue == "العربية") {
                      prefs.setString("language", "ar");
                      Get.updateLocale(Locale("ar", ''));
                    } else if (newValue == "فارسی") {
                      prefs.setString("language", "fa");
                      Get.updateLocale(Locale("fa", ''));
                    } else if (newValue == "Polski") {
                      prefs.setString("language", "pl");
                      Get.updateLocale(Locale("pl", ''));
                    } else if (newValue == "Türkçe") {
                      prefs.setString("language", "tr");
                      Get.updateLocale(Locale("tr", ''));
                    }
                  });
                  Phoenix.rebirth(context);
                },
                items: <String>[
                  "English",
                  "Français",
                  "Español",
                  "Português",
                  "العربية",
                  "فارسی",
                  "Polski",
                  "Türkçe"
                ].map<DropdownMenuItem<String>>((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(value),
                  );
                }).toList(),
              )),
          new Container(
            child: new TextField(
              controller: _emailFilter,
              decoration:
              new InputDecoration(labelText: (' Username/Email').tr),
            ),
          ),
          new Container(
            child: new TextField(
              controller: _passwordFilter,
              decoration: new InputDecoration(labelText: ('userPassword').tr),
              obscureText: true,
            ),
          ),
          _buildButtons(),
        ],
      ),
    );
  }

  Widget _buildButtons() {
    if (_form == FormType.login) {
      return new Container(
        width: MediaQuery.of(context).size.width,
        child: new Column(
          children: <Widget>[
            Padding(
              padding: EdgeInsets.all(5),
            ),
            CustomButton(text: ('loginTitle').tr,onTap: _loginPressed,),
            new TextButton(
              child: new Text(DEVELOPED_BY),
              onPressed: () {},
            ),
          ],
        ),
      );
    } else {
      return new Container(
        child: new Column(
          children: <Widget>[
            new Container(
              child: ElevatedButton(
                onPressed: () {
                  _createAccountPressed();
                },
                child: Text("Submit", style: TextStyle(fontSize: 18)),
              ),
            ),
            new TextButton(
              child: new Text('Have an account? Click here to login.'),
              onPressed: _formChange,
            )
          ],
        ),
      );
    }
  }

  void _loginPressed() async {
    // print("Hello");
    try {
      _showProgress(true);
      Traccar.login(_email, _password).then((response) {
        if (response != null) {
          print(response.statusCode);
          if (response.statusCode == 200) {
            prefs.setString("user", response.body);
            _showProgress(false);
            final user = User.fromJson(jsonDecode(response.body));
            prefs.setString("userId", user.id.toString());
            prefs.setString("userJson", response.body);
            updateUserInfo(user, user.id.toString());
            Navigator.pushReplacementNamed(context, '/home');
          } else if (response.statusCode == 401) {
            _showProgress(false);
            Fluttertoast.showToast(
                msg: ("loginFailed").tr,
                toastLength: Toast.LENGTH_SHORT,
                gravity: ToastGravity.CENTER,
                timeInSecForIosWeb: 1,
                backgroundColor: Colors.black54,
                textColor: Colors.white,
                fontSize: 16.0);
            setState(() {});
          } else if (response.statusCode == 400) {
            if (response.body ==
                "Account has expired - SecurityException (PermissionsManager:259 < *:441 < SessionResource:104 < ...)") {
              setState(() {});
              showDialog(
                context: context,
                builder: (context) => new AlertDialog(
                  title: Text(("failed").tr),
                  content: Text(("loginFailed").tr),
                  actions: <Widget>[
                    new TextButton(
                      onPressed: () {
                        _showProgress(false);
                        Navigator.of(context, rootNavigator: true)
                            .pop(); // dismisses only the dialog and returns nothing
                      },
                      child: new Text(("ok").tr),
                    ),
                  ],
                ),
              );
            }
          } else {
            _showProgress(false);
            Fluttertoast.showToast(
                msg: response.body,
                toastLength: Toast.LENGTH_SHORT,
                gravity: ToastGravity.CENTER,
                timeInSecForIosWeb: 1,
                backgroundColor: Colors.black54,
                textColor: Colors.white,
                fontSize: 16.0);
            setState(() {});
          }
        } else {
          setState(() {});
          _showProgress(false);
          Fluttertoast.showToast(
              msg: ("errorMsg").tr,
              toastLength: Toast.LENGTH_SHORT,
              gravity: ToastGravity.CENTER,
              timeInSecForIosWeb: 1,
              backgroundColor: Colors.black54,
              textColor: Colors.white,
              fontSize: 16.0);
        }
      });
    } catch (e) {
      _showProgress(false);
      setState(() {});
    }
  }

  void _createAccountPressed() {
    print('The user wants to create an account with $_email and $_password');
  }

  void updateUserInfo(User user, String id) {
    var oldToken = user.attributes!["notificationTokens"].toString().split(",");
    var tokens = user.attributes!["notificationTokens"];
    print("Tnotifyu");
    print(oldToken);
    print(tokens);

    if (user.attributes!.containsKey("notificationTokens")) {
      if (!oldToken.contains(_notificationToken)) {
        user.attributes!["notificationTokens"] =
            _notificationToken + "," + tokens;
      }
    } else {
      user.attributes!["notificationTokens"] = _notificationToken;
    }

    String userReq = json.encode(user.toJson());
    print(userReq);
    Traccar.updateUser(userReq, id).then((value) => {
      print(value.body),
    });
  }




  Future<void> _showProgress(bool status) async {
    if (status) {
      return showDialog<void>(
        context: context,
        barrierDismissible: true, // user must tap button!
        builder: (BuildContext context) {
          return AlertDialog(
            content: new Row(
              children: [
                CircularProgressIndicator(),
                Container(
                    margin: EdgeInsets.only(left: 5),
                    child: Text(('sharedLoading').tr)),
              ],
            ),
          );
        },
      );
    } else {
      Navigator.pop(context);
    }
  }
}
