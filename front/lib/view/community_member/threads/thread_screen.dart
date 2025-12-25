import 'package:flutter/material.dart';
import 'package:front/controller/groups/thread_message_controller.dart';
import 'package:front/model/groups/thread_message_model.dart';
import 'package:front/utils/app_colors.dart';
import 'package:front/utils/custom_widgets.dart';
import 'package:front/utils/sizes.dart';
import 'package:front/utils/snackbars.dart';
import 'package:front/utils/time_utils.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'dart:async';

class ThreadScreen extends StatefulWidget {
  final String threadId;
  final String topicName;
  final String currentUserId;

  const ThreadScreen({
    super.key,
    required this.threadId,
    required this.topicName,
    required this.currentUserId,
  });

  @override
  State<ThreadScreen> createState() => _ThreadScreenState();
}

class _ThreadScreenState extends State<ThreadScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  List<ThreadMessage> _messages = [];
  bool _isLoading = false;
  bool _isSending = false;
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    _loadMessages();
    ThreadMessageController.joinThreadRoom(widget.threadId);
    ThreadMessageController.listenForNewMessages(_onNewMessage);
    ThreadMessageController.listenForDeletedMessages(_onMessageDeleted);

    // Refresh messages every 3 seconds to ensure UI stays updated
    _refreshTimer = Timer.periodic(const Duration(seconds: 3), (timer) {
      if (mounted) {
        _loadMessages(silent: true);
      }
    });
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    _messageController.dispose();
    _scrollController.dispose();
    ThreadMessageController.leaveThreadRoom(widget.threadId);
    super.dispose();
  }

  Future<void> _loadMessages({bool silent = false}) async {
    if (!silent) {
      setState(() => _isLoading = true);
    }
    final result = await ThreadMessageController.getThreadMessages(
      threadId: widget.threadId,
    );
    if (mounted) {
      setState(() {
        _messages = result['messages'] as List<ThreadMessage>;
        if (!silent) {
          _isLoading = false;
        }
      });
      if (!silent) {
        _scrollToBottom();
      }
    }
  }

  void _onNewMessage(ThreadMessage message) {
    setState(() {
      _messages.add(message);
    });
    _scrollToBottom();
  }

  void _onMessageDeleted(String messageId) {
    setState(() {
      final index = _messages.indexWhere((m) => m.id == messageId);
      if (index != -1) {
        _messages[index] = ThreadMessage(
          id: _messages[index].id,
          threadId: _messages[index].threadId,
          senderId: _messages[index].senderId,
          senderName: _messages[index].senderName,
          senderImageUrl: _messages[index].senderImageUrl,
          message: 'This message was deleted',
          isDeleted: true,
          readBy: _messages[index].readBy,
          createdAt: _messages[index].createdAt,
          updatedAt: DateTime.now(),
        );
      }
    });
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      Future.delayed(const Duration(milliseconds: 100), () {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      });
    }
  }

  Future<void> _sendMessage() async {
    if (_messageController.text.trim().isEmpty) return;

    final message = _messageController.text.trim();
    _messageController.clear();

    setState(() => _isSending = true);

    final result = await ThreadMessageController.sendMessage(
      threadId: widget.threadId,
      message: message,
    );

    setState(() => _isSending = false);

    if (!result.contains('success')) {
      CustomSnackbars.showErrorSnackbar(context, result);
    }
  }

  Future<void> _deleteMessage(ThreadMessage message) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Message'),
        content: const Text('Are you sure you want to delete this message?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      final result = await ThreadMessageController.deleteMessage(message.id);
      if (mounted) {
        if (result.contains('success')) {
          CustomSnackbars.showSuccessSnackbar(context, result, 1);
        } else {
          CustomSnackbars.showErrorSnackbar(context, result);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.topicName,
              style: TextStyle(
                color: AppColors.foregroundColor,
                fontSize: AppSizes.titleFontSize(context),
              ),
            ),
            Text(
              '${_messages.length} messages',
              style: TextStyle(
                color: AppColors.foregroundColor.withOpacity(0.7),
                fontSize: AppSizes.subtitleFontSize(context) * 0.8,
              ),
            ),
          ],
        ),
        backgroundColor: AppColors.appBarColor,
        iconTheme: IconThemeData(color: AppColors.foregroundColor),
      ),
      body: Column(
        children: [
          // Messages list
          Expanded(
            child: _isLoading
                ? Center(child: CustomWidgets.circularProgressIndicator())
                : _messages.isEmpty
                ? Center(
                    child: Text(
                      'No messages yet.\nBe the first to start the discussion!',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: AppColors.shadeColor,
                        fontSize: AppSizes.subtitleFontSize(context),
                      ),
                    ),
                  )
                : ListView.builder(
                    controller: _scrollController,
                    padding: EdgeInsets.all(AppSizes.mediumPadding(context)),
                    itemCount: _messages.length,
                    itemBuilder: (context, index) {
                      final message = _messages[index];
                      final isMyMessage =
                          message.senderId == widget.currentUserId;
                      final showDate =
                          index == 0 ||
                          !_isSameDay(
                            _messages[index - 1].createdAt,
                            message.createdAt,
                          );

                      return Column(
                        children: [
                          if (showDate) _buildDateDivider(message.createdAt),
                          _buildMessageBubble(message, isMyMessage),
                        ],
                      );
                    },
                  ),
          ),

          // Message input
          Container(
            padding: EdgeInsets.all(AppSizes.smallPadding(context)),
            decoration: BoxDecoration(
              color: AppColors.backgroundColor,
              border: Border(
                top: BorderSide(color: AppColors.shadeColor.withOpacity(0.2)),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: InputDecoration(
                      hintText: 'Type a message...',
                      hintStyle: TextStyle(color: AppColors.shadeColor),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide(color: AppColors.shadeColor),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide(color: AppColors.shadeColor),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide(color: AppColors.primary),
                      ),
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: AppSizes.mediumPadding(context),
                        vertical: AppSizes.smallPadding(context),
                      ),
                    ),
                    style: TextStyle(color: AppColors.foregroundColor),
                    maxLines: null,
                    textCapitalization: TextCapitalization.sentences,
                  ),
                ),
                SizedBox(width: AppSizes.smallSpacing(context)),
                _isSending
                    ? Center(child: CustomWidgets.circularProgressIndicator())
                    : IconButton(
                        onPressed: _sendMessage,
                        icon: Icon(Icons.send, color: AppColors.primary),
                        iconSize: 28,
                      ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDateDivider(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final messageDate = DateTime(date.year, date.month, date.day);

    String dateText;
    if (messageDate == today) {
      dateText = 'Today';
    } else if (messageDate == today.subtract(const Duration(days: 1))) {
      dateText = 'Yesterday';
    } else {
      dateText = TimeUtils.formatDatePKT(date);
    }

    return Padding(
      padding: EdgeInsets.symmetric(vertical: AppSizes.mediumSpacing(context)),
      child: Row(
        children: [
          Expanded(
            child: Divider(color: AppColors.shadeColor.withOpacity(0.3)),
          ),
          Padding(
            padding: EdgeInsets.symmetric(
              horizontal: AppSizes.mediumPadding(context),
            ),
            child: Text(
              dateText,
              style: TextStyle(
                color: AppColors.shadeColor,
                fontSize: AppSizes.subtitleFontSize(context) * 0.85,
              ),
            ),
          ),
          Expanded(
            child: Divider(color: AppColors.shadeColor.withOpacity(0.3)),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(ThreadMessage message, bool isMyMessage) {
    return Align(
      alignment: isMyMessage ? Alignment.centerRight : Alignment.centerLeft,
      child: GestureDetector(
        onLongPress: isMyMessage && !message.isDeleted
            ? () => _deleteMessage(message)
            : null,
        child: Container(
          margin: EdgeInsets.only(
            bottom: AppSizes.smallSpacing(context),
            left: isMyMessage ? 50 : 0,
            right: isMyMessage ? 0 : 50,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (!isMyMessage) ...[
                CircleAvatar(
                  radius: 16,
                  backgroundColor: AppColors.primary.withOpacity(0.2),
                  backgroundImage: message.senderImageUrl != null
                      ? CachedNetworkImageProvider(message.senderImageUrl!)
                      : null,
                  child: message.senderImageUrl == null
                      ? Icon(Icons.person, size: 16, color: AppColors.primary)
                      : null,
                ),
                SizedBox(width: AppSizes.smallSpacing(context)),
              ],
              Flexible(
                child: Column(
                  crossAxisAlignment: isMyMessage
                      ? CrossAxisAlignment.end
                      : CrossAxisAlignment.start,
                  children: [
                    if (!isMyMessage)
                      Padding(
                        padding: EdgeInsets.only(
                          left: AppSizes.smallPadding(context),
                          bottom: 4,
                        ),
                        child: Text(
                          message.senderName,
                          style: TextStyle(
                            color: AppColors.shadeColor,
                            fontSize: AppSizes.subtitleFontSize(context) * 0.85,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: AppSizes.mediumPadding(context),
                        vertical: AppSizes.smallPadding(context),
                      ),
                      decoration: BoxDecoration(
                        color: message.isDeleted
                            ? AppColors.shadeColor.withOpacity(0.1)
                            : isMyMessage
                            ? AppColors.primary
                            : AppColors.shadeColor.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            message.message,
                            style: TextStyle(
                              color: message.isDeleted
                                  ? AppColors.shadeColor
                                  : isMyMessage
                                  ? AppColors.foregroundColor
                                  : AppColors.titleColor,
                              fontSize: AppSizes.subtitleFontSize(context),
                              fontStyle: message.isDeleted
                                  ? FontStyle.italic
                                  : FontStyle.normal,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            TimeUtils.formatTimePKT(message.createdAt),
                            style: TextStyle(
                              color: isMyMessage
                                  ? AppColors.foregroundColor.withOpacity(0.7)
                                  : AppColors.shadeColor,
                              fontSize:
                                  AppSizes.subtitleFontSize(context) * 0.75,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  bool _isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year &&
        date1.month == date2.month &&
        date1.day == date2.day;
  }
}
