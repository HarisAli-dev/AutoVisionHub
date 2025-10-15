import 'package:front/main.dart';
import 'package:front/model/chats/message_model.dart';
import 'package:front/utils/hive_utils.dart';
import 'package:flutter/material.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;

class SocketService {
  static final SocketService _instance = SocketService._internal();

  factory SocketService() {
    return _instance;
  }

  SocketService._internal();

  late IO.Socket socket;
  bool _isConnected = false;
  String? _userId;

  // Event callbacks
  Function(Message)? onNewMessage;
  Function(String, String)? onMessageDelivered;
  Function(String, String)? onMessageSeen;
  Function(String, String)?
  onChatRead; // New callback for entire chat marked as read
  Function(String)? onUserTyping;
  Function(String)? onUserStoppedTyping;

  // Live streaming callbacks
  Function(dynamic)? onLiveStreamEnded;
  Function(dynamic)? onRecordingStatusChanged;
  Function(dynamic)? onViewerCountChanged;
  Function(dynamic)? onUserJoinedStream;
  Function(dynamic)? onUserLeftStream;

  // Current live stream state
  String? _currentLiveStreamRoom;

  bool get isConnected => _isConnected;

  void init() {
    _userId = HiveUtils.getData('userId');
    final token = HiveUtils.getData('token');

    if (_userId == null || token == null) {
      debugPrint('Cannot initialize socket: userId or token is null');
      return;
    }

    try {
      // Initialize the socket connection
      socket = IO.io(
        apiUrl.replaceAll(
          '/api',
          '',
        ), // Remove /api suffix for socket connection
        IO.OptionBuilder()
            .setTransports(['websocket'])
            .disableAutoConnect()
            .setExtraHeaders({'Authorization': 'Bearer $token'})
            .enableForceNew()
            .build(),
      );

      // Connect to the socket server
      socket.connect();

      // Set up event listeners
      _setupEventListeners();

      debugPrint('Socket initialized successfully');
    } catch (e) {
      debugPrint('Error initializing socket: $e');
    }
  }

  void _setupEventListeners() {
    // Connection events
    socket.on('connect', (_) {
      debugPrint('Socket connected');
      _isConnected = true;

      // Join user's room for personal messages
      if (_userId != null) {
        joinUserRoom(_userId!);
      }
    });

    socket.on('disconnect', (_) {
      debugPrint('Socket disconnected');
      _isConnected = false;
    });

    socket.on('connect_error', (error) {
      debugPrint('Socket connection error: $error');
      _isConnected = false;
    });

    // Message events
    socket.on('new_message', (data) {
      debugPrint('New message received: $data');
      if (onNewMessage != null) {
        try {
          final Message message = Message.fromJson(data);
          onNewMessage!(message);
        } catch (e) {
          debugPrint('Error parsing message: $e');
        }
      }
    });

    socket.on('message_delivered', (data) {
      debugPrint('Message delivered: $data');
      if (onMessageDelivered != null) {
        final String messageId = data['messageId'];
        final String chatId = data['chatId'];
        onMessageDelivered!(messageId, chatId);
      }
    });

    socket.on('message_seen', (data) {
      debugPrint('Message seen: $data');
      if (onMessageSeen != null) {
        final String messageId = data['messageId'];
        final String chatId = data['chatId'];
        onMessageSeen!(messageId, chatId);
      }
    });

    // Add listener for chat read events
    socket.on('chat_read', (data) {
      debugPrint('Chat read: $data');
      if (onChatRead != null) {
        final String chatId = data['chatId'];
        final String userId = data['userId'];
        onChatRead!(chatId, userId);
      }
    });

    // Typing events
    socket.on('typing', (data) {
      debugPrint('User typing: $data');
      if (onUserTyping != null) {
        final String userId = data['userId'];
        onUserTyping!(userId);
      }
    });

    socket.on('stopped_typing', (data) {
      debugPrint('User stopped typing: $data');
      if (onUserStoppedTyping != null) {
        final String userId = data['userId'];
        onUserStoppedTyping!(userId);
      }
    });

    // Live streaming events
    socket.on('liveStreamEnded', (data) {
      debugPrint('Live stream ended: $data');

      // Global handler - always handle stream ended regardless of current screen
      _handleGlobalStreamEnded(data);

      // Also call the callback if one is set
      if (onLiveStreamEnded != null) {
        onLiveStreamEnded!(data);
      }
    });

    socket.on('recordingStatusChanged', (data) {
      debugPrint('Recording status changed: $data');
      if (onRecordingStatusChanged != null) {
        onRecordingStatusChanged!(data);
      }
    });

    socket.on('viewerCountChanged', (data) {
      debugPrint('Viewer count changed: $data');
      if (onViewerCountChanged != null) {
        onViewerCountChanged!(data);
      }
    });

    socket.on('userJoinedStream', (data) {
      debugPrint('User joined stream: $data');
      if (onUserJoinedStream != null) {
        onUserJoinedStream!(data);
      }
    });

    socket.on('userLeftStream', (data) {
      debugPrint('User left stream: $data');
      if (onUserLeftStream != null) {
        onUserLeftStream!(data);
      }
    });
  }

