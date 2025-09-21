// theme_provider.dart

import 'package:flutter/material.dart';

class AppColors {
  static const Color primary = Colors.orange;
  static const Color buttonColor = Colors.orange;
  static Color? secondary = Colors.amber[100];
  static Color backgroundColor = Colors.white;
  static Color foregroundColor = Colors.black;
  static Color shadeColor = Colors.grey;
  static Color appBarColor = Colors.orange;
  static Color successColor = Colors.green;
  static Color errorColor = Colors.red;
  static Color titleColor = Colors.white;

  static const Color gridLineColor = Colors.grey; // For grid lines
  static const Color seatEmptyColor = Colors.blue; // For empty seats
  static const Color seatBookedColor = Colors.amber; // For booked seats
  static const Color seatReservedColor = Colors.red;

  static Color messageReceiverColor = Colors.purple;

  static Color? disabledInputFillColor = Colors.black38;

  static getBackgroundColor(BuildContext context) {
    if (Theme.of(context).brightness == Brightness.dark) {
      backgroundColor = Colors.black;
      foregroundColor = Colors.white;
      messageReceiverColor = Colors.purpleAccent;
      titleColor = Colors.white;
    } else {
      backgroundColor = Colors.white;
      foregroundColor = Colors.black;
      messageReceiverColor = Colors.purple;
      titleColor = Colors.black;
    }
  }
}
