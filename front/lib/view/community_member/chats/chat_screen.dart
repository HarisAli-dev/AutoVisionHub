import 'dart:async';
import 'dart:io';
import 'package:front/controller/chats/chat_controller.dart';
import 'package:front/controller/chats/chat_message_controller.dart';
import 'package:front/controller/report_controller.dart';
import 'package:front/model/chats/message_model.dart';
import 'package:front/providers/unified_audio_provider.dart';
import 'package:front/services/cloudinary_service.dart';
import 'package:front/services/socket_service.dart';
import 'package:front/services/unified_audio_service.dart';
import 'package:front/utils/app_colors.dart';
import 'package:front/utils/group_chat_components.dart';
import 'package:front/utils/hive_utils.dart';
import 'package:front/utils/snackbars.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:front/utils/time_utils.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

class ChatScreen extends StatefulWidget {
  final String chatId;
  final String chatName;

  const ChatScreen({required this.chatId, required this.chatName, super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final SocketService _socketService = SocketService();

  // State variables
  List<Message> _messages = [];
  String? _currentUserId;
  bool _isTyping = false;
  Timer? _typingTimer;
  String? _otherUserTyping;
  bool _hasInitiallyLoaded = false;

  @override
  void initState() {
    super.initState();
    _loadUserInfo();
    // No longer calling _loadMessages() directly here since we'll use FutureBuilder
    _setupSocketListeners();

    // Mark chat as read when opened
    ChatController.markChatAsRead(widget.chatId);

    _scrollController.addListener(_scrollListener);
    // Listen to text input changes for typing indicator
    _messageController.addListener(_onTextChanged);
  }

  Future<void> _loadUserInfo() async {
    _currentUserId = HiveUtils.getData('userId');
  }

  void _scrollListener() {
    if (_scrollController.position.pixels ==
        _scrollController.position.maxScrollExtent) {
      _loadMessages();
    }
  }

  void _setupSocketListeners() {
    if (!_socketService.isConnected) {
      _socketService.init();
    }

    // Join the chat room
    _socketService.joinChatRoom(widget.chatId);

    // Set up event handlers
    _socketService.onNewMessage = _handleNewMessage;
    _socketService.onMessageDelivered = _handleMessageDelivered;
    _socketService.onMessageSeen = _handleMessageSeen;
    _socketService.onChatRead = _handleChatRead;
    _socketService.onUserTyping = _handleUserTyping;
    _socketService.onUserStoppedTyping = _handleUserStoppedTyping;
  }

  void _handleNewMessage(Message message) {
    // Only process messages for this chat
    if (message.chatId != widget.chatId) return;

    setState(() {
      // Create a new list to avoid mutating a potentially unmodifiable list
      final updatedMessages = List<Message>.from(_messages);

      // Add message to list if not already present
      if (!updatedMessages.any((m) => m.id == message.id)) {
        updatedMessages.add(message);
        updatedMessages.sort((a, b) => a.createdAt.compareTo(b.createdAt));
        _messages = updatedMessages;
      }
    });

    // Mark message as delivered if from someone else
    if (message.senderId != _currentUserId) {
      // First mark as delivered
      _socketService.markMessageAsDelivered(message.id, widget.chatId);

      // Then immediately mark as read since the chat is open
      _socketService.markMessageAsSeen(message.id, widget.chatId);

      // Also mark the entire chat as read through the API
      ChatController.markChatAsRead(widget.chatId)
          .then((_) {
            debugPrint('Chat marked as read after new message');
          })
          .catchError((error) {
            debugPrint('Error marking chat as read: $error');
          });
    }

    // Scroll to bottom after the UI has been updated (only for new messages)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToBottom();
    });
  }

