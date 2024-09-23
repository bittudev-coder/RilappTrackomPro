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
import 'WebViewScreen.dart';

class Item {
  final String title;
  final IconData iconData;
  final IconData icon;
  Item({required this.title, required this.iconData,required this.icon});
}

class SettingsPage extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => new _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final List<Item> items = [
    Item(title:  ("notifications").tr, iconData: Icons.notifications,icon:Icons.arrow_forward_ios),
    Item(title: ("changePassword").tr, iconData: Icons.lock,icon:Icons.arrow_forward_ios),
    Item(title:  ("sharedMaintenance").tr, iconData: Icons.build,icon:Icons.arrow_forward_ios),
    Item(title: ("Edit Device").tr, iconData: Icons.edit,icon:Icons.arrow_forward_ios),
    Item(title:  ("moreReports").tr, iconData: Icons.featured_play_list_outlined,icon: Icons.arrow_forward_ios),
    Item(title: ("appRate").tr, iconData: Icons.star_rate,icon: Icons.arrow_forward_ios),
  ];

  bool _thank=false;
  User? user;
  late SharedPreferences prefs;

  bool isLoading = true;

  int online = 0, offline = 0, unknown = 0;

  double _rating = 0;

  // void _updateRating(double newRating) {
  //   setState(() {
  //     _rating = newRating;
  //
  //   });
  // }

  @override
  initState() {
    //_postsController = new StreamController();
    super.initState();
    getUser();
  }

  getUser() async {
    prefs = await SharedPreferences.getInstance();
    String? userJson = prefs.getString("user");

    final parsed = json.decode(userJson!);
    user = User.fromJson(parsed);
    setState(() {});
  }

  logout() {
    Traccar.sessionLogout()
        .then((value) => {UserRepository.doLogout(), Phoenix.rebirth(context)});
  }

  @override
  Widget build(BuildContext context) {
    if (user != null) {
      return Scaffold(
        appBar: AppBar(
          // Use a Row to align icon and text
          title: Row(
            children: [
              Text(
                'Settings', // Text to display
                style: TextStyle(
                  color: CustomColor.secondaryColor, // Text color
                  fontSize: 18.0, // Text size
                ),
              ),
              // Leading icon
              SizedBox(width: 8.0), // Space between icon and text
              Spacer(), // Pushes the text to the end
              Icon(Icons.person),
              SizedBox(width: 8.0),
              Text(
                user!.email!,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20.0, // Set text size to 20
                ),
                overflow: TextOverflow.ellipsis,
              ),
              SizedBox(width: 8.0),
            ],
          ),
          iconTheme: IconThemeData(
            color: CustomColor.secondaryColor, // Icon color
          ), // Background color of the AppBar
        ),
        body: new Column(children: <Widget>[
          new Expanded(
            child: ListView.builder(
              itemCount: items.length,
              itemBuilder: (context, index) {
                final item = items[index];
                return Container(
                  margin: EdgeInsets.symmetric(vertical: 4,horizontal: 8 ),
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
                  child: ListTile(
                    contentPadding: EdgeInsets.symmetric(horizontal: 15,vertical: 4),
                    leading: Icon(item.iconData, color: Colors.black87, size: 25), // Adjusted icon size and color
                    title: Text(
                      item.title,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600, // Slightly lighter bold
                        color: Colors.black87,

                      ),
                    ),
                    // trailing:  Icon(item.icon, color: Colors.black87, size: 30),
                    onTap: () {
                      if(index==0){
                        Navigator.pushNamed(context, "/enableNotifications");
                      }else if(index==1){
                        showChangePasswordDialog(context);
                      }else if(index==2){
                        Navigator.pushNamed(context, "/maintenance");
                      }else if(index==3){
                        Navigator.pushNamed(context, "/deviceEdit");
                      }else if(index==4){
                        Navigator.push(context, MaterialPageRoute(
                            builder: (context) =>  WebViewScreen(title: "More Reports", url: '${MORE_REPORT}username=${UserRepository.getEmail()}&password=${UserRepository.getPassword()}')));
                      }else if(index==5){
                        _thank=false;
                        _rating = 0;
                        showReportDialog(context);
                      }
                    },
                  ),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(bottom: 70),
            child: SizedBox(
              width: MediaQuery.of(context).size.width*0.92,
              height: 50,
              child: Center(child: CustomButton(onTap: logout,text: "logout",),),
            ),
          )
        ]),
      );

    } else {
      return Scaffold(
        appBar: AppBar(
          title: Text(('settings').tr),
        ),
        body: new Center(
          child: new CircularProgressIndicator(),
        ),
      );
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
          onUpdatePassword: (){
            updatePassword(newPasswordController.text,retypePasswordController.text);
          },
          onCancel: () {
            Navigator.of(context).pop(); // Close the dialog
          },
        );
      },
    );
  }


  void updatePassword(String newPass,String rePass) {
    if (newPass == rePass) {
      final user = User.fromJson(jsonDecode(prefs.getString("userJson")!));
      user.password = newPass;
      String userReq = json.encode(user.toJson());
      print(user.password);
      Traccar.updateUser(userReq, prefs.getString("userId")!).then((value) => {
        AlertDialogCustom().showAlertDialog(
            context,
            ('passwordUpdatedSuccessfully').tr,
            ('changePassword').tr,
            ('ok').tr)
      });
    } else {
      AlertDialogCustom().showAlertDialog(
          context, ('passwordNotSame').tr, ('failed').tr, ('ok').tr);
    }
  }

  void showReportDialog(BuildContext context) {
    Dialog simpleDialog = Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.0),
      ),
      child: StatefulBuilder(
        builder: (BuildContext context, StateSetter setState) {
          return Container(
            decoration: BoxDecoration(
              color: Colors.blue.shade50, // Set the background color
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
            height: 387,
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height,
            ),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  Container(
                    width: MediaQuery.of(context).size.width,
                      height: 50,
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50, // Set the background color
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
                      child: Center(child: CustomText(TxtName: 'Rate Us!',))),
                  SizedBox(
                      height: 180,
                      width:MediaQuery.of(context).size.width ,
                      child: _thank ? Image.asset('images/Thanku.gif',scale: 1.5,):Image.asset('images/star.png',),

                  ),

                  RatingBar(
                    initialRating: _rating,
                    onRatingChanged: (rating) {
                      setState(()  {
                        _rating = rating;
                        _thank=true;
                        // Future.delayed(const Duration(milliseconds: 500), ()  async {
                        //   if(_rating>=4){
                        //     final url = RATE_APP; // Replace with your app's package name
                        //     if (await canLaunch(url)) {
                        //       await launch(url);
                        //     } else {
                        //       throw 'Could not launch $url';
                        //     }
                        //   }else{
                        //
                        //     Navigator.pop(context);
                        //   }
                        //
                        // });



                      });
                    },
                  ),
                  SizedBox(height: 20),
                  // Text(
                  //   'Rating: ${_rating.toStringAsFixed(1)}',
                  //   style: TextStyle(fontSize: 24),
                  // ),
                  // SizedBox(height: 10,),
                  // Text(
                  //   Thanku,
                  //   style: TextStyle(fontSize: 24),
                  // ),
                  SizedBox(
                      height: 40,
                      width: MediaQuery.of(context).size.width*.58,
                      child: CustomButton(text: "Submit",onTap:_goPlaystore,)),
                  TextButton(onPressed: (){  Navigator.pop(context);}, child: Text("No Thanks!"))
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

  _goPlaystore() async {
      if(_rating>=4){
        final url = RATE_APP; // Replace with your app's package name
        if (await canLaunch(url)) {
          await launch(url);
        } else {
          throw 'Could not launch $url';
        }
      }
      Navigator.pop(context);

  }


}




