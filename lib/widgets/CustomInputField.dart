import 'package:flutter/material.dart';
import '../theme/CustomColor.dart';

class CustomInputField extends StatelessWidget {
  final TextEditingController textEditingController; // Required text editing controller
  final String? labelText; // Label text for the input field
  final Icon icon; // Icon for the input field
  final TextInputType keyboardType; // Keyboard type for the input field
  final FocusNode? focusNode; // Focus node for managing focus state

  const CustomInputField({
    Key? key,
    this.labelText, // Default label text
    this.icon = const Icon(Icons.email, size: 24.0), // Default icon with size
    required this.textEditingController, // Required text editing controller
    this.keyboardType = TextInputType.text, // Default keyboard type
    this.focusNode, // Optional focus node
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: textEditingController,
      keyboardType: keyboardType,
      focusNode: focusNode, // Use the provided focus node
      decoration: InputDecoration(
        labelText: labelText,
        labelStyle: TextStyle(
          color: Colors.black,
          fontSize: 15.0, // Font size when label is floating
          fontWeight: FontWeight.w600,
        ),
        floatingLabelStyle: TextStyle(
          color: CustomColor.primaryColor,
          fontSize: 16.0, // Font size when label is not floating
          fontWeight: FontWeight.w600,
        ),
        floatingLabelBehavior: FloatingLabelBehavior.auto, // Auto-float the label when there is input
        prefixIcon: icon, // Use the provided icon
        prefixIconConstraints: BoxConstraints(
          minWidth: 34, // Ensure icon size consistency
          minHeight: 24,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6.0), // Slightly smaller radius for a modern look
          borderSide: BorderSide(
            color: CustomColor.primaryColor.withOpacity(0.5), // Subtle border color
            width: 1.5, // Border width
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderSide: BorderSide(
            color: CustomColor.primaryColor,
            width: 2.0, // Slightly thicker border when focused
          ),
          borderRadius: BorderRadius.circular(6.0),
        ),
        border: OutlineInputBorder(
          borderSide: BorderSide(
            color: CustomColor.primaryColor.withOpacity(0.5),
            width: 1.5,
          ),
          borderRadius: BorderRadius.circular(6.0),
        ),
        contentPadding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0), // Added padding for better touch experience
      ),
    );
  }
}
