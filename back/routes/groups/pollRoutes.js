const express = require('express');
const router = express.Router();
const {
  createPoll,
  voteOnPoll,
  getPoll,
  deletePoll,
  getGroupPolls,
  getUserPolls,
  getPollResults
} = require('../../controllers/groups/pollController');
const { protect } = require('../../middleware/authMiddleware');

// All routes require authentication
router.use(protect);

// Poll CRUD routes
router.post('/create', createPoll);
router.get('/:pollId', getPoll);
router.delete('/:pollId', deletePoll);

// Poll interaction routes
router.post('/:pollId/vote', voteOnPoll);
router.get('/:pollId/results', getPollResults);

// Poll listing routes
router.get('/group/:groupId', getGroupPolls);
router.get('/user/my-polls', getUserPolls);

module.exports = router;
