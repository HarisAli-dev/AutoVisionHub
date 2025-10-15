import 'package:front/model/users/user_model.dart';

class BidModel {
  String? id;
  String listing;
  User? bidder;
  double amount;
  bool isWinning;
  bool isOutbid;
  String status;
  double? maxBid;
  bool isAutoBid;
  DateTime? bidTime;
  DateTime? outbidAt;
  DateTime? wonAt;
  DateTime? createdAt;
  DateTime? updatedAt;

  BidModel({
    this.id,
    required this.listing,
    this.bidder,
    required this.amount,
    this.isWinning = false,
    this.isOutbid = false,
    this.status = 'active',
    this.maxBid,
    this.isAutoBid = false,
    this.bidTime,
    this.outbidAt,
    this.wonAt,
    this.createdAt,
    this.updatedAt,
  });

  factory BidModel.fromJson(Map<String, dynamic> json) {
    return BidModel(
      id: json['_id'] ?? json['id'] ?? '',
      listing: json['listing'] ?? '',
      bidder: json['bidder'] != null ? User.fromJson(json['bidder']) : null,
      amount: (json['amount'] as num).toDouble(),
      isWinning: json['isWinning'] ?? false,
      isOutbid: json['isOutbid'] ?? false,
      status: json['status'] ?? 'active',
      maxBid: json['maxBid'] != null ? (json['maxBid'] as num).toDouble() : null,
      isAutoBid: json['isAutoBid'] ?? false,
      bidTime: json['bidTime'] != null ? DateTime.parse(json['bidTime']) : null,
      outbidAt: json['outbidAt'] != null ? DateTime.parse(json['outbidAt']) : null,
      wonAt: json['wonAt'] != null ? DateTime.parse(json['wonAt']) : null,
      createdAt: json['createdAt'] != null ? DateTime.parse(json['createdAt']) : null,
      updatedAt: json['updatedAt'] != null ? DateTime.parse(json['updatedAt']) : null,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'listing': listing,
    'bidder': bidder?.toJson(),
    'amount': amount,
    'isWinning': isWinning,
    'isOutbid': isOutbid,
    'status': status,
    'maxBid': maxBid,
    'isAutoBid': isAutoBid,
    'bidTime': bidTime?.toIso8601String(),
    'outbidAt': outbidAt?.toIso8601String(),
    'wonAt': wonAt?.toIso8601String(),
    'createdAt': createdAt?.toIso8601String(),
    'updatedAt': updatedAt?.toIso8601String(),
  };

  // Helper methods
  String get formattedAmount => 'PKR ${amount.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')}';
  
  String get timeAgo {
    final time = bidTime ?? createdAt;
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
}
