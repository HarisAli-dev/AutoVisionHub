import 'dart:convert';
import 'dart:io';

import 'package:front/main.dart';
import 'package:front/model/groups/group_message_model.dart';
import 'package:front/model/groups/poll_model.dart';
import 'package:front/services/cloudinary_service.dart';
import 'package:front/services/socket_service.dart';
import 'package:front/utils/hive_utils.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class GroupMessageController {
  // ==================== BASIC MESSAGE OPERATIONS ====================

  /// Send a text message to group
  static Future<bool> sendTextMessage(String groupId, String content) async {
    return sendMessage(groupId, GroupMessageType.text, content: content);
  }

  /// Send a media message (image, video, file, voice) to group
  static Future<bool> sendMediaMessage(
    String groupId,
    GroupMessageType type,
    File file,
  ) async {
    try {
      debugPrint(
        'Sending group media message of type: ${_messageTypeToString(type)}',
      );
      debugPrint('File exists: ${file.existsSync()}');
      debugPrint('File path: ${file.path}');

      if (!file.existsSync()) {
        throw Exception('File does not exist at path: ${file.path}');
      }

      // Upload file to Cloudinary based on message type
      Map<String, dynamic> uploadResult;

      switch (type) {
        case GroupMessageType.image:
          debugPrint('Uploading image to Cloudinary...');
          uploadResult = await CloudinaryService.uploadFile(
            file: file,
            fileType: 'image',
          );
          break;
        case GroupMessageType.video:
          debugPrint('Uploading video to Cloudinary...');
          uploadResult = await CloudinaryService.uploadFile(
            file: file,
            fileType: 'video',
          );
          break;
        case GroupMessageType.voice:
          debugPrint('Uploading audio to Cloudinary...');
          uploadResult = await CloudinaryService.uploadFile(
            file: file,
            fileType: 'audio',
          );
          break;
        case GroupMessageType.file:
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
      if (type == GroupMessageType.video &&
          uploadResult.containsKey('thumbnailUrl')) {
        thumbnailUrl = uploadResult['thumbnailUrl'];
        debugPrint('Using auto-generated thumbnail: $thumbnailUrl');
      }

      // Send the message with the media URL
      debugPrint('Sending group message with media URL to backend...');
      return sendMessage(
        groupId,
        type,
        content: 'media',
        mediaUrl: mediaUrl,
        thumbnailUrl: thumbnailUrl,
      );
    } catch (e) {
      debugPrint('Error sending group media message: $e');
      throw Exception('Failed to send group media message: $e');
    }
  }

  /// Generic send message method for groups
  static Future<bool> sendMessage(
    String groupId,
    GroupMessageType type, {
    String? content,
    String? mediaUrl,
    String? thumbnailUrl,
    int? duration,
    GroupCallType? callType,
    String? pollId, // For poll messages
  }) async {
    try {
      debugPrint(
        'Preparing to send group message of type: ${_messageTypeToString(type)}',
      );
      final token = HiveUtils.getData('token');
      final userId = HiveUtils.getData('userId');
      final userName = HiveUtils.getData('name') ?? 'User';

      if (token == null || userId == null) {
        throw Exception('Authentication information not found');
      }

      // Prepare message data
      final Map<String, dynamic> messageData = {
        'groupId': groupId,
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
      }

      if (duration != null) {
        messageData['duration'] = duration;
      }

      if (callType != null) {
        messageData['callType'] = _callTypeToString(callType);
      }

      if (pollId != null) {
        messageData['pollId'] = pollId;
      }

      // Send request to server
      debugPrint('Sending group message to server: ${messageData.toString()}');

      final response = await http.post(
        Uri.parse('$apiUrl/groupMessage/sendMessage'),
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

        // Create group message from response
        final message = GroupMessage.fromJson(messageJson);
        debugPrint('Group message created with ID: ${message.id}');

        // Also emit via socket for real-time updates if available
        final socketService = SocketService();
        if (socketService.isConnected) {
          debugPrint('Sending group message via socket');
          socketService.socket.emit('group_message', messageJson);
        }

        return true;
      } else {
        debugPrint(
          'Failed to send group message. Status: ${response.statusCode}, Body: ${response.body}',
        );
        throw Exception(
          'Failed to send group message: ${response.statusCode} - ${response.body}',
        );
      }
    } catch (e) {
      debugPrint('Error sending group message: $e');
      throw Exception('Failed to send group message: $e');
    }
  }

  // ==================== MESSAGE MANAGEMENT ====================

  /// Get group messages with pagination
  static Future<List<GroupMessage>> getGroupMessages({
    required String groupId,
    int? page,
    int? limit,
  }) async {
    try {
      final token = HiveUtils.getData('token');
      if (token == null) {
        throw Exception('Authentication token not found');
      }

      String url = '$apiUrl/groupMessage/$groupId/messages';
      if (page != null || limit != null) {
        url += '?';
        if (page != null) url += 'page=$page&';
        if (limit != null) url += 'limit=$limit&';
        url = url.substring(0, url.length - 1); // Remove trailing &
      }

      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );
      debugPrint('Fetch messages response status: ${response.body}');

      if (response.statusCode == 200) {
        final dynamic decodedResponse = json.decode(response.body);

        List<dynamic> data;
        if (decodedResponse is List) {
          data = decodedResponse;
        } else if (decodedResponse is Map<String, dynamic>) {
          data = decodedResponse['messages'] ?? [];
        } else {
          throw Exception('Unexpected response format');
        }

        return data.map((message) => GroupMessage.fromJson(message)).toList();
      } else {
        throw Exception(
          'Failed to load group messages: ${response.statusCode}',
        );
      }
    } catch (e) {
      debugPrint('Error fetching group messages: $e');
      throw Exception('Failed to load group messages: $e');
    }
  }

  /// Delete a group message
  static Future<bool> deleteGroupMessage(String messageId) async {
    try {
      final token = HiveUtils.getData('token');
      if (token == null) {
        throw Exception('Authentication token not found');
      }

      final response = await http.delete(
        Uri.parse('$apiUrl/groupMessage/message/$messageId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        // Emit socket event for real-time updates
        final socketService = SocketService();
        if (socketService.isConnected) {
          socketService.socket.emit('group_message_deleted', {
            'messageId': messageId,
          });
        }
        return true;
      } else {
        throw Exception(
          'Failed to delete group message: ${response.statusCode}',
        );
      }
    } catch (e) {
      debugPrint('Error deleting group message: $e');
      return false;
    }
  }

  /// Edit a group message
  static Future<bool> editGroupMessage(
    String messageId,
    String newContent,
  ) async {
    try {
      final token = HiveUtils.getData('token');
      if (token == null) {
        throw Exception('Authentication token not found');
      }

      final response = await http.patch(
        Uri.parse('$apiUrl/groupMessage/message/$messageId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode({'content': newContent}),
      );

      if (response.statusCode == 200) {
        return true;
      } else {
        throw Exception('Failed to edit group message: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Error editing group message: $e');
      return false;
    }
  }

  /// Mark group messages as read
  static Future<void> markGroupAsRead(String groupId) async {
    try {
      final token = HiveUtils.getData('token');
      if (token == null) {
        throw Exception('Authentication token not found');
      }

      final response = await http.patch(
        Uri.parse('$apiUrl/groupMessage/$groupId/read'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to mark group as read: ${response.statusCode}');
      }

      // Also notify via socket for real-time updates
      final socketService = SocketService();
      if (socketService.isConnected) {
        final userId = HiveUtils.getData('userId');
        if (userId != null) {
          socketService.socket.emit('mark_group_read', {
            'groupId': groupId,
            'userId': userId,
          });
        }
      }
    } catch (e) {
      debugPrint('Error marking group as read: $e');
      throw Exception('Failed to mark group as read: $e');
    }
  }

  // ==================== POLL MANAGEMENT (Polls are messages) ====================

  /// Create a poll in group (sends a poll message)
  static Future<bool> createPoll({
    required String groupId,
    required String question,
    required List<String> options,
  }) async {
    try {
      final token = HiveUtils.getData('token');
      if (token == null) {
        throw Exception('Authentication token not found');
      }

      // First create the poll
      final pollResponse = await http.post(
        Uri.parse('$apiUrl/poll/create'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode({
          'question': question,
          'options': options,
          'groupId': groupId,
        }),
      );

      if (pollResponse.statusCode == 201) {
        final pollData = json.decode(pollResponse.body);
        debugPrint('Poll created successfully: $pollData');
        final poll = Poll.fromJson(pollData['poll'] ?? pollData);

        // Now send a poll message with the poll ID
        bool response = await sendMessage(
          groupId,
          GroupMessageType.poll,
          content: poll.question,
          pollId: poll.id,
        );
        return response;
      } else {
        throw Exception('Failed to create poll: ${pollResponse.statusCode}');
      }
    } catch (e) {
      debugPrint('Error creating poll: $e');
      throw Exception('Failed to create poll: $e');
    }
  }

  /// Vote on a poll
  static Future<Poll> voteOnPoll({
    required String pollId,
    required String option,
  }) async {
    try {
      final token = HiveUtils.getData('token');
      if (token == null) {
        throw Exception('Authentication token not found');
      }

      final response = await http.post(
        Uri.parse('$apiUrl/poll/$pollId/vote'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode({'option': option}),
      );

      if (response.statusCode == 200) {
        final dynamic decodedResponse = json.decode(response.body);
        final updatedPoll = Poll.fromJson(
          decodedResponse['poll'] ?? decodedResponse,
        );

        return updatedPoll;
      } else {
        throw Exception('Failed to vote on poll: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Error voting on poll: $e');
      throw Exception('Failed to vote on poll: $e');
    }
  }

  /// Get poll details
  static Future<Poll> getPoll(String pollId) async {
    try {
      final token = HiveUtils.getData('token');
      if (token == null) {
        throw Exception('Authentication token not found');
      }

      final response = await http.get(
        Uri.parse('$apiUrl/poll/$pollId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final dynamic decodedResponse = json.decode(response.body);
        debugPrint('Poll fetched: $decodedResponse');
        return Poll.fromJson(decodedResponse['poll'] ?? decodedResponse);
      } else {
        throw Exception('Failed to get poll: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Error getting poll: $e');
      throw Exception('Failed to get poll: $e');
    }
  }

  /// Delete a poll (and its associated message)
  static Future<bool> deletePoll(String pollId) async {
    try {
      final token = HiveUtils.getData('token');
      if (token == null) {
        throw Exception('Authentication token not found');
      }

      final response = await http.delete(
        Uri.parse('$apiUrl/poll/$pollId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        // Emit socket event for real-time updates
        final socketService = SocketService();
        if (socketService.isConnected) {
          socketService.socket.emit('poll_deleted', {'pollId': pollId});
        }
        return true;
      } else {
        throw Exception('Failed to delete poll: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Error deleting poll: $e');
      throw Exception('Failed to delete poll: $e');
    }
  }

  // ==================== CALL MESSAGES ====================

  /// Send a call message
  static Future<bool> sendCallMessage({
    required String groupId,
    required GroupCallType callType,
    int? duration,
  }) async {
    return sendMessage(
      groupId,
      GroupMessageType.call,
      content: 'Call',
      callType: callType,
      duration: duration,
    );
  }

  // ==================== UTILITY METHODS ====================

  /// Convert GroupMessageType enum to string
  static String _messageTypeToString(GroupMessageType type) {
    switch (type) {
      case GroupMessageType.text:
        return 'text';
      case GroupMessageType.image:
        return 'image';
      case GroupMessageType.video:
        return 'video';
      case GroupMessageType.voice:
        return 'voice';
      case GroupMessageType.file:
        return 'file';
      case GroupMessageType.call:
        return 'call';
      case GroupMessageType.poll:
        return 'poll';
    }
  }

  /// Convert GroupCallType enum to string
  static String _callTypeToString(GroupCallType type) {
    switch (type) {
      case GroupCallType.missed:
        return 'missed';
      case GroupCallType.outgoing:
        return 'outgoing';
      case GroupCallType.incoming:
        return 'incoming';
    }
  }

  // ==================== SOCKET HELPERS ====================

  /// Join group room for real-time message updates
  static void joinGroupRoom(String groupId) {
    final socketService = SocketService();
    if (socketService.isConnected) {
      socketService.socket.emit('join_group', {'groupId': groupId});
    }
  }

  /// Leave group room
  static void leaveGroupRoom(String groupId) {
    final socketService = SocketService();
    if (socketService.isConnected) {
      socketService.socket.emit('leave_group', {'groupId': groupId});
    }
  }
}
