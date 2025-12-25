import 'package:flutter/material.dart';
import 'package:front/controller/users/user_controller.dart';
import 'package:front/model/users/user_model.dart';
import 'package:front/utils/app_colors.dart';
import 'package:front/utils/sizes.dart';
import 'package:front/utils/snackbars.dart';

class ManageUsersScreen extends StatefulWidget {
  const ManageUsersScreen({super.key});

  @override
  State<ManageUsersScreen> createState() => _ManageUsersScreenState();
}

class _ManageUsersScreenState extends State<ManageUsersScreen> {
  List<User> users = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  Future<void> _loadUsers() async {
    try {
      setState(() {
        isLoading = true;
      });

      final result = await UserController.getAllUsers();
      setState(() {
        users = result;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      if (mounted) {
        CustomSnackbars.showErrorSnackbar(context, 'Error loading users: $e');
      }
    }
  }

  Future<void> _deleteUser(String userId) async {
    try {
      final result = await UserController.deleteUser(userId);
      if (result) {
        if (mounted) {
          CustomSnackbars.showSuccessSnackbar(
            context,
            'User deleted successfully',
            2.0,
          );
          _loadUsers(); // Reload the list
        }
      } else {
        if (mounted) {
          CustomSnackbars.showErrorSnackbar(context, 'Failed to delete user');
        }
      }
    } catch (e) {
      if (mounted) {
        CustomSnackbars.showErrorSnackbar(context, 'Error deleting user: $e');
      }
    }
  }

  Future<void> _toggleBanUser(String userId, bool currentBanStatus) async {
    try {
      final newBanStatus = !currentBanStatus;
      final result = await UserController.banUser(userId, newBanStatus);
      if (result) {
        if (mounted) {
          CustomSnackbars.showSuccessSnackbar(
            context,
            newBanStatus
                ? 'User banned successfully'
                : 'User unbanned successfully',
            2.0,
          );
          _loadUsers(); // Reload the list
        }
      } else {
        if (mounted) {
          CustomSnackbars.showErrorSnackbar(
            context,
            'Failed to update ban status',
          );
        }
      }
    } catch (e) {
      if (mounted) {
        CustomSnackbars.showErrorSnackbar(
          context,
          'Error updating ban status: $e',
        );
      }
    }
  }

  void _showDeleteConfirmation(String userId, String userName) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Delete User'),
          content: Text(
            'Are you sure you want to delete "$userName"?\n\n'
            'This will:\n'
            '• Delete all one-to-one chats\n'
            '• Remove from all groups\n'
            '• Delete all bookings\n'
            '• Delete all user data',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                _deleteUser(userId);
              },
              child: const Text('Delete', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }

  void _showBanConfirmation(
    String userId,
    String userName,
    bool currentBanStatus,
  ) {
    final action = currentBanStatus ? 'Unban' : 'Ban';
    final description = currentBanStatus
        ? 'This will allow "$userName" to access groups and send messages again.'
        : 'This will prevent "$userName" from:\n'
              '• Joining groups\n'
              '• Sending messages in groups\n'
              '• Accessing group content';

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('$action User'),
          content: Text(description),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                _toggleBanUser(userId, currentBanStatus);
              },
              child: Text(
                action,
                style: TextStyle(
                  color: currentBanStatus ? Colors.green : Colors.orange,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Users'),
        backgroundColor: AppColors.appBarColor,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : users.isEmpty
          ? const Center(
              child: Text(
                'No users found',
                style: TextStyle(fontSize: 18, color: Colors.grey),
              ),
            )
          : RefreshIndicator(
              onRefresh: _loadUsers,
              child: ListView.builder(
                padding: EdgeInsets.all(AppSizes.mediumPadding(context)),
                itemCount: users.length,
                itemBuilder: (context, index) {
                  final user = users[index];
                  final isBanned = user.isBanned ?? false;

                  return Card(
                    margin: EdgeInsets.only(
                      bottom: AppSizes.mediumPadding(context),
                    ),
                    elevation: 2,
                    child: ListTile(
                      contentPadding: EdgeInsets.all(
                        AppSizes.mediumPadding(context),
                      ),
                      leading: CircleAvatar(
                        radius: AppSizes.largeIconSize(context),
                        backgroundColor: isBanned
                            ? Colors.red.shade100
                            : AppColors.appBarColor,
                        backgroundImage:
                            user.profileImageUrl != null &&
                                user.profileImageUrl!.isNotEmpty
                            ? NetworkImage(user.profileImageUrl!)
                            : null,
                        child:
                            user.profileImageUrl == null ||
                                user.profileImageUrl!.isEmpty
                            ? Text(
                                user.name.isNotEmpty
                                    ? user.name[0].toUpperCase()
                                    : 'U',
                                style: TextStyle(
                                  fontSize: AppSizes.largeFontSize(context),
                                  fontWeight: FontWeight.bold,
                                  color: isBanned
                                      ? Colors.red
                                      : AppColors.foregroundColor,
                                ),
                              )
                            : null,
                      ),
                      title: Row(
                        children: [
                          Expanded(
                            child: Text(
                              user.name,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: AppSizes.subtitleFontSize(context),
                              ),
                            ),
                          ),
                          if (isBanned)
                            Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: AppSizes.smallPadding(context),
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.red.shade100,
                                borderRadius: BorderRadius.circular(
                                  AppSizes.inputBorderRadius(context),
                                ),
                              ),
                              child: Text(
                                'BANNED',
                                style: TextStyle(
                                  color: Colors.red,
                                  fontSize: AppSizes.smallFontSize(context),
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                        ],
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(height: AppSizes.smallSpacing(context)),
                          Text(user.email),
                          SizedBox(height: AppSizes.smallSpacing(context)),
                          Text(
                            'Role: ${user.role ?? 'N/A'}',
                            style: TextStyle(
                              fontSize: AppSizes.smallFontSize(context),
                              color: Colors.grey.shade600,
                            ),
                          ),
                          SizedBox(height: AppSizes.smallSpacing(context)),
                          Text(
                            'Phone: ${user.phoneNumber}',
                            style: TextStyle(
                              fontSize: AppSizes.smallFontSize(context),
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                      trailing: PopupMenuButton<String>(
                        onSelected: (value) {
                          if (value == 'ban') {
                            _showBanConfirmation(user.id!, user.name, isBanned);
                          } else if (value == 'delete') {
                            _showDeleteConfirmation(user.id!, user.name);
                          }
                        },
                        itemBuilder: (BuildContext context) => [
                          PopupMenuItem<String>(
                            value: 'ban',
                            child: Row(
                              children: [
                                Icon(
                                  isBanned ? Icons.check_circle : Icons.block,
                                  color: isBanned
                                      ? Colors.green
                                      : Colors.orange,
                                ),
                                SizedBox(width: AppSizes.smallPadding(context)),
                                Text(isBanned ? 'Unban' : 'Ban'),
                              ],
                            ),
                          ),
                          const PopupMenuItem<String>(
                            value: 'delete',
                            child: Row(
                              children: [
                                Icon(Icons.delete, color: Colors.red),
                                SizedBox(width: 8),
                                Text('Delete'),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
    );
  }
}
