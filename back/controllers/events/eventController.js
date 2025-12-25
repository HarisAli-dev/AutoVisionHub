// controllers/eventController.js
const Event= require('../../models/events/eventModel');
const Seat = require('../../models/events/seatModel');
const Ticket = require('../../models/events/ticketModel');
const Layout = require('../../models/events/layoutModel');
const Booking = require('../../models/events/bookingModel');
const User = require('../../models/users/userModel');
const rsvpEmailService = require('../../services/rsvpEmailService');

const mongoose = require('mongoose');


exports.deleteEvent = async (req, res) => {
    const { id } = req.params;

    // A session is required to use transactions
    const session = await mongoose.startSession();
    session.startTransaction();

    try {
        // Step 1: Find the event document
        const event = await Event.findById(id).session(session);
        if (!event) {
            await session.abortTransaction();
            session.endSession();
            return res.status(404).json({ message: 'Event not found' });
        }

        // Step 2: Delete all bookings associated with this event
        await Booking.deleteMany({ eventId: id }).session(session);

        // Step 3: Handle event-specific data deletion
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
            if(layout) {
                await Layout.findByIdAndDelete(layout._id).session(session);
            }
        }

        // Step 4: Finally, delete the event itself
        await Event.findByIdAndDelete(id).session(session);

        // If all operations were successful, commit the transaction
        await session.commitTransaction();
        session.endSession();

        res.status(200).json({ message: 'Event and all associated data deleted successfully' });

    } catch (error) {
        // If any error occurs, abort the transaction to roll back all changes
        await session.abortTransaction();
        session.endSession();
        console.error('Transaction aborted due to an error:', error);
        res.status(500).json({ message: 'Failed to delete event. Operation was rolled back.' });
    }
};

// Create Event with Layout
exports.createEventWithLayout = async (req, res) => {
    try {
        const { eventName, images, eventDescription, eventDateTime, ticketPrice, eventLocation, layout } = req.body;
        const userId = req.user.id;

        // Validate required fields
        if (!eventName || !images || !eventDescription || !eventDateTime || !eventLocation || !layout) {
            return res.status(400).json({
                success: false,
                message: 'All fields are required'
            });
        }
        //check if event name already exists
        const existingEvent = await Event.findOne({ eventName });
        if (existingEvent) {
            return res.status(400).json({
                success: false,
                message: 'Event with this name already exists'
            });
        }

        // Create layout first
        // Create seats first as separate documents
        const seatPromises = layout.seatList.map(seatData => {
            const seat = new Seat({
                seatNumber: seatData.seatNumber,
                gridX: seatData.gridX,
                gridY: seatData.gridY,
                state: seatData.state || 'empty',
                booking: null,
                isBooked: false
            });
            return seat.save();
        });

        const savedSeats = await Promise.all(seatPromises);

        // Create layout with seat references
        const newLayout = new Layout({
            layoutName: layout.layoutName,
            gridWidth: layout.gridWidth,
            gridHeight: layout.gridHeight,
            seatList: savedSeats.map(seat => seat._id) // Array of ObjectIds
        });

        const savedLayout = await newLayout.save();

        // Create event
        const newEvent = new Event({
            eventName,
            images,
            eventDescription,
            eventDateTime: new Date(eventDateTime),
            eventLocation,
            ticketPrice,
            bookingType: 'seat',
            createdBy: userId,
            layout: savedLayout._id
        });

        const savedEvent = await newEvent.save();

        // Populate the layout in the response
        const populatedEvent = await Event.findById(savedEvent._id).populate('layout');

        res.status(201).json({
            success: true,
            message: 'Event created successfully with layout',
            data: populatedEvent
        });

    } catch (error) {
        console.error('Error creating event with layout:', error);
        res.status(500).json({
            success: false,
            message: 'Internal server error',
            error: error.message
        });
    }
};

