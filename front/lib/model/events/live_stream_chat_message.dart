/// Model for live stream chat messages
class LiveStreamChatMessage {
  final String id;
  final String senderId;
  final String senderName;
  final String message;
  final DateTime timestamp;
  final bool isBot;
  final bool isMention; // If message mentions the bot

  LiveStreamChatMessage({
    required this.id,
    required this.senderId,
    required this.senderName,
    required this.message,
    required this.timestamp,
    this.isBot = false,
    this.isMention = false,
  });

  factory LiveStreamChatMessage.fromJson(Map<String, dynamic> json) {
    return LiveStreamChatMessage(
      id: json['_id'] ?? json['id'] ?? '',
      senderId: json['senderId'] ?? '',
      senderName: json['senderName'] ?? 'Anonymous',
      message: json['message'] ?? '',
      timestamp: json['timestamp'] != null
          ? DateTime.parse(json['timestamp'])
          : DateTime.now(),
      isBot: json['isBot'] ?? false,
      isMention: json['isMention'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'senderId': senderId,
      'senderName': senderName,
      'message': message,
      'timestamp': timestamp.toIso8601String(),
      'isBot': isBot,
      'isMention': isMention,
    };
  }

  /// Create a bot message
  factory LiveStreamChatMessage.bot({
    required String message,
    String? replyToMessageId,
  }) {
    return LiveStreamChatMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      senderId: 'bot',
      senderName: 'Community Hub Bot',
      message: message,
      timestamp: DateTime.now(),
      isBot: true,
    );
  }
}
