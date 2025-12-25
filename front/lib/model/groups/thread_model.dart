class Thread {
  final String id;
  final String topicName;
  final String? description;
  final String? imageUrl;
  final String? imagePublicId;
  final String createdBy;
  final String creatorName;
  final String? creatorImageUrl;
  final List<String> participants;
  final String? lastMessageId;
  final int messageCount;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  Thread({
    required this.id,
    required this.topicName,
    this.description,
    this.imageUrl,
    this.imagePublicId,
    required this.createdBy,
    required this.creatorName,
    this.creatorImageUrl,
    required this.participants,
    this.lastMessageId,
    required this.messageCount,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Thread.fromJson(Map<String, dynamic> json) {
    return Thread(
      id: json['_id'] ?? '',
      topicName: json['topicName'] ?? 'Untitled Thread',
      description: json['description'],
      imageUrl: json['imageUrl'],
      imagePublicId: json['imagePublicId'],
      createdBy: json['createdBy']['_id'] ?? json['createdBy'],
      creatorName: json['createdBy']['name'] ?? 'Unknown',
      creatorImageUrl: json['createdBy']['profileImageUrl'],
      participants: List<String>.from(
        json['participants']?.map((p) => p is String ? p : p['_id']) ?? [],
      ),
      lastMessageId: json['lastMessage']?['_id'],
      messageCount: json['messageCount'] ?? 0,
      isActive: json['isActive'] ?? true,
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
    );
  }
}
