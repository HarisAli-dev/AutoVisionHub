class TransactionModel {
  final String id;
  final String fromUserId;
  final String toUserId;
  final String transactionType;
  final String relatedEntityId;
  final String relatedEntityType;
  final double amount;
  final String currency;
  final double platformFee;
  final double platformFeePercentage;
  final double netAmount;
  final String? stripePaymentIntentId;
  final String? stripeChargeId;
  final String? stripeTransferId;
  final String status;
  final String paymentStatus;
  final String payoutStatus;
  final DateTime? paymentDate;
  final DateTime? payoutDate;
  final DateTime? completedAt;
  final String? errorMessage;
  final String? failureReason;
  final double? refundAmount;
  final DateTime? refundDate;
  final String? refundReason;
  final String? description;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  // Populated fields
  final Map<String, dynamic>? fromUser;
  final Map<String, dynamic>? toUser;

  TransactionModel({
    required this.id,
    required this.fromUserId,
    required this.toUserId,
    required this.transactionType,
    required this.relatedEntityId,
    required this.relatedEntityType,
    required this.amount,
    required this.currency,
    required this.platformFee,
    required this.platformFeePercentage,
    required this.netAmount,
    this.stripePaymentIntentId,
    this.stripeChargeId,
    this.stripeTransferId,
    required this.status,
    required this.paymentStatus,
    required this.payoutStatus,
    this.paymentDate,
    this.payoutDate,
    this.completedAt,
    this.errorMessage,
    this.failureReason,
    this.refundAmount,
    this.refundDate,
    this.refundReason,
    this.description,
    this.createdAt,
    this.updatedAt,
    this.fromUser,
    this.toUser,
  });

  factory TransactionModel.fromJson(Map<String, dynamic> json) {
    return TransactionModel(
      id: json['_id'] ?? '',
      fromUserId: json['fromUserId'] is String
          ? json['fromUserId']
          : json['fromUserId']?['_id'] ?? '',
      toUserId: json['toUserId'] is String
          ? json['toUserId']
          : json['toUserId']?['_id'] ?? '',
      transactionType: json['transactionType'] ?? '',
      relatedEntityId: json['relatedEntityId'] ?? '',
      relatedEntityType: json['relatedEntityType'] ?? '',
      amount: (json['amount'] ?? 0).toDouble(),
      currency: json['currency'] ?? 'usd',
      platformFee: (json['platformFee'] ?? 0).toDouble(),
      platformFeePercentage: (json['platformFeePercentage'] ?? 0).toDouble(),
      netAmount: (json['netAmount'] ?? 0).toDouble(),
      stripePaymentIntentId: json['stripePaymentIntentId'],
      stripeChargeId: json['stripeChargeId'],
      stripeTransferId: json['stripeTransferId'],
      status: json['status'] ?? 'pending',
      paymentStatus: json['paymentStatus'] ?? 'pending',
      payoutStatus: json['payoutStatus'] ?? 'pending',
      paymentDate: json['paymentDate'] != null
          ? DateTime.parse(json['paymentDate'])
          : null,
      payoutDate: json['payoutDate'] != null
          ? DateTime.parse(json['payoutDate'])
          : null,
      completedAt: json['completedAt'] != null
          ? DateTime.parse(json['completedAt'])
          : null,
      errorMessage: json['errorMessage'],
      failureReason: json['failureReason'],
      refundAmount: json['refundAmount']?.toDouble(),
      refundDate: json['refundDate'] != null
          ? DateTime.parse(json['refundDate'])
          : null,
      refundReason: json['refundReason'],
      description: json['description'],
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : null,
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'])
          : null,
      fromUser: json['fromUserId'] is Map
          ? json['fromUserId'] as Map<String, dynamic>
          : null,
      toUser: json['toUserId'] is Map
          ? json['toUserId'] as Map<String, dynamic>
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'fromUserId': fromUserId,
      'toUserId': toUserId,
      'transactionType': transactionType,
      'relatedEntityId': relatedEntityId,
      'relatedEntityType': relatedEntityType,
      'amount': amount,
      'currency': currency,
      'platformFee': platformFee,
      'platformFeePercentage': platformFeePercentage,
      'netAmount': netAmount,
      'stripePaymentIntentId': stripePaymentIntentId,
      'stripeChargeId': stripeChargeId,
      'stripeTransferId': stripeTransferId,
      'status': status,
      'paymentStatus': paymentStatus,
      'payoutStatus': payoutStatus,
      'paymentDate': paymentDate?.toIso8601String(),
      'payoutDate': payoutDate?.toIso8601String(),
      'completedAt': completedAt?.toIso8601String(),
      'errorMessage': errorMessage,
      'failureReason': failureReason,
      'refundAmount': refundAmount,
      'refundDate': refundDate?.toIso8601String(),
      'refundReason': refundReason,
      'description': description,
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }

  String getTransactionTypeLabel() {
    switch (transactionType) {
      case 'event_booking':
        return 'Event Booking';
      case 'marketplace_purchase':
        return 'Marketplace Purchase';
      case 'marketplace_bid':
        return 'Marketplace Bid';
      default:
        return 'Other';
    }
  }

  String getStatusLabel() {
    switch (status) {
      case 'pending':
        return 'Pending';
      case 'processing':
        return 'Processing';
      case 'completed':
        return 'Completed';
      case 'failed':
        return 'Failed';
      case 'refunded':
        return 'Refunded';
      case 'cancelled':
        return 'Cancelled';
      default:
        return status;
    }
  }
}
