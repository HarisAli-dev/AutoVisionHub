const Poll = require('../../models/groups/pollModel');
const Group = require('../../models/groups/groupModel');
const GroupMessage = require('../../models/groups/groupMessageModel');

// Create a poll
const createPoll = async (req, res) => {
  try {
    const { question, options, groupId } = req.body;
    const userId = req.user.id;

    // Validate required fields
    if (!question || !options || options.length < 2) {
      return res.status(400).json({ 
        error: 'Question and at least 2 options are required' 
      });
    }

    // If groupId is provided, validate user is in the group
    if (groupId) {
      const group = await Group.findById(groupId);
      if (!group) {
        return res.status(404).json({ error: 'Group not found' });
      }

      if (!group.participants.includes(userId)) {
        return res.status(403).json({ error: 'You are not a member of this group' });
      }
    }

    // Create the poll
    const poll = new Poll({
      question,
      options,
      votes: [],
      createdBy: userId,
      groupId: groupId || null
    });

    await poll.save();
    await poll.populate('createdBy', 'name email profileImageUrl');

    res.status(201).json({ poll });
  } catch (error) {
    console.error('Error creating poll:', error);
    res.status(500).json({ error: 'Failed to create poll' });
  }
};

// Vote on a poll
const voteOnPoll = async (req, res) => {
  try {
    const { pollId } = req.params;
    const { option } = req.body;
    const userId = req.user.id;

    // Find the poll
    const poll = await Poll.findById(pollId);
    if (!poll) {
      return res.status(404).json({ error: 'Poll not found' });
    }

    // Check if user has already voted
    const existingVoteIndex = poll.votes.findIndex(
      vote => vote.userId.toString() === userId
    );

    if (existingVoteIndex !== -1) {
      // Update existing vote
      poll.votes[existingVoteIndex].option = option;
    } else {
      // Add new vote
      poll.votes.push({
        userId,
        option
      });
    }

    await poll.save();
    
    // Populate the poll with user details for proper response
    await poll.populate('createdBy', 'name email profileImageUrl');

    // Emit socket event for real-time updates if poll is in a group
    if (poll.groupId) {
      const io = req.app.get('io');
      if (io) {
        io.to(`group_${poll.groupId}`).emit('poll_voted', {
          pollId: pollId,
          option: option,
          poll: poll,
          voterId: userId
        });
      }
    }

    res.status(200).json({ poll });
  } catch (error) {
    console.error('Error voting on poll:', error);
    res.status(500).json({ error: 'Failed to vote on poll' });
  }
};

// Get poll details
const getPoll = async (req, res) => {
  try {
    const { pollId } = req.params;
    const userId = req.user.id;

    const poll = await Poll.findById(pollId)
      .populate('createdBy', 'name email profileImageUrl');

    if (!poll) {
      return res.status(404).json({ error: 'Poll not found' });
    }

    // If poll is in a group, validate user is a member
    if (poll.groupId) {
      const group = await Group.findById(poll.groupId);
      if (!group || !group.participants.includes(userId)) {
        return res.status(403).json({ error: 'Access denied' });
      }
    }

    res.status(200).json({ poll });
  } catch (error) {
    console.error('Error getting poll:', error);
    res.status(500).json({ error: 'Failed to get poll' });
  }
};

// Delete a poll
const deletePoll = async (req, res) => {
  try {
    const { pollId } = req.params;
    const userId = req.user.id;

    const poll = await Poll.findById(pollId);
    if (!poll) {
      return res.status(404).json({ error: 'Poll not found' });
    }

    // Check if user is the creator
    if (poll.createdBy.toString() !== userId) {
      return res.status(403).json({ error: 'Only poll creator can delete the poll' });
    }

    // If poll is in a group, also delete any associated poll messages
    if (poll.groupId) {
      await GroupMessage.updateMany(
        { 
          groupId: poll.groupId,
          type: 'poll',
          pollId: pollId
        },
        { isDeleted: true }
      );
    }

    await Poll.findByIdAndDelete(pollId);

    // Emit socket event to notify group members
    if (poll.groupId) {
      const io = req.app.get('io');
      if (io) {
        io.to(`group_${poll.groupId}`).emit('poll_deleted', {
          pollId: pollId,
          groupId: poll.groupId,
          deletedBy: userId
        });
        console.log(`Poll deleted event emitted for group: ${poll.groupId}, poll: ${pollId}`);
      }
    }

    res.status(200).json({ success: true, message: 'Poll deleted successfully' });
  } catch (error) {
    console.error('Error deleting poll:', error);
    res.status(500).json({ error: 'Failed to delete poll' });
  }
};

// Get polls for a group
const getGroupPolls = async (req, res) => {
  try {
    const { groupId } = req.params;
    const userId = req.user.id;

    // Validate group and user membership
    const group = await Group.findById(groupId);
    if (!group) {
      return res.status(404).json({ error: 'Group not found' });
    }

    if (!group.participants.includes(userId)) {
      return res.status(403).json({ error: 'You are not a member of this group' });
    }

    const polls = await Poll.find({ groupId })
      .populate('createdBy', 'name email profileImageUrl')
      .populate('votes.userId', 'name email profileImageUrl')
      .sort({ createdAt: -1 });

    res.status(200).json({ polls });
  } catch (error) {
    console.error('Error getting group polls:', error);
    res.status(500).json({ error: 'Failed to get group polls' });
  }
};

// Get user's polls
const getUserPolls = async (req, res) => {
  try {
    const userId = req.user.id;

    const polls = await Poll.find({ createdBy: userId })
      .populate('createdBy', 'name email profileImageUrl')
      .populate('votes.userId')
      .sort({ createdAt: -1 });

    res.status(200).json({ polls });
  } catch (error) {
    console.error('Error getting user polls:', error);
    res.status(500).json({ error: 'Failed to get user polls' });
  }
};

// Get poll results/statistics
const getPollResults = async (req, res) => {
  try {
    const { pollId } = req.params;
    const userId = req.user.id;

    const poll = await Poll.findById(pollId)
      .populate('createdBy', 'name email profileImageUrl')
      .populate('votes.userId', 'name email profileImageUrl');

    if (!poll) {
      return res.status(404).json({ error: 'Poll not found' });
    }

    // If poll is in a group, validate user is a member
    if (poll.groupId) {
      const group = await Group.findById(poll.groupId);
      if (!group || !group.participants.includes(userId)) {
        return res.status(403).json({ error: 'Access denied' });
      }
    }

    // Calculate results
    const results = poll.options.map((option) => {
      const votes = poll.votes.filter(vote => vote.option === option);
      return {
        option,
        option: option,
        voteCount: votes.length,
        percentage: poll.votes.length > 0 ? (votes.length / poll.votes.length) * 100 : 0,
        voters: votes.map(vote => vote.userId)
      };
    });

    const pollResults = {
      poll: {
        id: poll._id,
        question: poll.question,
        options: poll.options,
        createdBy: poll.createdBy,
        createdAt: poll.createdAt,
        groupId: poll.groupId
      },
      totalVotes: poll.votes.length,
      results,
      userVote: poll.votes.find(vote => vote.userId._id.toString() === userId)?.option || null
    };

    res.status(200).json({ pollResults });
  } catch (error) {
    console.error('Error getting poll results:', error);
    res.status(500).json({ error: 'Failed to get poll results' });
  }
};

module.exports = {
  createPoll,
  voteOnPoll,
  getPoll,
  deletePoll,
  getGroupPolls,
  getUserPolls,
  getPollResults
};