//update Event with Layout
exports.updateEventWithLayout = async (req, res) => {
    try {
        const { id } = req.params;
        const { eventName, images, eventDescription, eventDateTime, eventLocation, ticketPrice } = req.body;
        const userId = req.user.id;

        // Validate required fields (layout is no longer required since it won't be updated)
        if (!eventName || !images || !eventDescription || !eventDateTime || !eventLocation) {
            return res.status(400).json({
                success: false,
                message: 'All fields are required'
            });
        }

        // Find the event and verify ownership
        const existingEvent = await Event.findById(id);
        if (!existingEvent) {
            return res.status(404).json({
                success: false,
                message: 'Event not found'
            });
        }

        if (existingEvent.createdBy.toString() !== userId) {
            return res.status(403).json({
                success: false,
                message: 'You are not authorized to update this event'
            });
        }

        // Check if event name already exists (excluding current event)
        const duplicateEvent = await Event.findOne({ 
            eventName, 
            _id: { $ne: id } 
        });
        if (duplicateEvent) {
            return res.status(400).json({
                success: false,
                message: 'Event with this name already exists'
            });
        }

        // Update event details only (layout remains unchanged)
        const updatedEvent = await Event.findByIdAndUpdate(
            id,
            {
                eventName,
                images,
                eventDescription,
                eventDateTime: new Date(eventDateTime),
                eventLocation,
                ticketPrice
            },
            { new: true }
        ).populate({
            path: 'layout',
            populate: {
                path: 'seatList'
            }
        });

        res.status(200).json({
            success: true,
            message: 'Event updated successfully',
            data: updatedEvent
        });

    } catch (error) {
        console.error('Error updating event with layout:', error);
        res.status(500).json({
            success: false,
            message: 'Internal server error',
            error: error.message
        });
    }
};

// Update Event with Tickets
exports.updateEventWithTickets = async (req, res) => {
    try {
        const { id } = req.params;
        const { eventName, images, eventDescription, eventDateTime, eventLocation, totalTickets, ticketPrice } = req.body;
        const userId = req.user.id;

        // Validate required fields
        if (!eventName || !images || !eventDescription || !eventDateTime || !eventLocation || !totalTickets) {
            return res.status(400).json({
                success: false,
                message: 'All fields are required'
            });
        }

        // Find the event and verify ownership
        const existingEvent = await Event.findById(id);
        if (!existingEvent) {
            return res.status(404).json({
                success: false,
                message: 'Event not found'
            });
        }

        if (existingEvent.createdBy.toString() !== userId) {
            return res.status(403).json({
                success: false,
                message: 'You are not authorized to update this event'
            });
        }

        // Check if event name already exists (excluding current event)
        const duplicateEvent = await Event.findOne({ 
            eventName, 
            _id: { $ne: id } 
        });
        if (duplicateEvent) {
            return res.status(400).json({
                success: false,
                message: 'Event with this name already exists'
            });
        }

        // Start transaction for atomic updates
        const session = await mongoose.startSession();
        session.startTransaction();

        try {
            // Delete old tickets that are not booked
            const oldTickets = await Ticket.find({ 
                _id: { $in: existingEvent.ticketList },
                isBooked: false 
            }).session(session);
            
            await Ticket.deleteMany({ 
                _id: { $in: oldTickets.map(ticket => ticket._id) }
            }).session(session);

            // Keep booked tickets
            const bookedTickets = await Ticket.find({ 
                _id: { $in: existingEvent.ticketList },
                isBooked: true 
            }).session(session);

            // Create new tickets for the updated count
            const newTicketPromises = [];
            const startingTicketNumber = bookedTickets.length + 1;
            
            if (Array.isArray(totalTickets)) {
                // If totalTickets is an array of ticket objects
                totalTickets.forEach((ticketData, index) => {
                    const ticket = new Ticket({
                        ticketNumber: ticketData.ticketNumber || (startingTicketNumber + index),
                        isBooked: false,
                        booking: null
                    });
                    newTicketPromises.push(ticket.save({ session }));
                });
            } else {
                // If totalTickets is a number, create remaining tickets
                const remainingTicketsNeeded = totalTickets - bookedTickets.length;
                for (let i = 0; i < remainingTicketsNeeded; i++) {
                    const ticket = new Ticket({
                        ticketNumber: startingTicketNumber + i,
                        isBooked: false,
                        booking: null
                    });
                    newTicketPromises.push(ticket.save({ session }));
                }
            }

            const savedNewTickets = await Promise.all(newTicketPromises);

            // Update event with new ticket list (booked + new tickets)
            const allTicketIds = [
                ...bookedTickets.map(ticket => ticket._id),
                ...savedNewTickets.map(ticket => ticket._id)
            ];

            const updatedEvent = await Event.findByIdAndUpdate(
                id,
                {
                    eventName,
                    images,
                    eventDescription,
                    eventDateTime: new Date(eventDateTime),
                    eventLocation,
                    ticketPrice: ticketPrice || 0,
                    totalTickets: allTicketIds.length,
                    ticketList: allTicketIds
                },
                { new: true, session }
            ).populate('ticketList');

            await session.commitTransaction();
            session.endSession();

            res.status(200).json({
                success: true,
                message: 'Event updated successfully',
                data: updatedEvent
            });

        } catch (error) {
            await session.abortTransaction();
            session.endSession();
            throw error;
        }

    } catch (error) {
        console.error('Error updating event with tickets:', error);
        res.status(500).json({
            success: false,
            message: 'Internal server error',
            error: error.message
        });
    }
};

