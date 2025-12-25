import 'package:flutter/material.dart';
import 'package:front/model/events/event_model.dart';
import 'package:front/services/live_stream_service.dart';
import 'package:front/services/video_player_service.dart';
import 'package:front/services/socket_service.dart';
import 'package:front/utils/app_colors.dart';
import 'package:front/utils/snackbars.dart';
import 'package:front/utils/time_utils.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:front/view/community_member/events/widgets/live_stream_chat_widget.dart';

/// Viewer Live Stream Screen for audience to join and watch live streaming
class ViewerLiveStreamScreen extends StatefulWidget {
  final EventModel event;
  final String? existingRoomId; // For joining existing live streams

  const ViewerLiveStreamScreen({
    super.key,
    required this.event,
    this.existingRoomId,
  });

  @override
  State<ViewerLiveStreamScreen> createState() => _ViewerLiveStreamScreenState();
}

class _ViewerLiveStreamScreenState extends State<ViewerLiveStreamScreen>
    with SingleTickerProviderStateMixin {
  // State variables
  bool _isLoading = false;
  bool _isLiveStreamActive = false;
  String? _currentRoomId;
  Map<String, dynamic>? _liveStreamStatus;

  // Socket service instance
  final SocketService _socketService = SocketService();

  // Animation controller for live indicator
  late AnimationController _animationController;
  late Animation<double> _pulseAnimation;

  // TODO: Chatbot related variables (for future implementation)
  // bool _isChatbotEnabled = false;
  // List<Map<String, dynamic>> _chatbotMessages = [];
  final TextEditingController _chatController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _initializeStreamData();
    _checkExistingLiveStream();
    _initializeSocket();

    // TODO: Initialize chatbot service
    // _initializeChatbot();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _chatController.dispose();
    _socketService.clearLiveStreamCallbacks();
    _socketService.leaveLiveStreamRoom();
    super.dispose();
  }

  /// Initialize Socket.IO connection for real-time events
  void _initializeSocket() {
    try {
      // Initialize socket service if not already connected
      if (!_socketService.isConnected) {
        _socketService.init();
      }

      // Set up live streaming event callbacks
      _socketService.setLiveStreamCallbacks(
        onLiveStreamEnded: (data) {
          debugPrint('Received live stream ended event: $data');
          if (mounted) {
            _handleStreamEnded(data);
          }
        },
        onRecordingStatusChanged: (data) {
          debugPrint('Recording status changed: $data');
          if (mounted) {
            _handleRecordingStatusChanged(data);
          }
        },
        onViewerCountChanged: (data) {
          debugPrint('Viewer count changed: $data');
          if (mounted) {
            _handleViewerCountChanged(data);
          }
        },
        onUserJoinedStream: (data) {
          debugPrint('User joined stream: $data');
          if (mounted) {
            _handleUserJoinedStream(data);
          }
        },
        onUserLeftStream: (data) {
          debugPrint('User left stream: $data');
          if (mounted) {
            _handleUserLeftStream(data);
          }
        },
      );
    } catch (e) {
      debugPrint('Error initializing socket: $e');
    }
  }

  /// Handle when the stream ends (for audience)
  void _handleStreamEnded(dynamic data) {
    if (!mounted) return;

    // Leave the socket room
    _socketService.leaveLiveStreamRoom();

    // Show dialog and navigate back to event details
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Stream Ended'),
        content: Text(
          data['message'] ?? 'The live stream has ended by the host.',
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop(); // Close dialog
              // Navigate back to event details (pop current live stream screen)
              Navigator.of(context).pop();
            },
            child: const Text('Back to Event'),
          ),
        ],
      ),
    );

    // Update local state
    setState(() {
      _isLiveStreamActive = false;
      _currentRoomId = null;
    });
  }

  /// Handle recording status changes
  void _handleRecordingStatusChanged(dynamic data) {
    if (!mounted) return;

    final status = data['status'];
    debugPrint('Recording status changed to: $status');

    setState(() {
      _isLiveStreamActive = status == 'recording';
    });

    if (status == 'stopped') {
      CustomSnackbars.showInfoSnackbar(context, 'Recording has stopped', 3.0);
    }
  }

  /// Handle viewer count changes
  void _handleViewerCountChanged(dynamic data) {
    if (!mounted) return;

    final viewerCount = data['viewerCount'];
    debugPrint('Viewer count changed to: $viewerCount');

    // Update UI if needed
    if (_liveStreamStatus != null) {
      setState(() {
        _liveStreamStatus!['viewerCount'] = viewerCount;
      });
    }
  }

  /// Handle user joined stream
  void _handleUserJoinedStream(dynamic data) {
    if (!mounted) return;

    final userName = data['userName'];
    final isHost = data['isHost'] ?? false;

    if (!isHost) {
      CustomSnackbars.showInfoSnackbar(
        context,
        '$userName joined the stream',
        2.0,
      );
    }
  }

  /// Handle user left stream
  void _handleUserLeftStream(dynamic data) {
    if (!mounted) return;

    final userId = data['userId'];
    debugPrint('User $userId left the stream');

    // Update viewer count if available
    final viewerCount = data['viewerCount'];
    if (viewerCount != null && _liveStreamStatus != null) {
      setState(() {
        _liveStreamStatus!['viewerCount'] = viewerCount;
      });
    }
  }

  /// Initialize animations for live indicator
  void _initializeAnimations() {
    _animationController = AnimationController(
      duration: const Duration(seconds: 1),
      vsync: this,
    );

    _pulseAnimation = Tween<double>(begin: 0.8, end: 1.2).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    _animationController.repeat(reverse: true);
  }

  /// Initialize stream data with default values
  void _initializeStreamData() {
    _currentRoomId = widget.existingRoomId;
  }

  /// Check if there's an existing live stream for this event
  Future<void> _checkExistingLiveStream() async {
    if (widget.existingRoomId != null) {
      setState(() {
        _isLiveStreamActive = true;
        _currentRoomId = widget.existingRoomId;
      });
      return;
    }

    setState(() => _isLoading = true);

    try {
      final status = await LiveStreamService.getLiveStreamStatus(
        widget.event.id!,
      );
      if (status != null && mounted) {
        setState(() {
          _isLiveStreamActive = status['isActive'] ?? false;
          _currentRoomId = status['roomId'];
          _liveStreamStatus = status;
        });
      }
    } catch (e) {
      if (mounted) {
        CustomSnackbars.showErrorSnackbar(
          context,
          'Failed to check live stream status: $e',
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  /// Join live streaming as audience
  Future<void> _joinLiveStream() async {
    if (_currentRoomId == null) return;

    setState(() => _isLoading = true);

    try {
      final success = await LiveStreamService.joinLiveStream(_currentRoomId!);

      if (success && mounted) {
        // Join Socket.IO room for real-time events
        _socketService.joinLiveStreamRoom(_currentRoomId!);
        debugPrint('Joined Socket.IO room: $_currentRoomId');

        // Navigate to Zego live streaming page as audience
        LiveStreamService.navigateToAudienceLiveStream(
          context: context,
          roomId: _currentRoomId!,
          event: widget.event,
        );

        // TODO: Notify chatbot that user joined as audience
        // ChatbotService.notifyUserJoinedAsAudience(_currentRoomId!, HiveUtils.getData('userId'));
      } else {
        throw Exception('Failed to join live stream');
      }
    } catch (e) {
      if (mounted) {
        CustomSnackbars.showErrorSnackbar(
          context,
          'Failed to join live stream: $e',
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  /// Show recorded content if available
  void _showRecordedContent() {
    // TODO: Integrate with video player service for recorded content
    if (widget.event.images.isNotEmpty) {
      VideoPlayerService.showVideoPlayerDialog(
        context,
        videoUrl:
            widget.event.images.first, // Assuming first image might be video
        autoPlay: false,
      );
    } else {
      CustomSnackbars.showErrorSnackbar(
        context,
        'No recorded content available for this event',
      );
    }
  }

  // TODO: Chatbot related methods (for future implementation)
  /*
  void _initializeChatbot() async {
    // Initialize chatbot service
    // _isChatbotEnabled = await ChatbotService.initialize(widget.event.id!);
  }

  void _sendChatbotMessage() async {
    if (_chatController.text.trim().isEmpty) return;
    
    final message = _chatController.text.trim();
    _chatController.clear();
    
    // Add user message
    setState(() {
      _chatbotMessages.add({
        'type': 'user',
        'message': message,
        'timestamp': DateTime.now(),
      });
    });
    
    // Send to chatbot and get response
    // final response = await ChatbotService.sendMessage(message, widget.event.id!);
    // if (response != null) {
    //   setState(() {
    //     _chatbotMessages.add({
    //       'type': 'bot',
    //       'message': response,
    //       'timestamp': DateTime.now(),
    //     });
    //   });
    // }
  }
  */

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Live Stream - ${widget.event.eventName}',
          style: TextStyle(color: AppColors.foregroundColor),
        ),
        backgroundColor: AppColors.appBarColor,
        actions: [
          if (_isLiveStreamActive)
            AnimatedBuilder(
              animation: _pulseAnimation,
              builder: (context, child) {
                return Transform.scale(
                  scale: _pulseAnimation.value,
                  child: Container(
                    margin: const EdgeInsets.only(right: 16),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Text(
                      'LIVE',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                );
              },
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildEventInfo(),
                  const SizedBox(height: 24),
                  _buildLiveStreamStatus(),
                  const SizedBox(height: 24),
                  _buildAudienceControls(),
                  const SizedBox(height: 24),
                  _buildAdditionalFeatures(),

                  // Live Stream Chat
                  if (_isLiveStreamActive && _currentRoomId != null) ...[
                    const SizedBox(height: 24),
                    LiveStreamChatWidget(
                      roomId: _currentRoomId!,
                      event: widget.event,
                      enableChatbot: true,
                    ),
                  ],

                  // TODO: Add chatbot interface
                  // const SizedBox(height: 24),
                  // _buildChatbotInterface(),
                ],
              ),
            ),
    );
  }

  /// Build event information section
  Widget _buildEventInfo() {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Event image
            if (widget.event.images.isNotEmpty)
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: CachedNetworkImage(
                  imageUrl: widget.event.images.first,
                  height: 200,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  placeholder: (context, url) => Container(
                    height: 200,
                    color: Colors.grey[300],
                    child: const Center(child: CircularProgressIndicator()),
                  ),
                  errorWidget: (context, url, error) => Container(
                    height: 200,
                    color: Colors.grey[300],
                    child: const Icon(Icons.image_not_supported, size: 64),
                  ),
                ),
              ),

            const SizedBox(height: 16),

            // Event details
            Text(
              widget.event.eventName,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              widget.event.eventDescription,
              style: TextStyle(fontSize: 16, color: Colors.grey[600]),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Icon(Icons.location_on, color: AppColors.primary),
                const SizedBox(width: 8),
                Expanded(child: Text(widget.event.eventLocation)),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.access_time, color: AppColors.primary),
                const SizedBox(width: 8),
                Text(
                  TimeUtils.formatDateTimePKT(widget.event.eventDateTime),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// Build live stream status section
  Widget _buildLiveStreamStatus() {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  _isLiveStreamActive
                      ? Icons.radio_button_checked
                      : Icons.radio_button_unchecked,
                  color: _isLiveStreamActive ? Colors.red : Colors.grey,
                ),
                const SizedBox(width: 8),
                Text(
                  _isLiveStreamActive
                      ? 'Live Stream Active'
                      : 'Live Stream Inactive',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: _isLiveStreamActive ? Colors.red : Colors.grey,
                  ),
                ),
              ],
            ),
            if (_liveStreamStatus != null) ...[
              const SizedBox(height: 12),
              Text('Viewers: ${_liveStreamStatus!['viewerCount'] ?? 0}'),
              Text('Duration: ${_liveStreamStatus!['duration'] ?? 'N/A'}'),
              if (_liveStreamStatus!['startTime'] != null)
                Text('Started: ${_liveStreamStatus!['startTime']}'),
            ],
          ],
        ),
      ),
    );
  }

  /// Build audience controls
  Widget _buildAudienceControls() {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Viewer Controls',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),

            if (_isLiveStreamActive) ...[
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _joinLiveStream,
                  icon: const Icon(Icons.play_arrow),
                  label: const Text('Join Live Stream'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
              ),
            ] else ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  children: [
                    Icon(Icons.info_outline, size: 48, color: Colors.grey[600]),
                    const SizedBox(height: 8),
                    Text(
                      'No live stream is currently active for this event.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Check back later or contact the event organizer for updates.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey[500], fontSize: 12),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// Build additional features section
  Widget _buildAdditionalFeatures() {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Additional Features',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),

            // Recorded content
            ListTile(
              leading: Icon(Icons.video_library, color: AppColors.primary),
              title: const Text('View Recorded Content'),
              subtitle: const Text('Watch previous recordings of this event'),
              onTap: _showRecordedContent,
            ),

            // Share event
            ListTile(
              leading: Icon(Icons.share, color: AppColors.primary),
              title: const Text('Share Event'),
              subtitle: const Text('Share this event with others'),
              onTap: () {
                // TODO: Implement share functionality
                CustomSnackbars.showSuccessSnackbar(
                  context,
                  'Share functionality coming soon!',
                  2.0,
                );
              },
            ),

            // Refresh stream status
            ListTile(
              leading: Icon(Icons.refresh, color: AppColors.primary),
              title: const Text('Refresh Stream Status'),
              subtitle: const Text('Check for stream updates'),
              onTap: () {
                _checkExistingLiveStream();
                CustomSnackbars.showInfoSnackbar(
                  context,
                  'Refreshing stream status...',
                  2.0,
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  // TODO: Build chatbot interface (for future implementation)
  /*
  Widget _buildChatbotInterface() {
    if (!_isChatbotEnabled) return const SizedBox.shrink();
    
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Event Assistant (AI)',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            
            // Chat messages
            Container(
              height: 200,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey[300]!),
                borderRadius: BorderRadius.circular(8),
              ),
              child: ListView.builder(
                itemCount: _chatbotMessages.length,
                itemBuilder: (context, index) {
                  final message = _chatbotMessages[index];
                  final isUser = message['type'] == 'user';
                  
                  return Align(
                    alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
                    child: Container(
                      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: isUser ? AppColors.primary : Colors.grey[200],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        message['message'],
                        style: TextStyle(
                          color: isUser ? Colors.white : Colors.black,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            
            const SizedBox(height: 12),
            
            // Chat input
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _chatController,
                    decoration: const InputDecoration(
                      hintText: 'Ask about the event...',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  onPressed: _sendChatbotMessage,
                  icon: Icon(Icons.send, color: AppColors.primary),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
  */
}
