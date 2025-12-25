import 'dart:convert';
import 'package:front/main.dart';
import 'package:front/model/groups/group_model.dart';
import 'package:front/model/users/user_model.dart';
import 'package:front/services/socket_service.dart';
import 'package:front/utils/hive_utils.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class GroupController {
  // ==================== GROUP MANAGEMENT ====================
  // Note: Message-related functionalities (including polls) are in GroupMessageController

  /// Fetch all groups for the current user
  static Future<List<Group>> fetchUserGroups() async {
    try {
      final token = HiveUtils.getData('token');
      print(token);
      if (token == null) {
        throw Exception('Authentication token not found');
      }

      final response = await http.get(
        Uri.parse('$apiUrl/group/getGroups'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final dynamic decodedResponse = json.decode(response.body);

        // Handle both possible formats: direct list or map with 'groups' key
        List<dynamic> data;
        if (decodedResponse is List) {
          data = decodedResponse;
        } else if (decodedResponse is Map<String, dynamic>) {
          data = decodedResponse['groups'] ?? [];
        } else {
          throw Exception('Unexpected response format');
        }
        debugPrint('Fetched groups: $data');
        if (data.isNotEmpty) {
          debugPrint('Fetched groups count: ${data.length}, first group: ${data[0]}');
        } else {
          debugPrint('No groups found');
        }

        return data.map((group) => Group.fromJson(group)).toList();
      } else {
        throw Exception('Failed to load groups: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Error fetching groups: $e');
      throw Exception('Failed to load groups: $e');
    }
  }

  /// Fetch all groups
  static Future<List<Group>> fetchGroups() async {
    try {
      final token = HiveUtils.getData('token');
      if (token == null) {
        throw Exception('Authentication token not found');
      }

      final response = await http.get(
        Uri.parse('$apiUrl/group/getAllGroups'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        debugPrint('Response body: ${response.body}');
        final List<dynamic> jsonData = json.decode(response.body)['groups'];
        return jsonData.map((group) => Group.fromJson(group)).toList();
      } else {
        throw Exception('Failed to load groups: ${response.statusCode}');
      }
    } catch (e, stackTrace) {
      debugPrint('Error fetching groups: $e');
      debugPrint('Stack trace: $stackTrace');
      throw Exception('Failed to load groups: $e');
    }
  }

  /// Create a new group
  static Future<bool> createGroup({
    required String groupName,
    required List<String> participantIds,
    String? description,
    String? groupImageUrl,
  }) async {
    try {
      final token = HiveUtils.getData('token');
      if (token == null) {
        throw Exception('Authentication token not found');
      }

      final response = await http.post(
        Uri.parse('$apiUrl/group/createGroup'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode({
          'groupName': groupName,
          'participants': participantIds,
          'description': description,
          'groupImageUrl': groupImageUrl,
        }),
      );

      if (response.statusCode == 200) {
        return true;
      } else {
        throw Exception('Failed to create group: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Error creating group: $e');
      throw Exception('Failed to create group: $e');
    }
  }

  /// Update group details
  static Future<bool> updateGroup({
    required String groupId,
    String? groupName,
    String? description,
    String? groupImageUrl,
  }) async {
    try {
      final token = HiveUtils.getData('token');
      if (token == null) {
        throw Exception('Authentication token not found');
      }

      debugPrint('Updating group with image URL: $groupImageUrl');

      final response = await http.patch(
        Uri.parse('$apiUrl/group/$groupId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode({
          'groupName': groupName,
          'description': description,
          'groupImageUrl': groupImageUrl,
        }),
      );

      debugPrint('Update group response: ${response.body}');

      if (response.statusCode == 200) {
        return true;
      } else {
        throw Exception('Failed to update group: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Error updating group: $e');
      throw Exception('Failed to update group: $e');
    }
  }

  /// Delete a group
  static Future<bool> deleteGroup(String groupId) async {
    try {
      final token = HiveUtils.getData('token');
      if (token == null) {
        throw Exception('Authentication token not found');
      }

      final response = await http.delete(
        Uri.parse('$apiUrl/group/$groupId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        return true;
      } else {
        throw Exception('Failed to delete group: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Error deleting group: $e');
      throw Exception('Failed to delete group: $e');
    }
  }

  /// Leave a group
  static Future<bool> leaveGroup(String groupId) async {
    try {
      final token = HiveUtils.getData('token');
      if (token == null) {
        throw Exception('Authentication token not found');
      }

      final response = await http.post(
        Uri.parse('$apiUrl/group/$groupId/leave'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        return true;
      } else {
        throw Exception('Failed to leave group: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Error leaving group: $e');
      throw Exception('Failed to leave group: $e');
    }
  }

  // ==================== PARTICIPANT MANAGEMENT ====================

  /// Add participants to group
  static Future<bool> addParticipants({
    required String groupId,
    required List<String> participantIds,
  }) async {
    try {
      final token = HiveUtils.getData('token');
      if (token == null) {
        throw Exception('Authentication token not found');
      }

      final response = await http.post(
        Uri.parse('$apiUrl/group/$groupId/addParticipants'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode({'participants': participantIds}),
      );

      if (response.statusCode == 200) {
        return true;
      } else {
        throw Exception('Failed to add participants: ${response.statusCode}');
      }
    } catch (e, stackTrace) {
      debugPrint('Error adding participants: $e');
      debugPrint('Stack trace: $stackTrace');
      throw Exception('Failed to add participants: $e');
    }
  }

  /// Remove participant from group
  static Future<bool> removeParticipant({
    required String groupId,
    required String participantId,
  }) async {
    try {
      final token = HiveUtils.getData('token');
      if (token == null) {
        throw Exception('Authentication token not found');
      }

      final response = await http.post(
        Uri.parse('$apiUrl/group/$groupId/removeParticipant'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode({'participantId': participantId}),
      );

      if (response.statusCode == 200) {
        return true;
      } else {
        throw Exception('Failed to remove participant: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Error removing participant: $e');
      throw Exception('Failed to remove participant: $e');
    }
  }

  /// Make participant admin
  static Future<bool> makeAdmin({
    required String groupId,
    required String participantId,
  }) async {
    try {
      final token = HiveUtils.getData('token');
      if (token == null) {
        throw Exception('Authentication token not found');
      }

      final response = await http.post(
        Uri.parse('$apiUrl/group/$groupId/makeAdmin'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode({'participantId': participantId}),
      );

      if (response.statusCode == 200) {
        return true;
      } else {
        throw Exception('Failed to make admin: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Error making admin: $e');
      throw Exception('Failed to make admin: $e');
    }
  }

  /// Remove admin privileges
  static Future<bool> removeAdmin({
    required String groupId,
    required String participantId,
  }) async {
    try {
      final token = HiveUtils.getData('token');
      if (token == null) {
        throw Exception('Authentication token not found');
      }

      final response = await http.post(
        Uri.parse('$apiUrl/group/$groupId/removeAdmin'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode({'participantId': participantId}),
      );

      if (response.statusCode == 200) {
        return true;
      } else {
        throw Exception('Failed to remove admin: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Error removing admin: $e');
      throw Exception('Failed to remove admin: $e');
    }
  }

  // ==================== SEARCH AND UTILITY ====================

  /// Search groups
  static Future<List<Group>> searchGroups(String query) async {
    try {
      final token = HiveUtils.getData('token');
      if (token == null) {
        throw Exception('Authentication token not found');
      }

      final response = await http.get(
        Uri.parse('$apiUrl/group/search?q=${Uri.encodeComponent(query)}'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final dynamic decodedResponse = json.decode(response.body);

        List<dynamic> data;
        if (decodedResponse is List) {
          data = decodedResponse;
        } else if (decodedResponse is Map<String, dynamic>) {
          data = decodedResponse['groups'] ?? [];
        } else {
          throw Exception('Unexpected response format');
        }

        return data.map((group) => Group.fromJson(group)).toList();
      } else {
        throw Exception('Failed to search groups: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Error searching groups: $e');
      throw Exception('Failed to search groups: $e');
    }
  }

  /// Get group participants
  static Future<List<User>> getGroupParticipants(String groupId) async {
    try {
      final token = HiveUtils.getData('token');
      if (token == null) {
        throw Exception('Authentication token not found');
      }

      final response = await http.get(
        Uri.parse('$apiUrl/group/$groupId/participants'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final dynamic decodedResponse = json.decode(response.body);

        List<dynamic> data;
        if (decodedResponse is List) {
          data = decodedResponse;
        } else if (decodedResponse is Map<String, dynamic>) {
          data = decodedResponse['participants'] ?? [];
        } else {
          throw Exception('Unexpected response format');
        }

        return data.map((user) => User.fromJson(user)).toList();
      } else {
        throw Exception(
          'Failed to get group participants: ${response.statusCode}',
        );
      }
    } catch (e) {
      debugPrint('Error getting group participants: $e');
      throw Exception('Failed to get group participants: $e');
    }
  }

  // ==================== SOCKET HELPERS ====================

  /// Join group room for real-time updates
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

  /// Get available users for group creation
  static Future<List<User>> getAvailableUsers() async {
    try {
      final token = HiveUtils.getData('token');
      if (token == null) {
        throw Exception('Authentication token not found');
      }

      final response = await http.get(
        Uri.parse(
          '$apiUrl/users/all',
        ), // Assuming there's an endpoint to get all users
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final dynamic decodedResponse = json.decode(response.body);

        List<dynamic> data;
        if (decodedResponse is List) {
          data = decodedResponse;
        } else if (decodedResponse is Map<String, dynamic>) {
          data = decodedResponse['users'] ?? [];
        } else {
          throw Exception('Unexpected response format');
        }

        return data.map((user) => User.fromJson(user)).toList();
      } else {
        throw Exception('Failed to get users: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Error getting users: $e');
      throw Exception('Failed to get users: $e');
    }
  }
}
