import 'package:flutter/material.dart';
import 'package:front/controller/groups/group_controller.dart';
import 'package:front/model/groups/group_model.dart';
import 'package:front/model/groups/group_message_model.dart';
import 'package:front/utils/app_colors.dart';
import 'package:front/utils/hive_utils.dart';
import 'package:front/utils/sizes.dart';
import 'package:front/utils/snackbars.dart';
import 'package:front/view/community_member/groups/group_screen.dart';
import 'package:front/view/community_member/groups/join_group_screen.dart';

class GroupListScreen extends StatefulWidget {
  const GroupListScreen({super.key});

  @override
  State<GroupListScreen> createState() => _GroupListScreenState();
}

class _GroupListScreenState extends State<GroupListScreen> {
  List<Group> groups = [];
  List<Group> filteredGroups = [];
  bool isLoading = true;
  String currentUserId = '';
  final TextEditingController searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadGroups();
    currentUserId = _getCurrentUserId();
    searchController.addListener(_filterGroups);
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  String _getCurrentUserId() {
    return HiveUtils.getData('userId');
  }

  Future<void> _loadGroups() async {
    try {
      setState(() => isLoading = true);
      final fetchedGroups = await GroupController.fetchUserGroups();
      setState(() {
        groups = fetchedGroups;
        filteredGroups = fetchedGroups;
        isLoading = false;
      });
    } catch (e) {
      setState(() => isLoading = false);
      CustomSnackbars.showErrorSnackbar(
        context,
        'Failed to load groups: ${e.toString()}',
  
      );
    }
  }

  void _filterGroups() {
    final query = searchController.text.toLowerCase();
    setState(() {
      if (query.isEmpty) {
        filteredGroups = groups;
      } else {
        filteredGroups = groups.where((group) {
          final groupName = group.name.toLowerCase();
          return groupName.contains(query);
        }).toList();
      }
    });
  }

  String _getLastMessageText(GroupMessage message) {
    switch (message.type) {
      case GroupMessageType.text:
        return message.content ?? '';
      case GroupMessageType.image:
        return '📷 Photo';
      case GroupMessageType.video:
        return '🎥 Video';
      case GroupMessageType.voice:
        return '🎵 Voice message';
      case GroupMessageType.file:
        return '📄 File';
      case GroupMessageType.poll:
        return '📊 Poll';
      case GroupMessageType.call:
        return '📞 Call';
    }
  }

