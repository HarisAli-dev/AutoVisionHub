import 'package:flutter/material.dart';

class CustomSnackbars {
  static void showErrorSnackbar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        duration: Duration(seconds: 1),
        elevation: 10,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(10),
            topRight: Radius.circular(10),
          ),
        ),
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  static void showSuccessSnackbar(
    BuildContext context,
    String message,
    double duration,
  ) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        elevation: 10,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(10),
            topRight: Radius.circular(10),
          ),
        ),
        content: Text(message),
        backgroundColor: Colors.green,
      ),
    );
  }

  static void showInfoSnackbar(
    BuildContext context,
    String message,
    double duration,
  ) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        elevation: 10,
        duration: Duration(seconds: duration.toInt()),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(10),
            topRight: Radius.circular(10),
          ),
        ),
        content: Text(message),
        backgroundColor: Colors.orange,
      ),
    );
  }

  static SnackBar showLoadingSnackbar(String message) {
    return SnackBar(
      elevation: 10,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(10),
          topRight: Radius.circular(10),
        ),
      ),
      content: Row(
        children: [
          CircularProgressIndicator(color: Colors.white),
          SizedBox(width: 16),
          Text(message),
        ],
      ),
      backgroundColor: Colors.blue,
      duration: Duration(
        minutes: 1,
      ), // Long duration as we'll dismiss it manually
    );
  }

  static void showPermissionSnackbar(
    BuildContext context,
    String message,
    VoidCallback onActionPressed,
  ) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        elevation: 10,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(10),
            topRight: Radius.circular(10),
          ),
        ),
        content: Text(message),
        backgroundColor: Colors.deepPurple,
        action: SnackBarAction(
          label: 'Settings',
          onPressed: onActionPressed,
          textColor: Colors.white,
        ),
        duration: Duration(seconds: 5),
      ),
    );
  }
}
