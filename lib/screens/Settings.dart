import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_phoenix/flutter_phoenix.dart';
import 'package:get/get.dart';
import 'package:gpspro/storage/user_repository.dart';
import 'package:gpspro/theme/CustomColor.dart';
import 'package:gpspro/widgets/AlertDialogCustom.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../traccar_gennissi.dart';
import '../Config.dart';
import '../widgets/ChangePassword.dart';
import '../widgets/CustomButton.dart';
import '../widgets/CustomText.dart';
import '../widgets/RatingPage.dart';
import 'AppWebPage.dart';
import 'WebViewScreen.dart';

class Item {
  final String title;
  final IconData iconData;
  final IconData icon;

  Item({required this.title, required this.iconData, required this.icon});
}

class SettingsPage extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final List<Item> items = [
    Item(title: "notifications".tr, iconData: Icons.notifications, icon: Icons.arrow_forward_ios),
    Item(title: "changePassword".tr, iconData: Icons.lock, icon: Icons.arrow_forward_ios),
    Item(title: "sharedMaintenance".tr, iconData: Icons.build, icon: Icons.arrow_forward_ios),
    Item(title: "Edit Device".tr, iconData: Icons.edit, icon: Icons.arrow_forward_ios),
    Item(title: "moreReports".tr, iconData: Icons.featured_play_list_outlined, icon: Icons.arrow_forward_ios),
    Item(title: "appRate".tr, iconData: Icons.star_rate, icon: Icons.arrow_forward_ios),
  ];

  User? user;
  late SharedPreferences prefs;
  double _rating = 0;
  bool _thank = false;

  @override
  void initState() {
    super.initState();
    getUser();
  }

  Future<void> getUser() async {
    prefs = await SharedPreferences.getInstance();
    String? userJson = prefs.getString("user");
    print("Ftyagaggh${userJson}");
    if (userJson != null) {
      final parsed = json.decode(userJson);
      user = User.fromJson(parsed);
      setState(() {});
    } else {
      // Handle case when user is not logged in
    }
  }

  void logout() {
    Traccar.sessionLogout().then((_) {
      UserRepository.doLogout();
      Phoenix.rebirth(context);
    });
  }

  @override
  Widget build(BuildContext context) {
    if (user == null) {
      return Scaffold(
        appBar: AppBar(title: Text(('settings').tr)),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Text('Settings', style: TextStyle(color: CustomColor.secondaryColor, fontSize: 18.0)),
            Spacer(),
            Icon(Icons.person),
            SizedBox(width: 8.0),
            Text(
              user!.email ?? 'Guest', // Default to 'Guest' if email is null
              style: TextStyle(color: Colors.white, fontSize: 20.0),
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
        iconTheme: IconThemeData(color: CustomColor.secondaryColor),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              itemCount: items.length,
              itemBuilder: (context, index) {
                final item = items[index];
                return Container(
                  margin: EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.blue.withOpacity(0.2),
                        spreadRadius: 2,
                        blurRadius: 12,
                        offset: Offset(0, 6),
                      ),
                    ],
                  ),
                  child: ListTile(
                    contentPadding: EdgeInsets.symmetric(horizontal: 15, vertical: 4),
                    leading: Icon(item.iconData, color: Colors.black87, size: 25),
                    title: Text(
                      item.title,
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Colors.black87),
                    ),
                    onTap: () => _handleItemTap(index),
                  ),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(bottom: 70),
            child: SizedBox(
              width: MediaQuery.of(context).size.width * 0.92,
              height: 50,
              child: Center(child: CustomButton(onTap: logout, text: "Logout")),
            ),
          )
        ],
      ),
    );
  }

  void _handleItemTap(int index) {
    switch (index) {
      case 0:
        Navigator.pushNamed(context, "/enableNotifications");
        break;
      case 1:
        showChangePasswordDialog(context);
        break;
      case 2:
        Navigator.pushNamed(context, "/maintenance");
        break;
      case 3:
        Navigator.pushNamed(context, "/deviceEdit");
        break;
      case 4:
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => Appwebpage(title: "More Reports", url: '${MORE_REPORT}username=${UserRepository.getEmail()}&password=${UserRepository.getPassword()}'),
          ),
        );
        break;
      case 5:
        _thank = false;
        _rating = 0;
        showReportDialog(context);
        break;
    }
  }

  void showChangePasswordDialog(BuildContext context) {
    TextEditingController newPasswordController = TextEditingController();
    TextEditingController retypePasswordController = TextEditingController();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return ChangePasswordDialog(
          newPasswordController: newPasswordController,
          retypePasswordController: retypePasswordController,
          onUpdatePassword: () => updatePassword(newPasswordController.text, retypePasswordController.text),
          onCancel: () => Navigator.of(context).pop(),
        );
      },
    );
  }

  void updatePassword(String newPass, String rePass) {
    if (newPass == rePass) {
      final user = User.fromJson(jsonDecode(prefs.getString("userJson")!));
      user.password = newPass;
      String userReq = json.encode(user.toJson());

      Traccar.updateUser(userReq, prefs.getString("userId")!).then((_) {
        AlertDialogCustom().showAlertDialog(context, 'Password updated successfully', 'Change Password', 'OK');
      }).catchError((error) {
        AlertDialogCustom().showAlertDialog(context, 'Error updating password', 'Error', 'OK');
      });
    } else {
      AlertDialogCustom().showAlertDialog(context, 'Passwords do not match', 'Error', 'OK');
    }
  }

  void showReportDialog(BuildContext context) {
    Dialog simpleDialog = Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
      child: StatefulBuilder(
        builder: (BuildContext context, StateSetter setState) {
          return Container(
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(12.0),
              boxShadow: [
                BoxShadow(
                  color: Colors.blue.withOpacity(0.5),
                  spreadRadius: 2,
                  blurRadius: 8,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            height: 387,
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  Container(
                    width: MediaQuery.of(context).size.width,
                    height: 50,
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(12.0),
                    ),
                    child: Center(child: CustomText(TxtName: 'Rate Us!')),
                  ),
                  SizedBox(
                    height: 180,
                    width: MediaQuery.of(context).size.width,
                    child: _thank ? Image.asset('images/Thanku.gif', scale: 1.5) : Image.asset('images/star.png'),
                  ),
                  RatingBar(
                    initialRating: _rating,
                    onRatingChanged: (rating) {
                      setState(() {
                        _rating = rating;
                        _thank = true;
                      });
                    },
                  ),
                  SizedBox(height: 20),
                  SizedBox(
                    height: 40,
                    width: MediaQuery.of(context).size.width * 0.58,
                    child: CustomButton(text: "Submit", onTap: _goPlaystore),
                  ),
                  TextButton(onPressed: () => Navigator.pop(context), child: Text("No Thanks!")),
                ],
              ),
            ),
          );
        },
      ),
    );

    showDialog(context: context, builder: (BuildContext context) => simpleDialog);
  }

  Future<void> _goPlaystore() async {
    if (_rating >= 4) {
      final url = RATE_APP; // Replace with your app's package name
      if (await canLaunch(url)) {
        await launch(url);
      } else {
        print('Could not launch $url');
      }
    }
    Navigator.pop(context);
  }
}
