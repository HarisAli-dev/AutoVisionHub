const mongoose = require('mongoose');

const eventSchema = new mongoose.Schema({
    eventName: { type: String, required: true },
    images: [{ type: String, required: true }],
    eventDescription: { type: String, required: true },
    eventDateTime: { type: Date, required: true },
    eventLocation: { type: String, required: true },
    ticketPrice: { type: Number },
    bookingType: { type: String, enum: ['seat', 'ticket'], required: true },
    createdBy: { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true },
    ticketList: [{ type: mongoose.Schema.Types.ObjectId, ref: 'Ticket' }],
    layout: { type: mongoose.Schema.Types.ObjectId, ref: 'Layout' },
}, { timestamps: true });

const Event = mongoose.model('Event', eventSchema);
module.exports = Event;