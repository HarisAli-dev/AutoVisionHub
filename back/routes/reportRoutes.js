const express = require('express');
const router = express.Router();
const reportController = require('../controllers/reportController');
const { protect, admin } = require('../middleware/authMiddleware');

// User routes - Report creation
router.post('/user', protect, reportController.reportUser);
router.post('/listitem', protect, reportController.reportListItem);
router.post('/reactivation', protect, reportController.requestReactivation);

// Admin routes - Report management
router.get('/all', protect, admin, reportController.getAllReports);
router.get('/stats', protect, admin, reportController.getReportStats);
router.get('/:reportId', protect, admin, reportController.getReportById);
router.put('/:reportId/status', protect, admin, reportController.updateReportStatus);
router.post('/:reportId/handle-user', protect, admin, reportController.handleUserReport);
router.post('/:reportId/handle-listitem', protect, admin, reportController.handleListItemReport);
router.post('/:reportId/handle-reactivation', protect, admin, reportController.handleReactivationRequest);

module.exports = router;
