
import 'package:flutter/material.dart';
import 'package:get/get_utils/get_utils.dart';

import 'CustomButton.dart';

class ChangePasswordDialog extends StatelessWidget {
  final TextEditingController newPasswordController;
  final TextEditingController retypePasswordController;
  final VoidCallback onUpdatePassword;
  final VoidCallback onCancel;

  ChangePasswordDialog({
    required this.newPasswordController,
    required this.retypePasswordController,
    required this.onUpdatePassword,
    required this.onCancel, // Default background color
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.0),
      ),
      contentPadding: EdgeInsets.zero, // Remove default padding
      backgroundColor: Colors.transparent, // Make background transparent
      content: Container(
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
        height: 220.0,
        child: Column(
          children: <Widget>[
            Column(
              children: <Widget>[
                Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(children: [
                    TextField(
                      controller: newPasswordController,
                      decoration: InputDecoration(
                        labelText:  ('newPassword').tr,
                      ),
                      obscureText: true,
                    ),
                    TextField(
                      controller: retypePasswordController,
                      decoration: InputDecoration(
                        labelText: ('retypePassword').tr,
                      ),
                      obscureText: true,
                    ),
                  ],),
                ),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      Expanded(
                        child: SizedBox(
                          height: 40,
                          child: CustomButton2(
                            onTap: onCancel,
                            text: 'Cancel',
                          ),
                        ),
                      ),
                      SizedBox(width: 20), // Space between buttons
                      Expanded(
                        child: SizedBox(
                          height: 40,
                          child: CustomButton(
                            onTap: onUpdatePassword,
                            text: 'Update',
                          ),
                        ),
                      ),
                    ],
                  ),
                )

              ],
            ),
          ],
        ),
      ),
    );
  }
}