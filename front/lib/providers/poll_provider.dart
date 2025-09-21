import 'package:flutter/foundation.dart';
import 'package:front/controller/groups/group_message_controller.dart';
import 'package:front/model/groups/poll_model.dart';
import 'package:front/services/socket_service.dart';
import 'package:front/utils/hive_utils.dart';

class PollProvider extends ChangeNotifier {
  // Map to store polls by pollId
  final Map<String, Poll> _polls = {};

  // Map to store optimistic votes (before API response)
  final Map<String, Map<String, dynamic>> _optimisticVotes = {};

  // Loading states
  final Map<String, bool> _loadingStates = {};

  // Voting states
  final Map<String, bool> _votingStates = {};

  // Getters
  Map<String, Poll> get polls => Map.unmodifiable(_polls);

  Poll? getPoll(String pollId) => _polls[pollId];

  bool isLoading(String pollId) => _loadingStates[pollId] ?? false;

  bool isVoting(String pollId) => _votingStates[pollId] ?? false;

  bool hasOptimisticVote(String pollId) => _optimisticVotes.containsKey(pollId);

  String? getOptimisticVote(String pollId) =>
      _optimisticVotes[pollId]?['option'];

  // Initialize provider and setup socket listeners
  void initialize() {
    _setupSocketListeners();
  }

  // Load a poll from API
  Future<void> loadPoll(String pollId) async {
    if (_loadingStates[pollId] == true) return; // Already loading

    try {
      _loadingStates[pollId] = true;
      notifyListeners();

      final poll = await GroupMessageController.getPoll(pollId);
      _polls[pollId] = poll;

      debugPrint(
        'Poll loaded: ${poll.question} with ${poll.votes?.length ?? 0} votes',
      );
    } catch (e) {
      debugPrint('Error loading poll $pollId: $e');
    } finally {
      _loadingStates[pollId] = false;
      notifyListeners();
    }
  }

  // Vote on a poll with optimistic updates
  Future<bool> voteOnPoll(String pollId, String option) async {
    final currentUserId = HiveUtils.getData('userId') ?? '';
    if (currentUserId.isEmpty) return false;

    final poll = _polls[pollId];
    if (poll == null) {
      debugPrint('Poll not found: $pollId');
      return false;
    }

    // Check if user has already voted (including optimistic votes)
    if (hasUserVoted(pollId)) {
      debugPrint('User has already voted in poll $pollId');
      return false;
    }

    try {
      // Set voting state
      _votingStates[pollId] = true;

      // Add optimistic vote for immediate UI feedback
      _addOptimisticVote(pollId, option, currentUserId);
      notifyListeners();

      debugPrint('Added optimistic vote for poll $pollId, option: $option');

      // Make API call
      final updatedPoll = await GroupMessageController.voteOnPoll(
        pollId: pollId,
        option: option,
      );

      // Remove optimistic vote and update with real data from API
      _optimisticVotes.remove(pollId);
      _polls[pollId] = updatedPoll;

      debugPrint(
        'Vote submitted successfully for poll $pollId, updated votes: ${updatedPoll.votes?.length}',
      );
      return true;
    } catch (e) {
      // Remove optimistic vote on error and revert state
      _optimisticVotes.remove(pollId);
      debugPrint('Error voting on poll $pollId: $e');
      notifyListeners();
      return false;
    } finally {
      _votingStates[pollId] = false;
      notifyListeners();
    }
  }

  // Add optimistic vote for immediate UI feedback
  void _addOptimisticVote(String pollId, String option, String userId) {
    _optimisticVotes[pollId] = {
      'option': option,
      'userId': userId,
      'timestamp': DateTime.now(),
    };
  }

  // Get poll with optimistic vote applied
  Poll? getPollWithOptimisticVote(String pollId) {
    final poll = _polls[pollId];
    if (poll == null) return null;

    final optimisticVote = _optimisticVotes[pollId];
    if (optimisticVote == null) return poll;

    // Create a copy of the poll with the optimistic vote added
    final newVotes = List<PollVote>.from(poll.votes ?? []);
    newVotes.add(
      PollVote(
        userId: optimisticVote['userId'],
        option: optimisticVote['option'],
      ),
    );

    return Poll(
      id: poll.id,
      question: poll.question,
      options: poll.options,
      votes: newVotes,
      groupId: poll.groupId,
      createdById: poll.createdById,
      createdByName: poll.createdByName,
      createdByEmail: poll.createdByEmail,
      createdAt: poll.createdAt,
      updatedAt: poll.updatedAt,
    );
  }

