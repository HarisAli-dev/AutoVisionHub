import 'package:front/model/users/user_model.dart';

enum GroupMessageType { text, image, video, voice, file, call, poll }

enum GroupCallType { missed, outgoing, incoming }

enum GroupMessageStatus { sent, delivered, seen }

class GroupMessage {
  final String id;
  final String groupId;
  final String senderId;
  final String? senderImageUrl;
  final String senderName;
  final GroupMessageType type;
  final String? content;
  final String? mediaUrl;
  final String? thumbnailUrl;
  final int? duration;
  final GroupCallType? callType;
  final String? pollId;
  final GroupMessageStatus status;
  final bool isDeleted;
  final List<User>? deletedFor;
  final DateTime createdAt;
  final DateTime updatedAt;

  GroupMessage({
    required this.id,
    required this.groupId,
    required this.senderId,
    required this.senderName,
    required this.type,
    this.content,
    this.senderImageUrl,
    this.mediaUrl,
    this.thumbnailUrl,
    this.duration,
    this.callType,
    this.pollId,
    this.status = GroupMessageStatus.sent,
    this.isDeleted = false,
    this.deletedFor,
    required this.createdAt,
    required this.updatedAt,
  });

  factory GroupMessage.fromJson(Map<String, dynamic> json) {
    return GroupMessage(
      id: json['_id'] ?? '',
      groupId: json['groupId'] ?? '',
      senderId: json['senderId'] ?? '',
      senderName: json['senderName'] ?? '',
      senderImageUrl: json['senderImageUrl'] ?? '',
      type: _parseMessageType(json['type']),
      content: json['content'],
      mediaUrl: json['mediaUrl'],
      thumbnailUrl: json['thumbnailUrl'],
      duration: json['duration'],
      callType: _parseCallType(json['callType']),
      pollId: json['pollId'],
      status: _parseMessageStatus(json['status']),
      isDeleted: json['isDeleted'] ?? false,
      deletedFor: json['deletedFor'] != null
          ? (json['deletedFor'] as List)
                .map((user) => User.fromJson(user))
                .toList()
          : null,
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'groupId': groupId,
      'senderId': senderId,
      'senderName': senderName,
      'type': _messageTypeToString(type),
      'content': content,
      'mediaUrl': mediaUrl,
      'thumbnailUrl': thumbnailUrl,
      'duration': duration,
      'callType': callType != null ? _callTypeToString(callType!) : null,
      'status': _messageStatusToString(status),
      'isDeleted': isDeleted,
      'deletedFor': deletedFor,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  static GroupMessageType _parseMessageType(String? type) {
    switch (type) {
      case 'text':
        return GroupMessageType.text;
      case 'image':
        return GroupMessageType.image;
      case 'video':
        return GroupMessageType.video;
      case 'voice':
        return GroupMessageType.voice;
      case 'file':
        return GroupMessageType.file;
      case 'call':
        return GroupMessageType.call;
      case 'poll':
        return GroupMessageType.poll;
      default:
        return GroupMessageType.text;
    }
  }

  static String _messageTypeToString(GroupMessageType type) {
    switch (type) {
      case GroupMessageType.text:
        return 'text';
      case GroupMessageType.image:
        return 'image';
      case GroupMessageType.video:
        return 'video';
      case GroupMessageType.voice:
        return 'voice';
      case GroupMessageType.file:
        return 'file';
      case GroupMessageType.call:
        return 'call';
      case GroupMessageType.poll:
        return 'poll';
    }
  }

  static GroupCallType? _parseCallType(String? type) {
    switch (type) {
      case 'missed':
        return GroupCallType.missed;
      case 'outgoing':
        return GroupCallType.outgoing;
      case 'incoming':
        return GroupCallType.incoming;
      default:
        return null;
    }
  }

  static String _callTypeToString(GroupCallType type) {
    switch (type) {
      case GroupCallType.missed:
        return 'missed';
      case GroupCallType.outgoing:
        return 'outgoing';
      case GroupCallType.incoming:
        return 'incoming';
    }
  }

  static GroupMessageStatus _parseMessageStatus(String? status) {
    switch (status) {
      case 'sent':
        return GroupMessageStatus.sent;
      case 'delivered':
        return GroupMessageStatus.delivered;
      case 'seen':
        return GroupMessageStatus.seen;
      default:
        return GroupMessageStatus.sent;
    }
  }

  static String _messageStatusToString(GroupMessageStatus status) {
    switch (status) {
      case GroupMessageStatus.sent:
        return 'sent';
      case GroupMessageStatus.delivered:
        return 'delivered';
      case GroupMessageStatus.seen:
        return 'seen';
    }
  }
}
