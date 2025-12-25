const Report = require('../models/reportModel');
const User = require('../models/users/userModel');
const Listing = require('../models/marketplace/listingModel');
const notificationService = require('../services/notificationService');

// Create a report for user
exports.reportUser = async (req, res) => {
  try {
    const { userId, reason, proofImages } = req.body;
    const reporterId = req.user.id;

    if (!userId || !reason) {
      return res.status(400).json({ error: 'User ID and reason are required' });
    }

    if (userId === reporterId) {
      return res.status(400).json({ error: 'You cannot report yourself' });
    }

    // Check if user exists
    const user = await User.findById(userId);
    if (!user) {
      return res.status(404).json({ error: 'User not found' });
    }

    // Check if already reported by this user
    const existingReport = await Report.findOne({
      reportedBy: reporterId,
      reportedUser: userId,
      status: 'pending'
    });

    if (existingReport) {
      return res.status(400).json({ error: 'You have already reported this user' });
    }

    const report = new Report({
      reportType: 'user',
      reportedBy: reporterId,
      reportedUser: userId,
      reason: reason.trim(),
      proofImages: proofImages || []
    });

    await report.save();

    res.status(200).json({ 
      success: true, 
      message: 'User reported successfully. Our team will review it shortly.' 
    });
  } catch (error) {
    console.error('Error reporting user:', error);
    res.status(500).json({ error: 'Failed to report user' });
  }
};

// Create a report for list item
exports.reportListItem = async (req, res) => {
  try {
    const { listItemId, reason, proofImages } = req.body;
    const reporterId = req.user.id;

    if (!listItemId || !reason) {
      return res.status(400).json({ error: 'List item ID and reason are required' });
    }

    // Check if list item exists
    const listItem = await Listing.findById(listItemId);
    if (!listItem) {
      return res.status(404).json({ error: 'List item not found' });
    }

    // Check if reporting own item
    if (listItem.seller.toString() === reporterId) {
      return res.status(400).json({ error: 'You cannot report your own listing' });
    }

    // Check if already reported by this user
    const existingReport = await Report.findOne({
      reportedBy: reporterId,
      reportedListItem: listItemId,
      status: 'pending'
    });

    if (existingReport) {
      return res.status(400).json({ error: 'You have already reported this listing' });
    }

    const report = new Report({
      reportType: 'listitem',
      reportedBy: reporterId,
      reportedListItem: listItemId,
      reason: reason.trim(),
      proofImages: proofImages || []
    });

    await report.save();

    res.status(200).json({ 
      success: true, 
      message: 'Listing reported successfully. Our team will review it shortly.' 
    });
  } catch (error) {
    console.error('Error reporting list item:', error);
    res.status(500).json({ error: 'Failed to report listing' });
  }
};

// Get all reports (Admin only)
exports.getAllReports = async (req, res) => {
  try {
    const { status, type } = req.query;
    
    const filter = {};
    if (status) filter.status = status;
    if (type) filter.reportType = type;

    const reports = await Report.find(filter)
      .populate('reportedBy', 'name email profileImageUrl')
      .populate('reportedUser', 'name email profileImageUrl phoneNumber')
      .populate('reportedListItem', 'title description price images userId category brand condition')
      .populate('reviewedBy', 'name email')
      .sort({ createdAt: -1 });

    res.status(200).json({ reports });
  } catch (error) {
    console.error('Error fetching reports:', error);
    res.status(500).json({ error: 'Failed to fetch reports' });
  }
};

// Get single report details (Admin only)
exports.getReportById = async (req, res) => {
  try {
    const { reportId } = req.params;

    const report = await Report.findById(reportId)
      .populate('reportedBy', 'name email profileImageUrl phoneNumber')
      .populate('reportedUser', 'name email profileImageUrl phoneNumber createdAt')
      .populate('reportedListItem')
      .populate('reviewedBy', 'name email');

    if (!report) {
      return res.status(404).json({ error: 'Report not found' });
    }

    // If list item, populate its owner details
    if (report.reportedListItem) {
      await report.reportedListItem.populate('userId', 'name email profileImageUrl');
    }

    res.status(200).json({ report });
  } catch (error) {
    console.error('Error fetching report:', error);
    res.status(500).json({ error: 'Failed to fetch report' });
  }
};

