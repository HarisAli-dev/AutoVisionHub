import 'package:front/model/users/user_model.dart';
import 'package:front/model/groups/group_message_model.dart';

class Group {
  final String id;
  final String name;
  final String? description;
  final String? imageUrl;
  final List<User> participants;
  final GroupMessage? lastMessage;
  final Map<String, int> unreadCounts;
  final String? createdBy;
  final List<String> admins;
  final DateTime createdAt;
  final DateTime updatedAt;

  Group({
    required this.id,
    required this.name,
    this.description,
    this.imageUrl,
    required this.participants,
    this.lastMessage,
    required this.unreadCounts,
    this.createdBy,
    required this.admins,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Group.fromJson(Map<String, dynamic> json) {
    return Group(
      id: json['_id'] ?? '',
      name: json['groupName'] ?? '',
      description: json['description'] ?? '',
      imageUrl: json['groupImageUrl'] ?? '',
      participants:
          (json['participants'])
              ?.map<User>((user) => User.fromJson(user as Map<String, dynamic>))
              .toList() ??
          <User>[],
      lastMessage: json['lastMessage'] != null
          ? GroupMessage.fromJson(json['lastMessage'] as Map<String, dynamic>)
          : null,
      unreadCounts: Map<String, int>.from(json['unreadCounts'] ?? {}),
      createdBy: json['createdBy'],
      admins:
          (json['admins'] as List<dynamic>?)
              ?.map((admin) => admin.toString())
              .toList() ??
          [],
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'groupName': name,
      'description': description,
      'groupImageUrl': imageUrl,
      'participants': participants.map((user) => user.toJson()).toList(),
      'lastMessage': lastMessage?.toJson(),
      'unreadCounts': unreadCounts,
      'createdBy': createdBy,
      'admins': admins,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }
}
