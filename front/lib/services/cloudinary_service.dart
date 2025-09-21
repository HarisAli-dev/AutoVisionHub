import 'dart:io';
import 'package:front/main.dart';
import 'package:front/utils/hive_utils.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class CloudinaryService {
  static final String backendUrl = apiUrl;

  // Get authorization headers for multipart
  static Map<String, String> _getMultipartHeaders() {
    final token = HiveUtils.getData('token');
    return {'Authorization': 'Bearer $token'};
  }

  // Get authorization headers
  static Map<String, String> _getHeaders() {
    final token = HiveUtils.getData('token');
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  // ========== UPLOAD FILE ==========
  static Future<Map<String, dynamic>> uploadFile({
    required File file,
    required String fileType,
  }) async {
    try {
      debugPrint('=== UPLOADING FILE ===');
      debugPrint('File type: $fileType');
      debugPrint('File path: ${file.path}');

      final uri = Uri.parse('$backendUrl/media/upload');
      final request = http.MultipartRequest('POST', uri);

      // Add headers
      request.headers.addAll(_getMultipartHeaders());

      // Add file
      final multipartFile = await http.MultipartFile.fromPath(
        'file',
        file.path,
      );
      request.files.add(multipartFile);

      // Add file type
      request.fields['fileType'] = fileType;
      

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      debugPrint('Upload response: ${response.toString()}');
      debugPrint('Upload response status: ${response.statusCode}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final responseData = json.decode(response.body);
        debugPrint('Upload response data: $responseData');
        return {
          'success': true,
          'url': responseData['data']['url'],
          'thumbnailUrl': responseData['data']['thumbnailUrl'],
          'publicId': responseData['data']['publicId'],
        };
      } else {
        final errorData = json.decode(response.body);
        throw Exception(errorData['message'] ?? 'Upload failed');
      }
    } catch (e) {
      debugPrint('Upload error: $e');
      throw Exception('Failed to upload file: $e');
    }
  }

  // ========== DELETE FILE ==========
  static Future<bool> deleteFile({required String publicId}) async {
    try {
      debugPrint('=== DELETING FILE ===');
      debugPrint('Public ID: $publicId');

      final uri = Uri.parse('$backendUrl/media/delete');
      final response = await http.delete(
        uri,
        headers: _getHeaders(),
        body: json.encode({'publicId': publicId}),
      );

      debugPrint('Delete response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        return responseData['success'] ?? false;
      } else {
        return false;
      }
    } catch (e) {
      debugPrint('Delete error: $e');
      return false;
    }
  }

  // ========== GET FILE WITH TRANSFORMATIONS ==========
  static Future<String> getFile({
    required String publicId,
    int? width,
    int? height,
    String quality = 'auto',
  }) async {
    try {
      debugPrint('=== GETTING FILE ===');
      debugPrint('Public ID: $publicId');

      final queryParams = <String, String>{
        'publicId': publicId,
        if (width != null) 'width': width.toString(),
        if (height != null) 'height': height.toString(),
        if (quality != 'auto') 'quality': quality,
      };

      final uri = Uri.parse(
        '$backendUrl/media/get',
      ).replace(queryParameters: queryParams);

      final response = await http.get(uri, headers: _getHeaders());

      debugPrint('Get file response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        return responseData['data']['url'];
      } else {
        final errorData = json.decode(response.body);
        throw Exception(errorData['message'] ?? 'Failed to get file');
      }
    } catch (e) {
      debugPrint('Get file error: $e');
      throw Exception('Failed to get file: $e');
    }
  }

  // ========== DELETE FILE BY URL ==========
  static Future<bool> deleteFileByUrl({required String url}) async {
    try {
      debugPrint('=== DELETING FILE BY URL ===');
      debugPrint('URL: $url');

      final uri = Uri.parse('$backendUrl/media/delete-by-url');
      final response = await http.delete(
        uri,
        headers: _getHeaders(),
        body: json.encode({'url': url}),
      );

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        return responseData['success'] ?? false;
      } else {
        return false;
      }
    } catch (e) {
      debugPrint('Delete by URL error: $e');
      return false;
    }
  }

  // ========== UTILITY METHODS ==========

  // Get small image (300px width)
  static Future<String> getSmallImage(String publicId) async {
    return await getFile(publicId: publicId, width: 300, quality: '80');
  }

  // Get medium image (600px width)
  static Future<String> getMediumImage(String publicId) async {
    return await getFile(publicId: publicId, width: 600, quality: '85');
  }
}