// Take action on user report (Admin only)
exports.handleUserReport = async (req, res) => {
  try {
    const { reportId } = req.params;
    const { action, adminNotes } = req.body; // action: 'ban', 'delete', 'ignore'
    const adminId = req.user.id;

    if (!action || !['ban', 'delete', 'ignore'].includes(action)) {
      return res.status(400).json({ error: 'Invalid action' });
    }

    const report = await Report.findById(reportId).populate('reportedUser');
    if (!report) {
      return res.status(404).json({ error: 'Report not found' });
    }

    if (report.reportType !== 'user') {
      return res.status(400).json({ error: 'This is not a user report' });
    }

    let actionTaken = 'none';
    const user = report.reportedUser;

    if (action === 'ban') {
      user.isBanned = true;
      await user.save();
      actionTaken = 'user_banned';
      
      // Send notification to banned user
      await notificationService.sendNotificationToUser(
        user._id,
        {
          title: 'Account Suspended',
          body: 'Your account has been suspended due to violations of our community guidelines.'
        }
      );
    } else if (action === 'delete') {
      // Soft delete by marking as inactive
      user.isActive = false;
      await user.save();
      actionTaken = 'user_deleted';
      
      await notificationService.sendNotificationToUser(
        user._id,
        {
          title: 'Account Removed',
          body: 'Your account has been removed due to violations of our community guidelines.'
        }
      );
    } else if (action === 'ignore') {
      actionTaken = 'ignored';
    }

    report.status = 'resolved';
    report.actionTaken = actionTaken;
    report.adminNotes = adminNotes || '';
    report.reviewedBy = adminId;
    report.reviewedAt = new Date();

    await report.save();

    res.status(200).json({ 
      success: true, 
      message: `Action '${action}' completed successfully` 
    });
  } catch (error) {
    console.error('Error handling user report:', error);
    res.status(500).json({ error: 'Failed to handle report' });
  }
};

// Take action on list item report (Admin only)
exports.handleListItemReport = async (req, res) => {
  try {
    const { reportId } = req.params;
    const { action, adminNotes } = req.body; // action: 'remove', 'ignore'
    const adminId = req.user.id;

    if (!action || !['remove', 'ignore'].includes(action)) {
      return res.status(400).json({ error: 'Invalid action' });
    }

    const report = await Report.findById(reportId)
      .populate('reportedListItem');
    
    if (!report) {
      return res.status(404).json({ error: 'Report not found' });
    }

    if (report.reportType !== 'listitem') {
      return res.status(400).json({ error: 'This is not a list item report' });
    }

    let actionTaken = 'none';
    const listItem = report.reportedListItem;

    if (action === 'remove') {
      // Mark list item as inactive/removed
      listItem.isActive = false;
      await listItem.save();
      actionTaken = 'listitem_removed';
      
      // Send notification to list item owner
      const notificationMessage = adminNotes 
        ? `Your listing "${listItem.title}" has been removed. Reason: ${adminNotes}`
        : `Your listing "${listItem.title}" has been removed due to violation of our community guidelines.`;
      
      await notificationService.sendNotificationToUser(
        listItem.seller,
        {
          title: 'Listing Removed',
          body: notificationMessage
        }
      );
    } else if (action === 'ignore') {
      actionTaken = 'ignored';
    }

    report.status = 'resolved';
    report.actionTaken = actionTaken;
    report.adminNotes = adminNotes || '';
    report.reviewedBy = adminId;
    report.reviewedAt = new Date();

    await report.save();

    res.status(200).json({ 
      success: true, 
      message: `Action '${action}' completed successfully` 
    });
  } catch (error) {
    console.error('Error handling list item report:', error);
    res.status(500).json({ error: 'Failed to handle report' });
  }
};

// Update report status (Admin only)
exports.updateReportStatus = async (req, res) => {
  try {
    const { reportId } = req.params;
    const { status, adminNotes } = req.body;
    const adminId = req.user.id;

    if (!status || !['pending', 'reviewed', 'resolved', 'ignored'].includes(status)) {
      return res.status(400).json({ error: 'Invalid status' });
    }

    const report = await Report.findById(reportId);
    if (!report) {
      return res.status(404).json({ error: 'Report not found' });
    }

    report.status = status;
    if (adminNotes) report.adminNotes = adminNotes;
    if (status === 'reviewed' || status === 'resolved') {
      report.reviewedBy = adminId;
      report.reviewedAt = new Date();
    }

    await report.save();

    res.status(200).json({ 
      success: true, 
      message: 'Report status updated successfully' 
    });
  } catch (error) {
    console.error('Error updating report status:', error);
    res.status(500).json({ error: 'Failed to update report status' });
  }
};

