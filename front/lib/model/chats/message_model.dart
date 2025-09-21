
enum MessageType { text, image, video, voice, file, call }

MessageType _msgTypeFromString(String v) {
  switch (v) {
    case 'text':
      return MessageType.text;
    case 'image':
      return MessageType.image;
    case 'video':
      return MessageType.video;
    case 'voice':
      return MessageType.voice;
    case 'file':
      return MessageType.file;
    case 'call':
      return MessageType.call;
    default:
      throw Exception('Unknown message type: $v');
  }
}

String _msgTypeToString(MessageType t) {
  switch (t) {
    case MessageType.text:
      return 'text';
    case MessageType.image:
      return 'image';
    case MessageType.video:
      return 'video';
    case MessageType.voice:
      return 'voice';
    case MessageType.file:
      return 'file';
    case MessageType.call:
      return 'call';
  }
}

class Message {
  final String id;
  final String chatId;
  final String senderId;
  final String senderName;

  final MessageType type;

  /// text or caption
  final String? content;

  /// image/file/voice url (Cloudinary)
  final String? mediaUrl;

  /// preview (optional)
  final String? thumbnailUrl;

  /// seconds (voice/call)
  final int? duration;

  /// for calls: missed | outgoing | incoming
  final String? callType;

  /// sent | delivered | seen
  final String status;

  /// soft-delete flags
  final bool isDeleted;
  final List<String> deletedFor;

  final DateTime createdAt;
  final DateTime updatedAt;

  Message({
    required this.id,
    required this.chatId,
    required this.senderId,
    required this.senderName,
    required this.type,
    this.content,
    this.mediaUrl,
    this.thumbnailUrl,
    this.duration,
    this.callType,
    required this.status,
    required this.isDeleted,
    required this.deletedFor,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Message.fromJson(Map<String, dynamic> json) {
    return Message(
      id: json['_id'],
      chatId: json['chatId'],
      senderId: json['senderId'],
      senderName: json['senderName'] ?? '',
      type: _msgTypeFromString(json['type']),
      content: json['content'],
      mediaUrl: json['mediaUrl'],
      thumbnailUrl: json['thumbnailUrl'],
      duration: json['duration'],
      callType: json['callType'],
      status: json['status'] ?? 'sent',
      isDeleted: json['isDeleted'] ?? false,
      deletedFor: (json['deletedFor'] as List?)?.map((e) => e.toString()).toList() ?? const [],
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
    );
  }

  Map<String, dynamic> toJson() => {
        '_id': id,
        'chatId': chatId,
        'senderId': senderId,
        'senderName': senderName,
        'type': _msgTypeToString(type),
        'content': content,
        'mediaUrl': mediaUrl,
        'thumbnailUrl': thumbnailUrl,
        'duration': duration,
        'callType': callType,
        'status': status,
        'isDeleted': isDeleted,
        'deletedFor': deletedFor,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
      };

  bool get isMine => false; // set in UI: msg.senderId == myUserId

  bool get isHiddenForMe => deletedFor.contains(senderId); // you’ll pass viewer id in UI

  //tostring
  @override
  String toString() {
    return 'Message{id: $id, chatId: $chatId, senderId: $senderId, senderName: $senderName, type: $type, content: $content, mediaUrl: $mediaUrl, thumbnailUrl: $thumbnailUrl, duration: $duration, callType: $callType, status: $status, isDeleted: $isDeleted, deletedFor: $deletedFor, createdAt: $createdAt, updatedAt: $updatedAt}';
  }
}
