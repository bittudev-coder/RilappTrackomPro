import 'package:flutter/material.dart';
import 'package:gpspro/theme/CustomColor.dart';

class ConfigurableRectangleButton extends StatelessWidget {
  final bool showText;
  final String mapStatusText;
  final Color mapTypeBackgroundColor;
  final Color mapTypeForegroundColor;
  final VoidCallback onMapTypeButtonPressed;
  final IconData iconData; // Change this to IconData
  const ConfigurableRectangleButton({
    required this.showText,
    required this.mapStatusText,
    required this.mapTypeBackgroundColor,
    required this.mapTypeForegroundColor,
    required this.onMapTypeButtonPressed,
    required this.iconData, // Update parameter
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (showText) // Conditionally render the text container
          Container(
            margin: EdgeInsets.symmetric(horizontal: 4.0),
            padding: EdgeInsets.all(8.0),
            decoration:   BoxDecoration(
              color: CustomColor.backgroundOffColor,
              borderRadius: BorderRadius.circular(12), // Slightly larger radius for a smoother look
              boxShadow: [
                BoxShadow(
                  color: Colors.blue.withOpacity(0.2), // Darker shadow for a more noticeable effect
                  spreadRadius: 2, // Increased spread radius for a more pronounced shadow
                  blurRadius: 12, // Increased blur radius for a softer, more extended shadow
                  offset: Offset(2, 6), // Adjusted offset for a more noticeable shadow
                ),
              ],
            ),
            child: Text(
              mapStatusText,
              style: TextStyle(color: Colors.black, fontSize: 16.0,fontWeight: FontWeight.w500),
            ),
          ),
        SizedBox(width: 8.0), // Spacing between text and button
        Material(
          color: mapTypeBackgroundColor,
          borderRadius: BorderRadius.circular(10.0), // Rounded corners
          child: InkWell(
            borderRadius: BorderRadius.circular(10.0),
            onTap: onMapTypeButtonPressed,
            child: Container(
              decoration:   BoxDecoration(
                color: mapTypeBackgroundColor,
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
              width: 40.0, // Adjust width as needed
              height: 40.0, // Adjust height as needed
              alignment: Alignment.center,
              child: Icon(
                iconData, // Use IconData here
                color: mapTypeForegroundColor,
                size: 25.0, // Adjust icon size as needed
              ),
            ),
          ),
        ),
      ],
    );
  }
}
