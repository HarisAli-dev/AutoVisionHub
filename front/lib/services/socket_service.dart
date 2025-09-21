
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
  Function(String, String)? onChatRead; // New callback for entire chat marked as read
  Function(String)? onUserTyping;
  Function(String)? onUserStoppedTyping;
  
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
        apiUrl, // from main.dart
        IO.OptionBuilder()
            .setTransports(['websocket'])
            .disableAutoConnect()
            .setExtraHeaders({'Authorization': 'Bearer $token'})
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
      socket.emit('mark_chat_read', {
        'chatId': chatId,
        'userId': _userId,
      });
    }
  }
  
  // Send typing indicator
  void sendTypingIndicator(String chatId) {
    if (_isConnected && _userId != null) {
      socket.emit('typing', {
        'chatId': chatId,
        'userId': _userId,
      });
    }
  }
  
  // Send stopped typing indicator
  void sendStoppedTypingIndicator(String chatId) {
    if (_isConnected && _userId != null) {
      socket.emit('stopped_typing', {
        'chatId': chatId,
        'userId': _userId,
      });
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
}
