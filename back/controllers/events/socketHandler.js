// controllers/events/socketHandler.js

/**
 * Socket.IO event handlers for live streaming
 */

const { liveStreamService } = require('../../services/liveStreamService');
const supportService = require('../../services/supportService');
const geminiChatbotService = require('../../services/geminiChatbotService');
const Event = require('../../models/events/eventModel');

class LiveStreamSocketHandler {
  constructor(io) {
    this.io = io;
    this.rooms = new Map(); // roomId -> { host, viewers: Set, chatMessages: [] }
  }

  /**
   * Setup socket event handlers
   */
  setupEventHandlers(socket) {
    console.log(`Socket connected: ${socket.id}`);

    // Live streaming room management
    socket.on('join_live_stream', (data) => this.handleJoinLiveStream(socket, data));
    socket.on('leave_live_stream', (data) => this.handleLeaveLiveStream(socket, data));
    
    // Recording status events
    socket.on('recording_started', (data) => this.handleRecordingStarted(socket, data));
    socket.on('recording_stopped', (data) => this.handleRecordingStopped(socket, data));
    
    // Chat events
    socket.on('send_live_stream_chat', (data) => this.handleSendChatMessage(socket, data));
    socket.on('get_chat_history', (data) => this.handleGetChatHistory(socket, data));
    
    // General room events
    socket.on('join', (roomId) => this.handleJoinRoom(socket, roomId));
    socket.on('leave', (roomId) => this.handleLeaveRoom(socket, roomId));
    
    // Disconnect handler
    socket.on('disconnect', () => this.handleDisconnect(socket));
  }

  /**
   * Handle user joining live stream room
   */
  async handleJoinLiveStream(socket, data) {
    const { roomId, userId, userName } = data;
    
    if (!roomId || !userId) {
      console.error('Invalid join_live_stream data:', data);
      return;
    }

    try {
      // Join socket room
      socket.join(roomId);
      socket.roomId = roomId;
      socket.userId = userId;
      
      // Initialize room if doesn't exist
      if (!this.rooms.has(roomId)) {
        this.rooms.set(roomId, { host: null, viewers: new Set(), chatMessages: [] });
      }
      
      const room = this.rooms.get(roomId);
      
      // Check if user is host (has permission to start streams for this room)
      const liveStream = await liveStreamService.getLiveStreamByRoomId(roomId);
      const isHost = liveStream && liveStream.hostId.toString() === userId;
      
      if (isHost) {
        room.host = { socketId: socket.id, userId, userName };
        console.log(`Host ${userName} (${userId}) joined live stream room: ${roomId}`);
      } else {
        room.viewers.add({ socketId: socket.id, userId, userName });
        console.log(`Viewer ${userName} (${userId}) joined live stream room: ${roomId}`);
      }
      
      // Notify room about user joining
      socket.to(roomId).emit('userJoinedStream', {
        userId,
        userName,
        isHost,
        viewerCount: room.viewers.size
      });
      
      // Send current viewer count to all in room
      this.io.to(roomId).emit('viewerCountChanged', {
        roomId,
        viewerCount: room.viewers.size
      });
      
      // Confirm join to the user
      socket.emit('joinedRoom', { roomId, isHost, viewerCount: room.viewers.size });
      
    } catch (error) {
      console.error('Error handling join_live_stream:', error);
      socket.emit('error', { message: 'Failed to join live stream' });
    }
  }

  /**
   * Handle user leaving live stream room
   */
  handleLeaveLiveStream(socket, data) {
    const { roomId, userId } = data;
    
    if (!roomId || !userId) {
      console.error('Invalid leave_live_stream data:', data);
      return;
    }

    this._removeUserFromRoom(socket, roomId, userId);
  }

