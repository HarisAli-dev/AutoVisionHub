import 'dart:convert';
import 'dart:io';
import 'package:front/services/cloudinary_service.dart';
import 'package:front/services/notification_service.dart';
import 'package:front/utils/hive_utils.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:front/main.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

class AuthController {
  static Future<String> signup(
    String name,
    String email,
    String password,
    String phoneNumber,
    String city,
    String role,
  ) async {
    final String registerApiUrl = '$apiUrl/auth/register';
    final response = await http.post(
      Uri.parse(registerApiUrl),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        'name': name,
        'email': email,
        'password': password,
        'phoneNumber': phoneNumber,
        'city': city,
        'role': role,
      }),
    );

    final message = json.decode(response.body)['message'];
    if (response.statusCode == 201 || response.statusCode == 200) {
      return "Signup successful";
    }
    return message;
  }

  static Future<String> signin(String email, String password) async {
    print('API URL: $apiUrl');
    final String signinApiUrl = '$apiUrl/auth/login';
    final response = await http.post(
      Uri.parse(signinApiUrl),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({'email': email, 'password': password}),
    );
    if (response.statusCode == 200 || response.statusCode == 201) {
      final data = json.decode(response.body);
      final String role = data['role'];
      HiveUtils.putData('userId', data['userId']);
      HiveUtils.putData('name', data['userName']);
      HiveUtils.putData('token', data['token']);
      HiveUtils.loginSession();
      HiveUtils.putData('role', role);

      // Update FCM token after successful login
      try {
        final fcmToken = await FirebaseMessaging.instance.getToken();
        if (fcmToken != null) {
          await NotificationService.updateFCMToken(fcmToken);
        }
      } catch (e) {
        debugPrint('Error updating FCM token after login: $e');
      }

      return "Login successful";
    } else if (response.statusCode == 403) {
      // User is banned
      final data = json.decode(response.body);
      return "BANNED:${data['message']}";
    } else {
      return "Wrong email or password";
    }
  }

  static Future<bool> checkTokenExpiry(String token) async {
    final String checkTokenApiUrl = '$apiUrl/auth/checkTokenExpiry/$token';
    try {
      final response = await http.get(
        Uri.parse(checkTokenApiUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['message'] == true;
      } else {
        return false;
      }
    } catch (e) {
      debugPrint('Error checking token expiry: $e');
      return false;
    }
  }

  static Future<String> uploadProfileImage(File imageFile) async {
    try {
      final token = HiveUtils.getData('token');
      if (token == null) {
        throw Exception('Authentication token not found');
      }

      // use cloudinary service to upload image
      final result = await CloudinaryService.uploadFile(
        file: imageFile,
        fileType: 'profileImages',
      );

      if (result.containsKey('url')) {
        return result['url']!;
      } else {
        debugPrint('Upload failed for ${imageFile.path}: No URL in response');
        return '';
      }
    } catch (e) {
      debugPrint('Error uploading profile image: $e');
      throw Exception('Error uploading image: ${e.toString()}');
    }
  }

  /// Logout user and clear FCM token from backend
  static Future<bool> logout() async {
    try {
      final token = HiveUtils.getData('token');
      if (token == null) {
        debugPrint('No auth token found for logout');
        // Still clear local data even if no token
        await _clearLocalData();
        return true;
      }

      // Call backend logout API
      final response = await http.post(
        Uri.parse('$apiUrl/auth/logout'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        debugPrint('Logout successful on backend');
      } else {
        debugPrint('Backend logout failed: ${response.body}');
        // Continue with local logout even if backend fails
      }
    } catch (e) {
      debugPrint('Error during logout API call: $e');
      // Continue with local logout even if API fails
    }

    // Always clear local data regardless of API response
    await _clearLocalData();
    return true;
  }

  /// Clear all local user data
  static Future<void> _clearLocalData() async {
    try {
      // Clear notification service FCM token
      await NotificationService.clearFCMToken();

      // Clear all session data
      await HiveUtils.logOutSession();

      debugPrint('Local data cleared successfully');
    } catch (e) {
      debugPrint('Error clearing local data: $e');
    }
  }
}
