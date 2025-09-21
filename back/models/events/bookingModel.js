const mongoose = require('mongoose');

const bookingSchema = new mongoose.Schema({
    userId: { type: String},
    userName: { type: String },
    userEmail: { type: String },
    userPhoneNumber: { type: String },
    eventId: { type: mongoose.Schema.Types.ObjectId, ref: 'Event' },
    bookingDate: { type: Date, default: Date.now },
    bookingType: { type: String , required: true}, // 'ticket' or 'seat'
    ticketOrSeatNumber: { type: Number , required: true},
}, { timestamps: true });

const Booking = mongoose.model('Booking', bookingSchema);
module.exports = Booking;
