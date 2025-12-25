import 'dart:async';
import 'package:flutter/material.dart';
import 'package:zego_express_engine/zego_express_engine.dart' as ZEGO;
import 'package:zego_express_engine/zego_express_engine.dart'
    show ZegoCanvas, ZegoBarrageMessageInfo, ZegoRoomState;
import 'package:front/services/zego_service.dart';
import 'package:front/services/live_stream_service.dart';
import 'package:front/services/socket_service.dart';
import 'package:front/model/events/event_model.dart';
import 'package:front/utils/hive_utils.dart';
import 'package:front/utils/app_colors.dart';
import 'package:front/utils/sizes.dart';

class LiveStreamHostScreen extends StatefulWidget {
  final String roomId;
  final EventModel event;
  final VoidCallback? onStreamEnded;

  const LiveStreamHostScreen({
    super.key,
    required this.roomId,
    required this.event,
    this.onStreamEnded,
  });

  @override
  State<LiveStreamHostScreen> createState() => _LiveStreamHostScreenState();
}

class _LiveStreamHostScreenState extends State<LiveStreamHostScreen> {
  final ZegoService _zegoService = ZegoService.instance;
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _chatScrollController = ScrollController();
  final SocketService _socketService = SocketService();

  Widget? _localVideoView;
  List<ChatMessage> _messages = [];
  int _viewerCount = 0;
  bool _isCameraOn = true;
  bool _isMicOn = true;
  bool _isFrontCamera = true;
  String? _userId;
  String? _userName;

  @override
  void initState() {
    super.initState();
    _initializeStream();
  }