  /**
   * Handle recording started by host
   */
  async handleRecordingStarted(socket, data) {
    const { roomId, hostId, timestamp } = data;
    
    if (!roomId || !hostId) {
      console.error('Invalid recording_started data:', data);
      return;
    }

    try {
      // Verify host permissions
      const liveStream = await liveStreamService.getLiveStreamByRoomId(roomId);
      if (!liveStream || liveStream.hostId.toString() !== hostId) {
        socket.emit('error', { message: 'Unauthorized to control recording' });
        return;
      }

      // Notify all viewers that recording started
      socket.to(roomId).emit('recordingStatusChanged', {
        roomId,
        status: 'recording',
        timestamp,
        hostId
      });

      console.log(`Recording started for room ${roomId} by host ${hostId}`);
      
    } catch (error) {
      console.error('Error handling recording_started:', error);
    }
  }

  /**
   * Handle recording stopped by host
   */
  async handleRecordingStopped(socket, data) {
    const { roomId, hostId, timestamp } = data;
    
    if (!roomId || !hostId) {
      console.error('Invalid recording_stopped data:', data);
      return;
    }

    try {
      // Verify host permissions
      const liveStream = await liveStreamService.getLiveStreamByRoomId(roomId);
      if (!liveStream || liveStream.hostId.toString() !== hostId) {
        socket.emit('error', { message: 'Unauthorized to control recording' });
        return;
      }

      // Notify all viewers that recording stopped and stream ended
      this.io.to(roomId).emit('liveStreamEnded', {
        roomId,
        message: 'The live stream has ended',
        timestamp,
        hostId
      });

      console.log(`Recording stopped for room ${roomId} by host ${hostId}`);
      
      // Clean up room after a short delay to allow clients to process
      setTimeout(() => {
        this._cleanupRoom(roomId);
      }, 1000);
      
    } catch (error) {
      console.error('Error handling recording_stopped:', error);
    }
  }

  /**
   * Handle sending chat message in live stream
   */
  async handleSendChatMessage(socket, data) {
    const { roomId, userId, userName, message, isBot = false } = data;
    
    console.log('\n🔔 === CHAT MESSAGE RECEIVED === 🔔');
    console.log('📋 Full data object:', JSON.stringify(data, null, 2));
    console.log('RoomId:', roomId);
    console.log('UserId:', userId);
    console.log('UserName:', userName);
    console.log('Message:', message);
    console.log('IsBot:', isBot);
    console.log('Timestamp:', new Date().toISOString());
    
    if (!roomId || !message) {
      console.error('Invalid send_live_stream_chat data:', data);
      return;
    }

    try {
      const chatMessage = {
        id: Date.now().toString() + Math.random().toString(36).substr(2, 9),
        senderId: userId || 'bot',
        senderName: userName || 'Bot',
        message: message.trim(),
        timestamp: new Date().toISOString(),
        isBot: isBot
      };

      // Store message in room if room exists
      if (this.rooms.has(roomId)) {
        const room = this.rooms.get(roomId);
        room.chatMessages.push(chatMessage);
        
        // Keep only last 100 messages
        if (room.chatMessages.length > 100) {
          room.chatMessages = room.chatMessages.slice(-100);
        }
      }

      // Broadcast message to all in room
      this.io.to(roomId).emit('new_live_stream_chat', chatMessage);
      
      console.log(`Chat message broadcast to room ${roomId}`);
      
      // Process for chatbot response if not from bot
      if (!isBot) {
        this._processChatbotResponse(roomId, message, userName, userId);
      }
      
    } catch (error) {
      console.error('Error handling send_live_stream_chat:', error);
    }
  }

