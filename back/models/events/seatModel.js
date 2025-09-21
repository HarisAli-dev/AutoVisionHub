const mongoose = require('mongoose');

const seatSchema = new mongoose.Schema({
    seatNumber: { type: Number, required: true },
    gridX: { type: Number, required: true },
    gridY: { type: Number, required: true },
    state: { 
        type: String, 
        enum: ['empty', 'booked', 'reserved'], 
        default: 'empty' 
    },
    booking: { type: mongoose.Schema.Types.ObjectId, ref: 'Booking' },
    isBooked: { type: Boolean, default: false }
}, { timestamps: true });

const Seat = mongoose.model('Seat', seatSchema);

module.exports = Seat;