  // Join a chat room
  void joinChatRoom(String chatId) {
    if (_isConnected) {
      socket.emit('join_room', {'roomId': chatId});
      debugPrint('Joined chat room: $chatId');
    }
  }

  // Join user's personal room
  void joinUserRoom(String userId) {
    if (_isConnected) {
      socket.emit('join_user_room', {'userId': userId});
      debugPrint('Joined user room: $userId');
    }
  }

  // Leave a chat room
  void leaveChatRoom(String chatId) {
    if (_isConnected) {
      socket.emit('leave_room', {'roomId': chatId});
      debugPrint('Left chat room: $chatId');
    }
  }

  // Send a message
  void sendMessage(Map<String, dynamic> messageData) {
    if (_isConnected) {
      socket.emit('send_message', messageData);
      debugPrint('Sent message: $messageData');
    } else {
      debugPrint('Cannot send message: socket not connected');
    }
  }

  // Mark message as delivered
  void markMessageAsDelivered(String messageId, String chatId) {
    if (_isConnected && _userId != null) {
      socket.emit('mark_delivered', {
        'messageId': messageId,
        'chatId': chatId,
        'userId': _userId,
      });
    }
  }

  // Mark message as seen
  void markMessageAsSeen(String messageId, String chatId) {
    if (_isConnected && _userId != null) {
      socket.emit('mark_seen', {
        'messageId': messageId,
        'chatId': chatId,
        'userId': _userId,
      });
    }
  }

  // Mark entire chat as read
  void markChatAsRead(String chatId) {
    if (_isConnected && _userId != null) {
      socket.emit('mark_chat_read', {'chatId': chatId, 'userId': _userId});
    }
  }

  // Send typing indicator
  void sendTypingIndicator(String chatId) {
    if (_isConnected && _userId != null) {
      socket.emit('typing', {'chatId': chatId, 'userId': _userId});
    }
  }

  // Send stopped typing indicator
  void sendStoppedTypingIndicator(String chatId) {
    if (_isConnected && _userId != null) {
      socket.emit('stopped_typing', {'chatId': chatId, 'userId': _userId});
    }
  }

  // Disconnect socket
  void disconnect() {
    if (_isConnected) {
      socket.disconnect();
      _isConnected = false;
      debugPrint('Socket disconnected');
    }
  }

  // ========== LIVE STREAMING METHODS ==========

