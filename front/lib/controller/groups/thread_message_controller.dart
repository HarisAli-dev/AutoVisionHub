import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:front/model/groups/thread_message_model.dart';
import 'package:front/main.dart';
import 'package:front/utils/hive_utils.dart';
import 'package:http/http.dart' as http;
import 'package:socket_io_client/socket_io_client.dart' as IO;

class ThreadMessageController {
  static IO.Socket? _socket;

  static void initSocket() {
    if (_socket == null || !_socket!.connected) {
      final token = HiveUtils.getData('token');
      _socket = IO.io(
        apiUrl.replaceAll('/api', ''),
        IO.OptionBuilder()
            .setTransports(['websocket'])
            .enableAutoConnect()
            .setAuth({'token': token})
            .build(),
      );
      _socket!.connect();
    }
  }

  static void joinThreadRoom(String threadId) {
    initSocket();
    _socket?.emit('join_thread', {'threadId': threadId});
    debugPrint('Joined thread room: $threadId');
  }

  static void leaveThreadRoom(String threadId) {
    _socket?.emit('leave_thread', {'threadId': threadId});
    debugPrint('Left thread room: $threadId');
  }

  static void listenForNewMessages(Function(ThreadMessage) onNewMessage) {
    _socket?.on('new_thread_message', (data) {
      try {
        final message = ThreadMessage.fromJson(data);
        onNewMessage(message);
      } catch (e) {
        debugPrint('Error parsing new thread message: $e');
      }
    });
  }

  static void listenForDeletedMessages(Function(String) onMessageDeleted) {
    _socket?.on('thread_message_deleted', (data) {
      try {
        final messageId = data['messageId'];
        onMessageDeleted(messageId);
      } catch (e) {
        debugPrint('Error parsing deleted message: $e');
      }
    });
  }

  static Future<String> sendMessage({
    required String threadId,
    required String message,
  }) async {
    try {
      final token = HiveUtils.getData('token');
      final response = await http.post(
        Uri.parse('$apiUrl/thread/message/send'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({'threadId': threadId, 'message': message}),
      );

      if (response.statusCode == 200) {
        return 'Message sent successfully';
      } else {
        final error = jsonDecode(response.body);
        return error['error'] ?? 'Failed to send message';
      }
    } catch (e) {
      debugPrint('Error sending message: $e');
      return 'Error sending message';
    }
  }

  static Future<Map<String, dynamic>> getThreadMessages({
    required String threadId,
    int page = 1,
    int limit = 50,
  }) async {
    try {
      final token = HiveUtils.getData('token');
      final response = await http.get(
        Uri.parse('$apiUrl/thread/$threadId/messages?page=$page&limit=$limit'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List messages = data['messages'] ?? [];
        return {
          'messages': messages
              .map((json) => ThreadMessage.fromJson(json))
              .toList(),
          'pagination': data['pagination'],
        };
      }
      return {'messages': [], 'pagination': null};
    } catch (e) {
      debugPrint('Error fetching thread messages: $e');
      return {'messages': [], 'pagination': null};
    }
  }

  static Future<String> deleteMessage(String messageId) async {
    try {
      final token = HiveUtils.getData('token');
      final response = await http.delete(
        Uri.parse('$apiUrl/thread/message/$messageId'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        return 'Message deleted successfully';
      } else {
        final error = jsonDecode(response.body);
        return error['error'] ?? 'Failed to delete message';
      }
    } catch (e) {
      debugPrint('Error deleting message: $e');
      return 'Error deleting message';
    }
  }

  static void dispose() {
    _socket?.dispose();
    _socket = null;
  }
}