  /**
   * Process message for potential chatbot response
   */
  async _processChatbotResponse(roomId, message, userName, userId) {
    try {
      console.log('\n=== CHATBOT PROCESSING START ===');
      
      // Get event details for context
      const liveStream = await liveStreamService.getLiveStreamByRoomId(roomId);
      if (!liveStream) {
        console.log('No live stream found for room:', roomId);
        return;
      }

      const event = await Event.findById(liveStream.eventId);
      if (!event) {
        console.log('No event found for live stream');
        return;
      }

      console.log('Event found:', event.eventName);

      // Get recent chat history from room
      const room = this.rooms.get(roomId);
      const recentMessages = room && room.chatMessages ? room.chatMessages.slice(-10) : [];
      
      console.log('Recent messages count:', recentMessages.length);

      // Process message with Gemini chatbot service
      const botResponseData = await geminiChatbotService.processLiveStreamMessage({
        message: message,
        userName: userName,
        userId: userId
      }, event);

      if (botResponseData) {
        console.log('✅ Bot response generated:', botResponseData.message);
        
        // Create bot message
        const botMessage = {
          id: Date.now().toString() + Math.random().toString(36).substr(2, 9),
          senderId: 'chatbot_ai',
          senderName: '🤖 AI Assistant',
          message: botResponseData.message,
          timestamp: new Date().toISOString(),
          isBot: true
        };

        // Store bot message in room
        if (this.rooms.has(roomId)) {
          const room = this.rooms.get(roomId);
          room.chatMessages.push(botMessage);
          
          // Keep only last 100 messages
          if (room.chatMessages.length > 100) {
            room.chatMessages = room.chatMessages.slice(-100);
          }
        }

        // Broadcast bot response to room with a slight delay
        setTimeout(() => {
          this.io.to(roomId).emit('new_live_stream_chat', botMessage);
          console.log('🤖 Bot message sent to room:', roomId);
        }, 1000); // 1 second delay to feel more natural
      } else {
        console.log('❌ No bot response generated');
      }


      
    } catch (error) {
      console.error('Error processing chatbot response:', error);
    }
  }



  /**
   * Handle getting chat history
   */
  handleGetChatHistory(socket, data) {
    const { roomId } = data;
    
    if (!roomId) {
      console.error('Invalid get_chat_history data:', data);
      return;
    }

    try {
      if (this.rooms.has(roomId)) {
        const room = this.rooms.get(roomId);
        socket.emit('chat_history', {
          roomId,
          messages: room.chatMessages || []
        });
      } else {
        socket.emit('chat_history', {
          roomId,
          messages: []
        });
      }
    } catch (error) {
      console.error('Error handling get_chat_history:', error);
    }
  }



  /**
   * Handle getting chat history for a room
   */
  handleGetChatHistory(socket, data) {
    const { roomId } = data;
    
    if (this.rooms.has(roomId)) {
      const room = this.rooms.get(roomId);
      socket.emit('chatHistory', {
        roomId,
        messages: room.chatMessages || []
      });
    } else {
      socket.emit('chatHistory', {
        roomId,
        messages: []
      });
    }
  }

  /**
   * Process message for chatbot response
   */
  async _processChatbotResponse(roomId, message, userId, userName) {
    try {
      console.log('🤖 Processing message for chatbot:', { message, userId, userName });

      // Skip if message is from bot
      if (userId === 'chatbot_ai' || userName?.includes('🤖')) {
        console.log('🤖 Skipping bot message');
        return;
      }

      // Check if message should trigger chatbot
      if (!geminiChatbotService.shouldRespond(message)) {
        console.log('❌ Message should not trigger bot');
        return;
      }

      console.log('✅ Message should trigger bot');

      // Get event context
      const event = await this._getEventFromRoomId(roomId);
      
      // Generate bot response with a slight delay for natural feel
      setTimeout(async () => {
        try {
          const botResponseData = await geminiChatbotService.processLiveStreamMessage({
            message,
            userName,
            userId
          }, event);

          if (botResponseData && botResponseData.message) {
            console.log('🤖 Bot response generated:', botResponseData.message);
            
            // Create bot message
            const botMessage = {
              id: Date.now() + Math.random(),
              message: botResponseData.message,
              userId: 'chatbot_ai',
              userName: '🤖 AI Assistant',
              timestamp: new Date(),
              isBot: true
            };

            // Store bot message in room history
            if (this.rooms.has(roomId)) {
              const room = this.rooms.get(roomId);
              room.chatMessages.push(botMessage);
            }

            // Send bot response to all users in the room (using same event as user messages)
            this.io.to(roomId).emit('new_live_stream_chat', botMessage);
            
            console.log('✅ Bot message sent to room:', roomId);
          }
        } catch (error) {
          console.error('❌ Error generating bot response:', error);
        }
      }, 1000); // 1-second delay for natural conversation feel

    } catch (error) {
      console.error('❌ Error processing chatbot response:', error);
    }
  }

