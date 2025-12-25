class PaymentProfileModel {
  final String id;
  final String userId;
  final String stripeAccountId;
  final String accountStatus;
  final AccountDetails accountDetails;
  final List<PayoutMethod> payoutMethods;
  final PaymentStatistics statistics;
  final Verification verification;
  final PaymentSettings settings;
  final bool isActive;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  PaymentProfileModel({
    required this.id,
    required this.userId,
    required this.stripeAccountId,
    required this.accountStatus,
    required this.accountDetails,
    required this.payoutMethods,
    required this.statistics,
    required this.verification,
    required this.settings,
    required this.isActive,
    this.createdAt,
    this.updatedAt,
  });

  factory PaymentProfileModel.fromJson(Map<String, dynamic> json) {
    return PaymentProfileModel(
      id: json['_id'] ?? '',
      userId: json['userId'] ?? '',
      stripeAccountId: json['stripeAccountId'] ?? '',
      accountStatus: json['accountStatus'] ?? 'pending',
      accountDetails: AccountDetails.fromJson(json['accountDetails'] ?? {}),
      payoutMethods:
          (json['payoutMethods'] as List?)
              ?.map((method) => PayoutMethod.fromJson(method))
              .toList() ??
          [],
      statistics: PaymentStatistics.fromJson(json['statistics'] ?? {}),
      verification: Verification.fromJson(json['verification'] ?? {}),
      settings: PaymentSettings.fromJson(json['settings'] ?? {}),
      isActive: json['isActive'] ?? true,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : null,
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'userId': userId,
      'stripeAccountId': stripeAccountId,
      'accountStatus': accountStatus,
      'accountDetails': accountDetails.toJson(),
      'payoutMethods': payoutMethods.map((m) => m.toJson()).toList(),
      'statistics': statistics.toJson(),
      'verification': verification.toJson(),
      'settings': settings.toJson(),
      'isActive': isActive,
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }
}

class AccountDetails {
  final String country;
  final String currency;
  final String accountHolderName;
  final String accountHolderType;

  AccountDetails({
    required this.country,
    required this.currency,
    required this.accountHolderName,
    required this.accountHolderType,
  });

  factory AccountDetails.fromJson(Map<String, dynamic> json) {
    return AccountDetails(
      country: json['country'] ?? 'US',
      currency: json['currency'] ?? 'usd',
      accountHolderName: json['accountHolderName'] ?? '',
      accountHolderType: json['accountHolderType'] ?? 'individual',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'country': country,
      'currency': currency,
      'accountHolderName': accountHolderName,
      'accountHolderType': accountHolderType,
    };
  }
}

class PayoutMethod {
  final String type;
  final String? last4;
  final String? bankName;
  final bool isDefault;
  final String? stripeBankAccountId;
  final DateTime? addedAt;

  PayoutMethod({
    required this.type,
    this.last4,
    this.bankName,
    required this.isDefault,
    this.stripeBankAccountId,
    this.addedAt,
  });

  factory PayoutMethod.fromJson(Map<String, dynamic> json) {
    return PayoutMethod(
      type: json['type'] ?? 'bank_account',
      last4: json['last4'],
      bankName: json['bankName'],
      isDefault: json['isDefault'] ?? false,
      stripeBankAccountId: json['stripeBankAccountId'],
      addedAt: json['addedAt'] != null ? DateTime.parse(json['addedAt']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'type': type,
      'last4': last4,
      'bankName': bankName,
      'isDefault': isDefault,
      'stripeBankAccountId': stripeBankAccountId,
      'addedAt': addedAt?.toIso8601String(),
    };
  }
}

class PaymentStatistics {
  final double totalEarnings;
  final double totalPayouts;
  final double pendingBalance;
  final DateTime? lastPayoutDate;
  final int transactionCount;

  PaymentStatistics({
    required this.totalEarnings,
    required this.totalPayouts,
    required this.pendingBalance,
    this.lastPayoutDate,
    required this.transactionCount,
  });

  factory PaymentStatistics.fromJson(Map<String, dynamic> json) {
    return PaymentStatistics(
      totalEarnings: (json['totalEarnings'] ?? 0).toDouble(),
      totalPayouts: (json['totalPayouts'] ?? 0).toDouble(),
      pendingBalance: (json['pendingBalance'] ?? 0).toDouble(),
      lastPayoutDate: json['lastPayoutDate'] != null
          ? DateTime.parse(json['lastPayoutDate'])
          : null,
      transactionCount: json['transactionCount'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'totalEarnings': totalEarnings,
      'totalPayouts': totalPayouts,
      'pendingBalance': pendingBalance,
      'lastPayoutDate': lastPayoutDate?.toIso8601String(),
      'transactionCount': transactionCount,
    };
  }
}

class Verification {
  final bool isVerified;
  final bool documentsSubmitted;
  final DateTime? verifiedAt;
  final bool requiresAdditionalInfo;

  Verification({
    required this.isVerified,
    required this.documentsSubmitted,
    this.verifiedAt,
    required this.requiresAdditionalInfo,
  });

  factory Verification.fromJson(Map<String, dynamic> json) {
    return Verification(
      isVerified: json['isVerified'] ?? false,
      documentsSubmitted: json['documentsSubmitted'] ?? false,
      verifiedAt: json['verifiedAt'] != null
          ? DateTime.parse(json['verifiedAt'])
          : null,
      requiresAdditionalInfo: json['requiresAdditionalInfo'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'isVerified': isVerified,
      'documentsSubmitted': documentsSubmitted,
      'verifiedAt': verifiedAt?.toIso8601String(),
      'requiresAdditionalInfo': requiresAdditionalInfo,
    };
  }
}

class PaymentSettings {
  final bool autoPayoutEnabled;
  final int minimumPayoutAmount;
  final String payoutSchedule;

  PaymentSettings({
    required this.autoPayoutEnabled,
    required this.minimumPayoutAmount,
    required this.payoutSchedule,
  });

  factory PaymentSettings.fromJson(Map<String, dynamic> json) {
    return PaymentSettings(
      autoPayoutEnabled: json['autoPayoutEnabled'] ?? true,
      minimumPayoutAmount: json['minimumPayoutAmount'] ?? 1000,
      payoutSchedule: json['payoutSchedule'] ?? 'weekly',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'autoPayoutEnabled': autoPayoutEnabled,
      'minimumPayoutAmount': minimumPayoutAmount,
      'payoutSchedule': payoutSchedule,
    };
  }
}
