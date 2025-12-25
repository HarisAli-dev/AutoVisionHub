import 'dart:convert';
import 'package:front/main.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../../model/users/user_model.dart';
import '../../utils/hive_utils.dart';

class UserController {
  // Get list of users that current user has not chatted with yet
  static Future<List<User>> getNewChatUsers({required String userId}) async {
    try {
      // Create URL without query parameters
      final uri = Uri.parse('$apiUrl/users/new-chat-users/$userId');

      // Make API request
      final token = HiveUtils.getData('token');
      final response = await http.get(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );
      print('Response status: ${response}');

      // Check response status
      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);

        // Parse user list from response
        final List<dynamic> userList = data['users'] ?? [];
        final List<User> users = userList
            .map((user) => User.fromJson(user))
            .toList();

        return users;
      } else {
        throw Exception('Failed to load users: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Error fetching new chat users: $e');
      throw Exception('Failed to load users: $e');
    }
  }

  // Start a new chat with a user
  static Future<Map<String, dynamic>> startNewChat(String userId) async {
    try {
      // Get auth token from local storage
      final token = HiveUtils.getData('token');

      if (token == null) {
        throw Exception('Authentication token not found');
      }

      // Make API request to create a new chat
      final response = await http.post(
        Uri.parse('$apiUrl/chat/createChat'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode({
          'participants': [userId],
        }),
      );

      // Check response status
      if (response.statusCode == 201) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to start new chat: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Error starting new chat: $e');
      throw Exception('Failed to start new chat: $e');
    }
  }

  static Future<User> getProfile(String userId) async {
    try {
      final token = HiveUtils.getData('token');
      if (token == null) {
        throw Exception('Authentication token not found');
      }

      final response = await http.get(
        Uri.parse('$apiUrl/users/profile'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print('Fetched user profile: $data');
        return User.fromJson(data);
      } else {
        throw Exception('Failed to load profile: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Error fetching profile: $e');
      throw Exception('Failed to load profile: $e');
    }
  }

  //-----======================== UPDATE PROFILE ========================-----

  // Update user profile
  static Future<bool> updateProfile({
    required String name,
    required String phoneNumber,
    required String city,
    String? profileImageUrl,
  }) async {
    try {
      final token = HiveUtils.getData('token');
      if (token == null) {
        throw Exception('Authentication token not found');
      }

      final response = await http.put(
        Uri.parse('$apiUrl/users/update'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode({
          'name': name,
          'phoneNumber': phoneNumber,
          'city': city,
          'profileImageUrl': profileImageUrl,
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print('Updated user profile: $data');
        return true;
      } else {
        throw Exception('Failed to update profile: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Error updating profile: $e');
      throw Exception('Failed to update profile: $e');
    }
  }

  //-----======================== CHANGE PASSWORD ========================-----
  static Future<bool> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    try {
      final token = HiveUtils.getData('token');
      if (token == null) {
        throw Exception('Authentication token not found');
      }

      final response = await http.put(
        Uri.parse('$apiUrl/users/change-password'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode({
          'currentPassword': currentPassword,
          'newPassword': newPassword,
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        debugPrint('Password change response: $data');
        return true;
      } else {
        debugPrint('Failed to change password: ${response.statusCode}');
        return false;
      }
    } catch (e) {
      debugPrint('Error changing password: $e');
      return false;
    }
  }

  //-----======================== GET ALL USERS (Admin) ========================-----
  static Future<List<User>> getAllUsers() async {
    try {
      final token = HiveUtils.getData('token');
      if (token == null) {
        throw Exception('Authentication token not found');
      }

      final response = await http.get(
        Uri.parse('$apiUrl/users/all'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((user) => User.fromJson(user)).toList();
      } else {
        throw Exception('Failed to load users: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Error fetching all users: $e');
      throw Exception('Failed to load users: $e');
    }
  }

  //-----======================== DELETE USER (Admin) ========================-----
  static Future<bool> deleteUser(String userId) async {
    try {
      final token = HiveUtils.getData('token');
      if (token == null) {
        throw Exception('Authentication token not found');
      }

      final response = await http.delete(
        Uri.parse('$apiUrl/users/delete/$userId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        debugPrint('User deleted successfully');
        return true;
      } else {
        debugPrint('Failed to delete user: ${response.statusCode}');
        return false;
      }
    } catch (e) {
      debugPrint('Error deleting user: $e');
      return false;
    }
  }

  //-----======================== BAN/UNBAN USER (Admin) ========================-----
  static Future<bool> banUser(String userId, bool ban) async {
    try {
      final token = HiveUtils.getData('token');
      if (token == null) {
        throw Exception('Authentication token not found');
      }

      final response = await http.put(
        Uri.parse('$apiUrl/users/ban/$userId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode({'ban': ban}),
      );

      if (response.statusCode == 200) {
        debugPrint('User ban status updated successfully');
        return true;
      } else {
        debugPrint('Failed to update ban status: ${response.statusCode}');
        return false;
      }
    } catch (e) {
      debugPrint('Error updating ban status: $e');
      return false;
    }
  }
}
