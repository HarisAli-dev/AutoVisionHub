import 'package:front/model/users/user_model.dart';


class OfferModel {
  String? id;
  String listing;
  User? buyer;
  User? seller;
  double amount;
  String? message;
  String status;
  CounterOffer? counterOffer;
  String? responseMessage;
  String? respondedBy;
  DateTime? respondedAt;
  DateTime? expiresAt;
  DateTime? offerTime;
  DateTime? createdAt;
  DateTime? updatedAt;

  OfferModel({
    this.id,
    required this.listing,
    this.buyer,
    this.seller,
    required this.amount,
    this.message,
    this.status = 'pending',
    this.counterOffer,
    this.responseMessage,
    this.respondedBy,
    this.respondedAt,
    this.expiresAt,
    this.offerTime,
    this.createdAt,
    this.updatedAt,
  });

  factory OfferModel.fromJson(Map<String, dynamic> json) {
    return OfferModel(
      id: json['_id'] ?? json['id'] ?? '',
      listing: json['listing'] ?? '',
      buyer: json['buyer'] != null ? User.fromJson(json['buyer']) : null,
      seller: json['seller'] != null ? User.fromJson(json['seller']) : null,
      amount: (json['amount'] as num).toDouble(),
      message: json['message'],
      status: json['status'] ?? 'pending',
      counterOffer: json['counterOffer'] != null ? CounterOffer.fromJson(json['counterOffer']) : null,
      responseMessage: json['responseMessage'],
      respondedBy: json['respondedBy'],
      respondedAt: json['respondedAt'] != null ? DateTime.parse(json['respondedAt']) : null,
      expiresAt: json['expiresAt'] != null ? DateTime.parse(json['expiresAt']) : null,
      offerTime: json['offerTime'] != null ? DateTime.parse(json['offerTime']) : null,
      createdAt: json['createdAt'] != null ? DateTime.parse(json['createdAt']) : null,
      updatedAt: json['updatedAt'] != null ? DateTime.parse(json['updatedAt']) : null,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'listing': listing,
    'buyer': buyer?.toJson(),
    'seller': seller?.toJson(),
    'amount': amount,
    'message': message,
    'status': status,
    'counterOffer': counterOffer?.toJson(),
    'responseMessage': responseMessage,
    'respondedBy': respondedBy,
    'respondedAt': respondedAt?.toIso8601String(),
    'expiresAt': expiresAt?.toIso8601String(),
    'offerTime': offerTime?.toIso8601String(),
    'createdAt': createdAt?.toIso8601String(),
    'updatedAt': updatedAt?.toIso8601String(),
  };

  // Helper methods
  String get formattedAmount => 'PKR ${amount.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')}';
  
  String get timeAgo {
    final time = offerTime ?? createdAt;
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

  bool get isExpired => expiresAt != null && DateTime.now().isAfter(expiresAt!);
  
  bool get isPending => status == 'pending';
  bool get isAccepted => status == 'accepted';
  bool get isRejected => status == 'rejected';
  bool get isCountered => status == 'countered';
  bool get isCancelled => status == 'cancelled';
}

class CounterOffer {
  double amount;
  String? message;
  String? counterOfferBy;
  DateTime? counterOfferAt;

  CounterOffer({
    required this.amount,
    this.message,
    this.counterOfferBy,
    this.counterOfferAt,
  });

  factory CounterOffer.fromJson(Map<String, dynamic> json) {
    return CounterOffer(
      amount: (json['amount'] as num).toDouble(),
      message: json['message'],
      counterOfferBy: json['counterOfferBy'],
      counterOfferAt: json['counterOfferAt'] != null ? DateTime.parse(json['counterOfferAt']) : null,
    );
  }

  Map<String, dynamic> toJson() => {
    'amount': amount,
    'message': message,
    'counterOfferBy': counterOfferBy,
    'counterOfferAt': counterOfferAt?.toIso8601String(),
  };

  String get formattedAmount => 'PKR ${amount.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')}';
}
