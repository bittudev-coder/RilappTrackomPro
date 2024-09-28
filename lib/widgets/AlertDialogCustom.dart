import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../storage/dataController/DataController.dart';
import 'CustomButton.dart';

class AlertDialogCustom {

  void showAlertDialog(BuildContext context, String message, String heading, String buttonAcceptTitle) {
    // Set up the button
    Widget okButton = CustomButton(
      onTap: (){
        Navigator.of(context).pop();
        Navigator.of(context).pop();
      },
    );
    // Create the AlertDialog
    AlertDialog alert = AlertDialog(
      title: Text(
        heading,
        style: TextStyle(
          fontSize: 20.0,
          fontWeight: FontWeight.bold,
          color: Colors.black, // Customize title color
        ),
      ),
      content: Text(
        message,
        style: TextStyle(
          fontSize: 16.0,
          color: Colors.grey[700], // Customize content color
        ),
      ),
      actions: [
        okButton,
      ],
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.0), // Customize dialog border radius
      ),
      backgroundColor: Colors.white, // Customize dialog background color
      contentPadding: EdgeInsets.all(16.0), // Customize content padding
    );

    // Show the dialog
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return alert;
      },
    );
  }
  void showHintDialog(BuildContext context, String message, String heading, String buttonAcceptTitle) {
    // Set up the button
    Widget okButton = CustomButton(
    onTap: (){
      Navigator.of(context).pop(); // Close the dialog
      Get.find<DataController>().getDevices(); // Call your method
    },
    );

    // Set up the AlertDialog
    AlertDialog alert = AlertDialog(
      title: Text(
        heading,
        style: TextStyle(
          fontSize: 20.0,
          fontWeight: FontWeight.bold,
          color: Colors.black, // Customize title color
        ),
      ),
      content: Text(
        message,
        style: TextStyle(
          fontSize: 16.0,
          color: Colors.grey[700], // Customize content color
        ),
      ),
      actions: [
        okButton,
      ],
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.0), // Customize dialog border radius
      ),
      backgroundColor: Colors.white, // Customize dialog background color
      contentPadding: EdgeInsets.all(16.0), // Customize content padding
    );

    // Show the dialog
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return alert;
      },
    );
  }

}