  Widget _buildGroupTile(Group group) {
    final groupName = group.name;
    final groupImage = group.imageUrl;
    final participantCount = group.participants.length;

    return Card(
      margin: EdgeInsets.symmetric(
        horizontal: AppSizes.containerPadding(context) * 0.5,
        vertical: AppSizes.getSizeBoxHeight(context) * 0.2,
      ),
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(
          AppSizes.containerPadding(context) * 0.5,
        ),
      ),
      child: ListTile(
        contentPadding: EdgeInsets.symmetric(
          horizontal: AppSizes.containerPadding(context),
          vertical: AppSizes.getSizeBoxHeight(context) * 0.3,
        ),
        leading: CircleAvatar(
          radius: AppSizes.getScreenWidth(context) * 0.06,
          backgroundColor: AppColors.primary,
          backgroundImage: (groupImage?.isNotEmpty == true)
              ? NetworkImage(groupImage!)
              : null,
          child: (groupImage?.isEmpty != false)
              ? Icon(
                  Icons.group,
                  color: Colors.white,
                  size: AppSizes.getScreenWidth(context) * 0.06,
                )
              : null,
        ),
        title: Text(
          groupName,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: AppSizes.subtitleFontSize(context),
            color: AppColors.foregroundColor,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: AppSizes.getSizeBoxHeight(context) * 0.1),
            if (group.lastMessage != null)
              Text(
                _getLastMessageText(group.lastMessage!),
                style: TextStyle(
                  color: AppColors.foregroundColor.withOpacity(0.7),
                  fontSize: AppSizes.bodyFontSize(context) * 0.9,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              )
            else
              Text(
                'No messages yet',
                style: TextStyle(
                  color: AppColors.foregroundColor.withOpacity(0.6),
                  fontSize: AppSizes.bodyFontSize(context) * 0.9,
                ),
              ),
            SizedBox(height: AppSizes.getSizeBoxHeight(context) * 0.1),
            Text(
              '$participantCount participant${participantCount != 1 ? 's' : ''}',
              style: TextStyle(
                color: AppColors.foregroundColor.withOpacity(0.5),
                fontSize: AppSizes.bodyFontSize(context) * 0.8,
              ),
            ),
          ],
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              _formatTime(group.updatedAt),
              style: TextStyle(
                color: AppColors.foregroundColor.withOpacity(0.5),
                fontSize: AppSizes.bodyFontSize(context) * 0.75,
                fontWeight: FontWeight.normal,
              ),
            ),
            SizedBox(height: AppSizes.getSizeBoxHeight(context) * 0.2),
          ],
        ),
        onTap: () => _navigateToGroup(group),
        onLongPress: () => _showGroupOptions(group),
      ),
    );
  }

  String _formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays == 0) {
      return '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
    }
  }

  void _navigateToGroup(Group group) {
    debugPrint('Navigating to group: ${group.imageUrl}');
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => GroupScreen(
          currentUserId: currentUserId,
          groupImage: group.imageUrl!,
          groupId: group.id,
          groupName: group.name,
        ),
      ),
    );
  }

  void _showGroupOptions(Group group) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              group.name,
              style: TextStyle(
                fontSize: AppSizes.subtitleFontSize(context),
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 16),
            ListTile(
              leading: Icon(Icons.info, color: AppColors.primary),
              title: Text('Group Info'),
              onTap: () {
                Navigator.pop(context);
                _showGroupInfo(group);
              },
            ),
            ListTile(
              leading: Icon(Icons.exit_to_app, color: Colors.orange),
              title: Text('Leave Group'),
              onTap: () {
                Navigator.pop(context);
                _leaveGroup(group);
              },
            ),
            ListTile(
              leading: Icon(Icons.delete, color: Colors.red),
              title: Text('Delete Group'),
              onTap: () {
                Navigator.pop(context);
                _deleteGroup(group);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showGroupInfo(Group group) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Group Information'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Name: ${group.name}'),
            SizedBox(height: 8),
            Text('Participants: ${group.participants.length}'),
            SizedBox(height: 8),
            Text('Created: ${_formatTime(group.createdAt)}'),
            SizedBox(height: 16),
            Text('Members:', style: TextStyle(fontWeight: FontWeight.bold)),
            ...group.participants.map(
              (user) => Padding(
                padding: EdgeInsets.only(left: 16, top: 4),
                child: Text('• ${user.name}'),
              ),
            ),
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

  Future<void> _leaveGroup(Group group) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Leave Group'),
        content: Text('Are you sure you want to leave "${group.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('Leave', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await GroupController.leaveGroup(group.id);
        CustomSnackbars.showSuccessSnackbar(
          context,
          'Left group successfully',
          3.0,
        );
        _loadGroups(); // Refresh the list
      } catch (e) {
        CustomSnackbars.showErrorSnackbar(
          context,
          'Failed to leave group: ${e.toString()}',
      
        );
      }
    }
  }

  Future<void> _deleteGroup(Group group) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete Group'),
        content: Text(
          'Are you sure you want to delete "${group.name}"? This action cannot be undone.',
        ),
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
        await GroupController.deleteGroup(group.id);
        CustomSnackbars.showSuccessSnackbar(
          context,
          'Group deleted successfully',
          3.0,
        );
        _loadGroups(); // Refresh the list
      } catch (e) {
        CustomSnackbars.showErrorSnackbar(
          context,
          'Failed to delete group: ${e.toString()}',
       
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    AppColors.getBackgroundColor(context);

    return Scaffold(
      backgroundColor: AppColors.backgroundColor,

      body: Column(
        children: [
          // Search bar
          Container(
            padding: EdgeInsets.all(8),
            color: AppColors.backgroundColor,
            child: TextField(
              controller: searchController,
              decoration: InputDecoration(
                hintText: 'Search groups...',
                prefixIcon: Icon(Icons.search, color: AppColors.primary),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(25),
                  borderSide: BorderSide(color: AppColors.primary),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(25),
                  borderSide: BorderSide(color: AppColors.primary),
                ),
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
              ),
            ),
          ),

          // Groups list
          Expanded(
            child: isLoading
                ? Center(
                    child: CircularProgressIndicator(color: AppColors.primary),
                  )
                : filteredGroups.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.group_outlined,
                          size: 80,
                          color: Colors.grey[400],
                        ),
                        SizedBox(height: 16),
                        Text(
                          searchController.text.isNotEmpty
                              ? 'No groups found'
                              : 'No groups yet',
                          style: TextStyle(
                            fontSize: AppSizes.subtitleFontSize(context),
                            color: Colors.grey[600],
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          searchController.text.isNotEmpty
                              ? 'Try a different search term'
                              : 'Create a group to get started',
                          style: TextStyle(
                            fontSize: AppSizes.bodyFontSize(context),
                            color: Colors.grey[500],
                          ),
                        ),
                      ],
                    ),
                  )
                : RefreshIndicator(
                    onRefresh: _loadGroups,
                    color: AppColors.primary,
                    child: ListView.builder(
                      itemCount: filteredGroups.length,
                      itemBuilder: (context, index) {
                        return _buildGroupTile(filteredGroups[index]);
                      },
                    ),
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) =>
                  JoinGroupScreen(currentUserId: currentUserId),
            ),
          );
        },
        backgroundColor: AppColors.primary,
        tooltip: 'Create Group',
        child: Icon(Icons.chat, color: AppColors.foregroundColor),
      ),
    );
  }
}