// Request listing reactivation
exports.requestReactivation = async (req, res) => {
  try {
    const { listItemId, reason } = req.body;
    const userId = req.user.id;

    if (!listItemId || !reason) {
      return res.status(400).json({ error: 'List item ID and reason are required' });
    }

    // Check if list item exists
    const listItem = await Listing.findById(listItemId);
    if (!listItem) {
      return res.status(404).json({ error: 'List item not found' });
    }

    // Check if user owns the listing
    if (listItem.seller.toString() !== userId) {
      return res.status(403).json({ error: 'You can only request reactivation for your own listings' });
    }

    // Check if listing is already active
    if (listItem.isActive) {
      return res.status(400).json({ error: 'This listing is already active' });
    }

    // Check if there's already a pending reactivation request
    const existingRequest = await Report.findOne({
      reportType: 'reactivation_request',
      reportedListItem: listItemId,
      status: 'pending'
    });

    if (existingRequest) {
      return res.status(400).json({ error: 'You already have a pending reactivation request for this listing' });
    }

    const report = new Report({
      reportType: 'reactivation_request',
      reportedBy: userId,
      reportedListItem: listItemId,
      reason: reason.trim()
    });

    await report.save();

    res.status(200).json({ 
      success: true, 
      message: 'Reactivation request submitted successfully. Our team will review it shortly.' 
    });
  } catch (error) {
    console.error('Error requesting reactivation:', error);
    res.status(500).json({ error: 'Failed to submit reactivation request' });
  }
};

// Handle reactivation request (Admin only)
exports.handleReactivationRequest = async (req, res) => {
  try {
    const { reportId } = req.params;
    const { action, adminNotes } = req.body; // action: 'accept', 'reject'
    const adminId = req.user.id;

    if (!action || !['accept', 'reject'].includes(action)) {
      return res.status(400).json({ error: 'Invalid action' });
    }

    const report = await Report.findById(reportId)
      .populate('reportedListItem')
      .populate('reportedBy', 'name email');
    
    if (!report) {
      return res.status(404).json({ error: 'Reactivation request not found' });
    }

    if (report.reportType !== 'reactivation_request') {
      return res.status(400).json({ error: 'This is not a reactivation request' });
    }

    let actionTaken = 'none';
    const listItem = report.reportedListItem;
    const owner = report.reportedBy;

    if (action === 'accept') {
      // Reactivate the listing
      listItem.isActive = true;
      await listItem.save();
      actionTaken = 'listitem_reactivated';
      
      // Send notification to owner
      const notificationMessage = adminNotes 
        ? `Your listing "${listItem.title}" has been reactivated. Note: ${adminNotes}`
        : `Your listing "${listItem.title}" has been reactivated and is now live.`;
      
      await notificationService.sendNotificationToUser(
        listItem.seller,
        {
          title: 'Listing Reactivated',
          body: notificationMessage
        }
      );
    } else if (action === 'reject') {
      actionTaken = 'ignored';
      
      // Send notification about rejection
      const notificationMessage = adminNotes 
        ? `Your reactivation request for "${listItem.title}" was rejected. Reason: ${adminNotes}`
        : `Your reactivation request for "${listItem.title}" was rejected.`;
      
      await notificationService.sendNotificationToUser(
        listItem.seller,
        {
          title: 'Reactivation Request Rejected',
          body: notificationMessage
        }
      );
    }

    report.status = 'resolved';
    report.actionTaken = actionTaken;
    report.adminNotes = adminNotes || '';
    report.reviewedBy = adminId;
    report.reviewedAt = new Date();

    await report.save();

    res.status(200).json({ 
      success: true, 
      message: `Reactivation request ${action}ed successfully` 
    });
  } catch (error) {
    console.error('Error handling reactivation request:', error);
    res.status(500).json({ error: 'Failed to handle reactivation request' });
  }
};

// Get report statistics (Admin only)
exports.getReportStats = async (req, res) => {
  try {
    const totalReports = await Report.countDocuments();
    const pendingReports = await Report.countDocuments({ status: 'pending' });
    const resolvedReports = await Report.countDocuments({ status: 'resolved' });
    const userReports = await Report.countDocuments({ reportType: 'user' });
    const listItemReports = await Report.countDocuments({ reportType: 'listitem' });

    res.status(200).json({
      stats: {
        total: totalReports,
        pending: pendingReports,
        resolved: resolvedReports,
        userReports,
        listItemReports
      }
    });
  } catch (error) {
    console.error('Error fetching report stats:', error);
    res.status(500).json({ error: 'Failed to fetch report statistics' });
  }
};
