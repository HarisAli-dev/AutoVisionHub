import 'package:front/model/chats/message_model.dart';
import 'package:front/model/users/user_model.dart';

class ChatModel {
  final String id;
  final List<User> participants;
  final Message? lastMessage;
  final Map<String, int> unreadCounts;
  final String? createdById;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final List<Message>? messages;

  ChatModel.empty({
    this.id = '',
    this.participants = const [],
    this.lastMessage,
    this.unreadCounts = const {},
    this.createdById,
    this.createdAt,
    this.updatedAt,
    this.messages,
  });

  ChatModel({
    required this.id,
    required this.participants,
    this.lastMessage,
    required this.unreadCounts,
    this.createdById,
    this.createdAt,
    this.updatedAt,
    this.messages,
  });

  factory ChatModel.fromJson(Map<String, dynamic> json) {
    // Parse participants
    List<User> participants = [];
    if (json['participants'] != null) {
      participants = (json['participants'] as List)
          .map((user) => User.fromJson(user))
          .toList();
    }
    
    // Parse last message if available
    Message? lastMessage;
    if (json['lastMessage'] != null) {
      lastMessage = Message.fromJson(json['lastMessage']);
    }
    
    // Parse unread counts
    Map<String, int> unreadCounts = {};
    if (json['unreadCounts'] != null) {
      json['unreadCounts'].forEach((key, value) {
        unreadCounts[key] = value as int;
      });
    }
    // Parse messages if they are included in the response
    List<Message>? messages;
    if (json['messages'] != null && json['messages'] is List) {
      messages = (json['messages'] as List)
          .map((msgJson) => Message.fromJson(msgJson))
          .toList();
      print('Parsed ${messages.length} messages from chat response');
    }
    
    return ChatModel(
      id: json['_id'] ?? json['id'] ?? '',
      participants: participants,
      lastMessage: lastMessage,
      unreadCounts: unreadCounts,
      createdById: json['createdBy'],
      createdAt: json['createdAt'] != null 
          ? DateTime.parse(json['createdAt']) 
          : null,
      updatedAt: json['updatedAt'] != null 
          ? DateTime.parse(json['updatedAt']) 
          : null,
      messages: messages,
    );
  }
  
  // Helper method to get the chat name (other user's name)
  String getChatName(String currentUserId) {
    // For direct chats, use the other person's name
    final otherUser = participants.firstWhere(
      (user) => user.id != currentUserId,
      orElse: () => participants.isNotEmpty ? participants.first : User.empty(),
    );
    return otherUser.name;
  }
  
  // Helper method to get the chat avatar (to be implemented later when user model has avatar)
  String? getChatAvatar(String currentUserId) {
    // Will be implemented when user model has avatar field
    return null;
  }
  
  // Get unread count for current user
  int getUnreadCount(String userId) {
    return unreadCounts[userId] ?? 0;
  }
}
