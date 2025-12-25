import 'dart:async';
import 'package:flutter/material.dart';
import 'package:front/services/socket_service.dart';
import 'package:zego_express_engine/zego_express_engine.dart' as ZEGO;
import 'package:zego_express_engine/zego_express_engine.dart'
    show ZegoCanvas, ZegoBarrageMessageInfo, ZegoRoomState;
import 'package:front/services/zego_service.dart';
import 'package:front/services/live_stream_service.dart';
import 'package:front/model/events/event_model.dart';
import 'package:front/utils/hive_utils.dart';
import 'package:front/utils/app_colors.dart';
import 'package:front/utils/sizes.dart';

class LiveStreamAudienceScreen extends StatefulWidget {
  final String roomId;
  final EventModel event;

  const LiveStreamAudienceScreen({
    super.key,
    required this.roomId,
    required this.event,
  });

  @override
  State<LiveStreamAudienceScreen> createState() =>
      _LiveStreamAudienceScreenState();
}

class _LiveStreamAudienceScreenState extends State<LiveStreamAudienceScreen> {
  final ZegoService _zegoService = ZegoService.instance;
  final SocketService _socketService = SocketService();
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _chatScrollController = ScrollController();

  Widget? _remoteVideoView;
  List<ChatMessage> _messages = [];
  int _viewerCount = 0;
  bool _isPlaying = false;
  bool _streamEnded = false;
  String? _userId;
  String? _userName;
  Timer? _statusCheckTimer;

  @override
  void initState() {
    super.initState();
    _initializeViewer();
  }

  Future<void> _initializeViewer() async {
    _userId =
        HiveUtils.getData('userId') ??
        'viewer_${DateTime.now().millisecondsSinceEpoch}';
    _userName = HiveUtils.getData('name') ?? 'Viewer';

    // Set up ZEGO callbacks
    _zegoService.onMessageReceived = _handleMessageReceived;
    _zegoService.onRoomStateChanged = _handleRoomStateChanged;
    _zegoService.onRemoteStreamStateUpdate = _handleStreamStateUpdate;
    _zegoService.onStreamEnded = _handleStreamEnded;

    // Set up Socket.IO listeners for chatbot messages
    _setupSocketListeners();

    try {
      // Initialize engine
      await _zegoService.initEngine();

      // Join backend
      await LiveStreamService.joinLiveStream(widget.roomId);

      // Login to ZEGO room
      await _zegoService.loginRoom(
        roomId: widget.roomId,
        userId: _userId!,
        userName: _userName!,
      );

      // Wait a moment for room connection
      await Future.delayed(const Duration(milliseconds: 500));

      // Actively look for the host's stream
      final streamId = 'stream_${widget.roomId}';
      await _startPlayingStream(streamId);

      // Start periodic status check (as backup)
      _startStatusCheck();

      debugPrint('✅ Joined live stream successfully');
    } catch (e) {
      debugPrint('❌ Failed to join stream: $e');
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to join stream: $e')));
        Navigator.pop(context);
      }
    }
  }

  void _setupSocketListeners() {
    // Join socket.io room
    _socketService.joinLiveStream(widget.roomId, _userId!, _userName!);

    // Listen for chatbot messages
    _socketService.socket.on('new_live_stream_chat', (data) {
      debugPrint('📨 Received chat message: $data');
      if (mounted && data != null) {
        setState(() {
          _messages.add(
            ChatMessage(
              sender: data['senderName'] ?? 'Unknown',
              senderId: data['senderId'] ?? 'unknown',
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

  void _startStatusCheck() {
    _statusCheckTimer = Timer.periodic(const Duration(seconds: 15), (
      timer,
    ) async {
      if (_streamEnded) {
        timer.cancel();
        return;
      }

      try {
        final status = await LiveStreamService.getLiveStreamStatus(
          widget.event.id!,
        );
        if (status == null || status['isActive'] != true) {
          debugPrint('Stream is no longer active');
          _handleStreamEnded();
        }
      } catch (e) {
        debugPrint('Error checking stream status: $e');
      }
    });
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
    debugPrint('Room state changed: $state, error: $errorCode');

    if (state == ZegoRoomState.Disconnected && errorCode != 0) {
      _handleStreamEnded();
    }
  }

  void _handleStreamStateUpdate(
    String streamId,
    ZegoRemoteStreamState state,
  ) async {
    debugPrint('Remote stream state: $state');

    if (state == ZegoRemoteStreamState.Playing && !_isPlaying) {
      // Start playing the stream
      await _startPlayingStream(streamId);
    } else if (state == ZegoRemoteStreamState.NoPlay && _isPlaying) {
      setState(() {
        _isPlaying = false;
      });
    }
  }

  Future<void> _startPlayingStream(String streamId) async {
    try {
      // Create canvas for remote video
      final videoView = await ZEGO.ZegoExpressEngine.instance.createCanvasView((
        viewID,
      ) {
        final canvas = ZegoCanvas.view(viewID);
        ZEGO.ZegoExpressEngine.instance.startPlayingStream(
          streamId,
          canvas: canvas,
        );
      });

      await _zegoService.startPlayingStream(streamId);

      if (mounted) {
        setState(() {
          _remoteVideoView = videoView;
          _isPlaying = true;
        });
      }

      debugPrint('✅ Started playing stream: $streamId');
    } catch (e) {
      debugPrint('❌ Failed to start playing stream: $e');
    }
  }

  void _handleStreamEnded() {
    if (_streamEnded) return;

    setState(() {
      _streamEnded = true;
    });

    _statusCheckTimer?.cancel();

    if (mounted) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          backgroundColor: AppColors.backgroundColor,
          title: Text(
            'Stream Ended',
            style: TextStyle(color: AppColors.titleColor),
          ),
          content: Text(
            'The live stream has ended.',
            style: TextStyle(color: AppColors.foregroundColor),
          ),
          actions: [
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context); // Close dialog
                Navigator.pop(context); // Close stream screen
              },
              child: const Text('OK'),
            ),
          ],
        ),
      );
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

  Future<void> _leaveStream() async {
    await _cleanup();
    if (mounted) {
      Navigator.pop(context);
    }
  }

  Future<void> _cleanup() async {
    try {
      _statusCheckTimer?.cancel();

      // Stop playing streams
      if (_isPlaying) {
        final streamId = 'stream_${widget.roomId}';
        await _zegoService.stopPlayingStream(streamId);
      }

      // Logout from room
      await _zegoService.logoutRoom();

      // Leave stream in backend
      await LiveStreamService.leaveLiveStream(widget.roomId);

      debugPrint('✅ Stream cleanup completed');
    } catch (e) {
      debugPrint('❌ Error during cleanup: $e');
    }
  }

  @override
  void dispose() {
    _messageController.dispose();
    _chatScrollController.dispose();
    _statusCheckTimer?.cancel();
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
            if (_remoteVideoView != null)
              _remoteVideoView!
            else
              Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(color: AppColors.primary),
                    const SizedBox(height: 16),
                    const Text(
                      'Waiting for stream...',
                      style: TextStyle(color: Colors.white),
                    ),
                  ],
                ),
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
                    // Event info
                    Expanded(
                      child: Text(
                        widget.event.eventName,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const Spacer(),
                    // Close button
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.white),
                      onPressed: _leaveStream,
                    ),
                  ],
                ),
              ),
            ),

            // Chat messages
            Positioned(
              left: 0,
              right: 0,
              bottom: 100,
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

            // Message input
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
                child: Row(
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
              ),
            ),
          ],
        ),
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
