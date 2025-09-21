const mongoose = require('mongoose');


const layoutSchema = new mongoose.Schema({
    layoutName: { type: String, required: true },
    gridWidth: { type: Number, required: true },
    gridHeight: { type: Number, required: true },
    seatList: [{ type: mongoose.Schema.Types.ObjectId, ref: 'Seat' }]
}, { timestamps: true });


const Layout = mongoose.model('Layout', layoutSchema);

module.exports =Layout;
