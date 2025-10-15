import 'package:front/model/users/user_model.dart';


class MarketplaceChatModel {
  String? id;
  String listing;
  List<User> participants;
  LastMessage? lastMessage;
  bool isActive;
  List<UnreadCount> unreadCounts;
  String? relatedOffer;
  String? relatedBid;
  DateTime? createdAt;
  DateTime? updatedAt;

  MarketplaceChatModel({
    this.id,
    required this.listing,
    required this.participants,
    this.lastMessage,
    this.isActive = true,
    required this.unreadCounts,
    this.relatedOffer,
    this.relatedBid,
    this.createdAt,
    this.updatedAt,
  });

  factory MarketplaceChatModel.fromJson(Map<String, dynamic> json) {
    return MarketplaceChatModel(
      id: json['_id'] ?? json['id'] ?? '',
      listing: json['listing'] ?? '',
      participants: json['participants'] != null 
        ? (json['participants'] as List).map((p) => User.fromJson(p)).toList()
        : [],
      lastMessage: json['lastMessage'] != null ? LastMessage.fromJson(json['lastMessage']) : null,
      isActive: json['isActive'] ?? true,
      unreadCounts: json['unreadCounts'] != null 
        ? (json['unreadCounts'] as List).map((u) => UnreadCount.fromJson(u)).toList()
        : [],
      relatedOffer: json['relatedOffer'],
      relatedBid: json['relatedBid'],
      createdAt: json['createdAt'] != null ? DateTime.parse(json['createdAt']) : null,
      updatedAt: json['updatedAt'] != null ? DateTime.parse(json['updatedAt']) : null,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'listing': listing,
    'participants': participants.map((p) => p.toJson()).toList(),
    'lastMessage': lastMessage?.toJson(),
    'isActive': isActive,
    'unreadCounts': unreadCounts.map((u) => u.toJson()).toList(),
    'relatedOffer': relatedOffer,
    'relatedBid': relatedBid,
    'createdAt': createdAt?.toIso8601String(),
    'updatedAt': updatedAt?.toIso8601String(),
  };

  // Helper methods
  int getUnreadCountForUser(String userId) {
    final unread = unreadCounts.firstWhere(
      (u) => u.user == userId,
      orElse: () => UnreadCount(user: userId, count: 0),
    );
    return unread.count;
  }

  User? getOtherParticipant(String currentUserId) {
    return participants.firstWhere(
      (p) => p.id != currentUserId,
      orElse: () => participants.first,
    );
  }
}

class LastMessage {
  String content;
  String? sender;
  DateTime? timestamp;
  String messageType;

  LastMessage({
    required this.content,
    this.sender,
    this.timestamp,
    this.messageType = 'text',
  });

  factory LastMessage.fromJson(Map<String, dynamic> json) {
    return LastMessage(
      content: json['content'] ?? '',
      sender: json['sender'],
      timestamp: json['timestamp'] != null ? DateTime.parse(json['timestamp']) : null,
      messageType: json['messageType'] ?? 'text',
    );
  }

  Map<String, dynamic> toJson() => {
    'content': content,
    'sender': sender,
    'timestamp': timestamp?.toIso8601String(),
    'messageType': messageType,
  };
}

class UnreadCount {
  String user;
  int count;

  UnreadCount({
    required this.user,
    required this.count,
  });

  factory UnreadCount.fromJson(Map<String, dynamic> json) {
    return UnreadCount(
      user: json['user'] ?? '',
      count: json['count'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
    'user': user,
    'count': count,
  };
}
