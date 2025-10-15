import 'package:front/model/users/user_model.dart';

class MarketplaceMessageModel {
  String? id;
  String chat;
  User? sender;
  String content;
  String messageType;
  String? imageUrl;
  OfferData? offerData;
  BidData? bidData;
  List<ReadBy> readBy;
  String? replyTo;
  bool isDeleted;
  DateTime? deletedAt;
  String? deletedBy;
  DateTime? createdAt;
  DateTime? updatedAt;

  MarketplaceMessageModel({
    this.id,
    required this.chat,
    this.sender,
    required this.content,
    this.messageType = 'text',
    this.imageUrl,
    this.offerData,
    this.bidData,
    required this.readBy,
    this.replyTo,
    this.isDeleted = false,
    this.deletedAt,
    this.deletedBy,
    this.createdAt,
    this.updatedAt,
  });

  factory MarketplaceMessageModel.fromJson(Map<String, dynamic> json) {
    return MarketplaceMessageModel(
      id: json['_id'] ?? json['id'] ?? '',
      chat: json['chat'] ?? '',
      sender: json['sender'] != null ? User.fromJson(json['sender']) : null,
      content: json['content'] ?? '',
      messageType: json['messageType'] ?? 'text',
      imageUrl: json['imageUrl'],
      offerData: json['offerData'] != null ? OfferData.fromJson(json['offerData']) : null,
      bidData: json['bidData'] != null ? BidData.fromJson(json['bidData']) : null,
      readBy: json['readBy'] != null 
        ? (json['readBy'] as List).map((r) => ReadBy.fromJson(r)).toList()
        : [],
      replyTo: json['replyTo'],
      isDeleted: json['isDeleted'] ?? false,
      deletedAt: json['deletedAt'] != null ? DateTime.parse(json['deletedAt']) : null,
      deletedBy: json['deletedBy'],
      createdAt: json['createdAt'] != null ? DateTime.parse(json['createdAt']) : null,
      updatedAt: json['updatedAt'] != null ? DateTime.parse(json['updatedAt']) : null,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'chat': chat,
    'sender': sender?.toJson(),
    'content': content,
    'messageType': messageType,
    'imageUrl': imageUrl,
    'offerData': offerData?.toJson(),
    'bidData': bidData?.toJson(),
    'readBy': readBy.map((r) => r.toJson()).toList(),
    'replyTo': replyTo,
    'isDeleted': isDeleted,
    'deletedAt': deletedAt?.toIso8601String(),
    'deletedBy': deletedBy,
    'createdAt': createdAt?.toIso8601String(),
    'updatedAt': updatedAt?.toIso8601String(),
  };

  // Helper methods
  bool isReadByUser(String userId) {
    return readBy.any((r) => r.user == userId);
  }

  String get timeAgo {
    final time = createdAt;
    if (time == null) return '';
    
    final now = DateTime.now();
    final difference = now.difference(time);
    
    if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }

  String get formattedTime {
    final time = createdAt;
    if (time == null) return '';
    
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final messageDate = DateTime(time.year, time.month, time.day);
    
    if (messageDate == today) {
      return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
    } else if (messageDate == today.subtract(const Duration(days: 1))) {
      return 'Yesterday';
    } else {
      return '${time.day}/${time.month}/${time.year}';
    }
  }
}

class OfferData {
  double amount;
  String? offerId;

  OfferData({
    required this.amount,
    this.offerId,
  });

  factory OfferData.fromJson(Map<String, dynamic> json) {
    return OfferData(
      amount: (json['amount'] as num).toDouble(),
      offerId: json['offerId'],
    );
  }

  Map<String, dynamic> toJson() => {
    'amount': amount,
    'offerId': offerId,
  };

  String get formattedAmount => 'PKR ${amount.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')}';
}

class BidData {
  double amount;
  String? bidId;

  BidData({
    required this.amount,
    this.bidId,
  });

  factory BidData.fromJson(Map<String, dynamic> json) {
    return BidData(
      amount: (json['amount'] as num).toDouble(),
      bidId: json['bidId'],
    );
  }

  Map<String, dynamic> toJson() => {
    'amount': amount,
    'bidId': bidId,
  };

  String get formattedAmount => 'PKR ${amount.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')}';
}

class ReadBy {
  String user;
  DateTime readAt;

  ReadBy({
    required this.user,
    required this.readAt,
  });

  factory ReadBy.fromJson(Map<String, dynamic> json) {
    return ReadBy(
      user: json['user'] ?? '',
      readAt: json['readAt'] != null ? DateTime.parse(json['readAt']) : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
    'user': user,
    'readAt': readAt.toIso8601String(),
  };
}