  /**
   * Get event details from room ID
   */
  async _getEventFromRoomId(roomId) {
    try {
      // Try to find live stream by room ID
      const liveStream = await liveStreamService.getLiveStreamByRoomId(roomId);
      if (liveStream && liveStream.eventId) {
        return await Event.findById(liveStream.eventId);
      }
      return null;
    } catch (error) {
      console.error('Error getting event from room ID:', error);
      return null;
    }
  }

  /**
   * Handle joining general room (backward compatibility)
   */
  handleJoinRoom(socket, roomId) {
    if (roomId) {
      socket.join(roomId);
      socket.roomId = roomId;
      console.log(`Socket ${socket.id} joined room: ${roomId}`);
    }
  }

  /**
   * Handle leaving general room (backward compatibility)
   */
  handleLeaveRoom(socket, roomId) {
    if (roomId) {
      socket.leave(roomId);
      console.log(`Socket ${socket.id} left room: ${roomId}`);
    }
  }

  /**
   * Handle socket disconnection
   */
  handleDisconnect(socket) {
    console.log(`Socket disconnected: ${socket.id}`);
    
    // Remove from live stream room if was in one
    if (socket.roomId && socket.userId) {
      this._removeUserFromRoom(socket, socket.roomId, socket.userId);
    }
  }

  /**
   * Remove user from room and update viewer count
   */
  _removeUserFromRoom(socket, roomId, userId) {
    socket.leave(roomId);
    
    if (this.rooms.has(roomId)) {
      const room = this.rooms.get(roomId);
      
      // Remove from viewers
      room.viewers = new Set([...room.viewers].filter(v => v.userId !== userId));
      
      // Check if host left
      if (room.host && room.host.userId === userId) {
        room.host = null;
        // Notify all viewers that host left and stream ended
        this.io.to(roomId).emit('liveStreamEnded', {
          roomId,
          message: 'The host has left the stream',
          reason: 'host_disconnected'
        });
      }
      
      // Notify room about user leaving
      socket.to(roomId).emit('userLeftStream', {
        userId,
        viewerCount: room.viewers.size
      });
      
      // Update viewer count
      this.io.to(roomId).emit('viewerCountChanged', {
        roomId,
        viewerCount: room.viewers.size
      });
      
      console.log(`User ${userId} left live stream room: ${roomId}`);
      
      // Clean up empty room
      if (room.viewers.size === 0 && !room.host) {
        this._cleanupRoom(roomId);
      }
    }
    
    socket.emit('leftRoom', { roomId });
  }

  /**
   * Clean up empty room
   */
  _cleanupRoom(roomId) {
    this.rooms.delete(roomId);
    console.log(`Cleaned up empty room: ${roomId}`);
  }

  /**
   * Notify stream ended to all viewers in room
   */
  notifyStreamEnded(roomId, data = {}) {
    this.io.to(roomId).emit('liveStreamEnded', {
      roomId,
      message: 'The live stream has ended',
      ...data
    });
    
    // Clean up room after notification
    setTimeout(() => {
      this._cleanupRoom(roomId);
    }, 1000);
  }

  /**
   * Get room information
   */
  getRoomInfo(roomId) {
    return this.rooms.get(roomId);
  }

  /**
   * Get all active rooms
   */
  getAllRooms() {
    return Array.from(this.rooms.entries()).map(([roomId, room]) => ({
      roomId,
      hasHost: !!room.host,
      viewerCount: room.viewers.size
    }));
  }
}

module.exports = LiveStreamSocketHandler;