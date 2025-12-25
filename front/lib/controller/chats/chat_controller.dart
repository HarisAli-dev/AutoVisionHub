import 'dart:convert';
import 'package:front/main.dart';
import 'package:front/model/chats/chat_model.dart';
import 'package:front/model/chats/message_model.dart';
import 'package:front/services/socket_service.dart';
import 'package:front/utils/hive_utils.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class ChatController {
  // Fetch all chats for the current user
  static Future<List<ChatModel>> fetchChats() async {
    try {
      final token = HiveUtils.getData('token');
      if (token == null) {
        throw Exception('Authentication token not found');
      }

      final response = await http.get(
        Uri.parse('$apiUrl/chat/getChats'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final dynamic decodedResponse = json.decode(response.body);

        // Handle both possible formats: direct list or map with 'chats' key
        List<dynamic> data;
        if (decodedResponse is List) {
          // API is returning a direct list of chats
          data = decodedResponse;
        } else if (decodedResponse is Map<String, dynamic>) {
          // API is returning a map with a 'chats' key
          data = decodedResponse['chats'] ?? [];
        } else {
          throw Exception('Unexpected response format');
        }

        return data.map((chat) => ChatModel.fromJson(chat)).toList();
      } else {
        throw Exception('Failed to load chats: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Error fetching chats: $e');
      throw Exception('Failed to load chats: $e');
    }
  }

  //create chat with user
  static Future<ChatModel> createChatWithUser(String userId) async {
    try {
      final token = HiveUtils.getData('token');
      final response = await http.post(
        Uri.parse('$apiUrl/chat/createChat'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode({'userId': userId}),
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        final dynamic decodedResponse = json.decode(response.body);
        return ChatModel.fromJson(decodedResponse);
      } else {
        throw Exception('Failed to create chat: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Error creating chat: $e');
      throw Exception('Failed to create chat: $e');
    }
  }

  // Get or create a chat with a specific user
  static Future<ChatModel> getChatWithUser(String chatId) async {
    try {
      final token = HiveUtils.getData('token');
      if (token == null) {
        throw Exception('Authentication token not found');
      }
      final response = await http.get(
        Uri.parse('$apiUrl/chat/$chatId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );
      if (response.statusCode == 200) {
        final dynamic decodedResponse = json.decode(response.body);

        // Check if the response has both chat and messages
        if (decodedResponse is Map<String, dynamic> &&
            decodedResponse.containsKey('chat') &&
            decodedResponse.containsKey('messages')) {
          // Extract chat and messages
          final chatData = decodedResponse['chat'];
          final messagesList = decodedResponse['messages'] as List<dynamic>;

          // Parse messages
          final messages = messagesList
              .map((msgJson) => Message.fromJson(msgJson))
              .toList();

          // Create ChatModel with both chat data and messages
          final chatModel = ChatModel.fromJson(chatData);

          // Return a new ChatModel with all properties including messages
          return ChatModel(
            id: chatModel.id,
            participants: chatModel.participants,
            lastMessage: chatModel.lastMessage,
            unreadCounts: chatModel.unreadCounts,
            createdById: chatModel.createdById,
            createdAt: chatModel.createdAt,
            updatedAt: chatModel.updatedAt,
            messages: messages,
          );
        } else {
          // Fall back to original format if structure is different
          return ChatModel.fromJson(decodedResponse['chat'] ?? decodedResponse);
        }
      } else {
        throw Exception('Failed to get/create chat: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Error getting/creating chat: $e');
      throw Exception('Failed to get/create chat: $e');
    }
  }

  // Delete a chat
  static Future<void> deleteChat(String chatId) async {
    try {
      final token = HiveUtils.getData('token');
      if (token == null) {
        throw Exception('Authentication token not found');
      }

      final response = await http.delete(
        Uri.parse('$apiUrl/chat/$chatId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode({'chatId': chatId}),
      );
      print('Delete chat response: ${response.body}');
      if (response.statusCode != 200) {
        throw Exception('Failed to delete chat: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Error deleting chat: $e');
      throw Exception('Failed to delete chat: $e');
    }
  }

  // Mark chat as read
  static Future<void> markChatAsRead(String chatId) async {
    try {
      final token = HiveUtils.getData('token');
      if (token == null) {
        throw Exception('Authentication token not found');
      }

      final response = await http.patch(
        Uri.parse('$apiUrl/chat/$chatId/read'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to mark chat as read: ${response.statusCode}');
      }

      // Also notify via socket for real-time updates
      final socketService = SocketService();
      if (socketService.isConnected) {
        // The socket will handle marking each message as seen
        final userId = HiveUtils.getData('userId');
        if (userId != null) {
          socketService.socket.emit('mark_chat_read', {
            'chatId': chatId,
            'userId': userId,
          });
        }
      }
    } catch (e) {
      debugPrint('Error marking chat as read: $e');
      throw Exception('Failed to mark chat as read: $e');
    }
  }
}