// Book Tickets
exports.bookTickets = async (req, res) => {
    const { eventId } = req.params;
    const { numberOfTickets , userName , userEmail , userPhone } = req.body;
    const userId = req.user.id;

    let session;
    try {
        session = await mongoose.startSession();
        session.startTransaction();

        // Find the event
        const event = await Event.findById(eventId).populate('ticketList');
        if (!event) {
            await session.abortTransaction();
            session.endSession();
            return res.status(404).json({
                success: false,
                message: 'Event not found'
            });
        }

        // Check if tickets are available and sort them by ticket number
        const availableTickets = event.ticketList
            .filter(ticket => !ticket.isBooked)
            .sort((a, b) => a.ticketNumber - b.ticketNumber); // Sort by ticket number ascending
            
        if (availableTickets.length < numberOfTickets) {
            await session.abortTransaction();
            session.endSession();
            return res.status(400).json({
                success: false,
                message: `Not enough available tickets. Only ${availableTickets.length} tickets available.`
            });
        }

        // Book the tickets (takes the lowest numbered available tickets)
        const ticketsToBook = availableTickets.slice(0, numberOfTickets);
        const bookedTicketNumbers = [];
        
        const bookingPromises = ticketsToBook.map(async (ticket) => {
            // Create and save a booking for each ticket
            const newBooking = new Booking({
                userId,
                userName,
                userEmail,
                userPhoneNumber: userPhone,
                eventId,
                bookingType: 'ticket',
                ticketOrSeatNumber: ticket.ticketNumber
            });
            const savedBooking = await newBooking.save({ session });
            
            ticket.isBooked = true;
            ticket.booking = savedBooking._id;
            bookedTicketNumbers.push(ticket.ticketNumber);
            return ticket.save({ session });
        });

        await Promise.all(bookingPromises);

        await session.commitTransaction();
        session.endSession();

        // Send RSVP confirmation email
        try {
            const user = await User.findById(userId);
            const firstBooking = await Booking.findOne({ 
                userId, 
                eventId, 
                ticketOrSeatNumber: bookedTicketNumbers[0] 
            });
            await rsvpEmailService.sendRSVPConfirmation(firstBooking, event, user);
            console.log(`RSVP email sent to ${userEmail}`);
        } catch (emailError) {
            console.error('Error sending RSVP email:', emailError);
            // Don't fail the booking if email fails
        }

        res.status(200).json({
            success: true,
            message: 'Tickets booked successfully',
        });

    } catch (error) {
        if (session) {
            await session.abortTransaction();
            session.endSession();
        }
        console.error('Error booking tickets:', error);
        res.status(500).json({
            success: false,
            message: 'Internal server error',
            error: error.message
        });
    }
};

