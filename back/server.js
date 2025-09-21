const express = require('express');
const cors = require('cors');
const http = require('http');
const connectDB = require('./config/db');
const socketConfig = require('./config/socket');
require('dotenv').config();
const app = express();
const server = http.createServer(app);
// Initialize socket.io with our custom configuration
const io = socketConfig.init(server);
connectDB();

app.use(cors({
    origin: '*', // Add your frontend URL
    credentials: true
  }));
app.use(express.json());

app.get('/', (req, res) => {
    res.send('<h1>Welcome to AutoVisionHub API</h1><p>Server is running successfully!</p>');
});

// Add the user route for handling user search
app.use('/api/users', require('./routes/users/userRoutes'));
app.use('/api/auth', require('./routes/users/authRoutes'));
app.use('/api/chat', require('./routes/chats/chatRoutes'));
app.use('/api/chatMessage', require('./routes/chats/chatMessageRoutes'));
app.use('/api/group', require('./routes/groups/groupRoutes'));
app.use('/api/groupMessage', require('./routes/groups/GroupMessageRoutes'));
app.use('/api/poll', require('./routes/groups/pollRoutes'));
app.use('/api/event', require('./routes/events/eventRoutes'));
app.use('/api/media', require('./routes/mediaRoutes'));
app.use('/api/payment', require('./routes/paymentRoutes'));

app.get('/api/test', (req, res) => {
    res.json({ message: 'Server is working!' });
  });

// Listen for new messages and other real-time events
io.on('connection', (socket) => {
  console.log('A user connected: ' + socket.id);

  // Join a room with userId for private messages
  socket.on('joinUserRoom', (userId) => {
    socket.join(userId);
    console.log(`Socket ${socket.id} joined user room: ${userId}`);
  });
  
  // Join a group room
  socket.on('join_group', (data) => {
    const { groupId } = data;
    socket.join(groupId);
    console.log(`Socket ${socket.id} joined group room: ${groupId}`);
  });

  // Leave a group room
  socket.on('leave_group', (data) => {
    const { groupId } = data;
    socket.leave(groupId);
    console.log(`Socket ${socket.id} left group room: ${groupId}`);
  });
  
  // Join a chat room (for direct messages)
  socket.on('joinChatRoom', (chatId) => {
    socket.join(chatId);
    console.log(`Socket ${socket.id} joined chat room: ${chatId}`);
  });
  
  // Handle group message events
  socket.on('group_message', (messageData) => {
    // Broadcast message to all users in the group
    socket.to(messageData.groupId).emit('new_group_message', messageData);
  });

  // Handle group message deleted
  socket.on('group_message_deleted', (data) => {
    const { messageId } = data;
    // Broadcast to group that message was deleted
    socket.broadcast.emit('group_message_deleted', { messageId });
  });

  // Handle group message edited
  socket.on('group_message_edited', (messageData) => {
    // Broadcast edited message to group
    socket.to(messageData.groupId).emit('group_message_updated', messageData);
  });

  // Handle poll voting
  socket.on('poll_voted', (data) => {
    const { pollId, optionIndex, poll } = data;
    // Broadcast poll update to group if it's a group poll
    if (poll.groupId) {
      socket.to(poll.groupId).emit('poll_updated', poll);
    }
  });

  // Handle poll deletion
  socket.on('poll_deleted', (data) => {
    const { pollId } = data;
    socket.broadcast.emit('poll_deleted', { pollId });
  });

  // Handle mark group as read
  socket.on('mark_group_read', (data) => {
    const { groupId, userId } = data;
    // Broadcast to group that user has read messages
    socket.to(groupId).emit('group_read_by_user', { userId, groupId });
  });
  
  // Handle user typing indicator for groups
  socket.on('group_typing', ({ groupId, userId, userName }) => {
    // Broadcast to everyone in the group except the sender
    socket.to(groupId).emit('user_typing_in_group', { userId, userName, groupId });
  });
  
  // Handle user stopped typing for groups
  socket.on('group_stop_typing', ({ groupId, userId }) => {
    socket.to(groupId).emit('user_stopped_typing_in_group', { userId, groupId });
  });

  // Handle message reactions
  socket.on('message_reaction', (data) => {
    const { messageId, reaction, userId } = data;
    socket.broadcast.emit('message_reaction_added', { messageId, reaction, userId });
  });
  
  // Handle user typing indicator for direct chats
  socket.on('typing', ({ chatId, userId, userName }) => {
    // Broadcast to everyone in the chat except the sender
    socket.to(chatId).emit('userTyping', { userId, userName, chatId });
  });
  
  // Handle user stopped typing for direct chats
  socket.on('stopTyping', ({ chatId, userId }) => {
    socket.to(chatId).emit('userStoppedTyping', { userId, chatId });
  });
  
  // Handle message read receipts from client
  socket.on('markAsRead', async ({ messageId, userId }) => {
    try {
      // Find the message and update its status
      const Message = require('./models/chats/chatMessageModel');
      const message = await Message.findById(messageId);
      
      if (message && message.senderId.toString() !== userId && message.status !== 'seen') {
        message.status = 'seen';
        await message.save();
        
        // Notify the sender
        socket.to(message.senderId.toString()).emit('messageStatusUpdated', {
          messageId: message._id,
          status: 'seen',
          updatedBy: userId
        });
      }
    } catch (error) {
      console.error('Error updating message status via socket:', error);
    }
  });
  
  socket.on('disconnect', () => {
    console.log('User disconnected');
  });
});

server.listen(process.env.PORT || 8080, '0.0.0.0', () => {
  console.log(`Server is running`);
});
