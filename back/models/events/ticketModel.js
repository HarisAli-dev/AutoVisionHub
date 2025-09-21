const mongoose = require('mongoose');

//ticket model
const ticketSchema = new mongoose.Schema({
    ticketNumber: { type: Number, required: true },
    booking: { type: mongoose.Schema.Types.ObjectId, ref: 'Booking' },
    isBooked: { type: Boolean, default: false }
}, { timestamps: true });

const Ticket = mongoose.model('Ticket', ticketSchema);

module.exports = Ticket;