  /// Join a live streaming room
  void joinLiveStreamRoom(String roomId) {
    if (_isConnected && _userId != null) {
      _currentLiveStreamRoom = roomId;
      socket.emit('join_live_stream', {
        'roomId': roomId,
        'userId': _userId,
        'userName': HiveUtils.getData('name') ?? 'Unknown User',
      });
      debugPrint('Joined live stream room: $roomId');
    } else {
      debugPrint(
        'Cannot join live stream room: socket not connected or userId null',
      );
    }
  }

  /// Leave current live streaming room
  void leaveLiveStreamRoom() {
    if (_isConnected && _userId != null && _currentLiveStreamRoom != null) {
      socket.emit('leave_live_stream', {
        'roomId': _currentLiveStreamRoom,
        'userId': _userId,
      });
      debugPrint('Left live stream room: $_currentLiveStreamRoom');
      _currentLiveStreamRoom = null;
    }
  }

  /// Notify that recording started (host only)
  void notifyRecordingStarted(String roomId) {
    if (_isConnected && _userId != null) {
      socket.emit('recording_started', {
        'roomId': roomId,
        'hostId': _userId,
        'timestamp': DateTime.now().toIso8601String(),
      });
      debugPrint('Notified recording started for room: $roomId');
    }
  }

  /// Notify that recording stopped (host only)
  void notifyRecordingStopped(String roomId) {
    if (_isConnected && _userId != null) {
      socket.emit('recording_stopped', {
        'roomId': roomId,
        'hostId': _userId,
        'timestamp': DateTime.now().toIso8601String(),
      });
      debugPrint('Notified recording stopped for room: $roomId');
    }
  }

  /// Update viewer count in room
  void updateViewerCount(String roomId, int viewerCount) {
    if (_isConnected) {
      socket.emit('update_viewer_count', {
        'roomId': roomId,
        'viewerCount': viewerCount,
      });
    }
  }

  /// Set live streaming event callbacks
  void setLiveStreamCallbacks({
    Function(dynamic)? onLiveStreamEnded,
    Function(dynamic)? onRecordingStatusChanged,
    Function(dynamic)? onViewerCountChanged,
    Function(dynamic)? onUserJoinedStream,
    Function(dynamic)? onUserLeftStream,
  }) {
    this.onLiveStreamEnded = onLiveStreamEnded;
    this.onRecordingStatusChanged = onRecordingStatusChanged;
    this.onViewerCountChanged = onViewerCountChanged;
    this.onUserJoinedStream = onUserJoinedStream;
    this.onUserLeftStream = onUserLeftStream;
  }

  /// Clear live streaming callbacks
  void clearLiveStreamCallbacks() {
    onLiveStreamEnded = null;
    onRecordingStatusChanged = null;
    onViewerCountChanged = null;
    onUserJoinedStream = null;
    onUserLeftStream = null;
  }

  /// Get current live stream room
  String? get currentLiveStreamRoom => _currentLiveStreamRoom;

  /// Check if currently in a live stream room
  bool get isInLiveStreamRoom => _currentLiveStreamRoom != null;

  /// Global handler for live stream ended events
  /// This handles the case where viewers are in Zego interface and can't receive local callbacks
  void _handleGlobalStreamEnded(dynamic data) {
    final String? roomId = data['roomId'];

    // Only handle if we're currently in this room
    if (roomId != null && _currentLiveStreamRoom == roomId) {
      debugPrint('Global stream ended handler triggered for room: $roomId');

      // Leave the room
      leaveLiveStreamRoom();

      // TODO: Force close any active Zego interfaces
      // This could be implemented by using a global app state or navigation key
      // For now, we rely on the Zego interface's own connection management

      // Try to show a global notification if possible
      _showGlobalStreamEndedNotification(data);
    }
  }

  /// Show a global notification that stream has ended
  void _showGlobalStreamEndedNotification(dynamic data) {
    // This is a placeholder for showing global notifications
    // In a real app, you might use a notification service or global overlay
    debugPrint(
      'Stream ended notification: ${data['message'] ?? 'Stream ended'}',
    );
  }
}
