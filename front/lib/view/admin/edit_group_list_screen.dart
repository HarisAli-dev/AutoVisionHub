import 'package:flutter/material.dart';
import 'package:front/controller/groups/group_controller.dart';
import 'package:front/model/groups/group_model.dart';
import 'package:front/utils/app_colors.dart';
import 'package:front/utils/custom_widgets.dart';
import 'package:front/utils/sizes.dart';
import 'package:front/utils/snackbars.dart';
import 'package:front/view/admin/edit_group_screen.dart';

class EditGroupListScreen extends StatefulWidget {
  const EditGroupListScreen({super.key});

  @override
  State<EditGroupListScreen> createState() => _EditGroupListScreenState();
}

class _EditGroupListScreenState extends State<EditGroupListScreen> {
  List<Group> groups = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadGroups();
  }

  Future<void> _loadGroups() async {
    try {
      setState(() {
        isLoading = true;
      });

      final result = await GroupController.fetchGroups();
      setState(() {
        groups = result;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      if (mounted) {
        CustomSnackbars.showErrorSnackbar(context, 'Error loading groups: $e');
      }
    }
  }

  Future<void> _deleteGroup(String groupId) async {
    try {
      final result = await GroupController.deleteGroup(groupId);
      if (result) {
        if (mounted) {
          CustomSnackbars.showSuccessSnackbar(
            context,
            'Group deleted successfully',
            2.0,
          );
          _loadGroups(); // Reload the list
        }
      } else {
        if (mounted) {
          CustomSnackbars.showErrorSnackbar(context, 'Failed to delete group');
        }
      }
    } catch (e) {
      if (mounted) {
        CustomSnackbars.showErrorSnackbar(context, 'Error deleting group: $e');
      }
    }
  }

  void _showDeleteConfirmation(String groupId, String groupName) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Delete Group'),
          content: Text('Are you sure you want to delete "$groupName"?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                _deleteGroup(groupId);
              },
              child: Text('Delete', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    double screenWidth = AppSizes.getScreenWidth(context);
    double screenHeight = AppSizes.getScreenHeight(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Edit Groups',
          style: TextStyle(color: AppColors.foregroundColor),
        ),
        backgroundColor: AppColors.appBarColor,
        iconTheme: IconThemeData(color: AppColors.foregroundColor),
      ),
      body: Padding(
        padding: EdgeInsets.all(screenWidth * 0.04),
        child: isLoading
            ? Center(child: CustomWidgets.circularProgressIndicator())
            : groups.isEmpty
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.group_off, size: 64, color: Colors.grey),
                    SizedBox(height: screenHeight * 0.02),
                    Text(
                      'No groups found',
                      style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                    ),
                  ],
                ),
              )
            : RefreshIndicator(
                onRefresh: _loadGroups,
                child: ListView.builder(
                  itemCount: groups.length,
                  itemBuilder: (context, index) {
                    final group = groups[index];
                    return Card(
                      margin: EdgeInsets.only(bottom: screenHeight * 0.01),
                      elevation: 2,
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: AppColors.appBarColor,
                          backgroundImage: group.imageUrl != null
                              ? NetworkImage(group.imageUrl!)
                              : null,
                          child: group.imageUrl == null
                              ? Icon(
                                  Icons.group,
                                  color: AppColors.foregroundColor,
                                )
                              : null,
                        ),
                        title: Text(
                          group.name,
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                          ),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (group.description != null)
                              Text(
                                group.description!,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            Text(
                              '${group.participants.length} members',
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: Icon(Icons.edit, color: Colors.blue),
                              onPressed: () async {
                                final result = await Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        EditGroupScreen(group: group),
                                  ),
                                );
                                if (result == true) {
                                  _loadGroups(); // Reload if group was updated
                                }
                              },
                            ),
                            IconButton(
                              icon: Icon(Icons.delete, color: Colors.red),
                              onPressed: () =>
                                  _showDeleteConfirmation(group.id, group.name),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
      ),
    );
  }
}
