import 'package:flutter/material.dart';
import 'package:front/model/events/event_model.dart';
import 'package:front/services/live_stream_service.dart';
import 'package:front/services/video_player_service.dart';
import 'package:front/services/socket_service.dart';
import 'package:front/utils/app_colors.dart';
import 'package:front/utils/snackbars.dart';
import 'package:cached_network_image/cached_network_image.dart';

/// Host Live Stream Screen for event creators to manage live streaming
class HostLiveStreamScreen extends StatefulWidget {
  final EventModel event;
  final String? existingRoomId; // For managing existing live streams

  const HostLiveStreamScreen({
    super.key,
    required this.event,
    this.existingRoomId,
  });

  @override
  State<HostLiveStreamScreen> createState() => _HostLiveStreamScreenState();
}

class _HostLiveStreamScreenState extends State<HostLiveStreamScreen>
    with SingleTickerProviderStateMixin {
  // State variables
  bool _isLoading = false;
  bool _isLiveStreamActive = false;
  String? _currentRoomId;
  Map<String, dynamic>? _liveStreamStatus;

  // Socket service instance
  final SocketService _socketService = SocketService();

  // Controllers
  final TextEditingController _streamTitleController = TextEditingController();
  final TextEditingController _streamDescriptionController =
      TextEditingController();

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
    _streamTitleController.dispose();
    _streamDescriptionController.dispose();
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

  /// Handle when the stream ends
  void _handleStreamEnded(dynamic data) {
    if (!mounted) return;

    // Leave the socket room
    _socketService.leaveLiveStreamRoom();

    // Show notification
    CustomSnackbars.showInfoSnackbar(
      context,
      data['message'] ?? 'The live stream has ended.',
      3.0,
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
    _streamTitleController.text = widget.event.eventName;
    _streamDescriptionController.text = widget.event.eventDescription;
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

  /// Start live streaming as host
  Future<void> _startLiveStream() async {
    if (!LiveStreamService.isZegoConfigured()) {
      CustomSnackbars.showErrorSnackbar(
        context,
        'Live streaming is not configured. Please contact support.',
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final roomId = await LiveStreamService.startLiveStream(
        eventId: widget.event.id!,
        streamTitle: _streamTitleController.text.trim(),
        streamDescription: _streamDescriptionController.text.trim(),
      );

      if (roomId != null && mounted) {
        setState(() {
          _currentRoomId = roomId;
          _isLiveStreamActive = true;
        });

        // Join Socket.IO room for real-time events
        _socketService.joinLiveStreamRoom(roomId);
        debugPrint('Host joined Socket.IO room: $roomId');

        // Navigate to Zego live streaming page as host
        LiveStreamService.navigateToHostLiveStream(
          context: context,
          roomId: roomId,
          event: widget.event,
          onLiveStreamingEnded: _onLiveStreamEnded,
        );

        // TODO: Notify chatbot that live stream started
        // ChatbotService.notifyLiveStreamStarted(roomId, widget.event);
      }
    } catch (e) {
      if (mounted) {
        CustomSnackbars.showErrorSnackbar(
          context,
          'Failed to start live stream: $e',
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  /// Manage existing live streaming
  Future<void> _manageLiveStream() async {
    if (_currentRoomId == null) return;

    setState(() => _isLoading = true);

    try {
      // Join Socket.IO room for real-time events
      _socketService.joinLiveStreamRoom(_currentRoomId!);
      debugPrint('Host managing Socket.IO room: $_currentRoomId');

      // Navigate to Zego live streaming page as host
      LiveStreamService.navigateToHostLiveStream(
        context: context,
        roomId: _currentRoomId!,
        event: widget.event,
        onLiveStreamingEnded: _onLiveStreamEnded,
      );
    } catch (e) {
      if (mounted) {
        CustomSnackbars.showErrorSnackbar(
          context,
          'Failed to manage live stream: $e',
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  /// Stop live streaming
  Future<void> _stopLiveStream() async {
    if (_currentRoomId == null) return;

    // Show confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Stop Live Stream'),
        content: const Text(
          'Are you sure you want to stop the live stream? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Stop', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _isLoading = true);

    try {
      final success = await LiveStreamService.stopLiveStream(_currentRoomId!);
      if (success && mounted) {
        _onLiveStreamEnded();
        CustomSnackbars.showSuccessSnackbar(
          context,
          'Live stream stopped successfully',
          2.0,
        );
      }
    } catch (e) {
      if (mounted) {
        CustomSnackbars.showErrorSnackbar(
          context,
          'Failed to stop live stream: $e',
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  /// Handle live stream ended
  void _onLiveStreamEnded() {
    if (mounted) {
      setState(() {
        _isLiveStreamActive = false;
        _currentRoomId = null;
        _liveStreamStatus = null;
      });

      // TODO: Process live stream analytics with chatbot
      // ChatbotService.processLiveStreamEnded(widget.event.id!, _liveStreamStatus);
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
          'Host Live Stream - ${widget.event.eventName}',
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
                  _buildHostControls(),
                  const SizedBox(height: 24),
                  _buildAdditionalFeatures(),

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
                  '${widget.event.eventDateTime.day}/${widget.event.eventDateTime.month}/${widget.event.eventDateTime.year} '
                  '${widget.event.eventDateTime.hour}:${widget.event.eventDateTime.minute.toString().padLeft(2, '0')}',
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

  /// Build host controls
  Widget _buildHostControls() {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Host Controls',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),

            if (!_isLiveStreamActive) ...[
              // Stream setup form
              TextField(
                controller: _streamTitleController,
                decoration: const InputDecoration(
                  labelText: 'Stream Title',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _streamDescriptionController,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Stream Description',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),

              // Start stream button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _startLiveStream,
                  icon: const Icon(Icons.play_arrow),
                  label: const Text('Start Live Stream'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
              ),
            ] else ...[
              // Active stream controls
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _manageLiveStream,
                  icon: const Icon(Icons.videocam),
                  label: const Text('Manage Live Stream'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _stopLiveStream,
                  icon: const Icon(Icons.stop),
                  label: const Text('Stop Live Stream'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
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

            // Event analytics (for hosts)
            ListTile(
              leading: Icon(Icons.analytics, color: AppColors.primary),
              title: const Text('Event Analytics'),
              subtitle: const Text('View engagement and viewer statistics'),
              onTap: () {
                // TODO: Navigate to analytics page
                CustomSnackbars.showSuccessSnackbar(
                  context,
                  'Analytics page coming soon!',
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
