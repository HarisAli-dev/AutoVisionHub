import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:front/controller/groups/group_message_controller.dart';
import 'package:front/model/groups/group_message_model.dart';
import 'package:front/model/groups/group_model.dart';
import 'package:front/services/cloudinary_service.dart';
import 'package:front/services/unified_audio_service.dart';
import 'package:front/utils/app_colors.dart';
import 'package:front/utils/custom_widgets.dart';
import 'package:front/utils/group_chat_components.dart';
import 'package:front/utils/hive_utils.dart';
import 'package:front/utils/sizes.dart';
import 'package:front/utils/snackbars.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:front/utils/time_utils.dart';
import 'package:provider/provider.dart';
import 'package:front/providers/unified_audio_provider.dart';
import 'package:front/providers/poll_provider.dart';

class GroupScreen extends StatefulWidget {
  final String currentUserId;
  final String groupId;
  final String groupName;
  final String groupImage;

  const GroupScreen({
    required this.groupId,
    required this.groupName,
    required this.currentUserId,
    required this.groupImage,
    super.key,
  });

  @override
  _GroupScreenState createState() => _GroupScreenState();
}

class _GroupScreenState extends State<GroupScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final ImagePicker _imagePicker = ImagePicker();

  List<GroupMessage> messages = [];
  Group? group;
  bool isLoading = false;
  bool isSending = false;
  bool hasText = false;
  int currentPage = 1;
  final int pageSize = 50;

  @override
  void initState() {
    super.initState();
    _initializeScreen();
    _scrollController.addListener(_scrollListener);
    // Listen to text changes to update UI
    _messageController.addListener(() {
      final currentHasText = _messageController.text.trim().isNotEmpty;
      if (hasText != currentHasText) {
        setState(() {
          hasText = currentHasText;
        });
      }
    });
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();

    // Clear polls when leaving the group
    context.read<PollProvider>().clearPolls();

    // Leave group room
    GroupMessageController.leaveGroupRoom(widget.groupId);

    super.dispose();
  }

  Future<void> _initializeScreen() async {
    setState(() {
      isLoading = true;
    });
    await _loadMessages();
    // Join group room for real-time updates
    GroupMessageController.joinGroupRoom(widget.groupId);
    // Initialize poll provider
    context.read<PollProvider>().initialize();
    setState(() {
      isLoading = false;
    });
  }

  Future<void> _loadMessages({bool loadMore = false}) async {
    if (loadMore) return;

    try {
      final newMessages = await GroupMessageController.getGroupMessages(
        groupId: widget.groupId,
        page: loadMore ? currentPage + 1 : 1,
        limit: pageSize,
      );

      setState(() {
        if (loadMore) {
          messages.addAll(newMessages);
          currentPage++;
        } else {
          messages = newMessages;
        }
      });

      // Load polls for poll messages using PollProvider
      final pollProvider = context.read<PollProvider>();
      for (final message in newMessages) {
        if (message.type == GroupMessageType.poll && message.pollId != null) {
          pollProvider.loadPoll(message.pollId!);
        }
      }
    } catch (e) {
      CustomSnackbars.showErrorSnackbar(
        context,
        'Failed to load messages: ${e.toString()}',
      );
    }
  }

  void _scrollListener() {
    if (_scrollController.position.pixels ==
        _scrollController.position.maxScrollExtent) {
      _loadMessages(loadMore: true);
    }
  }

  Future<void> _handlePollVote(String pollId, String option) async {
    final pollProvider = context.read<PollProvider>();

    debugPrint('Attempting to vote on poll $pollId with option: $option');

    // Check if user has already voted
    if (pollProvider.hasUserVoted(pollId)) {
      debugPrint('User has already voted in poll $pollId');
      CustomSnackbars.showErrorSnackbar(
        context,
        'You have already voted in this poll',
      );
      return;
    }

    // Attempt to vote using the provider (includes optimistic voting)
    final success = await pollProvider.voteOnPoll(pollId, option);

    if (success) {
      debugPrint('Vote successful for poll $pollId');
      CustomSnackbars.showSuccessSnackbar(
        context,
        'Vote submitted successfully!',
        1.5,
      );
    } else {
      debugPrint('Vote failed for poll $pollId');
      CustomSnackbars.showErrorSnackbar(
        context,
        'Failed to submit vote. Please try again.',
      );
    }
  }

  Future<void> _sendTextMessage() async {
    if (_messageController.text.trim().isEmpty || isSending) return;

    final content = _messageController.text.trim();
    _messageController.clear();

    try {
      setState(() => isSending = true);

      if (await GroupMessageController.sendTextMessage(
        widget.groupId,
        content,
      )) {
        setState(() {
          isSending = false;
          _loadMessages();
        });
      }

      _scrollToBottom();
    } catch (e) {
      setState(() => isSending = false);
      CustomSnackbars.showErrorSnackbar(
        context,
        'Failed to send message: ${e.toString()}',
      );
    }
  }

  Future<void> _sendMediaMessage(GroupMessageType type) async {
    try {
      File? file;

      switch (type) {
        case GroupMessageType.image:
          final pickedFile = await _imagePicker.pickImage(
            source: ImageSource.gallery,
          );
          if (pickedFile != null) file = File(pickedFile.path);
          break;
        case GroupMessageType.video:
          final pickedFile = await _imagePicker.pickVideo(
            source: ImageSource.gallery,
          );
          if (pickedFile != null) file = File(pickedFile.path);
          break;
        case GroupMessageType.file:
          final result = await FilePicker.platform.pickFiles();
          if (result != null && result.files.single.path != null) {
            file = File(result.files.single.path!);
          }
          break;
        default:
          break;
      }

      if (file != null) {
        setState(() => isSending = true);

        if (await GroupMessageController.sendMediaMessage(
          widget.groupId,
          type,
          file,
        )) {
          setState(() {
            isSending = false;
            _loadMessages();
          });
        }

        _scrollToBottom();
      }
    } catch (e) {
      setState(() => isSending = false);
      CustomSnackbars.showErrorSnackbar(
        context,
        'Failed to send media: ${e.toString()}',
      );
    }
  }

  Future<void> _sendVoiceMessage(String recordingPath) async {
    try {
      setState(() => isSending = true);

      if (await GroupMessageController.sendMediaMessage(
        widget.groupId,
        GroupMessageType.voice,
        File(recordingPath),
      )) {
        setState(() {
          isSending = false;
          _loadMessages();
        });
      }

      _scrollToBottom();
    } catch (e) {
      setState(() => isSending = false);
      CustomSnackbars.showErrorSnackbar(
        context,
        'Failed to send voice message: ${e.toString()}',
      );
    }
  }

  Future<void> _createPoll() async {
    await _showCreatePollDialog();
  }

  Future<void> _showCreatePollDialog() async {
    final questionController = TextEditingController();
    final List<TextEditingController> optionControllers = [
      TextEditingController(),
      TextEditingController(),
    ];

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text('Create Poll'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: questionController,
                  decoration: InputDecoration(
                    labelText: 'Poll Question',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 2,
                ),
                SizedBox(height: AppSizes.getSizeBoxHeight(context)),
                ...optionControllers.asMap().entries.map((entry) {
                  final index = entry.key;
                  final controller = entry.value;
                  return Padding(
                    padding: EdgeInsets.only(
                      bottom: AppSizes.containerPadding(context) * 0.5,
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: controller,
                            decoration: InputDecoration(
                              labelText: 'Option ${index + 1}',
                              border: OutlineInputBorder(),
                            ),
                          ),
                        ),
                        if (optionControllers.length > 2)
                          IconButton(
                            icon: Icon(Icons.remove_circle, color: Colors.red),
                            onPressed: () {
                              setDialogState(() {
                                optionControllers.removeAt(index);
                              });
                            },
                          ),
                      ],
                    ),
                  );
                }).toList(),
                if (optionControllers.length < 6)
                  TextButton.icon(
                    onPressed: () {
                      setDialogState(() {
                        optionControllers.add(TextEditingController());
                      });
                    },
                    icon: Icon(Icons.add),
                    label: Text('Add Option'),
                  ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                final question = questionController.text.trim();
                final options = optionControllers
                    .map((c) => c.text.trim())
                    .where((text) => text.isNotEmpty)
                    .toList();

                if (question.isNotEmpty && options.length >= 2) {
                  Navigator.pop(context);
                  await _sendPoll(question, options);
                } else {
                  CustomSnackbars.showErrorSnackbar(
                    context,
                    'Please enter a question and at least 2 options',
                  );
                }
              },
              child: Text('Create Poll'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _sendPoll(String question, List<String> options) async {
    try {
      setState(() => isSending = true);

      final pollProvider = context.read<PollProvider>();
      final success = await pollProvider.createPoll(
        groupId: widget.groupId,
        question: question,
        options: options,
      );

      if (success) {
        setState(() {
          isSending = false;
          _loadMessages();
        });
      }

      _scrollToBottom();
    } catch (e) {
      setState(() => isSending = false);
      CustomSnackbars.showErrorSnackbar(
        context,
        'Failed to create poll: ${e.toString()}',
      );
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _showMessageOptions(GroupMessage message) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (message.type == GroupMessageType.text)
              ListTile(
                leading: Icon(Icons.edit, color: AppColors.primary),
                title: Text('Edit Message'),
                onTap: () {
                  Navigator.pop(context);
                  _editMessage(message);
                },
              ),
            ListTile(
              leading: Icon(Icons.delete, color: Colors.red),
              title: Text('Delete Message'),
              onTap: () {
                Navigator.pop(context);
                _deleteMessage(message);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _editMessage(GroupMessage message) async {
    final controller = TextEditingController(text: message.content ?? '');

    final newContent = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Edit Message'),
        content: TextField(
          controller: controller,
          decoration: InputDecoration(
            labelText: 'Message',
            border: OutlineInputBorder(),
          ),
          maxLines: 3,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            child: Text('Save'),
          ),
        ],
      ),
    );

    if (newContent != null &&
        newContent.isNotEmpty &&
        newContent != message.content) {
      try {
        final reponse = await GroupMessageController.editGroupMessage(
          message.id,
          newContent,
        );
        if (reponse) {
          setState(() {
            _loadMessages();
          });
        }
      } catch (e) {
        CustomSnackbars.showErrorSnackbar(
          context,
          'Failed to edit message: ${e.toString()}',
        );
      }
    }
  }

  Future<void> _deleteMessage(GroupMessage message) async {
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
        // Special handling for poll messages
        if (message.type == GroupMessageType.poll && message.pollId != null) {
          // Delete the poll first, which will also handle the poll message
          final pollProvider = context.read<PollProvider>();
          final pollDeleted = await pollProvider.deletePoll(message.pollId!);

          if (pollDeleted) {
            // Remove message from local state
            setState(() {
              messages.removeWhere((m) => m.id == message.id);
            });

            // Show success message for poll deletion
            CustomSnackbars.showSuccessSnackbar(
              context,
              'Poll deleted successfully',
              2.0,
            );

            // Refresh messages to sync with server
            await _loadMessages();
          } else {
            throw Exception('Failed to delete poll');
          }
        } else {
          // Handle regular message deletion
          // delete media if exists in cloudinary
          if (message.mediaUrl != null) {
            await CloudinaryService.deleteFileByUrl(url: message.mediaUrl!);
          }

          final success = await GroupMessageController.deleteGroupMessage(
            message.id,
          );

          if (success) {
            // Remove message from local state
            setState(() {
              messages.removeWhere((m) => m.id == message.id);
            });

            // Show success message
            CustomSnackbars.showSuccessSnackbar(
              context,
              'Message deleted successfully',
              2.0,
            );

            // Refresh messages to sync with server
            await _loadMessages();
          } else {
            throw Exception('Failed to delete message');
          }
        }
      } catch (e) {
        CustomSnackbars.showErrorSnackbar(
          context,
          'Failed to delete message: ${e.toString()}',
        );
      }
    }
  }

  Widget _buildMessage(GroupMessage message, String time) {
    final isMe = message.senderId == HiveUtils.getData('userId');

    return Container(
      margin: EdgeInsets.symmetric(
        vertical: AppSizes.getSizeBoxHeight(context) * 0.2,
        horizontal: AppSizes.containerPadding(context),
      ),
      child: Row(
        mainAxisAlignment: isMe
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isMe) ...[
            CircleAvatar(
              radius: AppSizes.getScreenWidth(context) * 0.04,
              backgroundColor: AppColors.primary,
              child: message.senderImageUrl!.isEmpty
                  ? Text(
                      message.senderName.isNotEmpty
                          ? message.senderName[0].toUpperCase()
                          : 'I',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: AppSizes.bodyFontSize(context) * 0.8,
                      ),
                    )
                  : Image.network(
                      message.senderImageUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Text(
                        message.senderName.isNotEmpty
                            ? message.senderName[0].toUpperCase()
                            : 'U',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: AppSizes.bodyFontSize(context) * 0.8,
                        ),
                      ),
                    ),
            ),
            SizedBox(width: AppSizes.containerPadding(context)),
          ],
          Flexible(
            child: GestureDetector(
              onLongPress: () => {
                if (isMe) {_showMessageOptions(message)},
              },
              child: Container(
                margin: EdgeInsets.symmetric(
                  vertical: AppSizes.getSizeBoxHeight(context) * 0.1,
                ),
                padding: EdgeInsets.all(AppSizes.containerPadding(context)),
                constraints: BoxConstraints(
                  maxWidth: MediaQuery.of(context).size.width * 0.7,
                ),
                decoration: BoxDecoration(
                  color: isMe ? AppColors.primary : AppColors.shadeColor,
                  borderRadius: BorderRadius.circular(16.0),
                ),
                child: Container(
                  padding: EdgeInsets.all(
                    AppSizes.containerPadding(context) * 0.01,
                  ),
                  decoration: BoxDecoration(
                    color: isMe ? AppColors.primary : AppColors.shadeColor,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(
                        AppSizes.containerPadding(context),
                      ),
                      topRight: Radius.circular(
                        AppSizes.containerPadding(context),
                      ),
                      bottomLeft: Radius.circular(
                        isMe
                            ? AppSizes.containerPadding(context)
                            : AppSizes.containerPadding(context) * 0.3,
                      ),
                      bottomRight: Radius.circular(
                        isMe
                            ? AppSizes.containerPadding(context) * 0.3
                            : AppSizes.containerPadding(context),
                      ),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (!isMe)
                        Text(
                          message.senderName,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: AppSizes.bodyFontSize(context) * 0.9,
                            color: AppColors.messageReceiverColor,
                          ),
                        ),
                      Consumer<PollProvider>(
                        builder: (context, pollProvider, child) {
                          return ChatComponents.buildMessageContent(
                            isMe,
                            context,
                            true,
                            groupMessage: message,
                            poll:
                                message.type == GroupMessageType.poll &&
                                    message.pollId != null
                                ? pollProvider.getPollWithOptimisticVote(
                                    message.pollId!,
                                  )
                                : null,
                            onVote: _handlePollVote,
                          );
                        },
                      ),
                      SizedBox(
                        height: AppSizes.getSizeBoxHeight(context) * 0.2,
                      ),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Text(
                            time,
                            style: TextStyle(
                              fontSize: AppSizes.bodyFontSize(context) * 0.7,
                              color: isMe ? Colors.white70 : Colors.grey[600],
                            ),
                          ),
                          if (isMe) ...[
                            SizedBox(
                              width: AppSizes.containerPadding(context) * 0.3,
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          if (isMe) ...[
            SizedBox(width: AppSizes.containerPadding(context)),
            CircleAvatar(
              radius: AppSizes.getScreenWidth(context) * 0.04,
              backgroundColor: AppColors.primary,
              child: Text(
                message.senderName.isNotEmpty
                    ? message.senderName[0].toUpperCase()
                    : 'M',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: AppSizes.bodyFontSize(context) * 0.8,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _formatTime(DateTime dateTime) {
    return '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  void _showAttachmentOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        margin: EdgeInsets.all(AppSizes.containerPadding(context)),
        padding: EdgeInsets.all(AppSizes.containerPadding(context)),
        decoration: BoxDecoration(
          color: AppColors.backgroundColor,
          borderRadius: BorderRadius.circular(
            AppSizes.containerPadding(context),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: AppSizes.getScreenWidth(context) * 0.12,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.foregroundColor.withOpacity(0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            SizedBox(height: AppSizes.getSizeBoxHeight(context)),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildAttachmentButton(
                  icon: Icons.photo,
                  label: 'Photo',
                  color: Colors.purple,
                  onPressed: () {
                    Navigator.pop(context);
                    _sendMediaMessage(GroupMessageType.image);
                  },
                ),
                _buildAttachmentButton(
                  icon: Icons.videocam,
                  label: 'Video',
                  color: Colors.red,
                  onPressed: () {
                    Navigator.pop(context);
                    _sendMediaMessage(GroupMessageType.video);
                  },
                ),
                _buildAttachmentButton(
                  icon: Icons.attach_file,
                  label: 'File',
                  color: Colors.blue,
                  onPressed: () {
                    Navigator.pop(context);
                    _sendMediaMessage(GroupMessageType.file);
                  },
                ),
                _buildAttachmentButton(
                  icon: Icons.poll,
                  label: 'Poll',
                  color: Colors.green,
                  onPressed: () {
                    Navigator.pop(context);
                    _createPoll();
                  },
                ),
              ],
            ),
            SizedBox(height: AppSizes.getSizeBoxHeight(context)),
          ],
        ),
      ),
    );
  }

  Widget _buildAttachmentButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(
        AppSizes.containerPadding(context) * 0.5,
      ),
      child: Container(
        padding: EdgeInsets.all(AppSizes.containerPadding(context) * 0.7),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: EdgeInsets.all(AppSizes.containerPadding(context)),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(
                  AppSizes.containerPadding(context),
                ),
              ),
              child: Icon(
                icon,
                color: color,
                size: AppSizes.getScreenWidth(context) * 0.06,
              ),
            ),
            SizedBox(height: AppSizes.getSizeBoxHeight(context) * 0.3),
            Text(
              label,
              style: TextStyle(
                fontSize: AppSizes.bodyFontSize(context) * 0.85,
                color: AppColors.foregroundColor,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    AppColors.getBackgroundColor(context);

    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      appBar: AppBar(
        backgroundColor: AppColors.appBarColor,
        foregroundColor: Colors.white,
        title: Row(
          children: [
            // Group image
            CircleAvatar(
              radius: AppSizes.getScreenWidth(context) * 0.05,
              backgroundColor: AppColors.primary,
              child: widget.groupName.isNotEmpty
                  ? CachedNetworkImage(
                      imageUrl: widget.groupImage,
                      placeholder: (context, url) =>
                          CustomWidgets.circularProgressIndicator(),
                      errorWidget: (context, url, error) => Icon(Icons.error),
                    )
                  : Icon(
                      Icons.group,
                      color: Colors.white,
                      size: AppSizes.getScreenWidth(context) * 0.06,
                    ),
            ),
            Text(
              widget.groupName,
              style: TextStyle(
                fontSize: AppSizes.titleFontSize(context),
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.info),
            onPressed: () {
              if (group != null) {
                _showGroupInfo();
              }
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Messages list
          Expanded(
            child: isLoading
                ? Center(
                    child: CustomWidgets.circularProgressIndicator(),
                  )
                : messages.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.chat_outlined,
                          size: 80,
                          color: Colors.grey[400],
                        ),
                        SizedBox(height: 16),
                        Text(
                          'No messages yet',
                          style: TextStyle(
                            fontSize: AppSizes.subtitleFontSize(context),
                            color: Colors.grey[600],
                          ),
                        ),
                        Text(
                          'Start the conversation!',
                          style: TextStyle(
                            fontSize: AppSizes.bodyFontSize(context),
                            color: Colors.grey[500],
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    controller: _scrollController,
                    reverse: true,
                    itemCount: messages.length,
                    itemBuilder: (context, index) {
                      final message = messages[index];
                      final localTime = message.createdAt.toLocal();
                      final time = TimeUtils.formatTimePKT(message.createdAt);

                      // Show date header if this is first message or date changed from previous message
                      final showDateHeader =
                          index == 0 ||
                          !ChatComponents.isSameDay(
                            messages[index - 1].createdAt.toLocal(),
                            message.createdAt.toLocal(),
                          );

                      return Column(
                        children: [
                          if (showDateHeader)
                            ChatComponents.buildDateHeader(message.createdAt),
                          _buildMessage(message, time),
                        ],
                      );
                    },
                  ),
          ),

          // Loading indicator when sending
          if (isSending)
            SizedBox(
              height: 2.5,
              child: LinearProgressIndicator(
                backgroundColor: AppColors.shadeColor,
                valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
              ),
            ),

          // Input area
          Container(
            padding: EdgeInsets.all(8.0),
            decoration: BoxDecoration(color: AppColors.shadeColor),
            child: Consumer<AudioProvider>(
              builder: (context, audioProvider, child) {
                return Row(
                  children: [
                    IconButton(
                      icon: Icon(Icons.add, color: AppColors.primary),
                      onPressed: () {
                        _showAttachmentOptions();
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
                        await _sendVoiceMessage(recordingPath);
                      },
                      onStartRecording: () {
                        // No need to hide attachment options since we're using bottom sheet
                      },
                      onCancelRecording: () {
                        // Optional: Handle any cleanup when recording is cancelled
                      },
                    ),
                    if (!audioProvider.isRecording)
                      IconButton(
                        icon: Icon(Icons.send, color: AppColors.primary),
                        onPressed: () {
                          if (_messageController.text.trim().isNotEmpty) {
                            _sendTextMessage();
                          }
                        },
                      ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _showGroupInfo() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Group Information'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Name: ${widget.groupName}'),
            SizedBox(height: 8),
            Text('Participants: ${group?.participants.length ?? 0}'),
            SizedBox(height: AppSizes.getSizeBoxHeight(context) * 0.5),
            if (group?.createdAt != null)
              Text('Created: ${_formatTime(group!.createdAt)}'),
            SizedBox(height: AppSizes.getSizeBoxHeight(context)),
            Text('Members:', style: TextStyle(fontWeight: FontWeight.bold)),
            if (group?.participants != null)
              ...group!.participants
                  .map(
                    (user) => Padding(
                      padding: EdgeInsets.only(
                        left: AppSizes.containerPadding(context),
                        top: AppSizes.getSizeBoxHeight(context) * 0.25,
                      ),
                      child: Text('• ${user.name}'),
                    ),
                  )
                  .toList(),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Close'),
          ),
        ],
      ),
    );
  }
}

// Helper widget for rounded corners
class ClipRounded extends StatelessWidget {
  final Widget child;
  final double radius;

  const ClipRounded({Key? key, required this.child, this.radius = 12.0})
    : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ClipRRect(borderRadius: BorderRadius.circular(radius), child: child);
  }
}