  // Setup socket listeners for real-time updates
  void _setupSocketListeners() {
    final socketService = SocketService();
    if (socketService.isConnected) {
      // Listen for poll vote updates
      socketService.socket.on('poll_voted', (data) {
        debugPrint('Received poll_voted event: $data');

        final pollData = data['poll'];
        final pollId = data['pollId'];

        if (pollData != null && pollId != null) {
          try {
            final updatedPoll = Poll.fromJson(pollData);

            // Remove any optimistic vote for this poll to prevent conflicts
            _optimisticVotes.remove(pollId);

            // Update the poll data
            _polls[pollId] = updatedPoll;

            debugPrint(
              'Poll vote update applied via socket: $pollId, total votes: ${updatedPoll.votes?.length}',
            );
            notifyListeners();
          } catch (e) {
            debugPrint('Error processing poll vote update: $e');
          }
        }
      });

      // Listen for poll deletion
      socketService.socket.on('poll_deleted', (data) {
        final pollId = data['pollId'];
        if (pollId != null) {
          _polls.remove(pollId);
          _optimisticVotes.remove(pollId);
          _loadingStates.remove(pollId);
          _votingStates.remove(pollId);

          debugPrint('Poll deleted via socket: $pollId');
          notifyListeners();
        }
      });
    }
  }

  // Create a new poll
  Future<bool> createPoll({
    required String groupId,
    required String question,
    required List<String> options,
  }) async {
    try {
      final success = await GroupMessageController.createPoll(
        groupId: groupId,
        question: question,
        options: options,
      );

      if (success) {
        debugPrint('Poll created successfully: $question');
      }

      return success;
    } catch (e) {
      debugPrint('Error creating poll: $e');
      return false;
    }
  }

  // Delete a poll
  Future<bool> deletePoll(String pollId) async {
    try {
      final success = await GroupMessageController.deletePoll(pollId);

      if (success) {
        _polls.remove(pollId);
        _optimisticVotes.remove(pollId);
        _loadingStates.remove(pollId);
        _votingStates.remove(pollId);
        notifyListeners();

        debugPrint('Poll deleted successfully: $pollId');
      }

      return success;
    } catch (e) {
      debugPrint('Error deleting poll: $e');
      return false;
    }
  }

  // Clear all polls (useful when leaving a group)
  void clearPolls() {
    _polls.clear();
    _optimisticVotes.clear();
    _loadingStates.clear();
    _votingStates.clear();
    notifyListeners();
  }

  // Clear socket listeners
  void dispose() {
    final socketService = SocketService();
    if (socketService.isConnected) {
      socketService.socket.off('poll_voted');
      socketService.socket.off('poll_deleted');
    }
    super.dispose();
  }

  // Get vote statistics for a poll option
  Map<String, dynamic> getOptionStats(String pollId, String option) {
    final poll = getPollWithOptimisticVote(pollId);
    if (poll == null) {
      return {'count': 0, 'percentage': 0};
    }

    final voteCount =
        poll.votes?.where((vote) => vote.option == option).length ?? 0;
    final totalVotes = poll.votes?.length ?? 0;
    final percentage = totalVotes > 0
        ? (voteCount / totalVotes * 100).round()
        : 0;

    return {
      'count': voteCount,
      'percentage': percentage,
      'totalVotes': totalVotes,
    };
  }

  // Check if current user voted for a specific option
  bool hasUserVotedForOption(String pollId, String option) {
    final currentUserId = HiveUtils.getData('userId') ?? '';

    // Check optimistic vote first
    final optimisticVote = _optimisticVotes[pollId];
    if (optimisticVote != null &&
        optimisticVote['userId'] == currentUserId &&
        optimisticVote['option'] == option) {
      return true;
    }

    // Check actual votes
    final poll = _polls[pollId];
    return poll?.votes?.any(
          (vote) => vote.userId == currentUserId && vote.option == option,
        ) ??
        false;
  }

  // Check if current user has voted in the poll
  bool hasUserVoted(String pollId) {
    final currentUserId = HiveUtils.getData('userId') ?? '';

    // Check optimistic vote first
    if (_optimisticVotes[pollId]?['userId'] == currentUserId) {
      return true;
    }

    // Check actual votes
    final poll = _polls[pollId];
    return poll?.votes?.any((vote) => vote.userId == currentUserId) ?? false;
  }
}