// Book Seats
exports.bookSeat = async (req, res) => {
    const { eventId } = req.params;
    const { seatNumber , userName , userEmail , userPhone } = req.body;
    const userId = req.user.id;

    const session = await mongoose.startSession();
    session.startTransaction();

    try {
        console.log(`Attempting to book seat ${seatNumber} for user ${userId} on event ${eventId}`);
        
        // Find the event
        const event = await Event.findById(eventId).populate({
            path: 'layout',
            populate: {
                path: 'seatList',
                populate: 'booking' // Populate booking inside each seat
            }
        }).session(session);

        if (!event) {
            await session.abortTransaction();
            session.endSession();
            return res.status(404).json({
                success: false,
                message: 'Event not found'
            });
        }

        if (!event.layout || !event.layout.seatList) {
            await session.abortTransaction();
            session.endSession();
            return res.status(400).json({
                success: false,
                message: 'Event layout not found'
            });
        }

        // Check if seat is available
        const seat = event.layout.seatList.find(s => s.seatNumber === seatNumber);
        if (!seat) {
            await session.abortTransaction();
            session.endSession();
            return res.status(400).json({
                success: false,
                message: 'Seat not found'
            });
        }

        if (seat.isBooked) {
            await session.abortTransaction();
            session.endSession();
            return res.status(400).json({
                success: false,
                message: 'Seat is already booked'
            });
        }

        // Create and save the booking first
        const newBooking = new Booking({
            userId,
            userName,
            userEmail,
            userPhoneNumber: userPhone,
            eventId,
            bookingType: 'seat',
            ticketOrSeatNumber: seatNumber
        });
        const savedBooking = await newBooking.save({ session });

        // Book the seat
        seat.state = 'booked';
        seat.isBooked = true;
        seat.booking = savedBooking._id;
        
        await seat.save({ session });

        await session.commitTransaction();
        session.endSession();
        
        console.log(`Seat ${seatNumber} booked successfully for user ${userId}`);
        
        // Send RSVP confirmation email
        try {
            const user = await User.findById(userId);
            await rsvpEmailService.sendRSVPConfirmation(savedBooking, event, user);
            console.log(`RSVP email sent to ${userEmail}`);
        } catch (emailError) {
            console.error('Error sending RSVP email:', emailError);
            // Don't fail the booking if email fails
        }
        
        res.status(200).json({
            success: true,
            message: 'Seat booked successfully'
        });

    } catch (error) {
        await session.abortTransaction();
        session.endSession();
        console.error('Error booking seats:', error);
        res.status(500).json({
            success: false,
            message: 'Internal server error',
            error: error.message
        });
    }
};

// Create Event with Tickets
exports.createEventWithTickets = async (req, res) => {
    try {
        const { eventName, images, eventDescription, eventDateTime, eventLocation, totalTickets, ticketPrice } = req.body;
        const userId = req.user.id;
        // Validate required fields
        if (!eventName || !images || !eventDescription || !eventDateTime || !eventLocation || !totalTickets) {
            console.log("Validation failed: Missing required fields");
            return res.status(400).json({
                success: false,
                message: 'All fields are required'
            });
        }
        //check if event name already exists
        const existingEvent = await Event.findOne({ eventName });
        if (existingEvent) {
            return res.status(400).json({
                success: false,
                message: 'Event with this name already exists'
            });
        }
        // Create event
        const newEvent = new Event({
            eventName,
            images,
            eventDescription,
            eventDateTime: new Date(eventDateTime),
            eventLocation,
            bookingType: 'ticket',
            ticketPrice: ticketPrice || 0,
            totalTickets: Array.isArray(totalTickets) ? totalTickets.length : totalTickets,
            createdBy: userId
        });

        const savedEvent = await newEvent.save();

        // Create tickets
        const ticketPromises = [];
        if (Array.isArray(totalTickets)) {
            // If totalTickets is an array of ticket objects
            totalTickets.forEach((ticketData, index) => {
                const ticket = new Ticket({
                    ticketNumber: ticketData.ticketNumber || index + 1,
                    isBooked: false,
                    booking: null
                });
                ticketPromises.push(ticket.save());
            });
        } else {
            // If totalTickets is a number
            for (let i = 1; i <= totalTickets; i++) {
                const ticket = new Ticket({
                    ticketNumber: i,
                    isBooked: false,
                    booking: null
                });
                ticketPromises.push(ticket.save());
            }
        }

        const savedTickets = await Promise.all(ticketPromises);

        // Update event with ticket IDs
        savedEvent.ticketList = savedTickets.map(ticket => ticket._id);
        await savedEvent.save();

        // Populate tickets in the response
        const populatedEvent = await Event.findById(savedEvent._id).populate('ticketList');
        res.status(200).json({
            success: true,
            message: 'Event created successfully with tickets',
            data: populatedEvent
        });

    } catch (error) {
        console.error('Error creating event with tickets:', error);
        res.status(500).json({
            success: false,
            message: 'Internal server error',
            error: error.message
        });
    }
};

