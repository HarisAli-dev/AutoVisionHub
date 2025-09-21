// config/socket.js
let io;

// Initialize Socket.IO instance
module.exports = {
  init: (httpServer) => {
    io = require('socket.io')(httpServer, {
      cors: {
        origin: '*', // Update this to match your frontend URL in production
        methods: ['GET', 'POST'],
        credentials: true
      }
    });
    return io;
  },
  getIO: () => {
    if (!io) {
      throw new Error('Socket.io not initialized!');
    }
    return io;
  }
};
