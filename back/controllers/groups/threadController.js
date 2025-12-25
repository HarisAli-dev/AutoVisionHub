const Thread = require('../../models/groups/threadModel');
const ThreadMessage = require('../../models/groups/threadMessageModel');
const User = require('../../models/users/userModel');
const cloudinary = require('../../config/cloudinary');
const multer = require('multer');

// Configure multer for memory storage
const storage = multer.memoryStorage();
const upload = multer({
  storage: storage,
  limits: { fileSize: 10 * 1024 * 1024 } // 10MB limit
}).single('image');

// Create a new discussion thread
exports.createThread = async (req, res) => {
  upload(req, res, async (err) => {
    try {
      if (err) {
        console.error('Multer error:', err);
        return res.status(400).json({ error: 'File upload error: ' + err.message });
      }

      const { topicName, description } = req.body;
      const userId = req.user.id;

      if (!topicName || topicName.trim().length === 0) {
        return res.status(400).json({ error: 'Topic name is required' });
      }

      let imageUrl = null;
      let imagePublicId = null;

      // Upload image to Cloudinary if provided
      if (req.file) {
        try {
          const timestamp = Date.now();
          const publicId = `thread_image_${userId}_${timestamp}`;

          const result = await new Promise((resolve, reject) => {
            cloudinary.uploader.upload_stream(
              {
                resource_type: 'image',
                folder: 'thread_images',
                public_id: publicId,
                transformation: [
                  { width: 800, height: 600, crop: 'limit' },
                  { quality: 'auto' }
                ]
              },
              (error, result) => {
                if (error) reject(error);
                else resolve(result);
              }
            ).end(req.file.buffer);
          });

          imageUrl = result.secure_url;
          imagePublicId = result.public_id;
        } catch (uploadError) {
          console.error('Cloudinary upload error:', uploadError);
          return res.status(500).json({ error: 'Failed to upload image' });
        }
      }

      const thread = new Thread({
        topicName: topicName.trim(),
        description: description?.trim(),
        imageUrl,
        imagePublicId,
        createdBy: userId,
        participants: [userId]
      });

      await thread.save();
      await thread.populate('createdBy', 'name email profileImageUrl');

      res.status(200).json({ success: true, thread });
    } catch (error) {
      console.error('Error creating thread:', error);
      res.status(500).json({ error: 'Failed to create thread' });
    }
  });
};

// Get all active threads
exports.getAllThreads = async (req, res) => {
  try {
    const userId = req.user.id;

    // Check if user is banned
    const user = await User.findById(userId);
    if (user && user.isBanned) {
      return res.status(403).json({ error: 'Your account has been banned' });
    }

    const threads = await Thread.find({ isActive: true })
      .populate('createdBy', 'name email profileImageUrl')
      .populate('lastMessage')
      .sort({ updatedAt: -1 });

    res.status(200).json({ threads });
  } catch (error) {
    console.error('Error fetching threads:', error);
    res.status(500).json({ error: 'Failed to fetch threads' });
  }
};

// Get user's joined threads
exports.getUserThreads = async (req, res) => {
  try {
    const userId = req.user.id;

    // Check if user is banned
    const user = await User.findById(userId);
    if (user && user.isBanned) {
      return res.status(403).json({ error: 'Your account has been banned' });
    }

    const threads = await Thread.find({
      participants: userId,
      isActive: true
    })
      .populate('createdBy', 'name email profileImageUrl')
      .populate('lastMessage')
      .sort({ updatedAt: -1 });

    res.status(200).json({ threads });
  } catch (error) {
    console.error('Error fetching user threads:', error);
    res.status(500).json({ error: 'Failed to fetch threads' });
  }
};

// Join a thread
exports.joinThread = async (req, res) => {
  try {
    const { threadId } = req.params;
    const userId = req.user.id;

    const thread = await Thread.findById(threadId);
    if (!thread) {
      return res.status(404).json({ error: 'Thread not found' });
    }

    if (!thread.isActive) {
      return res.status(400).json({ error: 'This thread is no longer active' });
    }

    if (thread.participants.includes(userId)) {
      return res.status(400).json({ error: 'You are already a participant' });
    }

    thread.participants.push(userId);
    await thread.save();

    res.status(200).json({ success: true, message: 'Joined thread successfully' });
  } catch (error) {
    console.error('Error joining thread:', error);
    res.status(500).json({ error: 'Failed to join thread' });
  }
};

// Leave a thread
exports.leaveThread = async (req, res) => {
  try {
    const { threadId } = req.params;
    const userId = req.user.id;

    const thread = await Thread.findById(threadId);
    if (!thread) {
      return res.status(404).json({ error: 'Thread not found' });
    }

    if (thread.createdBy.toString() === userId) {
      return res.status(400).json({ error: 'Creator cannot leave the thread. You can delete it instead.' });
    }

    thread.participants = thread.participants.filter(
      p => p.toString() !== userId
    );
    await thread.save();

    res.status(200).json({ success: true, message: 'Left thread successfully' });
  } catch (error) {
    console.error('Error leaving thread:', error);
    res.status(500).json({ error: 'Failed to leave thread' });
  }
};

// Delete a thread (creator only)
exports.deleteThread = async (req, res) => {
  try {
    const { threadId } = req.params;
    const userId = req.user.id;

    const thread = await Thread.findById(threadId);
    if (!thread) {
      return res.status(404).json({ error: 'Thread not found' });
    }

    if (thread.createdBy.toString() !== userId) {
      return res.status(403).json({ error: 'Only the creator can delete this thread' });
    }

    // Delete image from Cloudinary if exists
    if (thread.imagePublicId) {
      try {
        await cloudinary.uploader.destroy(thread.imagePublicId);
      } catch (cloudinaryError) {
        console.error('Error deleting image from Cloudinary:', cloudinaryError);
      }
    }

    thread.isActive = false;
    await thread.save();

    res.status(200).json({ success: true, message: 'Thread deleted successfully' });
  } catch (error) {
    console.error('Error deleting thread:', error);
    res.status(500).json({ error: 'Failed to delete thread' });
  }
};

// Get thread details
exports.getThreadDetails = async (req, res) => {
  try {
    const { threadId } = req.params;

    const thread = await Thread.findById(threadId)
      .populate('createdBy', 'name email profileImageUrl')
      .populate('participants', 'name email profileImageUrl')
      .populate('lastMessage');

    if (!thread) {
      return res.status(404).json({ error: 'Thread not found' });
    }

    res.status(200).json({ thread });
  } catch (error) {
    console.error('Error fetching thread details:', error);
    res.status(500).json({ error: 'Failed to fetch thread details' });
  }
};
