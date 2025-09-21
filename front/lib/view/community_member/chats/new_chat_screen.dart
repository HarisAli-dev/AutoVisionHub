import 'package:cached_network_image/cached_network_image.dart';
import 'package:front/controller/chats/chat_controller.dart';
import 'package:front/controller/users/user_controller.dart';
import 'package:front/model/users/user_model.dart';
import 'package:front/utils/app_colors.dart';
import 'package:front/utils/hive_utils.dart';
import 'package:front/view/community_member/chats/chat_screen.dart';
import 'package:flutter/material.dart';

class NewChatScreen extends StatefulWidget {
  const NewChatScreen({super.key});

  @override
  State<NewChatScreen> createState() => _NewChatScreenState();
}

class _NewChatScreenState extends State<NewChatScreen> {
  late Future<List<User>> _usersFuture;
  final TextEditingController _searchController = TextEditingController();
  List<User> _allUsers = [];
  List<User> _filteredUsers = [];
  bool _isLoading = false;
  String? _currentUserId;

  @override
  void initState() {
    super.initState();
    _loadCurrentUserId();
  }

  Future<void> _loadCurrentUserId() async {
    _currentUserId = HiveUtils.getData('userId');
    if (_currentUserId != null) {
      _loadUsers();
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('User ID not found')));
    }
  }

  void _loadUsers() {
    setState(() {
      _isLoading = true;
    });

    if (_currentUserId != null) {
      _usersFuture = UserController.getNewChatUsers(userId: _currentUserId!);

      _usersFuture
          .then((users) {
            setState(() {
              _allUsers = users;
              _filteredUsers = List.from(_allUsers);
              _isLoading = false;
            });
          })
          .catchError((error) {
            setState(() {
              _isLoading = false;
            });
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Error loading users: $error')),
            );
          });
    }
  }

  void _filterUsers(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredUsers = List.from(_allUsers);
      } else {
        _filteredUsers = _allUsers
            .where(
              (user) =>
                  user.name.toLowerCase().contains(query.toLowerCase()) ||
                  user.email.toLowerCase().contains(query.toLowerCase()),
            )
            .toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('New Chat'),
        backgroundColor: AppColors.appBarColor,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                labelText: 'Search Users',
                hintText: 'Enter name or email',
                prefixIcon: Icon(Icons.search, color: AppColors.primary),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: AppColors.primary),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: AppColors.primary, width: 2),
                ),
              ),
              onChanged: _filterUsers,
            ),
          ),
          Expanded(
            child: _isLoading
                ? Center(
                    child: CircularProgressIndicator(color: AppColors.primary),
                  )
                : _filteredUsers.isEmpty
                ? Center(
                    child: Text(
                      'No users found to chat with',
                      style: TextStyle(fontSize: 16),
                    ),
                  )
                : ListView.builder(
                    itemCount: _filteredUsers.length,
                    itemBuilder: (context, index) {
                      final user = _filteredUsers[index];
                      return ListTile(
                        leading: CircleAvatar(
                          backgroundColor: AppColors.primary,
                          child: CachedNetworkImage(
                            imageUrl: user.profileImageUrl ?? '',
                            placeholder: (context, url) => Icon(
                              Icons.person,
                              color: AppColors.foregroundColor,
                            ),
                            errorWidget: (context, url, error) => Icon(
                              Icons.error,
                              color: AppColors.foregroundColor,
                            ),
                            fit: BoxFit.cover,
                          ),
                        ),
                        title: Text(user.name),
                        subtitle: Text(user.email),
                        onTap: () => _startChat(user),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  void _startChat(User user) async {
    try {
      setState(() {
        _isLoading = true;
      });

      // Use the getChatWithUser method to get or create a chat with this user
      final chat = await ChatController.createChatWithUser(user.id!);

      setState(() {
        _isLoading = false;
      });

      // Navigate to chat screen
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) =>
              ChatScreen(chatId: chat.id, chatName: user.name),
        ),
      ).then((_) {
        // Return to this screen and possibly refresh the list
        Navigator.pop(context);
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to start chat: $e')));
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}
