import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:front/model/groups/thread_model.dart';
import 'package:front/main.dart';
import 'package:front/utils/hive_utils.dart';
import 'package:http/http.dart' as http;

class ThreadController {
  static Future<String> createThread({
    required String topicName,
    String? description,
    File? imageFile,
  }) async {
    try {
      final token = HiveUtils.getData('token');
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('$apiUrl/thread/create'),
      );

      request.headers['Authorization'] = 'Bearer $token';
      request.fields['topicName'] = topicName;
      if (description != null && description.isNotEmpty) {
        request.fields['description'] = description;
      }

      if (imageFile != null) {
        request.files.add(
          await http.MultipartFile.fromPath('image', imageFile.path),
        );
      }

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        return 'Thread created successfully';
      } else {
        final error = jsonDecode(response.body);
        return error['error'] ?? 'Failed to create thread';
      }
    } catch (e) {
      debugPrint('Error creating thread: $e');
      return 'Error creating thread';
    }
  }

  static Future<List<Thread>> getAllThreads() async {
    try {
      final token = HiveUtils.getData('token');
      final response = await http.get(
        Uri.parse('$apiUrl/thread/all'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List threads = data['threads'] ?? [];
        return threads.map((json) => Thread.fromJson(json)).toList();
      }
      return [];
    } catch (e) {
      debugPrint('Error fetching threads: $e');
      return [];
    }
  }

  static Future<List<Thread>> getUserThreads() async {
    try {
      final token = HiveUtils.getData('token');
      final response = await http.get(
        Uri.parse('$apiUrl/thread/user'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List threads = data['threads'] ?? [];
        return threads.map((json) => Thread.fromJson(json)).toList();
      }
      return [];
    } catch (e) {
      debugPrint('Error fetching user threads: $e');
      return [];
    }
  }

  static Future<String> joinThread(String threadId) async {
    try {
      final token = HiveUtils.getData('token');
      final response = await http.post(
        Uri.parse('$apiUrl/thread/$threadId/join'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        return 'Joined thread successfully';
      } else {
        final error = jsonDecode(response.body);
        return error['error'] ?? 'Failed to join thread';
      }
    } catch (e) {
      debugPrint('Error joining thread: $e');
      return 'Error joining thread';
    }
  }

  static Future<String> leaveThread(String threadId) async {
    try {
      final token = HiveUtils.getData('token');
      final response = await http.post(
        Uri.parse('$apiUrl/thread/$threadId/leave'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        return 'Left thread successfully';
      } else {
        final error = jsonDecode(response.body);
        return error['error'] ?? 'Failed to leave thread';
      }
    } catch (e) {
      debugPrint('Error leaving thread: $e');
      return 'Error leaving thread';
    }
  }

  static Future<String> deleteThread(String threadId) async {
    try {
      final token = HiveUtils.getData('token');
      final response = await http.delete(
        Uri.parse('$apiUrl/thread/$threadId'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        return 'Thread deleted successfully';
      } else {
        final error = jsonDecode(response.body);
        return error['error'] ?? 'Failed to delete thread';
      }
    } catch (e) {
      debugPrint('Error deleting thread: $e');
      return 'Error deleting thread';
    }
  }

  static Future<Thread?> getThreadDetails(String threadId) async {
    try {
      final token = HiveUtils.getData('token');
      final response = await http.get(
        Uri.parse('$apiUrl/thread/$threadId'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return Thread.fromJson(data['thread']);
      }
      return null;
    } catch (e) {
      debugPrint('Error fetching thread details: $e');
      return null;
    }
  }
}
