const Group = require('../../models/groups/groupModel');
const User = require('../../models/users/userModel');
const GroupMessage = require('../../models/groups/groupMessageModel');

// Create a new group
exports.createGroup = async (req, res) => {
  try {
    const { groupName, participants, description, groupImageUrl } = req.body;
    const userId = req.user.id;

    // Add the creator to the participants list if not already included
    const allParticipants = participants.includes(userId) ? participants : [...participants, userId];

    // Validate that all participants exist
    const validUsers = await User.find({ _id: { $in: allParticipants } });
    if (validUsers.length !== allParticipants.length) {
      return res.status(400).json({ error: 'Some participants do not exist' });
    }

    const group = new Group({
      participants: allParticipants,
      createdBy: userId,
      groupName,
      description,
      groupImageUrl,
      unreadCounts: new Map()
    });

    await group.save();
    await group.populate('participants', 'name email profileImageUrl');

    res.status(200).json({ success: true, group });
  } catch (error) {
    console.error('Error creating group:', error);
    res.status(500).json({ error: 'Failed to create group' });
  }
};

// Get all groups for the current user
exports.getUserGroups = async (req, res) => {
  try {
    const userId = req.user.id;

    const groups = await Group.find({
      participants: userId
    })
      .populate('participants', 'name email profileImageUrl')
      .populate('lastMessage')
      .sort({ updatedAt: -1 });

    res.status(200).json({ groups });
  } catch (error) {
    console.error('Error fetching groups:', error);
    res.status(500).json({ error: 'Failed to fetch groups' });
  }
};

// Get all groups (where user is not a participant) 
exports.getAllGroups = async (req, res) => {
  try {
    const groups = await Group.find()
      .populate('participants', 'name email profileImageUrl')
      .populate('lastMessage')
      .sort({ updatedAt: -1 });

    res.status(200).json({ groups });
  } catch (error) {
    console.error('Error fetching groups:', error);
    res.status(500).json({ error: 'Failed to fetch groups' });
  }
};

// Get group details
exports.getGroupDetails = async (req, res) => {
  try {
    const { groupId } = req.params;
    const userId = req.user.id;

    const group = await Group.findById(groupId)
      .populate('participants', 'name email profileImageUrl')
      .populate('lastMessage');

    if (!group) {
      return res.status(404).json({ error: 'Group not found' });
    }

    // Check if user is a participant
    if (!group.participants.some(participant => participant._id.toString() === userId)) {
      return res.status(403).json({ error: 'Access denied' });
    }

    res.status(200).json({ group });
  } catch (error) {
    console.error('Error getting group details:', error);
    res.status(500).json({ error: 'Failed to get group details' });
  }
};

// Update group details
exports.updateGroup = async (req, res) => {
  try {
    const { groupId } = req.params;
    const { groupName, description, groupImageUrl } = req.body;
    const userId = req.user.id;

    const group = await Group.findById(groupId);
    if (!group) {
      return res.status(404).json({ error: 'Group not found' });
    }

    // Update fields if provided
    group.groupName = groupName;
    group.description = description;
    group.groupImageUrl = groupImageUrl;
    console.log('Updated group:', group);
    await group.save();
    await group.populate('participants', 'name email profileImageUrl');

    res.status(200).json({ success: true, group });
  } catch (error) {
    console.error('Error updating group:', error);
    res.status(500).json({ error: 'Failed to update group' });
  }
};

// Delete a group
exports.deleteGroup = async (req, res) => {
  try {
    const { groupId } = req.params;
    const userId = req.user.id;

    const group = await Group.findById(groupId);
    if (!group) {
      return res.status(404).json({ error: 'Group not found' });
    }

    // Check if user is the creator or admin
    if (group.createdBy.toString() !== userId) {
      return res.status(403).json({ error: 'Only group creator can delete the group' });
    }

    // Delete all group messages
    await GroupMessage.deleteMany({ groupId });

    // Delete the group
    await Group.findByIdAndDelete(groupId);

    res.status(200).json({ success: true, message: 'Group deleted successfully' });
  } catch (error) {
    console.error('Error deleting group:', error);
    res.status(500).json({ error: 'Failed to delete group' });
  }
};

// Leave a group
exports.leaveGroup = async (req, res) => {
  try {
    const { groupId } = req.params;
    const userId = req.user.id;

    const group = await Group.findById(groupId);
    if (!group) {
      return res.status(404).json({ error: 'Group not found' });
    }

    // Check if user is a participant
    if (!group.participants.includes(userId)) {
      return res.status(404).json({ error: 'User is not a member of this group' });
    }

    // Remove user from participants
    group.participants = group.participants.filter(
      participantId => participantId.toString() !== userId
    );

    // Remove user from unread counts
    group.unreadCounts.delete(userId);

    await group.save();

    res.status(200).json({ success: true, message: 'Left group successfully' });
  } catch (error) {
    console.error('Error leaving group:', error);
    res.status(500).json({ error: 'Failed to leave group' });
  }
};

