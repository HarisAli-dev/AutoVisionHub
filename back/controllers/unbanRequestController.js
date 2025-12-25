// controllers/unbanRequestController.js
const Report = require('../models/reportModel');
const User = require('../models/users/userModel');

// Create unban request
exports.createUnbanRequest = async (req, res) => {
  try {
    const { email, message, proofImages } = req.body;

    if (!email || !message) {
      return res.status(400).json({ error: 'Email and message are required' });
    }

    // Find user by email
    const user = await User.findOne({ email });
    if (!user) {
      return res.status(404).json({ error: 'User not found' });
    }

    if (!user.isBanned) {
      return res.status(400).json({ error: 'User is not banned' });
    }

    // Check if there's already a pending request
    const existingRequest = await Report.findOne({
      reportType: 'unban_request',
      reportedUser: user._id,
      status: 'pending'
    });

    if (existingRequest) {
      return res.status(400).json({ error: 'You already have a pending unban request' });
    }

    const unbanRequest = await Report.create({
      reportType: 'unban_request',
      reportedUser: user._id,
      reason: message,
      proofImages: proofImages || [],
      status: 'pending'
    });

    res.status(201).json({
      message: 'Unban request submitted successfully',
      request: unbanRequest
    });
  } catch (error) {
    res.status(500).json({ error: 'Error creating unban request', details: error.message });
  }
};

// Get all unban requests (Admin only)
exports.getAllUnbanRequests = async (req, res) => {
  try {
    const { status } = req.query;
    const filter = { reportType: 'unban_request' };
    if (status) filter.status = status;

    const requests = await Report.find(filter)
      .populate('reportedUser', 'name email phoneNumber isBanned')
      .populate('reviewedBy', 'name email')
      .sort({ createdAt: -1 });

    res.status(200).json(requests);
  } catch (error) {
    res.status(500).json({ error: 'Error fetching unban requests', details: error.message });
  }
};

// Get unban request by user ID
exports.getUserUnbanRequest = async (req, res) => {
  try {
    const userId = req.user.id;

    const request = await Report.findOne({ 
      reportType: 'unban_request',
      reportedUser: userId 
    })
      .populate('reviewedBy', 'name email')
      .sort({ createdAt: -1 })
      .limit(1);

    res.status(200).json(request);
  } catch (error) {
    res.status(500).json({ error: 'Error fetching unban request', details: error.message });
  }
};

// Review unban request (Admin only)
exports.reviewUnbanRequest = async (req, res) => {
  try {
    const { requestId } = req.params;
    const { status, adminNotes } = req.body;
    const adminId = req.user.id;

    if (!['approved', 'rejected'].includes(status)) {
      return res.status(400).json({ error: 'Invalid status. Must be approved or rejected' });
    }

    const request = await Report.findById(requestId);
    if (!request) {
      return res.status(404).json({ error: 'Unban request not found' });
    }

    if (request.reportType !== 'unban_request') {
      return res.status(400).json({ error: 'This is not an unban request' });
    }

    if (request.status !== 'pending') {
      return res.status(400).json({ error: 'This request has already been reviewed' });
    }

    // Update request
    request.status = status;
    request.reviewedBy = adminId;
    request.reviewedAt = new Date();
    request.adminNotes = adminNotes;
    request.actionTaken = status === 'approved' ? 'user_unbanned' : 'ignored';
    await request.save();

    // If approved, unban the user
    if (status === 'approved') {
      await User.findByIdAndUpdate(request.reportedUser, { isBanned: false });
    }

    res.status(200).json({
      message: `Unban request ${status}`,
      request
    });
  } catch (error) {
    res.status(500).json({ error: 'Error reviewing unban request', details: error.message });
  }
};

module.exports = exports;
