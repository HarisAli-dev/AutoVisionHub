import 'package:flutter/material.dart';
import 'package:front/model/events/live_stream_chat_message.dart';
import 'package:front/services/socket_service.dart';
import 'package:front/services/gemini_chatbot_service.dart';
import 'package:front/model/events/event_model.dart';
import 'package:front/utils/app_colors.dart';
import 'package:front/utils/sizes.dart';
import 'package:front/utils/hive_utils.dart';
import 'package:front/config/app_config.dart';

/// Widget for live stream chat with AI chatbot integration
class LiveStreamChatWidget extends StatefulWidget {
  final String roomId;
  final EventModel event;
  final bool enableChatbot;

  const LiveStreamChatWidget({
    super.key,
    required this.roomId,
    required this.event,
    this.enableChatbot = true,
  });

  @override
  State<LiveStreamChatWidget> createState() => _LiveStreamChatWidgetState();
}

class _LiveStreamChatWidgetState extends State<LiveStreamChatWidget> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final SocketService _socketService = SocketService();

  final List<LiveStreamChatMessage> _messages = [];
  bool _isSendingMessage = false;
  bool _showQuickReplies = false;
  String? _currentUserId;

  @override
  void initState() {
    super.initState();
    debugPrint('\n🚀🚀🚀 CHAT WIDGET INITIALIZED 🚀🚀🚀');
    debugPrint('Room ID: ${widget.roomId}');
    debugPrint('Event: ${widget.event.eventName}');
    debugPrint('Chatbot enabled: ${widget.enableChatbot}');
    debugPrint('Gemini configured: ${GeminiChatbotService.isConfigured()}');
    debugPrint('Gemini API key length: ${AppConfig.geminiApiKey.length}');
    debugPrint('🚀🚀🚀🚀🚀🚀🚀🚀🚀🚀🚀🚀🚀🚀🚀🚀🚀\n');

    _currentUserId = HiveUtils.getData('userId');
    _setupChatListeners();
    _requestChatHistory();
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  /// Setup socket listeners for chat
  void _setupChatListeners() {
    _socketService.setLiveStreamCallbacks(
      onNewLiveStreamChat: (data) {
        if (mounted) {
          _handleNewMessage(data);
        }
      },
      onChatHistory: (messages) {
        if (mounted) {
          _handleChatHistory(messages);
        }
      },
    );
  }

  /// Request chat history from server
  void _requestChatHistory() {
    _socketService.requestLiveStreamChatHistory(widget.roomId);
  }

  /// Handle new chat message
  void _handleNewMessage(dynamic data) {
    try {
      final message = LiveStreamChatMessage.fromJson(data);
      setState(() {
        _messages.add(message);
      });
      _scrollToBottom();
    } catch (e) {
      debugPrint('Error handling new message: $e');
    }
  }

  /// Handle chat history
  void _handleChatHistory(List<dynamic> messages) {
    try {
      final chatMessages = messages
          .map((msg) => LiveStreamChatMessage.fromJson(msg))
          .toList();
      setState(() {
        _messages.clear();
        _messages.addAll(chatMessages);
      });
      _scrollToBottom();
    } catch (e) {
      debugPrint('Error handling chat history: $e');
    }
  }

  /// Send a chat message
  Future<void> _sendMessage() async {
    final message = _messageController.text.trim();
    if (message.isEmpty || _isSendingMessage) return;

    setState(() {
      _isSendingMessage = true;
    });

    try {
      debugPrint('\n========================================');
      debugPrint('📤 SENDING USER MESSAGE');
      debugPrint('Message: $message');
      debugPrint('Room ID: ${widget.roomId}');

      // Send message via socket
      _socketService.sendLiveStreamChatMessage(
        roomId: widget.roomId,
        message: message,
      );

      _messageController.clear();

      // Check if chatbot should respond
      debugPrint('🤖 CHATBOT CHECK:');
      debugPrint('  - Chatbot enabled: ${widget.enableChatbot}');
      debugPrint(
        '  - Gemini configured: ${GeminiChatbotService.isConfigured()}',
      );

      if (widget.enableChatbot && GeminiChatbotService.isConfigured()) {
        debugPrint('  ✅ Proceeding with chatbot processing');
        _processMessageForChatbot(message);
      } else {
        debugPrint('  ❌ Chatbot processing skipped');
        if (!widget.enableChatbot) {
          debugPrint('     Reason: Chatbot not enabled');
        }
        if (!GeminiChatbotService.isConfigured()) {
          debugPrint('     Reason: Gemini not configured');
        }
      }
    } catch (e) {
      debugPrint('❌ Error sending message: $e');
    } finally {
      setState(() {
        _isSendingMessage = false;
      });
    }
  }

  /// Process message to see if chatbot should respond
  Future<void> _processMessageForChatbot(String message) async {
    debugPrint('\n========================================');
    debugPrint('🤖 CHATBOT PROCESSING START');
    debugPrint('Message: "$message"');
    debugPrint('Event: ${widget.event.eventName}');

    try {
      // Generate event context
      debugPrint('📋 Generating event context...');
      final eventContext = GeminiChatbotService.generateEventContext(
        eventName: widget.event.eventName,
        eventDescription: widget.event.eventDescription,
        eventLocation: widget.event.eventLocation,
        eventDateTime: widget.event.eventDateTime,
        viewerCount: _messages.length,
      );
      debugPrint('Event context length: ${eventContext.length} chars');

      // Get recent chat history for context (last 10 messages)
      final recentMessages = _messages.length > 10
          ? _messages.sublist(_messages.length - 10)
          : _messages;

      debugPrint('📜 Chat history: ${recentMessages.length} messages');

      final chatHistory = recentMessages
          .map(
            (msg) => {
              'role': msg.isBot ? 'bot' : 'user',
              'message': '${msg.senderName}: ${msg.message}',
            },
          )
          .toList();

      // Check if bot should respond
      final userName = HiveUtils.getData('name') ?? 'User';
      final isBotMention =
          message.toLowerCase().contains('@bot') ||
          message.toLowerCase().contains('hey bot');

      debugPrint('👤 User: $userName');
      debugPrint('📢 Bot mentioned: $isBotMention');
      debugPrint('🔍 Calling processLiveStreamMessage...');

      final botResponse = await GeminiChatbotService.processLiveStreamMessage(
        message: message,
        senderName: userName,
        isBotMention: isBotMention,
        eventContext: eventContext,
        chatHistory: chatHistory,
      );

      debugPrint(
        '💬 Bot response received: ${botResponse != null ? "YES (${botResponse.length} chars)" : "NO (null)"}',
      );
      if (botResponse != null) {
        debugPrint(
          'Response preview: ${botResponse.substring(0, botResponse.length > 100 ? 100 : botResponse.length)}',
        );
      }

      // If bot should respond, send the response
      if (botResponse != null && mounted) {
        debugPrint('📤 Sending bot response to room: ${widget.roomId}');
        _socketService.sendLiveStreamChatMessage(
          roomId: widget.roomId,
          message: botResponse,
          isBot: true,
        );
        debugPrint('✅ Bot message sent successfully');
      } else {
        if (botResponse == null) {
          debugPrint('❌ Bot response is null - not sending');
        }
        if (!mounted) {
          debugPrint('❌ Widget not mounted - not sending');
        }
      }

      debugPrint('🤖 CHATBOT PROCESSING END');
      debugPrint('========================================\n');
    } catch (e, stackTrace) {
      debugPrint('\n========================================');
      debugPrint('❌ CHATBOT ERROR');
      debugPrint('Error: $e');
      debugPrint('Stack trace: $stackTrace');
      debugPrint('========================================\n');
    }
  }

  /// Send a quick reply message
  void _sendQuickReply(String message) {
    _messageController.text = message;
    _sendMessage();
    setState(() {
      _showQuickReplies = false;
    });
  }

  /// Scroll to bottom of chat
  void _scrollToBottom() {
    if (_scrollController.hasClients) {
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
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 400,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppSizes.cardBorderRadius(context)),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        children: [
          // Chat header
          _buildChatHeader(),

          // Messages list
          Expanded(
            child: _messages.isEmpty
                ? _buildEmptyState()
                : ListView.builder(
                    controller: _scrollController,
                    padding: EdgeInsets.all(AppSizes.smallPadding(context)),
                    itemCount: _messages.length,
                    itemBuilder: (context, index) {
                      return _buildMessageBubble(_messages[index]);
                    },
                  ),
          ),

          // Quick replies (if enabled)
          if (_showQuickReplies) _buildQuickReplies(),

          // Message input
          _buildMessageInput(),
        ],
      ),
    );
  }

  /// Build chat header
  Widget _buildChatHeader() {
    return Container(
      padding: EdgeInsets.all(AppSizes.mediumPadding(context)),
      decoration: BoxDecoration(
        color: AppColors.appBarColor,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(AppSizes.cardBorderRadius(context)),
          topRight: Radius.circular(AppSizes.cardBorderRadius(context)),
        ),
      ),
      child: Row(
        children: [
          Icon(Icons.chat, color: AppColors.foregroundColor),
          SizedBox(width: AppSizes.smallPadding(context)),
          Expanded(
            child: Text(
              'Live Chat',
              style: TextStyle(
                color: AppColors.foregroundColor,
                fontSize: AppSizes.subtitleFontSize(context),
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          if (widget.enableChatbot && GeminiChatbotService.isConfigured())
            Tooltip(
              message: 'AI Chatbot Active',
              child: Container(
                padding: EdgeInsets.symmetric(
                  horizontal: AppSizes.smallPadding(context),
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: Colors.green.shade100,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.smart_toy, size: 16, color: Colors.green),
                    const SizedBox(width: 4),
                    Text(
                      'AI',
                      style: TextStyle(
                        fontSize: AppSizes.captionFontSize(context),
                        color: Colors.green.shade700,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  /// Build empty state
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.chat_bubble_outline,
            size: 64,
            color: Colors.grey.shade300,
          ),
          SizedBox(height: AppSizes.mediumSpacing(context)),
          Text(
            'No messages yet',
            style: TextStyle(
              fontSize: AppSizes.bodyFontSize(context),
              color: Colors.grey.shade600,
            ),
          ),
          SizedBox(height: AppSizes.smallSpacing(context)),
          Text(
            'Be the first to say something!',
            style: TextStyle(
              fontSize: AppSizes.smallFontSize(context),
              color: Colors.grey.shade500,
            ),
          ),
        ],
      ),
    );
  }

  /// Build message bubble
  Widget _buildMessageBubble(LiveStreamChatMessage message) {
    final isCurrentUser = message.senderId == _currentUserId;
    final isBot = message.isBot;

    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: isCurrentUser
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isCurrentUser && !isBot) ...[
            CircleAvatar(
              radius: 16,
              backgroundColor: AppColors.appBarColor,
              child: Text(
                message.senderName[0].toUpperCase(),
                style: TextStyle(
                  color: AppColors.foregroundColor,
                  fontSize: AppSizes.smallFontSize(context),
                ),
              ),
            ),
            SizedBox(width: AppSizes.smallPadding(context)),
          ],
          if (isBot) ...[
            CircleAvatar(
              radius: 16,
              backgroundColor: Colors.green.shade100,
              child: Icon(Icons.smart_toy, size: 16, color: Colors.green),
            ),
            SizedBox(width: AppSizes.smallPadding(context)),
          ],
          Flexible(
            child: Container(
              padding: EdgeInsets.symmetric(
                horizontal: AppSizes.mediumPadding(context),
                vertical: AppSizes.smallPadding(context),
              ),
              decoration: BoxDecoration(
                color: isBot
                    ? Colors.green.shade50
                    : isCurrentUser
                    ? AppColors.primary
                    : Colors.grey.shade200,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (!isCurrentUser)
                    Text(
                      message.senderName,
                      style: TextStyle(
                        fontSize: AppSizes.smallFontSize(context),
                        fontWeight: FontWeight.bold,
                        color: isBot
                            ? Colors.green.shade700
                            : Colors.grey.shade700,
                      ),
                    ),
                  if (!isCurrentUser) const SizedBox(height: 4),
                  Text(
                    message.message,
                    style: TextStyle(
                      fontSize: AppSizes.bodyFontSize(context),
                      color: isCurrentUser ? Colors.white : Colors.black87,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Build quick replies
  Widget _buildQuickReplies() {
    final quickReplies = GeminiChatbotService.getQuickReplies();

    return Container(
      padding: EdgeInsets.all(AppSizes.smallPadding(context)),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        border: Border(top: BorderSide(color: Colors.grey.shade300)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Quick Questions:',
            style: TextStyle(
              fontSize: AppSizes.smallFontSize(context),
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade700,
            ),
          ),
          SizedBox(height: AppSizes.smallSpacing(context)),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: quickReplies.map((reply) {
              return InkWell(
                onTap: () => _sendQuickReply(reply),
                child: Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: AppSizes.mediumPadding(context),
                    vertical: AppSizes.smallPadding(context),
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.primary),
                  ),
                  child: Text(
                    reply,
                    style: TextStyle(
                      fontSize: AppSizes.smallFontSize(context),
                      color: AppColors.primary,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  /// Build message input
  Widget _buildMessageInput() {
    return Container(
      padding: EdgeInsets.all(AppSizes.mediumPadding(context)),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Colors.grey.shade300)),
      ),
      child: Row(
        children: [
          if (widget.enableChatbot)
            IconButton(
              icon: Icon(
                _showQuickReplies ? Icons.close : Icons.help_outline,
                color: AppColors.primary,
              ),
              onPressed: () {
                setState(() {
                  _showQuickReplies = !_showQuickReplies;
                });
              },
              tooltip: 'Quick Questions',
            ),
          Expanded(
            child: TextField(
              controller: _messageController,
              decoration: InputDecoration(
                hintText: 'Type a message...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                contentPadding: EdgeInsets.symmetric(
                  horizontal: AppSizes.mediumPadding(context),
                  vertical: AppSizes.smallPadding(context),
                ),
              ),
              onSubmitted: (_) => _sendMessage(),
              maxLines: null,
            ),
          ),
          SizedBox(width: AppSizes.smallPadding(context)),
          IconButton(
            icon: _isSendingMessage
                ? SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Icon(Icons.send, color: AppColors.primary),
            onPressed: _isSendingMessage ? null : _sendMessage,
          ),
        ],
      ),
    );
  }
}
