// controller/unban_request_controller.dart
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:front/main.dart';
import 'package:front/model/report_model.dart';
import 'package:front/services/cloudinary_service.dart';
import 'package:front/utils/hive_utils.dart';
import 'package:http/http.dart' as http;

class UnbanRequestController {
  // Create unban request
  static Future<String> createUnbanRequest({
    required String email,
    required String message,
    List<File>? proofImageFiles,
  }) async {
    try {
      // Upload proof images to Cloudinary
      List<String> proofImageUrls = [];
      if (proofImageFiles != null && proofImageFiles.isNotEmpty) {
        for (File imageFile in proofImageFiles) {
          try {
            final result = await CloudinaryService.uploadFile(
              file: imageFile,
              fileType: 'image',
            );
            if (result['success'] == true && result['url'] != null) {
              proofImageUrls.add(result['url']);
            }
          } catch (e) {
            debugPrint('Error uploading proof image: $e');
          }
        }
      }

      final response = await http.post(
        Uri.parse('$apiUrl/unban-request/create'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'email': email,
          'message': message,
          'proofImages': proofImageUrls,
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        return data['message'] ?? 'Unban request submitted successfully';
      } else {
        final error = jsonDecode(response.body);
        return error['error'] ?? 'Failed to submit unban request';
      }
    } catch (e) {
      debugPrint('Error creating unban request: $e');
      return 'Error submitting unban request';
    }
  }

  // Get user's unban request
  static Future<Report?> getUserUnbanRequest() async {
    try {
      final token = HiveUtils.getData('token');
      if (token == null) {
        return null;
      }

      final response = await http.get(
        Uri.parse('$apiUrl/unban-request/my-request'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data != null && data is Map<String, dynamic>) {
          return Report.fromJson(data);
        }
        return null;
      } else {
        return null;
      }
    } catch (e) {
      debugPrint('Error fetching unban request: $e');
      return null;
    }
  }

  // Get all unban requests (Admin only)
  static Future<List<Report>> getAllUnbanRequests({String? status}) async {
    try {
      final token = HiveUtils.getData('token');
      String url = '$apiUrl/unban-request/all';
      
      if (status != null) {
        url += '?status=$status';
      }

      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final List data = jsonDecode(response.body);
        return data.map((json) => Report.fromJson(json)).toList();
      }
      return [];
    } catch (e) {
      debugPrint('Error fetching unban requests: $e');
      return [];
    }
  }

  // Review unban request (Admin only)
  static Future<String> reviewUnbanRequest({
    required String requestId,
    required String status,
    String? adminNotes,
  }) async {
    try {
      final token = HiveUtils.getData('token');
      final response = await http.patch(
        Uri.parse('$apiUrl/unban-request/review/$requestId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'status': status,
          'adminNotes': adminNotes,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['message'] ?? 'Unban request reviewed successfully';
      } else {
        final error = jsonDecode(response.body);
        return error['error'] ?? 'Failed to review unban request';
      }
    } catch (e) {
      debugPrint('Error reviewing unban request: $e');
      return 'Error reviewing unban request';
    }
  }
}