// Get Events created by the logged-in user
exports.getMyEvents = async (req, res) => {
    try {
        const userId = req.user.id;
        
        // Use populate directly in the query for better performance
        const events = await Event.find({ createdBy: userId })
            .populate({
                path: 'ticketList',
                populate: {
                    path: 'booking'
                }
            })
            .populate({
                path: 'layout',
                populate: {
                    path: 'seatList',
                    populate: {
                        path: 'booking'
                    }
                }
            })
            .populate('createdBy', 'name email phoneNumber');

        // Debug logging to see what's happening
        console.log('Found events:', events.length);
        events.forEach((event, index) => {
            console.log(`Event ${index + 1}:`, {
                name: event.eventName,
                bookingType: event.bookingType,
                hasLayout: !!event.layout,
                layoutId: event.layout?._id,
                layoutName: event.layout?.layoutName,
                seatListLength: event.layout?.seatList?.length || 0,
                ticketListLength: event.ticketList?.length || 0
            });
        });
        res.status(200).json({
            success: true,
            data: events
        });
    } catch (error) {
        console.error('Error fetching user events:', error);
        res.status(500).json({
            success: false,
            message: 'Internal server error',
            error: error.message
        });
    }
};

// Get all Events (for public viewing)
exports.getAllEvents = async (req, res) => {
    try {
        // Use populate directly in the query for better performance
        const events = await Event.find()
            .populate('createdBy')
            .populate({
                path: 'ticketList',
                populate: {
                    path: 'booking'
                }
            })
            .populate({
                path: 'layout',
                populate: {
                    path: 'seatList',
                    populate: {
                        path: 'booking'
                    }
                }
            });
        res.status(200).json({
            success: true,
            data: events
        });
    } catch (error) {
        console.error('Error fetching all events:', error);
        res.status(500).json({
            success: false,
            message: 'Internal server error',
            error: error.message
        });
    }
};

// Get all bookings for a specific event
exports.getEventBookings = async (req, res) => {
    const { eventId } = req.params;
    const userId = req.user.id;

    try {
        // Find the event and verify ownership
        const event = await Event.findById(eventId);
        if (!event) {
            return res.status(404).json({
                success: false,
                message: 'Event not found'
            });
        }

        if (event.createdBy.toString() !== userId) {
            return res.status(403).json({
                success: false,
                message: 'You are not authorized to view bookings for this event'
            });
        }

        let bookings = [];

        if (event.bookingType === 'seat') {
            // Fetch bookings from seats
            const layout = await Layout.findById(event.layout).populate({
                path: 'seatList',
                populate: {
                    path: 'booking'
                }
            });
            if (layout && layout.seatList) {
                const bookedSeats = layout.seatList.filter(seat => seat.isBooked && seat.booking);
                bookings = bookedSeats.map(seat => ({
                    userId: seat.booking.userId,
                    userName: seat.booking.userName,
                    userEmail: seat.booking.userEmail,
                    userPhoneNumber: seat.booking.userPhoneNumber,
                    eventId: seat.booking.eventId,
                    bookingType: 'seat',
                    ticketOrSeatNumber: seat.seatNumber,
                    bookingDate: seat.booking.bookingDate,
                    createdAt: seat.booking.createdAt,
                    updatedAt: seat.booking.updatedAt,
                }));
            }
        } else if (event.bookingType === 'ticket') {
            // Fetch bookings from tickets
            const tickets = await Ticket.find({ 
                _id: { $in: event.ticketList }, 
                isBooked: true 
            }).populate('booking');
            bookings = tickets.filter(ticket => ticket.booking).map(ticket => ({
                userId: ticket.booking.userId,
                userName: ticket.booking.userName,
                userEmail: ticket.booking.userEmail,
                userPhoneNumber: ticket.booking.userPhoneNumber,
                eventId: ticket.booking.eventId,
                bookingType: 'ticket',
                ticketOrSeatNumber: ticket.ticketNumber,
                bookingDate: ticket.booking.bookingDate,
                createdAt: ticket.booking.createdAt,
                updatedAt: ticket.booking.updatedAt,
            }));
        }

        res.status(200).json({
            success: true,
            data: bookings
        });

    } catch (error) {
        console.error('Error fetching event bookings:', error);
        res.status(500).json({
            success: false,
            message: 'Internal server error',
            error: error.message
        });
    }
};

