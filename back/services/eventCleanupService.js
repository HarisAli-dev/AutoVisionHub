const cron = require('node-cron');
const Event = require('../models/events/eventModel');
const Seat = require('../models/events/seatModel');
const Ticket = require('../models/events/ticketModel');
const Layout = require('../models/events/layoutModel');
const Booking = require('../models/events/bookingModel');
const mongoose = require('mongoose');

class EventCleanupService {
    constructor() {
        this.isRunning = false;
    }

    // Start the cleanup service - runs every hour
    start() {
        if (this.isRunning) {
            console.log('Event cleanup service is already running');
            return;
        }

        // Schedule to run every hour
        cron.schedule('0 * * * *', async () => {
            console.log('Running event cleanup service...');
            await this.cleanupExpiredEvents();
        });

        // Also run once on startup
        this.cleanupExpiredEvents();

        this.isRunning = true;
        console.log('Event cleanup service started - will run every hour');
    }

    async cleanupExpiredEvents() {
        const session = await mongoose.startSession();
        session.startTransaction();

        try {
            const now = new Date();
            
            // Calculate date 5 days ago
            const fiveDaysAgo = new Date(now);
            fiveDaysAgo.setDate(fiveDaysAgo.getDate() - 5);
            
            // Find all events where eventDateTime was more than 5 days ago
            const expiredEvents = await Event.find({
                eventDateTime: { $lt: fiveDaysAgo }
            }).session(session);

            console.log(`Found ${expiredEvents.length} expired event(s) to clean up`);

            for (const event of expiredEvents) {
                console.log(`Deleting expired event: ${event.eventName} (${event._id})`);

                // Delete all bookings associated with this event
                await Booking.deleteMany({ eventId: event._id }).session(session);

                // Handle event-specific data deletion
                if (event.bookingType === 'ticket' && event.ticketList.length > 0) {
                    // Delete all tickets listed in the event
                    await Ticket.deleteMany({ _id: { $in: event.ticketList } }).session(session);
                }

                if (event.bookingType === 'seat' && event.layout) {
                    // Find the associated layout
                    const layout = await Layout.findById(event.layout).session(session);
                    if (layout && layout.seatList.length > 0) {
                        // Delete all seats listed in the layout
                        await Seat.deleteMany({ _id: { $in: layout.seatList } }).session(session);
                    }
                    // Delete the layout itself
                    if (layout) {
                        await Layout.findByIdAndDelete(layout._id).session(session);
                    }
                }

                // Finally, delete the event itself
                await Event.findByIdAndDelete(event._id).session(session);

                console.log(`Successfully deleted expired event: ${event.eventName}`);
            }

            await session.commitTransaction();
            session.endSession();

            if (expiredEvents.length > 0) {
                console.log(`Event cleanup completed: ${expiredEvents.length} expired event(s) deleted`);
            }

        } catch (error) {
            await session.abortTransaction();
            session.endSession();
            console.error('Error during event cleanup:', error);
        }
    }
}

module.exports = new EventCleanupService();
