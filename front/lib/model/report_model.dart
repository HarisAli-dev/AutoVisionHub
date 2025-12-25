class Report {
  final String id;
  final String reportType;
  final String? reportedById;
  final String? reportedByName;
  final String? reportedByImageUrl;
  final String? reportedUserId;
  final String? reportedUserName;
  final String? reportedUserImageUrl;
  final String? reportedListItemId;
  final String? reportedListItemTitle;
  final String? reportedListItemDescription;
  final double? reportedListItemPrice;
  final List<String>? reportedListItemImages;
  final String? reportedListItemCategory;
  final String? reportedListItemBrand;
  final String? reportedListItemCondition;
  final String reason;
  final List<String> proofImages;
  final String status;
  final String? adminNotes;
  final String? reviewedById;
  final String? reviewedByName;
  final DateTime? reviewedAt;
  final String actionTaken;
  final DateTime createdAt;
  final DateTime updatedAt;

  Report({
    required this.id,
    required this.reportType,
    this.reportedById,
    this.reportedByName,
    this.reportedByImageUrl,
    this.reportedUserId,
    this.reportedUserName,
    this.reportedUserImageUrl,
    this.reportedListItemId,
    this.reportedListItemTitle,
    this.reportedListItemDescription,
    this.reportedListItemPrice,
    this.reportedListItemImages,
    this.reportedListItemCategory,
    this.reportedListItemBrand,
    this.reportedListItemCondition,
    required this.reason,
    required this.proofImages,
    required this.status,
    this.adminNotes,
    this.reviewedById,
    this.reviewedByName,
    this.reviewedAt,
    required this.actionTaken,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Report.fromJson(Map<String, dynamic> json) {
    return Report(
      id: json['_id'] ?? '',
      reportType: json['reportType'] ?? '',
      reportedById: json['reportedBy'] != null 
          ? (json['reportedBy'] is String ? json['reportedBy'] : json['reportedBy']['_id'])
          : null,
      reportedByName: json['reportedBy'] is Map ? json['reportedBy']['name'] : null,
      reportedByImageUrl: json['reportedBy'] is Map ? json['reportedBy']['profileImageUrl'] : null,
      reportedUserId: json['reportedUser'] is String 
          ? json['reportedUser'] 
          : json['reportedUser']?['_id'],
      reportedUserName: json['reportedUser'] is Map ? json['reportedUser']['name'] : null,
      reportedUserImageUrl: json['reportedUser'] is Map ? json['reportedUser']['profileImageUrl'] : null,
      reportedListItemId: json['reportedListItem']?['_id'],
      reportedListItemTitle: json['reportedListItem']?['title'],
      reportedListItemDescription: json['reportedListItem']?['description'],
      reportedListItemPrice: json['reportedListItem']?['price']?.toDouble(),
      reportedListItemImages: json['reportedListItem']?['images'] != null
          ? List<String>.from(json['reportedListItem']['images'])
          : null,
      reportedListItemCategory: json['reportedListItem']?['category'],
      reportedListItemBrand: json['reportedListItem']?['brand'],
      reportedListItemCondition: json['reportedListItem']?['condition'],
      reason: json['reason'] ?? '',
      proofImages: json['proofImages'] != null 
          ? List<String>.from(json['proofImages'])
          : [],
      status: json['status'] ?? 'pending',
      adminNotes: json['adminNotes'],
      reviewedById: json['reviewedBy']?['_id'],
      reviewedByName: json['reviewedBy']?['name'],
      reviewedAt: json['reviewedAt'] != null
          ? DateTime.parse(json['reviewedAt'])
          : null,
      actionTaken: json['actionTaken'] ?? 'none',
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
    );
  }
}
