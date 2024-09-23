import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../theme/CustomColor.dart';

class RectangularFloatingActionButton extends StatelessWidget {
  final VoidCallback onPressed;
  final Color backgroundColor;
  final Color foregroundColor;
  final IconData icon;
  final String heroTag;

  const RectangularFloatingActionButton({
    required this.onPressed,
    required this.backgroundColor,
    required this.foregroundColor,
    required this.icon,
    required this.heroTag,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: backgroundColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8.0), // Adjust the radius as needed
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(8.0),
        onTap: onPressed,
        child: Container(
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
          width: 45.0, // Adjust the width as needed
          height: 45.0, // Adjust the height as needed
          alignment: Alignment.center,
          child: Icon(
            icon,
            color: foregroundColor,
            size: 25.0, // Icon size
          ),
        ),
      ),
    );
  }
}

class MyHomePage extends StatelessWidget {
  final GlobalKey<ScaffoldState> _drawerKey = GlobalKey<ScaffoldState>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _drawerKey,
      drawer: Drawer(
        // Drawer contents here
      ),
      body: Center(
        child: RectangularFloatingActionButton(
          heroTag: "openDrawer",
          onPressed: () {
            _drawerKey.currentState?.openDrawer();
          },
          backgroundColor: CustomColor.secondaryColor, // Replace with your color
          foregroundColor: CustomColor.primaryColor, // Replace with your color
          icon: Icons.menu,
        ),
      ),
    );
  }
}