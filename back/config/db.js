// config/db.js
const mongoose = require('mongoose');

const connectDB = async () => {
  try {
    await mongoose.connect("mongodb+srv://haris_ali:Veryvery_2@autovisionhub.revfieh.mongodb.net/?retryWrites=true&w=majority&appName=AutoVisionHub");
    console.log('MongoDB connected');
  } catch (error) {
    console.error('MongoDB connection error:', error);
    process.exit(1);
  }
};

module.exports = connectDB;
