import 'package:flutter/material.dart';
import 'package:awesome_bottom_bar/awesome_bottom_bar.dart';
import 'package:gpspro/screens/Dashboard.dart';
import 'package:gpspro/screens/Devices.dart';
import 'package:gpspro/screens/MapHome.dart';
import 'package:gpspro/screens/Settings.dart';
import 'package:gpspro/theme/CustomColor.dart';

class HomePage extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => _HomeState();
}

class _HomeState extends State<HomePage> {
  int _selectedIndex = 0;// Default to Dashboard page
  bool updateLive=false;
  bool ListUpdate=false;

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        extendBody: true,
        body: IndexedStack(
          index: _selectedIndex,
          children: <Widget>[
            DashboardPage(),
            MapPage(updateLive: updateLive,),
            DevicePage(),
            SettingsPage(),
          ],
        ),
          bottomNavigationBar: BottomBarFloating(
            iconSize: 22,
            enableShadow: true,
            borderRadius: BorderRadius.circular(25),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                offset: Offset(0, 5),
                blurRadius: 4.0,
                spreadRadius: 1.0,
              ),
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                offset: Offset(0, 10),
                blurRadius: 10.0,
                spreadRadius: 0,
              ),
            ],
            titleStyle: TextStyle(
              fontWeight: FontWeight.w500,
              fontFamily: 'fonts/OpenSans-Light.ttf',
              letterSpacing: 0,
              fontSize: 12,
            ),
            items: _bottomNavigationBarItems,
            backgroundColor: CustomColor.backgroundOffColor,
            color: Color.fromARGB(255, 4, 4, 4),
            colorSelected: CustomColor.primaryColor,
            indexSelected: _selectedIndex,
            onTap: (int index) {
              setState(() {
                _selectedIndex = index;
                // Update live and list states based on index
                updateLive = (index == 1);
                ListUpdate = (index == 0);
              });
            },

          ),

      ),
    );
  }

  List<TabItem> get _bottomNavigationBarItems => [
    TabItem(
      icon: _selectedIndex == 0
          ? Icons.dashboard
          : Icons.dashboard_outlined,
      title: 'Home',
    ),
    TabItem(
      icon: _selectedIndex == 1
          ? Icons.map
          : Icons.map_outlined,
      title: 'Map',
    ),
    TabItem(
      icon: _selectedIndex == 2
          ? Icons.directions_car_filled
          : Icons.directions_car_filled_outlined,
      title: 'Devices',
    ),
    TabItem(
      icon: _selectedIndex == 3
          ? Icons.settings
          : Icons.settings_outlined,
      title: 'Settings',
    ),
  ];

}