  Future<void> _initializeStream() async {
    _userId =
        HiveUtils.getData('userId') ??
        'host_${DateTime.now().millisecondsSinceEpoch}';
    _userName = HiveUtils.getData('name') ?? 'Host';

    // Set up ZEGO callbacks
    _zegoService.onMessageReceived = _handleMessageReceived;
    _zegoService.onRoomStateChanged = _handleRoomStateChanged;

    // Set up Socket.IO listeners for chatbot messages
    _setupSocketListeners();

    try {
      // Initialize engine
      await _zegoService.initEngine();

      // Login to room
      await _zegoService.loginRoom(
        roomId: widget.roomId,
        userId: _userId!,
        userName: _userName!,
      );

      // Join socket.io room for chatbot
      _socketService.joinLiveStream(widget.roomId, _userId!, _userName!);

      // Start preview
      await _startPreview();

      // Start publishing stream
      final streamId = 'stream_${widget.roomId}';
      await _zegoService.startPublishingStream(streamId);

      debugPrint('✅ Live stream started successfully');
    } catch (e) {
      debugPrint('❌ Failed to start stream: $e');
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to start stream: $e')));
        Navigator.pop(context);
      }
    }
  }

  void _setupSocketListeners() {
    // Listen for chatbot messages
    _socketService.socket.on('new_live_stream_chat', (data) {
      debugPrint('📨 Received chat message: $data');
      if (mounted && data != null) {
        setState(() {
          _messages.add(
            ChatMessage(
              sender: data['senderName'] ?? 'Chatbot',
              senderId: data['senderId'] ?? 'Chatbot',
              message: data['message'] ?? '',
              isBot: data['isBot'] == true,
              timestamp: DateTime.parse(
                data['timestamp'] ?? DateTime.now().toIso8601String(),
              ),
            ),
          );
        });

        // Auto-scroll to bottom
        Future.delayed(const Duration(milliseconds: 100), () {
          if (_chatScrollController.hasClients) {
            _chatScrollController.animateTo(
              _chatScrollController.position.maxScrollExtent,
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOut,
            );
          }
        });
      }
    });
  }

  Future<void> _startPreview() async {
    try {
      // Create canvas view first and get the widget
      final videoView = await ZEGO.ZegoExpressEngine.instance.createCanvasView((
        viewID,
      ) {
        // This callback is called when the canvas view is ready
        // Now we can start the preview with this viewID
        final canvas = ZegoCanvas.view(viewID);
        ZEGO.ZegoExpressEngine.instance.startPreview(canvas: canvas);
      });

      if (mounted) {
        setState(() {
          _localVideoView = videoView;
        });
      }

      debugPrint('✅ Camera preview started');
    } catch (e) {
      debugPrint('❌ Failed to start preview: $e');
      rethrow;
    }
  }

  void _handleMessageReceived(List<ZegoBarrageMessageInfo> messageList) {
    setState(() {
      for (var msg in messageList) {
        _messages.add(
          ChatMessage(
            sender: msg.fromUser.userName,
            senderId: msg.fromUser.userID,
            message: msg.message,
            isBot: msg.fromUser.userID.startsWith('ai-bot-'),
            timestamp: DateTime.now(),
          ),
        );
      }
    });

    // Auto-scroll to bottom
    if (_chatScrollController.hasClients) {
      _chatScrollController.animateTo(
        _chatScrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  void _handleRoomStateChanged(
    String roomId,
    ZegoRoomState state,
    int errorCode,
  ) {
    debugPrint(
      '\ud83c\udfe0 Room state changed: $state, errorCode: $errorCode',
    );

    if (state == ZegoRoomState.Disconnected && errorCode != 0) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Disconnected from stream')),
        );
      }
    }
  }

  Future<void> _sendMessage() async {
    final message = _messageController.text.trim();
    if (message.isEmpty) return;

    _messageController.clear();

    // Send via Socket.IO for chatbot processing
    _socketService.sendLiveStreamChat(
      roomId: widget.roomId,
      userId: _userId!,
      userName: _userName!,
      message: message,
    );

    // Also send via ZEGO for redundancy (optional)
    await _zegoService.sendBarrageMessage(message);

    // Record engagement
    LiveStreamService.recordEngagementEvent(
      roomId: widget.roomId,
      eventType: 'chat_message',
      data: {'message': message},
    );
  }

  Future<void> _toggleCamera() async {
    setState(() {
      _isCameraOn = !_isCameraOn;
    });
    await _zegoService.enableCamera(_isCameraOn);
  }

  Future<void> _toggleMicrophone() async {
    setState(() {
      _isMicOn = !_isMicOn;
    });
    await _zegoService.enableMicrophone(_isMicOn);
  }

  Future<void> _switchCamera() async {
    await _zegoService.switchCamera();
    setState(() {
      _isFrontCamera = !_isFrontCamera;
    });
  }

  Future<void> _endStream() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.backgroundColor,
        title: Text(
          'End Live Stream?',
          style: TextStyle(color: AppColors.titleColor),
        ),
        content: Text(
          'Are you sure you want to end this live stream?',
          style: TextStyle(color: AppColors.foregroundColor),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              'Cancel',
              style: TextStyle(color: AppColors.shadeColor),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('End Stream'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await _cleanup();
      if (mounted) {
        Navigator.pop(context);
      }
      widget.onStreamEnded?.call();
    }
  }

  Future<void> _cleanup() async {
    try {
      // Stop preview
      await ZEGO.ZegoExpressEngine.instance.stopPreview();

      // Stop publishing
      await _zegoService.stopPublishingStream();

      // Logout from room
      await _zegoService.logoutRoom();

      // Stop stream in backend
      await LiveStreamService.stopLiveStream(widget.roomId);

      debugPrint('✅ Stream cleanup completed');
    } catch (e) {
      debugPrint('❌ Error during cleanup: $e');
    }
  }

  @override
  void dispose() {
    _messageController.dispose();
    _chatScrollController.dispose();
    _cleanup();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    AppColors.getBackgroundColor(context);

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Stack(
          children: [
            // Video view
            if (_localVideoView != null)
              _localVideoView!
            else
              Center(
                child: CircularProgressIndicator(color: AppColors.primary),
              ),

            // Top bar
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: EdgeInsets.all(AppSizes.mediumPadding(context)),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Colors.black.withOpacity(0.7), Colors.transparent],
                  ),
                ),
                child: Row(
                  children: [
                    // Live indicator
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 6),
                          const Text(
                            'LIVE',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Viewer count
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.5),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.visibility,
                            color: Colors.white,
                            size: 16,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            '$_viewerCount',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Spacer(),
                    const SizedBox(width: 8),
                    // Close button
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.white),
                      onPressed: _endStream,
                    ),
                  ],
                ),
              ),
            ),

            // Chat messages
            Positioned(
              left: 0,
              right: 100,
              bottom: 140,
              height: 300,
              child: ListView.builder(
                controller: _chatScrollController,
                padding: EdgeInsets.all(AppSizes.mediumPadding(context)),
                itemCount: _messages.length,
                itemBuilder: (context, index) {
                  final msg = _messages[index];
                  return _buildChatBubble(msg);
                },
              ),
            ),

            // Bottom controls
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: EdgeInsets.all(AppSizes.mediumPadding(context)),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [Colors.black.withOpacity(0.7), Colors.transparent],
                  ),
                ),
                child: Column(
                  children: [
                    // Control buttons
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _buildControlButton(
                          icon: _isCameraOn
                              ? Icons.videocam
                              : Icons.videocam_off,
                          onTap: _toggleCamera,
                          isActive: _isCameraOn,
                        ),
                        _buildControlButton(
                          icon: _isMicOn ? Icons.mic : Icons.mic_off,
                          onTap: _toggleMicrophone,
                          isActive: _isMicOn,
                        ),
                        _buildControlButton(
                          icon: Icons.flip_camera_ios,
                          onTap: _switchCamera,
                          isActive: true,
                        ),
                        _buildControlButton(
                          icon: Icons.stop_circle,
                          onTap: _endStream,
                          isActive: true,
                          color: Colors.red,
                        ),
                      ],
                    ),
                    SizedBox(height: AppSizes.mediumSpacing(context)),
                    // Message input
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _messageController,
                            style: const TextStyle(color: Colors.white),
                            decoration: InputDecoration(
                              hintText: 'Send a message...',
                              hintStyle: TextStyle(
                                color: Colors.white.withOpacity(0.5),
                              ),
                              filled: true,
                              fillColor: Colors.black.withOpacity(0.5),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(25),
                                borderSide: BorderSide.none,
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 20,
                                vertical: 10,
                              ),
                            ),
                            onSubmitted: (_) => _sendMessage(),
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          icon: Icon(Icons.send, color: AppColors.primary),
                          onPressed: _sendMessage,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildControlButton({
    required IconData icon,
    required VoidCallback onTap,
    required bool isActive,
    Color? color,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          color: (color ?? (isActive ? AppColors.primary : Colors.grey))
              .withOpacity(0.8),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: Colors.white, size: 28),
      ),
    );
  }

  Widget _buildChatBubble(ChatMessage msg) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: msg.isBot
            ? AppColors.primary.withOpacity(0.2)
            : Colors.black.withOpacity(0.5),
        borderRadius: BorderRadius.circular(12),
        border: msg.isBot
            ? Border.all(color: AppColors.primary.withOpacity(0.5))
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (msg.isBot)
                Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: Icon(
                    Icons.smart_toy,
                    size: 16,
                    color: AppColors.primary,
                  ),
                ),
              Text(
                msg.sender,
                style: TextStyle(
                  color: msg.isBot
                      ? AppColors.primary
                      : AppColors.primary.withOpacity(0.8),
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            msg.message,
            style: const TextStyle(color: Colors.white, fontSize: 14),
          ),
        ],
      ),
    );
  }
}

class ChatMessage {
  final String sender;
  final String senderId;
  final String message;
  final bool isBot;
  final DateTime timestamp;

  ChatMessage({
    required this.sender,
    required this.senderId,
    required this.message,
    required this.isBot,
    required this.timestamp,
  });
}