// Add participants to group
exports.addParticipants = async (req, res) => {
  try {
    const { groupId } = req.params;
    const { participants } = req.body;
    const userId = req.user.id;

    const group = await Group.findById(groupId);
    if (!group) {
      return res.status(404).json({ error: 'Group not found' });
    }

    // Validate that all new participants exist
    const validUsers = await User.find({ _id: { $in: participants } });
    if (validUsers.length !== participants.length) {
      return res.status(400).json({ error: 'Some participants do not exist' });
    }

    // Add new participants (avoid duplicates)
    const newParticipants = participants.filter(
      participantId => !group.participants.includes(participantId)
    );

    group.participants.push(...newParticipants);
    await group.save();
    await group.populate('participants', 'name email profileImageUrl');
    res.status(200).json({ success: true, group });
  } catch (error) {
    console.error('Error adding participants:', error);
    res.status(500).json({ error: 'Failed to add participants' });
  }
};

// Remove participant from group
exports.removeParticipant = async (req, res) => {
  try {
    const { groupId } = req.params;
    const { participantId } = req.body;
    const userId = req.user.id;

    const group = await Group.findById(groupId);
    if (!group) {
      return res.status(404).json({ error: 'Group not found' });
    }

    // Check if user is the creator or admin
    if (group.createdBy.toString() !== userId) {
      return res.status(403).json({ error: 'Only group creator can remove participants' });
    }

    // Check if participant exists in group
    if (!group.participants.includes(participantId)) {
      return res.status(404).json({ error: 'Participant not found in group' });
    }

    // Remove participant
    group.participants = group.participants.filter(
      id => id.toString() !== participantId
    );

    // Remove from unread counts
    group.unreadCounts.delete(participantId);

    await group.save();
    await group.populate('participants', 'name email profileImageUrl');

    res.status(200).json({ success: true, group });
  } catch (error) {
    console.error('Error removing participant:', error);
    res.status(500).json({ error: 'Failed to remove participant' });
  }
};

// Make participant admin (you'll need to add admin field to group model)
exports.makeAdmin = async (req, res) => {
  try {
    const { groupId } = req.params;
    const { participantId } = req.body;
    const userId = req.user.id;

    const group = await Group.findById(groupId);
    if (!group) {
      return res.status(404).json({ error: 'Group not found' });
    }

    // Check if user is the creator
    if (group.createdBy.toString() !== userId) {
      return res.status(403).json({ error: 'Only group creator can make admins' });
    }

    // Check if participant exists in group
    if (!group.participants.includes(participantId)) {
      return res.status(404).json({ error: 'Participant not found in group' });
    }

    // Add admin functionality here when you add admins field to group model
    // For now, just return success
    res.status(200).json({ success: true, message: 'Admin functionality to be implemented' });
  } catch (error) {
    console.error('Error making admin:', error);
    res.status(500).json({ error: 'Failed to make admin' });
  }
};

// Remove admin privileges
exports.removeAdmin = async (req, res) => {
  try {
    const { groupId } = req.params;
    const { participantId } = req.body;
    const userId = req.user.id;

    const group = await Group.findById(groupId);
    if (!group) {
      return res.status(404).json({ error: 'Group not found' });
    }

    // Check if user is the creator
    if (group.createdBy.toString() !== userId) {
      return res.status(403).json({ error: 'Only group creator can remove admin privileges' });
    }

    // Add admin functionality here when you add admins field to group model
    // For now, just return success
    res.status(200).json({ success: true, message: 'Remove admin functionality to be implemented' });
  } catch (error) {
    console.error('Error removing admin:', error);
    res.status(500).json({ error: 'Failed to remove admin' });
  }
};

// Search groups
exports.searchGroups = async (req, res) => {
  try {
    const { q } = req.query;
    const userId = req.user.id;

    if (!q || q.trim() === '') {
      return res.status(400).json({ error: 'Search query is required' });
    }

    const groups = await Group.find({
      participants: userId,
      $or: [
        { groupName: { $regex: q, $options: 'i' } },
        { description: { $regex: q, $options: 'i' } }
      ]
    })
      .populate('participants', 'name email profileImageUrl')
      .populate('lastMessage')
      .sort({ updatedAt: -1 });

    res.status(200).json({ groups });
  } catch (error) {
    console.error('Error searching groups:', error);
    res.status(500).json({ error: 'Failed to search groups' });
  }
};

// Get group participants
exports.getGroupParticipants = async (req, res) => {
  try {
    const { groupId } = req.params;
    const userId = req.user.id;

    const group = await Group.findById(groupId)
      .populate('participants', 'name email profileImageUrl');

    if (!group) {
      return res.status(404).json({ error: 'Group not found' });
    }

    // Check if user is a participant
    if (!group.participants.some(participant => participant._id.toString() === userId)) {
      return res.status(403).json({ error: 'Access denied' });
    }

    res.status(200).json({ participants: group.participants });
  } catch (error) {
    console.error('Error getting group participants:', error);
    res.status(500).json({ error: 'Failed to get group participants' });
  }
};

