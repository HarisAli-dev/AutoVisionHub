import 'dart:convert';
import 'dart:io';

import 'package:front/main.dart';
import 'package:front/model/chats/message_model.dart';
import 'package:front/services/cloudinary_service.dart';
import 'package:front/services/socket_service.dart';
import 'package:front/utils/hive_utils.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class ChatMessageController {
  // Send a text message
  static Future<Message> sendTextMessage(
    String chatId,
    String content,
    bool isGroup,
  ) async {
    return sendMessage(chatId, isGroup, MessageType.text, content: content);
  }

  // Send a media message (image, video, file, voice)
  static Future<Message> sendMediaMessage(
    String chatId,
    bool isGroup,
    MessageType type,
    File file,
  ) async {
    try {
      debugPrint(
        'Sending media message of type: ${_messageTypeToString(type)}',
      );
      debugPrint('File exists: ${file.existsSync()}');
      debugPrint('File path: ${file.path}');

      if (!file.existsSync()) {
        throw Exception('File does not exist at path: ${file.path}');
      }

      // Upload file to Cloudinary based on message type
      Map<String, dynamic> uploadResult;

      switch (type) {
        case MessageType.image:
          debugPrint('Uploading image to Cloudinary...');
          uploadResult = await CloudinaryService.uploadFile(
            file: file,
            fileType: 'image',
          );
          break;
        case MessageType.video:
          debugPrint('Uploading video to Cloudinary...');
          uploadResult = await CloudinaryService.uploadFile(
            file: file,
            fileType: 'video',
          );
          break;
        case MessageType.voice:
          debugPrint('Uploading audio to Cloudinary...');
          uploadResult = await CloudinaryService.uploadFile(
            file: file,
            fileType: 'audio',
          );
          break;
        case MessageType.file:
          debugPrint('Uploading document to Cloudinary...');
          uploadResult = await CloudinaryService.uploadFile(
            file: file,
            fileType: 'file',
          );
          break;
        default:
          throw Exception('Unsupported message type for media upload');
      }

      // Verify that the upload result contains a URL
      if (!uploadResult['success'] || !uploadResult.containsKey('url')) {
        debugPrint('Upload result: $uploadResult');
        throw Exception('Cloudinary upload failed or did not return a URL');
      }

      // Get the URL from the upload result
      final String mediaUrl = uploadResult['url'];
      debugPrint('Successfully uploaded to Cloudinary: $mediaUrl');

      // Get thumbnail URL for videos if available
      String? thumbnailUrl;
      if (type == MessageType.video &&
          uploadResult.containsKey('thumbnailUrl')) {
        // Use thumbnail URL that was automatically generated during upload
        thumbnailUrl = uploadResult['thumbnailUrl'];
        debugPrint('Using auto-generated thumbnail: $thumbnailUrl');
      } else {
        debugPrint(
          'No thumbnail available: type=$type, hasThumbnailUrl=${uploadResult.containsKey('thumbnailUrl')}',
        );
      }

      // Send the message with the media URL
      debugPrint('Sending message with media URL to backend...');
      return sendMessage(
        chatId,
        isGroup,
        type,
        content: 'media',
        mediaUrl: mediaUrl,
        thumbnailUrl: thumbnailUrl,
      );
    } catch (e) {
      debugPrint('Error sending media message: $e');
      throw Exception('Failed to send media message: $e');
    }
  }

  // Generic send message method
  static Future<Message> sendMessage(
    String id,
    bool isGroup,
    MessageType type, {
    String? content,
    String? mediaUrl,
    String? thumbnailUrl,
    int? duration,
    String? callType,
  }) async {
    try {
      final token = HiveUtils.getData('token');
      final userId = HiveUtils.getData('userId');
      final userName = HiveUtils.getData('name') ?? 'User';

      if (token == null || userId == null) {
        throw Exception('Authentication information not found');
      }

      // Prepare message data
      final Map<String, dynamic> messageData = {
        if (isGroup) 'groupId': id else 'chatId': id,
        'type': _messageTypeToString(type),
        'senderId': userId,
        'senderName': userName,
      };

      // Add optional fields if they exist
      if (content != null && content.isNotEmpty) {
        messageData['content'] = content;
      }

      if (mediaUrl != null) {
        messageData['mediaUrl'] = mediaUrl;
      }

      if (thumbnailUrl != null) {
        messageData['thumbnailUrl'] = thumbnailUrl;
        debugPrint('Thumbnail URL being sent to backend: $thumbnailUrl');
      } else {
        debugPrint('No thumbnail URL to send to backend');
      }

      if (duration != null) {
        messageData['duration'] = duration;
      }

      if (callType != null) {
        messageData['callType'] = callType;
      }

      // Send request to server
      debugPrint('Sending message to server: ${messageData.toString()}');

      if (mediaUrl != null) {
        debugPrint('Media URL being sent: $mediaUrl');
      }
      dynamic response;
        response = await http.post(
          Uri.parse('$apiUrl/chatMessage/send'),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $token',
          },
          body: json.encode(messageData),
        );
    

      debugPrint('Response status code: ${response.statusCode}');

      if (response.statusCode == 201 || response.statusCode == 200) {
        final responseData = json.decode(response.body);
        debugPrint('Response received: ${response.body}');

        // Handle response format variations
        final messageJson =
            responseData is Map<String, dynamic> &&
                responseData.containsKey('message')
            ? responseData['message']
            : responseData;

        // Create message from response
        final message = Message.fromJson(messageJson);
        debugPrint('Message created with ID: ${message.id}');

        // Also emit via socket for real-time updates if available
        final socketService = SocketService();
        if (socketService.isConnected) {
          debugPrint('Sending message via socket');
          socketService.sendMessage(messageJson);
        }

        return message;
      } else {
        debugPrint(
          'Failed to send message. Status: ${response.statusCode}, Body: ${response.body}',
        );
        throw Exception(
          'Failed to send message: ${response.statusCode} - ${response.body}',
        );
      }
    } catch (e) {
      debugPrint('Error sending message: $e');
      throw Exception('Failed to send message: $e');
    }
  }

  // Convert message type enum to string
  static String _messageTypeToString(MessageType type) {
    switch (type) {
      case MessageType.text:
        return 'text';
      case MessageType.image:
        return 'image';
      case MessageType.video:
        return 'video';
      case MessageType.voice:
        return 'voice';
      case MessageType.file:
        return 'file';
      case MessageType.call:
        return 'call';
    }
  }

  static Future<bool> deleteMessage(String messageId) async {
    try {
      final token = HiveUtils.getData('token');
      if (token == null) {
        throw Exception('Authentication token not found');
      }

      final response = await http.delete(
        Uri.parse('$apiUrl/chatMessage/$messageId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        return true;
      } else {
        throw Exception('Failed to delete message: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Error deleting message: $e');
      return false;
    }
  }
}
