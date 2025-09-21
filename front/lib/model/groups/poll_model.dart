class PollVote {
  final String userId;
  final String option;

  PollVote({required this.userId, required this.option});

  factory PollVote.fromJson(Map<String, dynamic> json) {
    return PollVote(userId: json['userId'] ?? '', option: json['option'] ?? '');
  }

  Map<String, dynamic> toJson() {
    return {'userId': userId, 'option': option};
  }

  @override
  String toString() {
    return 'PollVote(userId: $userId, option: $option)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is PollVote &&
        other.userId == userId &&
        other.option == option;
  }

  @override
  int get hashCode => userId.hashCode ^ option.hashCode;
}

class Poll {
  final String id;
  final String question;
  final List<String> options;
  final List<PollVote>? votes;
  final String? createdById;
  final String? createdByName;
  final String? createdByEmail;
  final String? groupId;
  final DateTime createdAt;
  final DateTime updatedAt;

  Poll({
    required this.id,
    required this.question,
    required this.options,
    this.votes,
    this.createdById,
    this.createdByName,
    this.createdByEmail,
    this.groupId,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Poll.fromJson(Map<String, dynamic> json) {
    return Poll(
      id: json['_id'] ?? '',
      question: json['question'] ?? '',
      options: List<String>.from(json['options'] ?? []),
      votes:
          (json['votes'] as List<dynamic>?)
              ?.map((vote) => PollVote.fromJson(vote))
              .toList() ??
          [],
      createdById: json['createdBy']['_id'] ?? '',
      createdByName: json['createdBy']['name'] ?? '',
      createdByEmail: json['createdBy']['email'] ?? '',
      groupId: json['groupId'],
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'question': question,
      'options': options,
      'votes': votes?.map((vote) => vote.toJson()).toList(),
      'createdById': createdById,
      'createdByName': createdByName,
      'createdByEmail': createdByEmail,
      'groupId': groupId,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  // Helper method to get vote count for a specific option
  int getVoteCount(String option) {
    return votes?.where((vote) => vote.option == option).length ?? 0;
  }

  // Helper method to get total votes
  int get totalVotes => votes?.length ?? 0;

  // Helper method to check if a user has voted
  bool hasUserVoted(String userId) {
    return votes?.any((vote) => vote.userId == userId) ?? false;
  }

  // Helper method to get user's vote option
  String? getUserVoteOption(String userId) {
    final userVote = votes?.firstWhere(
      (vote) => vote.userId == userId,
      orElse: () => PollVote(userId: '', option: ''),
    );
    return userVote?.userId.isNotEmpty == true ? userVote?.option : null;
  }

  // Helper method to get vote percentage for an option
  double getVotePercentage(String option) {
    if (totalVotes == 0) return 0.0;
    return (getVoteCount(option) / totalVotes) * 100;
  }

  @override
  String toString() {
    return 'Poll(id: $id, question: $question, options: $options, votes: $votes, createdById: $createdById, createdByName: $createdByName, createdByEmail: $createdByEmail, groupId: $groupId, createdAt: $createdAt, updatedAt: $updatedAt)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Poll && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