  void _handleMessageDelivered(String messageId, String chatId) {
    if (chatId != widget.chatId) return;

    setState(() {
      final index = _messages.indexWhere((m) => m.id == messageId);
      if (index != -1) {
        // Create a new mutable list
        final updatedMessages = List<Message>.from(_messages);
        final message = updatedMessages[index];

        // Create updated message with delivered status
        final updatedMessage = Message(
          id: message.id,
          chatId: message.chatId,
          senderId: message.senderId,
          senderName: message.senderName,
          type: message.type,
          content: message.content,
          mediaUrl: message.mediaUrl,
          thumbnailUrl: message.thumbnailUrl,
          duration: message.duration,
          callType: message.callType,
          status: 'delivered',
          isDeleted: message.isDeleted,
          deletedFor: message.deletedFor,
          createdAt: message.createdAt,
          updatedAt: DateTime.now(),
        );

        // Update the message in the new list
        updatedMessages[index] = updatedMessage;

        // Assign the new list to _messages
        _messages = updatedMessages;
      }
    });
  }

  void _handleMessageSeen(String messageId, String chatId) {
    if (chatId != widget.chatId) return;

    setState(() {
      final index = _messages.indexWhere((m) => m.id == messageId);
      if (index != -1) {
        // Create a new mutable list
        final updatedMessages = List<Message>.from(_messages);
        final message = updatedMessages[index];

        // Create updated message with seen status
        final updatedMessage = Message(
          id: message.id,
          chatId: message.chatId,
          senderId: message.senderId,
          senderName: message.senderName,
          type: message.type,
          content: message.content,
          mediaUrl: message.mediaUrl,
          thumbnailUrl: message.thumbnailUrl,
          duration: message.duration,
          callType: message.callType,
          status: 'seen',
          isDeleted: message.isDeleted,
          deletedFor: message.deletedFor,
          createdAt: message.createdAt,
          updatedAt: DateTime.now(),
        );

        // Update the message in the new list
        updatedMessages[index] = updatedMessage;

        // Assign the new list to _messages
        _messages = updatedMessages;
      }
    });
  }

  void _handleUserTyping(String userId) {
    if (userId != _currentUserId) {
      setState(() {
        _otherUserTyping = userId;
      });
    }
  }

  void _handleUserStoppedTyping(String userId) {
    if (_otherUserTyping == userId) {
      setState(() {
        _otherUserTyping = null;
      });
    }
  }

  void _handleChatRead(String chatId, String userId) {
    // Only process for this chat and if the reader is not the current user
    if (chatId != widget.chatId || userId == _currentUserId) return;

    setState(() {
      // Update all messages sent by the current user to "seen" status
      final updatedMessages = List<Message>.from(_messages);
      bool hasChanges = false;

      for (int i = 0; i < updatedMessages.length; i++) {
        final message = updatedMessages[i];

        // Only update messages sent by the current user that aren't already marked as seen
        if (message.senderId == _currentUserId && message.status != 'seen') {
          updatedMessages[i] = Message(
            id: message.id,
            chatId: message.chatId,
            senderId: message.senderId,
            senderName: message.senderName,
            type: message.type,
            content: message.content,
            mediaUrl: message.mediaUrl,
            thumbnailUrl: message.thumbnailUrl,
            duration: message.duration,
            callType: message.callType,
            status: 'seen',
            isDeleted: message.isDeleted,
            deletedFor: message.deletedFor,
            createdAt: message.createdAt,
            updatedAt: DateTime.now(),
          );
          hasChanges = true;
        }
      }

      // Only update state if there were actually changes
      if (hasChanges) {
        _messages = updatedMessages;
      }
    });
  }

  void _onTextChanged() {
    if (_messageController.text.isNotEmpty && !_isTyping) {
      _isTyping = true;
      _socketService.sendTypingIndicator(widget.chatId);
    }

    // Reset typing timer
    _typingTimer?.cancel();
    _typingTimer = Timer(const Duration(seconds: 2), () {
      if (_isTyping) {
        _isTyping = false;
        _socketService.sendStoppedTypingIndicator(widget.chatId);
      }
    });
  }

