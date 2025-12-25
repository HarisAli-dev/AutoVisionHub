class ThreadMessage {
  final String id;
  final String threadId;
  final String senderId;
  final String senderName;
  final String? senderImageUrl;
  final String message;
  final bool isDeleted;
  final List<String> readBy;
  final DateTime createdAt;
  final DateTime updatedAt;

  ThreadMessage({
    required this.id,
    required this.threadId,
    required this.senderId,
    required this.senderName,
    this.senderImageUrl,
    required this.message,
    required this.isDeleted,
    required this.readBy,
    required this.createdAt,
    required this.updatedAt,
  });

  factory ThreadMessage.fromJson(Map<String, dynamic> json) {
    return ThreadMessage(
      id: json['_id'] ?? '',
      threadId: json['threadId'] ?? '',
      senderId: json['senderId']?['_id'] ?? json['senderId'] ?? '',
      senderName: json['senderName'] ?? 'Unknown',
      senderImageUrl: json['senderImageUrl'],
      message: json['message'] ?? '',
      isDeleted: json['isDeleted'] ?? false,
      readBy: List<String>.from(json['readBy'] ?? []),
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
    );
  }
}
