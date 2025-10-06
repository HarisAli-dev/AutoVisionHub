import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:hive/hive.dart';
import 'package:front/config/app_config.dart';

class NotificationService {
  static const String _fcmTokenKey = 'fcm_token';
  static const String _authTokenKey =
      'token'; // Match the key used in AuthController

  /// Update FCM token on the server
  static Future<bool> updateFCMToken(String fcmToken) async {
    try {
      final box = Hive.box('sessionBox');
      final authToken = box.get(_authTokenKey);

      if (authToken == null) {
        print('No auth token found');
        return false;
      }

      final response = await http.put(
        Uri.parse('${AppConfig.apiBaseUrl}/auth/fcm-token'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $authToken',
        },
        body: jsonEncode({'fcmToken': fcmToken}),
      );

      if (response.statusCode == 200) {
        // Store FCM token locally for future reference
        await box.put(_fcmTokenKey, fcmToken);
        print('FCM token updated successfully');
        return true;
      } else {
        print('Failed to update FCM token: ${response.body}');
        return false;
      }
    } catch (e) {
      print('Error updating FCM token: $e');
      return false;
    }
  }

  /// Get stored FCM token
  static String? getStoredFCMToken() {
    final box = Hive.box('sessionBox');
    return box.get(_fcmTokenKey);
  }

  /// Clear stored FCM token (on logout)
  static Future<void> clearFCMToken() async {
    try {
      final box = Hive.box('sessionBox');
      final authToken = box.get(_authTokenKey);

      // If we have an auth token, try to clear FCM token on backend first
      if (authToken != null) {
        try {
          final response = await http.put(
            Uri.parse('${AppConfig.apiBaseUrl}/auth/fcm-token'),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $authToken',
            },
            body: jsonEncode({
              'fcmToken': '', // Send empty string to clear
            }),
          );

          if (response.statusCode == 200) {
            print('FCM token cleared on backend successfully');
          } else {
            print('Failed to clear FCM token on backend: ${response.body}');
          }
        } catch (e) {
          print('Error clearing FCM token on backend: $e');
          // Continue with local clearing even if backend fails
        }
      }

      // Always clear local FCM token
      await box.delete(_fcmTokenKey);
      print('FCM token cleared locally');
    } catch (e) {
      print('Error clearing FCM token: $e');
    }
  }

  /// Check if FCM token needs to be updated
  static Future<void> syncFCMTokenIfNeeded(String currentToken) async {
    final storedToken = getStoredFCMToken();

    if (storedToken != currentToken) {
      print('FCM token changed, updating on server...');
      await updateFCMToken(currentToken);
    }
  }
}
