import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:front/main.dart';
import 'package:front/model/report_model.dart';
import 'package:front/services/cloudinary_service.dart';
import 'package:front/utils/hive_utils.dart';
import 'package:http/http.dart' as http;

class ReportController {
  // Report a user
  static Future<String> reportUser({
    required String userId,
    required String reason,
    List<File>? proofImageFiles,
  }) async {
    try {
      final token = HiveUtils.getData('token');
      
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
        Uri.parse('$apiUrl/report/user'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'userId': userId,
          'reason': reason,
          'proofImages': proofImageUrls,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['message'] ?? 'User reported successfully';
      } else {
        final error = jsonDecode(response.body);
        return error['error'] ?? 'Failed to report user';
      }
    } catch (e) {
      debugPrint('Error reporting user: $e');
      return 'Error reporting user';
    }
  }

  // Report a list item
  static Future<String> reportListItem({
    required String listItemId,
    required String reason,
    List<File>? proofImageFiles,
  }) async {
    try {
      final token = HiveUtils.getData('token');
      
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
        Uri.parse('$apiUrl/report/listitem'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'listItemId': listItemId,
          'reason': reason,
          'proofImages': proofImageUrls,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['message'] ?? 'Listing reported successfully';
      } else {
        final error = jsonDecode(response.body);
        return error['error'] ?? 'Failed to report listing';
      }
    } catch (e) {
      debugPrint('Error reporting listing: $e');
      return 'Error reporting listing';
    }
  }

  // Request listing reactivation
  static Future<String> requestReactivation({
    required String listItemId,
    required String reason,
  }) async {
    try {
      final token = HiveUtils.getData('token');
      final response = await http.post(
        Uri.parse('$apiUrl/report/reactivation'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({'listItemId': listItemId, 'reason': reason}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['message'] ?? 'Reactivation request submitted successfully';
      } else {
        final error = jsonDecode(response.body);
        return error['error'] ?? 'Failed to submit reactivation request';
      }
    } catch (e) {
      debugPrint('Error requesting reactivation: $e');
      return 'Error requesting reactivation';
    }
  }

  // Get all reports (Admin only)
  static Future<List<Report>> getAllReports({
    String? status,
    String? type,
  }) async {
    try {
      final token = HiveUtils.getData('token');
      String url = '$apiUrl/report/all';

      List<String> params = [];
      if (status != null) params.add('status=$status');
      if (type != null) params.add('type=$type');

      if (params.isNotEmpty) {
        url += '?${params.join('&')}';
      }

      final response = await http.get(
        Uri.parse(url),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List reports = data['reports'] ?? [];
        return reports.map((json) => Report.fromJson(json)).toList();
      }
      return [];
    } catch (e) {
      debugPrint('Error fetching reports: $e');
      return [];
    }
  }

  // Get report statistics (Admin only)
  static Future<Map<String, dynamic>> getReportStats() async {
    try {
      final token = HiveUtils.getData('token');
      final response = await http.get(
        Uri.parse('$apiUrl/report/stats'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['stats'] ?? {};
      }
      return {};
    } catch (e) {
      debugPrint('Error fetching report stats: $e');
      return {};
    }
  }

  // Handle user report action (Admin only)
  static Future<String> handleUserReport({
    required String reportId,
    required String action, // 'ban', 'delete', 'ignore'
    String? adminNotes,
  }) async {
    try {
      final token = HiveUtils.getData('token');
      final response = await http.post(
        Uri.parse('$apiUrl/report/$reportId/handle-user'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({'action': action, 'adminNotes': adminNotes}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['message'] ?? 'Action completed successfully';
      } else {
        final error = jsonDecode(response.body);
        return error['error'] ?? 'Failed to complete action';
      }
    } catch (e) {
      debugPrint('Error handling user report: $e');
      return 'Error handling report';
    }
  }

  // Handle list item report action (Admin only)
  static Future<String> handleListItemReport({
    required String reportId,
    required String action, // 'remove', 'ignore'
    String? adminNotes,
  }) async {
    try {
      final token = HiveUtils.getData('token');
      final response = await http.post(
        Uri.parse('$apiUrl/report/$reportId/handle-listitem'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({'action': action, 'adminNotes': adminNotes}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['message'] ?? 'Action completed successfully';
      } else {
        final error = jsonDecode(response.body);
        return error['error'] ?? 'Failed to complete action';
      }
    } catch (e) {
      debugPrint('Error handling list item report: $e');
      return 'Error handling report';
    }
  }

  // Handle reactivation request (Admin only)
  static Future<String> handleReactivationRequest({
    required String reportId,
    required String action, // 'accept', 'reject'
    String? adminNotes,
  }) async {
    try {
      final token = HiveUtils.getData('token');
      final response = await http.post(
        Uri.parse('$apiUrl/report/$reportId/handle-reactivation'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({'action': action, 'adminNotes': adminNotes}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['message'] ?? 'Action completed successfully';
      } else {
        final error = jsonDecode(response.body);
        return error['error'] ?? 'Failed to complete action';
      }
    } catch (e) {
      debugPrint('Error handling reactivation request: $e');
      return 'Error handling request';
    }
  }

  // Update report status (Admin only)
  static Future<String> updateReportStatus({
    required String reportId,
    required String status,
    String? adminNotes,
  }) async {
    try {
      final token = HiveUtils.getData('token');
      final response = await http.put(
        Uri.parse('$apiUrl/report/$reportId/status'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({'status': status, 'adminNotes': adminNotes}),
      );

      if (response.statusCode == 200) {
        return 'Report status updated successfully';
      } else {
        final error = jsonDecode(response.body);
        return error['error'] ?? 'Failed to update status';
      }
    } catch (e) {
      debugPrint('Error updating report status: $e');
      return 'Error updating status';
    }
  }
}
