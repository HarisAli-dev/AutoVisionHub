import 'dart:io';
import 'package:flutter/material.dart';
import 'package:front/controller/groups/group_controller.dart';
import 'package:front/model/users/user_model.dart';
import 'package:front/utils/app_colors.dart';
import 'package:front/utils/custom_widgets.dart';
import 'package:front/utils/sizes.dart';
import 'package:front/utils/snackbars.dart';
import 'package:image_picker/image_picker.dart';

class CreateGroupScreen extends StatefulWidget {
  const CreateGroupScreen({Key? key}) : super(key: key);

  @override
  _CreateGroupScreenState createState() => _CreateGroupScreenState();
}

class _CreateGroupScreenState extends State<CreateGroupScreen> {
  final TextEditingController _groupNameController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _searchController = TextEditingController();

  final ImagePicker _imagePicker = ImagePicker();
  File? _groupImage;
  List<User> availableUsers = [];
  List<User> selectedUsers = [];
  List<User> filteredUsers = [];
  bool isLoading = false;
  bool isCreating = false;
  bool isPrivate = false;

  @override
  void initState() {
    super.initState();
    _loadUsers();
    _searchController.addListener(_filterUsers);
  }

  @override
  void dispose() {
    _groupNameController.dispose();
    _descriptionController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadUsers() async {
    setState(() => isLoading = true);

    try {
      // Replace with actual API call to get users
      final users = await GroupController.getAvailableUsers();
      setState(() {
        availableUsers = users;
        filteredUsers = users;
        isLoading = false;
      });
    } catch (e) {
      setState(() => isLoading = false);
      CustomSnackbars.showErrorSnackbar(
        context,
        'Failed to load users: ${e.toString()}',

      );
    }
  }

  void _filterUsers() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      filteredUsers = availableUsers.where((user) {
        return user.name.toLowerCase().contains(query) ||
            user.email.toLowerCase().contains(query);
      }).toList();
    });
  }

  Future<void> _pickGroupImage() async {
    try {
      final pickedFile = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 70,
        maxWidth: 500,
        maxHeight: 500,
      );

      if (pickedFile != null) {
        setState(() {
          _groupImage = File(pickedFile.path);
        });
      }
    } catch (e) {
      CustomSnackbars.showErrorSnackbar(
        context,
        'Failed to pick image: ${e.toString()}',
 
      );
    }
  }

  void _toggleUserSelection(User user) {
    setState(() {
      if (selectedUsers.contains(user)) {
        selectedUsers.remove(user);
      } else {
        selectedUsers.add(user);
      }
    });
  }

  Future<void> _createGroup() async {
    final groupName = _groupNameController.text.trim();
    final description = _descriptionController.text.trim();

    if (groupName.isEmpty) {
      CustomSnackbars.showErrorSnackbar(
        context,
        'Please enter a group name',

      );
      return;
    }

    if (selectedUsers.isEmpty) {
      CustomSnackbars.showErrorSnackbar(
        context,
        'Please select at least one participant',

      );
      return;
    }

    setState(() => isCreating = true);

    try {
      await GroupController.createGroup(
        groupName: groupName,
        description: description.isEmpty ? null : description,
        participantIds: selectedUsers.map((u) => u.id!).cast<String>().toList(),
        groupImageUrl: null, // Will be handled by file upload later
      );

      // Group creation successful
      Navigator.pop(context, true);
      CustomSnackbars.showSuccessSnackbar(
        context,
        'Group created successfully!',
        3.0,
      );
    } catch (e) {
      setState(() => isCreating = false);
      CustomSnackbars.showErrorSnackbar(
        context,
        'Failed to create group: ${e.toString()}',

      );
    }
  }

  @override
  Widget build(BuildContext context) {
    AppColors.getBackgroundColor(context);

    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      appBar: AppBar(
        backgroundColor: AppColors.appBarColor,
        foregroundColor: Colors.white,
        title: Text(
          'Create Group',
          style: TextStyle(
            fontSize: AppSizes.titleFontSize(context),
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          if (isCreating)
            Center(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CustomWidgets.circularProgressIndicator(strokeWidth: 2.0)
                ),
              ),
            )
          else
            TextButton(
              onPressed: _createGroup,
              child: Text(
                'CREATE',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
        ],
      ),
      body: Column(
        children: [
          // Group Information Section
          Container(
            padding: EdgeInsets.all(16),
            child: Column(
              children: [
                // Group Image
                GestureDetector(
                  onTap: _pickGroupImage,
                  child: Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(50),
                      border: Border.all(color: AppColors.primary, width: 2),
                    ),
                    child: _groupImage != null
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(50),
                            child: Image.file(_groupImage!, fit: BoxFit.cover),
                          )
                        : Icon(
                            Icons.add_a_photo,
                            size: 40,
                            color: AppColors.primary,
                          ),
                  ),
                ),

                SizedBox(height: 16),

                // Group Name
                CustomWidgets.customTextFormField(
                  controller: _groupNameController,
                  label: 'Group Name',
                  borderColor: AppColors.primary,
                  textColor: AppColors.foregroundColor,
                  fontsize: AppSizes.bodyFontSize(context),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter a group name';
                    }
                    return null;
                  },
                ),

                SizedBox(height: 16),

                // Description
                CustomWidgets.customTextFormField(
                  controller: _descriptionController,
                  label: 'Description (optional)',
                  borderColor: AppColors.primary,
                  textColor: AppColors.foregroundColor,
                  fontsize: AppSizes.bodyFontSize(context),
                  maxLine: 4,
                ),

                SizedBox(height: 16),
              ],
            ),
          ),

          Divider(),

          // Participants Section
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                Icon(Icons.people, color: AppColors.primary),
                SizedBox(width: 8),
                Text(
                  'Add Participants (${selectedUsers.length})',
                  style: TextStyle(
                    fontSize: AppSizes.subtitleFontSize(context),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),

          // Search Bar
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search users...',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(25),
                ),
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
              ),
            ),
          ),

          SizedBox(height: 8),

          // Selected Users Chips
          if (selectedUsers.isNotEmpty)
            Container(
              height: 60,
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: selectedUsers.length,
                itemBuilder: (context, index) {
                  final user = selectedUsers[index];
                  return Container(
                    margin: EdgeInsets.only(right: 8),
                    child: Chip(
                      avatar: CircleAvatar(
                        backgroundColor: AppColors.primary,
                        child: Text(
                          user.name.isNotEmpty
                              ? user.name[0].toUpperCase()
                              : 'U',
                          style: TextStyle(color: Colors.white, fontSize: 12),
                        ),
                      ),
                      label: Text(user.name),
                      deleteIcon: Icon(Icons.close, size: 18),
                      onDeleted: () => _toggleUserSelection(user),
                      backgroundColor: AppColors.primary.withOpacity(0.1),
                    ),
                  );
                },
              ),
            ),

          // Users List
          Expanded(
            child: isLoading
                ? Center(
                    child: CustomWidgets.circularProgressIndicator(),
                  )
                : filteredUsers.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.people_outline,
                          size: 80,
                          color: Colors.grey[400],
                        ),
                        SizedBox(height: 16),
                        Text(
                          _searchController.text.isNotEmpty
                              ? 'No users found'
                              : 'No users available',
                          style: TextStyle(
                            fontSize: AppSizes.subtitleFontSize(context),
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    itemCount: filteredUsers.length,
                    itemBuilder: (context, index) {
                      final user = filteredUsers[index];
                      final isSelected = selectedUsers.contains(user);

                      return ListTile(
                        leading: CircleAvatar(
                          backgroundColor: AppColors.primary,
                          backgroundImage: user.profileImageUrl != null
                              ? NetworkImage(user.profileImageUrl!)
                              : null,
                          child: user.profileImageUrl == null
                              ? Text(
                                  user.name.isNotEmpty
                                      ? user.name[0].toUpperCase()
                                      : 'U',
                                  style: TextStyle(color: Colors.white),
                                )
                              : null,
                        ),
                        title: Text(
                          user.name,
                          style: TextStyle(fontWeight: FontWeight.w500),
                        ),
                        subtitle: Text(user.email),
                        trailing: isSelected
                            ? Icon(Icons.check_circle, color: AppColors.primary)
                            : Icon(
                                Icons.add_circle_outline,
                                color: Colors.grey[400],
                              ),
                        onTap: () => _toggleUserSelection(user),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
