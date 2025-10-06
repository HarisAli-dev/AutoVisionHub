// controllers/events/socketHandler.js

/**
 * Socket.IO event handlers for live streaming
 */

const liveStreamService = require('../../services/liveStreamService');

class LiveStreamSocketHandler {
  constructor(io) {
    this.io = io;
    this.rooms = new Map(); // roomId -> { host, viewers: Set }
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
        this.rooms.set(roomId, { host: null, viewers: new Set() });
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