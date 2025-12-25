import 'package:cached_network_image/cached_network_image.dart';
import 'package:front/controller/groups/group_controller.dart';
import 'package:front/model/groups/group_model.dart';
import 'package:front/utils/app_colors.dart';
import 'package:front/utils/custom_widgets.dart';
import 'package:front/utils/snackbars.dart';
import 'package:front/view/community_member/groups/group_screen.dart';
import 'package:flutter/material.dart';

class JoinGroupScreen extends StatefulWidget {
  final String currentUserId;
  const JoinGroupScreen({super.key, required this.currentUserId});

  @override
  State<JoinGroupScreen> createState() => _JoinGroupScreenState();
}

class _JoinGroupScreenState extends State<JoinGroupScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<Group> _allGroups = [];
  List<Group> _filteredGroups = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadGroups();
  }

  void _loadGroups() {
    setState(() {
      _isLoading = true;
    });

    GroupController.fetchGroups()
        .then((groups) {
          setState(() {
            _allGroups = groups;
            _filteredGroups = List.from(_allGroups);
            _isLoading = false;
          });
        })
        .catchError((error) {
          setState(() {
            _isLoading = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to load groups: $error'),
              backgroundColor: Colors.red,
            ),
          );
        });
  }

  void _filterGroups(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredGroups = List.from(_allGroups);
      } else {
        _filteredGroups = _allGroups
            .where(
              (group) =>
                  group.name.toLowerCase().contains(query.toLowerCase()) ||
                  (group.description?.toLowerCase().contains(
                        query.toLowerCase(),
                      ) ??
                      false),
            )
            .toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Join Group'),
        backgroundColor: AppColors.appBarColor,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                labelText: 'Search Groups',
                hintText: 'Enter group name or description',
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
              onChanged: _filterGroups,
            ),
          ),
          Expanded(
            child: _isLoading
                ? Center(
                    child: CustomWidgets.circularProgressIndicator(),
                  )
                : _filteredGroups.isEmpty
                ? Center(
                    child: Text(
                      'No groups found to join',
                      style: TextStyle(fontSize: 16),
                    ),
                  )
                : ListView.builder(
                    itemCount: _filteredGroups.length,
                    itemBuilder: (context, index) {
                      final group = _filteredGroups[index];
                      return Card(
                        margin: EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 4,
                        ),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: AppColors.primary,
                            child:
                                group.imageUrl != null &&
                                    group.imageUrl!.isNotEmpty
                                ? CachedNetworkImage(
                                    imageUrl: group.imageUrl!,
                                    placeholder: (context, url) => Icon(
                                      Icons.group,
                                      color: AppColors.foregroundColor,
                                    ),
                                    errorWidget: (context, url, error) => Icon(
                                      Icons.group,
                                      color: AppColors.foregroundColor,
                                    ),
                                    fit: BoxFit.cover,
                                  )
                                : Icon(
                                    Icons.group,
                                    color: AppColors.foregroundColor,
                                  ),
                          ),
                          title: Text(
                            group.name,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (group.description != null &&
                                  group.description!.isNotEmpty)
                                Text(
                                  group.description!,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(fontSize: 14),
                                ),
                              SizedBox(height: 4),
                              Text(
                                '${group.participants.length} members',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                          trailing: ElevatedButton(
                            onPressed: () => _joinGroup(group),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: AppColors.foregroundColor,
                              padding: EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 8,
                              ),
                            ),
                            child: Text('Join'),
                          ),
                          onTap: () => _showGroupDetails(group),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  void _showGroupDetails(Group group) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(group.name),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (group.imageUrl != null && group.imageUrl!.isNotEmpty)
                Container(
                  height: 150,
                  width: double.infinity,
                  margin: EdgeInsets.only(bottom: 16),
                  child: CachedNetworkImage(
                    imageUrl: group.imageUrl!,
                    fit: BoxFit.cover,
                    placeholder: (context, url) => Container(
                      color: Colors.grey[300],
                      child: Icon(Icons.group, size: 50),
                    ),
                    errorWidget: (context, url, error) => Container(
                      color: Colors.grey[300],
                      child: Icon(Icons.group, size: 50),
                    ),
                  ),
                ),
              if (group.description != null && group.description!.isNotEmpty)
                Text(
                  'Description:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              if (group.description != null && group.description!.isNotEmpty)
                Text(group.description!),
              SizedBox(height: 8),
              Text(
                'Members: ${group.participants.length}',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              Text(
                'Created: ${group.createdAt.toLocal().toString().split(' ')[0]}',
                style: TextStyle(color: Colors.grey[600]),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Close'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                _joinGroup(group);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.foregroundColor,
              ),
              child: Text('Join Group'),
            ),
          ],
        );
      },
    );
  }

  void _joinGroup(Group group) async {
    try {
      setState(() {
        _isLoading = true;
      });

      final result = await GroupController.addParticipants(
        groupId: group.id,
        participantIds: [widget.currentUserId],
      );
      await Future.delayed(Duration(seconds: 1));
      if (result) {
        // Show success message
        CustomSnackbars.showSuccessSnackbar(
          context,
          'Successfully joined the group "${group.name}"',
          1,
        );

        // Navigate to group screen
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => GroupScreen(
              groupId: group.id,
              groupName: group.name,
              currentUserId: widget.currentUserId,
              groupImage: group.imageUrl ?? '',
            ),
          ),
        );
      } else {
        CustomSnackbars.showErrorSnackbar(
          context,
          'Failed to join the group "${group.name}". Please try again.',
   
        );
      }
      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to join group: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}
