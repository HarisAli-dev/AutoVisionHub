// routes/eventRoutes.js
const express = require('express');
const router = express.Router();
const eventController = require('../../controllers/events/eventController');
const { protect } = require('../../middleware/authMiddleware');

router.get('/getAllEvents', eventController.getAllEvents);

// Protect all routes
router.use(protect);

// Create events with different booking types
router.post('/createEventWithLayout', eventController.createEventWithLayout);
router.put('/updateEventWithLayout/:id', eventController.updateEventWithLayout);
router.post('/createEventWithTickets', eventController.createEventWithTickets);
router.put('/updateEventWithTickets/:id', eventController.updateEventWithTickets);
router.post('/bookTickets/:eventId', eventController.bookTickets);
router.post('/bookSeat/:eventId', eventController.bookSeat);
router.get('/getMyEvents', eventController.getMyEvents);
router.delete('/:id', eventController.deleteEvent);

module.exports = router;