// Delete a booking
exports.deleteBooking = async (req, res) => {
    const { eventId } = req.params;
    const { bookingType, ticketOrSeatNumber } = req.body;
    const userId = req.user.id;

    const session = await mongoose.startSession();
    session.startTransaction();

    try {
        // Find the event and verify ownership
        const event = await Event.findById(eventId).session(session);
        if (!event) {
            await session.abortTransaction();
            session.endSession();
            return res.status(404).json({
                success: false,
                message: 'Event not found'
            });
        }

        if (event.createdBy.toString() !== userId) {
            await session.abortTransaction();
            session.endSession();
            return res.status(403).json({
                success: false,
                message: 'You are not authorized to delete bookings for this event'
            });
        }

        if (bookingType === 'seat') {
            // Find and update the seat
            const layout = await Layout.findById(event.layout).populate('seatList').session(session);
            if (!layout) {
                await session.abortTransaction();
                session.endSession();
                return res.status(404).json({
                    success: false,
                    message: 'Event layout not found'
                });
            }

            const seat = layout.seatList.find(s => s.seatNumber === ticketOrSeatNumber);
            if (!seat) {
                await session.abortTransaction();
                session.endSession();
                return res.status(404).json({
                    success: false,
                    message: 'Seat not found'
                });
            }

            if (!seat.isBooked) {
                await session.abortTransaction();
                session.endSession();
                return res.status(400).json({
                    success: false,
                    message: 'Seat is not booked'
                });
            }

            // Delete the booking document
            if (seat.booking) {
                await Booking.findByIdAndDelete(seat.booking).session(session);
            }

            // Reset seat booking
            seat.state = 'empty';
            seat.isBooked = false;
            seat.booking = null;
            await seat.save({ session });

        } else if (bookingType === 'ticket') {
            // Find and update the ticket
            const ticket = await Ticket.findOne({
                _id: { $in: event.ticketList },
                ticketNumber: ticketOrSeatNumber
            }).session(session);

            if (!ticket) {
                await session.abortTransaction();
                session.endSession();
                return res.status(404).json({
                    success: false,
                    message: 'Ticket not found'
                });
            }

            if (!ticket.isBooked) {
                await session.abortTransaction();
                session.endSession();
                return res.status(400).json({
                    success: false,
                    message: 'Ticket is not booked'
                });
            }

            // Delete the booking document
            if (ticket.booking) {
                await Booking.findByIdAndDelete(ticket.booking).session(session);
            }

            // Reset ticket booking
            ticket.isBooked = false;
            ticket.booking = null;
            await ticket.save({ session });
        } else {
            await session.abortTransaction();
            session.endSession();
            return res.status(400).json({
                success: false,
                message: 'Invalid booking type'
            });
        }

        await session.commitTransaction();
        session.endSession();

        res.status(200).json({
            success: true,
            message: 'Booking deleted successfully'
        });

    } catch (error) {
        await session.abortTransaction();
        session.endSession();
        console.error('Error deleting booking:', error);
        res.status(500).json({
            success: false,
            message: 'Internal server error',
            error: error.message
        });
    }
};
