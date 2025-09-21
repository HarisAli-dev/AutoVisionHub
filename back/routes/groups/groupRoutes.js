const express = require('express');
const router = express.Router();
const groupController = require('../../controllers/groups/groupController');
const { protect } = require('../../middleware/authMiddleware');

// All routes require authentication
router.use(protect);

// Group management routes
router.get('/getAllGroups', groupController.getAllGroups);
router.post('/createGroup', groupController.createGroup);
router.get('/getGroups', groupController.getUserGroups);
router.get('/search', groupController.searchGroups);
router.get('/:groupId', groupController.getGroupDetails);
router.patch('/:groupId', groupController.updateGroup);
router.delete('/:groupId', groupController.deleteGroup);

// Group membership routes
router.post('/:groupId/leave', groupController.leaveGroup);
router.post('/:groupId/addParticipants', groupController.addParticipants);
router.post('/:groupId/removeParticipant', groupController.removeParticipant);
router.get('/:groupId/participants', groupController.getGroupParticipants);

// Admin routes
router.post('/:groupId/makeAdmin', groupController.makeAdmin);
router.post('/:groupId/removeAdmin', groupController.removeAdmin);

module.exports = router;
