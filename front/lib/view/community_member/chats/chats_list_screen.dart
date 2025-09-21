import 'package:front/controller/chats/chat_controller.dart';
import 'package:front/model/chats/chat_model.dart';
import 'package:front/utils/app_colors.dart';
import 'package:front/utils/hive_utils.dart';
import 'package:front/utils/snackbars.dart';
import 'package:front/view/community_member/chats/chat_screen.dart';
import 'package:front/view/community_member/chats/new_chat_screen.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class ChatsListScreen extends StatefulWidget {
  const ChatsListScreen({super.key});

  @override
  State<ChatsListScreen> createState() => _ChatsListScreenState();
}

class _ChatsListScreenState extends State<ChatsListScreen> {
  late Future<List<ChatModel>> _chatsFuture;
  String? currentUserId;

  @override
  void initState() {
    super.initState();
    _loadCurrentUserId();
    _refreshChats();
  }

  Future<void> _loadCurrentUserId() async {
    // Get current user ID from local storage
    currentUserId = HiveUtils.getData('userId');
  }

  void _refreshChats() {
    setState(() {
      _chatsFuture = ChatController.fetchChats();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: RefreshIndicator(
        color: AppColors.primary,
        onRefresh: () async {
          _refreshChats();
          return Future.delayed(Duration(milliseconds: 500));
        },
        child: FutureBuilder<List<ChatModel>>(
          future: _chatsFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(
                child: CircularProgressIndicator(color: AppColors.primary),
              );
            } else if (snapshot.hasError) {
              return Center(child: Text('Error: ${snapshot.error}'));
            } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'No chats found',
                      style: TextStyle(
                        fontSize: 18,
                        color: AppColors.foregroundColor,
                      ),
                    ),
                    SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => NewChatScreen(),
                          ),
                        ).then((_) => _refreshChats());
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.buttonColor,
                      ),
                      child: Text('Start a New Chat'),
                    ),
                  ],
                ),
              );
            } else {
              final chats = snapshot.data!;
              return ListView.builder(
                itemCount: chats.length,
                itemBuilder: (context, index) {
                  final chat = chats[index];
                  final otherUserName = currentUserId != null
                      ? chat.getChatName(currentUserId!)
                      : 'Chat';

                  // Format the date - convert from UTC to local time
                  final lastMessageTime = chat.lastMessage?.createdAt;
                  final formattedTime = lastMessageTime != null
                      ? DateFormat.jm().format(lastMessageTime.toLocal())
                      : '';

                  return Card(
                    margin: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                    color: AppColors.shadeColor,
                    child: Dismissible(
                      key: Key(chat.id),
                      background: Container(
                        color: Colors.red,
                        alignment: Alignment.centerRight,
                        padding: EdgeInsets.symmetric(horizontal: 20),
                        child: Icon(Icons.delete, color: Colors.white),
                      ),
                      direction: DismissDirection.endToStart,
                      confirmDismiss: (direction) async {
                        return await showDialog(
                          context: context,
                          builder: (BuildContext context) {
                            return AlertDialog(
                              title: Text('Delete Chat?'),
                              content: Text(
                                'Are you sure you want to delete this chat?',
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () =>
                                      Navigator.of(context).pop(false),
                                  child: Text('Cancel'),
                                ),
                                TextButton(
                                  onPressed: () =>
                                      Navigator.of(context).pop(true),
                                  child: Text('Delete'),
                                ),
                              ],
                            );
                          },
                        );
                      },
                      onDismissed: (direction) async {
                        try {
                          await ChatController.deleteChat(chat.id);
                          CustomSnackbars.showSuccessSnackbar(
                            context,
                            'Chat deleted',
                            1.0,
                          );
                          _refreshChats();
                        } catch (e) {
                          CustomSnackbars.showErrorSnackbar(
                            context,
                            'Failed to delete chat: $e',
                  
                          );
                          _refreshChats(); // Refresh to restore the deleted chat
                        }
                      },
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: AppColors.primary,
                          child: Text(
                            otherUserName.isNotEmpty
                                ? otherUserName[0].toUpperCase()
                                : '?',
                            style: TextStyle(color: Colors.white),
                          ),
                        ),
                        title: Text(otherUserName),
                        subtitle: chat.lastMessage != null
                            ? Text(
                                chat.lastMessage!.content ?? 'Media message',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              )
                            : Text('No messages yet'),
                        trailing: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(formattedTime, style: TextStyle(fontSize: 12)),
                            SizedBox(height: 5),
                          ],
                        ),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => ChatScreen(
                                chatId: chat.id,
                                chatName: otherUserName,
                              ),
                            ),
                          );
                        },
                        onLongPress: () {
                          showDialog(
                            context: context,
                            builder: (BuildContext context) {
                              return AlertDialog(
                                title: Text('Chat Options'),
                                content: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    ListTile(
                                      leading: Icon(Icons.delete),
                                      title: Text('Delete Chat'),
                                      onTap: () async {
                                        Navigator.pop(context);
                                        try {
                                          await ChatController.deleteChat(
                                            chat.id,
                                          );
                                          CustomSnackbars.showSuccessSnackbar(
                                            context,
                                            'Chat deleted',
                                            1.0,
                                          );
                                          _refreshChats();
                                        } catch (e) {
                                          CustomSnackbars.showErrorSnackbar(
                                            context,
                                            'Failed to delete chat: $e',
                                          );
                                          _refreshChats(); // Refresh to restore the deleted chat
                                        }
                                      },
                                    ),
                                    ListTile(
                                      leading: Icon(Icons.mark_chat_read),
                                      title: Text('Mark as Read'),
                                      onTap: () async {
                                        Navigator.pop(context);
                                        try {
                                          await ChatController.markChatAsRead(
                                            chat.id,
                                          );
                                          CustomSnackbars.showSuccessSnackbar(
                                            context,
                                            'Chat marked as read',
                                            1.0,
                                          );
                                          _refreshChats();
                                        } catch (e) {
                                          CustomSnackbars.showErrorSnackbar(
                                            context,
                                            'Failed to mark chat as read: $e',
                                          );
                                        }
                                      },
                                    ),
                                  ],
                                ),
                              );
                            },
                          );
                        },
                      ),
                    ),
                  );
                },
              );
            }
          },
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => NewChatScreen()),
          ).then((_) => _refreshChats());
        },
        backgroundColor: AppColors.primary,
        child: Icon(Icons.chat, color: AppColors.foregroundColor),
      ),
    );
  }
}