  Future<void> _loadMessages() async {
    try {
      final chat = await ChatController.getChatWithUser(widget.chatId);
      setState(() {
        // Create a new mutable list from the messages and make sure they're in chronological order (oldest first)
        final messagesList = chat.messages ?? [];
        // Sort messages by timestamp (oldest first)
        messagesList.sort((a, b) => a.createdAt.compareTo(b.createdAt));
        _messages = messagesList;
      });

      // Mark chat as read via HTTP API and socket for real-time updates
      await ChatController.markChatAsRead(widget.chatId);

      // Use socket's direct chat read method for real-time notification
      _socketService.markChatAsRead(widget.chatId);

      // Also mark individual messages as seen via socket for better reliability
      for (final Message message in chat.messages ?? []) {
        if (message.senderId != _currentUserId && message.status != 'seen') {
          _socketService.markMessageAsSeen(message.id, widget.chatId);
        }
      }

      // Only scroll to bottom on initial load, not on every rebuild
      if (!_hasInitiallyLoaded) {
        _hasInitiallyLoaded = true;
        // Scroll to bottom on load
        _scrollToBottom();
      }
    } catch (e) {
      print('Error loading messages: $e');
      // We don't need to update the UI here, as FutureBuilder will handle the error state
      throw e; // Re-throw to let FutureBuilder handle the error
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        // First try immediate scroll
        _scrollController.jumpTo(_scrollController.position.maxScrollExtent);

        // Then use a slight delay for smooth animation to ensure proper positioning
        Future.delayed(const Duration(milliseconds: 100), () {
          if (_scrollController.hasClients) {
            _scrollController.animateTo(
              _scrollController.position.maxScrollExtent,
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOut,
            );
          }
        });
      }
    });
  }

  void _showMessageOptions(Message message) {
    final isMyMessage = message.senderId == _currentUserId;

    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isMyMessage)
              ListTile(
                leading: Icon(Icons.delete, color: Colors.red),
                title: Text('Delete Message'),
                onTap: () {
                  Navigator.pop(context);
                  _deleteMessage(message);
                },
              ),
            if (!isMyMessage)
              ListTile(
                leading: Icon(Icons.flag, color: Colors.orange),
                title: Text('Report User'),
                onTap: () {
                  Navigator.pop(context);
                  _reportUser(message);
                },
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _reportUser(Message message) async {
    final TextEditingController reasonController = TextEditingController();
    final List<File> selectedImages = [];
    final ImagePicker picker = ImagePicker();

    final result = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          backgroundColor: AppColors.backgroundColor,
          title: Text(
            'Report User',
            style: TextStyle(color: AppColors.titleColor),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Why are you reporting this user?',
                  style: TextStyle(fontSize: 14, color: AppColors.shadeColor),
                ),
                SizedBox(height: 16),
                TextField(
                  controller: reasonController,
                  style: TextStyle(color: AppColors.foregroundColor),
                  decoration: InputDecoration(
                    hintText: 'Enter reason...',
                    hintStyle: TextStyle(color: AppColors.shadeColor),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: AppColors.shadeColor),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: AppColors.shadeColor),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: AppColors.primary),
                    ),
                  ),
                  maxLines: 3,
                  maxLength: 200,
                ),
                SizedBox(height: 16),
                Text(
                  'Upload proof (optional):',
                  style: TextStyle(fontSize: 14, color: AppColors.shadeColor),
                ),
                SizedBox(height: 8),
                ElevatedButton.icon(
                  onPressed: () async {
                    final XFile? image = await picker.pickImage(source: ImageSource.gallery);
                    if (image != null) {
                      setState(() {
                        selectedImages.add(File(image.path));
                      });
                    }
                  },
                  icon: Icon(Icons.add_photo_alternate),
                  label: Text('Add Image'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.shadeColor,
                    foregroundColor: AppColors.foregroundColor,
                  ),
                ),
                if (selectedImages.isNotEmpty) ...[
                  SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: selectedImages.map((img) {
                      return Stack(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.file(
                              img,
                              width: 80,
                              height: 80,
                              fit: BoxFit.cover,
                            ),
                          ),
                          Positioned(
                            top: 0,
                            right: 0,
                            child: GestureDetector(
                              onTap: () {
                                setState(() {
                                  selectedImages.remove(img);
                                });
                              },
                              child: Container(
                                padding: EdgeInsets.all(4),
                                decoration: BoxDecoration(
                                  color: Colors.red,
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(Icons.close, size: 16, color: Colors.white),
                              ),
                            ),
                          ),
                        ],
                      );
                    }).toList(),
                  ),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: Text(
                'Cancel',
                style: TextStyle(color: AppColors.shadeColor),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                if (reasonController.text.trim().isEmpty) {
                  CustomSnackbars.showErrorSnackbar(
                    context,
                    'Please enter a reason',
                  );
                  return;
                }
                Navigator.pop(dialogContext, true);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: const Text('Submit Report'),
            ),
          ],
        ),
      ),
    );

    if (result == true && mounted) {
      // Show loading
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator()),
      );

      final reportResult = await ReportController.reportUser(
        userId: message.senderId,
        reason: reasonController.text.trim(),
        proofImageFiles: selectedImages,
      );

      if (mounted) {
        Navigator.pop(context); // Close loading

        if (reportResult.contains('success')) {
          CustomSnackbars.showSuccessSnackbar(context, reportResult, 2);
        } else {
          CustomSnackbars.showErrorSnackbar(context, reportResult);
        }
      }
    }

    reasonController.dispose();
  }

  Future<void> _deleteMessage(Message message) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete Message'),
        content: Text('Are you sure you want to delete this message?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        // First remove the message from UI to prevent image loading errors
        setState(() {
          _messages.removeWhere((m) => m.id == message.id);
        });

        // Then delete from server
        final success = await ChatMessageController.deleteMessage(message.id);

        if (success) {
          // Delete media file if applicable (after successful backend deletion)
          if (message.mediaUrl != null) {
            try {
              await CloudinaryService.deleteFileByUrl(url: message.mediaUrl!);
              if (message.thumbnailUrl != null) {
                await CloudinaryService.deleteFileByUrl(
                  url: message.thumbnailUrl!,
                );
              }
            } catch (mediaError) {
              debugPrint('Error deleting media files: $mediaError');
              // Don't show error to user for media deletion failures
            }
          }
        } else {
          // If backend deletion failed, restore the message in UI
          setState(() {
            _loadMessages(); // Reload messages to restore state
          });
          throw Exception('Failed to delete message from server');
        }
      } catch (e) {
        CustomSnackbars.showErrorSnackbar(
          context,
          'Failed to delete message: ${e.toString()}',
        );
      }
    }
  }

  Future<void> _pickImage(ImageSource source, MessageType type) async {
    final ImagePicker picker = ImagePicker();
    try {
      final XFile? xFile = await picker.pickImage(
        source: source,
        maxWidth: 1920,
        maxHeight: 1920,
        imageQuality: 85,
      );

      if (xFile != null) {
        // Convert XFile to File
        final File file = File(xFile.path);

        // Send message with image file
        await _sendMessage(type, file: file);
      }
    } catch (e) {
      CustomSnackbars.showErrorSnackbar(context, 'Error picking image: $e');
    }
  }

  void _showVideoOptions() {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Choose from Gallery'),
              onTap: () {
                Navigator.pop(context);
                _pickVideo(ImageSource.gallery);
              },
            ),
            ListTile(
              leading: const Icon(Icons.videocam),
              title: const Text('Record Video'),
              onTap: () {
                Navigator.pop(context);
                _pickVideo(ImageSource.camera);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickVideo(ImageSource source) async {
    final ImagePicker picker = ImagePicker();
    try {
      final XFile? xFile = await picker.pickVideo(
        source: source,
        maxDuration: const Duration(minutes: 5),
      );

      if (xFile != null) {
        // Convert XFile to File
        final File file = File(xFile.path);

        // Send message with video file
        await _sendMessage(MessageType.video, file: file);
      }
    } catch (e) {
      CustomSnackbars.showErrorSnackbar(context, 'Error picking video: $e');
    }
  }

  Future<void> _pickFile() async {
    try {
      final FilePickerResult? result = await FilePicker.platform.pickFiles();

      if (result != null && result.files.single.path != null) {
        final File file = File(result.files.single.path!);
        final String fileName = result.files.single.name;

        // Send message with file
        await _sendMessage(MessageType.file, content: fileName, file: file);
      }
    } catch (e) {
      CustomSnackbars.showErrorSnackbar(context, 'Error picking file: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.appBarColor,
        title: Text(
          widget.chatName,
          style: TextStyle(color: AppColors.titleColor),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: FutureBuilder<void>(
              future: _loadMessages(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(
                    child: Text('Error loading messages: ${snapshot.error}'),
                  );
                } else if (snapshot.connectionState ==
                        ConnectionState.waiting &&
                    _messages.isEmpty) {
                  return const Center(child: CircularProgressIndicator());
                } else {
                  return ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(8.0),
                    itemCount: _messages.length,
                    reverse:
                        false, // False means oldest at top, newest at bottom
                    itemBuilder: (context, index) {
                      final message = _messages[index];
                      final isMe = message.senderId == _currentUserId;
                      // Convert UTC time to local time zone
                      final localTime = message.createdAt.toLocal();
                      final time = TimeUtils.formatTimePKT(message.createdAt);

                      // Show date header if this is first message or date changed from previous message
                      final showDateHeader =
                          index == 0 ||
                          !ChatComponents.isSameDay(
                            _messages[index - 1].createdAt.toLocal(),
                            message.createdAt.toLocal(),
                          );

                      return Column(
                        children: [
                          if (showDateHeader)
                            ChatComponents.buildDateHeader(message.createdAt),
                          Align(
                            alignment: isMe
                                ? Alignment.centerRight
                                : Alignment.centerLeft,
                            child: GestureDetector(
                              onLongPress: () => _showMessageOptions(message),
                              child: Container(
                                margin: const EdgeInsets.symmetric(
                                  vertical: 4.0,
                                ),
                                padding: const EdgeInsets.all(12.0),
                                constraints: BoxConstraints(
                                  maxWidth:
                                      MediaQuery.of(context).size.width * 0.7,
                                ),
                                decoration: BoxDecoration(
                                  color: isMe
                                      ? AppColors.primary
                                      : AppColors.shadeColor,
                                  borderRadius: BorderRadius.circular(16.0),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    ChatComponents.buildMessageContent(
                                      isMe,
                                      context,
                                      false,
                                      chatMessage: message,
                                    ),
                                    const SizedBox(height: 4.0),
                                    Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          time,
                                          style: TextStyle(
                                            fontSize: 10.0,
                                            color: isMe
                                                ? AppColors.foregroundColor
                                                : Colors.black54,
                                          ),
                                        ),
                                        if (isMe) ...[
                                          const SizedBox(width: 4),
                                          _buildMessageStatus(message.status),
                                        ],
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  );
                }
              },
            ),
          ),
          if (_otherUserTyping != null)
            Container(
              padding: const EdgeInsets.symmetric(
                vertical: 8.0,
                horizontal: 16.0,
              ),
              alignment: Alignment.centerLeft,
              child: const Text(
                'Typing...',
                style: TextStyle(
                  fontStyle: FontStyle.italic,
                  color: Colors.grey,
                ),
              ),
            ),
          _buildMessageInput(),
        ],
      ),
    );
  }

  Widget _buildMessageStatus(String status) {
    IconData icon;
    Color color;

    switch (status) {
      case 'sent':
        icon = Icons.check;
        color = AppColors.foregroundColor;
        break;
      case 'delivered':
        icon = Icons.done_all;
        color = AppColors.foregroundColor;
        break;
      case 'seen':
        icon = Icons.done_all;
        color = Colors.blue[300]!;
        break;
      default:
        icon = Icons.access_time;
        color = AppColors.foregroundColor;
    }

    return Icon(icon, size: 12, color: color);
  }

  void _buildAttachmentOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        color: AppColors.shadeColor,
        padding: EdgeInsets.symmetric(vertical: 16.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildAttachmentButton(
              icon: Icons.image,
              label: 'Image',
              onPressed: () {
                Navigator.pop(context);
                _pickImage(ImageSource.gallery, MessageType.image);
              },
            ),
            _buildAttachmentButton(
              icon: Icons.camera_alt,
              label: 'Camera',
              onPressed: () {
                Navigator.pop(context);
                _pickImage(ImageSource.camera, MessageType.image);
              },
            ),
            _buildAttachmentButton(
              icon: Icons.videocam,
              label: 'Video',
              onPressed: () {
                Navigator.pop(context);
                _showVideoOptions();
              },
            ),
            _buildAttachmentButton(
              icon: Icons.insert_drive_file,
              label: 'File',
              onPressed: () {
                Navigator.pop(context);
                _pickFile();
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAttachmentButton({
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
  }) {
    return InkWell(
      onTap: onPressed,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircleAvatar(
            backgroundColor: AppColors.primary,
            radius: 25,
            child: Icon(icon, color: AppColors.foregroundColor),
          ),
          SizedBox(height: 4),
          Text(label, style: TextStyle(fontSize: 12)),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    _typingTimer?.cancel();

    // Leave chat room when screen is closed
    _socketService.leaveChatRoom(widget.chatId);

    super.dispose();
  }

  Future<void> _sendMessage(
    MessageType type, {
    String? content,
    String? mediaUrl,
    File? file,
    int? duration,
  }) async {
    // Clear the text field
    if (type == MessageType.text) {
      _messageController.clear();
    }

    try {
      // Handle message sending based on type
      if (type == MessageType.text) {
        await ChatMessageController.sendTextMessage(
          widget.chatId,
          content!,
          false,
        );
      } else if (file != null) {
        // Media message with file
        await ChatMessageController.sendMediaMessage(
          widget.chatId,
          false,
          type,
          file,
        );
      } else if (mediaUrl != null) {
        // We already have a URL (rare case)
        await ChatMessageController.sendMessage(
          widget.chatId,
          false,
          type,
          content: content,
          mediaUrl: mediaUrl,
          duration: duration,
        );
      }

      // if (message != null) {
      //   // Scroll to bottom
      //   _scrollToBottom();
      // }
    } catch (e) {
      CustomSnackbars.showErrorSnackbar(context, 'Error sending message: $e');
    }
  }

  Widget _buildMessageInput() {
    return Container(
      padding: EdgeInsets.all(8.0),
      decoration: BoxDecoration(color: AppColors.shadeColor),
      child: Consumer<AudioProvider>(
        builder: (context, audioProvider, child) {
          return Row(
            children: [
              IconButton(
                icon: Icon(Icons.add, color: AppColors.primary),
                onPressed: () {
                  _buildAttachmentOptions();
                },
              ),
              Expanded(
                child: TextField(
                  controller: _messageController,
                  style: TextStyle(
                    fontSize: 16.0,
                    color: AppColors.foregroundColor,
                  ),
                  decoration: InputDecoration(
                    hintStyle: TextStyle(color: AppColors.foregroundColor),
                    hintText: audioProvider.isRecording
                        ? 'Recording...'
                        : 'Type a message...',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(24.0),
                      borderSide: BorderSide.none,
                    ),
                    filled: true,
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 16.0,
                      vertical: 8.0,
                    ),
                  ),
                  textCapitalization: TextCapitalization.sentences,
                  minLines: 1,
                  maxLines: 5,
                  enabled: !audioProvider.isRecording,
                ),
              ),
              AudioRecorderInput(
                onRecordingComplete: (recordingPath) async {
                  final file = File(recordingPath);
                  await _sendMessage(MessageType.voice, file: file);
                },
              ),
              if (!audioProvider.isRecording)
                IconButton(
                  icon: Icon(Icons.send, color: AppColors.primary),
                  onPressed: () {
                    if (_messageController.text.trim().isNotEmpty) {
                      _sendMessage(
                        MessageType.text,
                        content: _messageController.text,
                      );
                    }
                  },
                ),
            ],
          );
        },
      ),
    );
  }
}
