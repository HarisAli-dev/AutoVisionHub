import 'dart:io';
import 'package:flutter/material.dart';
import 'package:front/services/cloudinary_service.dart';
import 'package:front/utils/app_colors.dart';
import 'package:front/utils/custom_widgets.dart';
import 'package:front/utils/sizes.dart';
import 'package:front/utils/snackbars.dart';
import 'package:image_picker/image_picker.dart';
import '../../controller/groups/group_controller.dart';
import '../../model/groups/group_model.dart';

class EditGroupScreen extends StatefulWidget {
  final Group group;

  const EditGroupScreen({Key? key, required this.group}) : super(key: key);

  @override
  State<EditGroupScreen> createState() => _EditGroupScreenState();
}

class _EditGroupScreenState extends State<EditGroupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();

  bool _isLoading = false;
  File? _selectedImage;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _nameController.text = widget.group.name;
    _descriptionController.text = widget.group.description ?? '';
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 80,
      );

      if (image != null) {
        setState(() {
          _selectedImage = File(image.path);
        });
      }
    } catch (e) {
      if (mounted) {
        CustomSnackbars.showErrorSnackbar(context, 'Failed to pick image: $e');
      }
    }
  }

  Future<void> _updateGroup() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    String? uploadedImageUrl;

    // Upload the group image if a new one is selected to cloudinary
    if (_selectedImage != null) {
      try {
        final uploadResult = await CloudinaryService.uploadFile(
          file: _selectedImage!,
          fileType: 'image',
        );
        if (uploadResult.containsKey('url')) {
          uploadedImageUrl = uploadResult['url'];
          debugPrint('Image uploaded successfully: $uploadedImageUrl');
        } else {
          throw Exception('Upload failed: No url in response');
        }
      } catch (e) {
        if (mounted) {
          CustomSnackbars.showErrorSnackbar(
            context,
            'Failed to upload image: $e',
          );
          setState(() {
            _isLoading = false;
          });
          return;
        }
      }
    }

    try {
      final success = await GroupController.updateGroup(
        groupId: widget.group.id,
        groupName: _nameController.text.trim(),
        description: _descriptionController.text.trim(),
        groupImageUrl:
            uploadedImageUrl ??
            widget.group.imageUrl, // Use uploaded URL or keep existing
      );

      if (mounted && success) {
        CustomSnackbars.showSuccessSnackbar(
          context,
          'Group updated successfully',
          2.0,
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        CustomSnackbars.showErrorSnackbar(
          context,
          'Failed to update group: $e',
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Widget _buildImageSection() {
    return GestureDetector(
      onTap: _pickImage,
      child: Container(
        width: 100,
        height: 100,
        decoration: BoxDecoration(
          color: Colors.grey[300],
          borderRadius: BorderRadius.circular(50),
          border: Border.all(color: AppColors.primary, width: 2),
        ),
        child: _selectedImage != null
            ? ClipRRect(
                borderRadius: BorderRadius.circular(50),
                child: Image.file(_selectedImage!, fit: BoxFit.cover),
              )
            : widget.group.imageUrl?.isNotEmpty == true
            ? ClipRRect(
                borderRadius: BorderRadius.circular(50),
                child: Image.network(
                  widget.group.imageUrl!,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Icon(
                      Icons.add_a_photo,
                      size: 40,
                      color: AppColors.primary,
                    );
                  },
                ),
              )
            : Icon(Icons.add_a_photo, size: 40, color: AppColors.primary),
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
        title: Text(
          'Edit Group',
          style: TextStyle(
            fontSize: AppSizes.titleFontSize(context),
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          if (_isLoading)
            Center(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2,
                  ),
                ),
              ),
            )
          else
            TextButton(
              onPressed: _updateGroup,
              child: Text(
                'SAVE',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Group Information Section
              Container(
                padding: EdgeInsets.all(16),
                child: Column(
                  children: [
                    // Group Image
                    _buildImageSection(),

                    SizedBox(height: 16),

                    // Group Name
                    CustomWidgets.customTextFormField(
                      controller: _nameController,
                      label: 'Group Name',
                      borderColor: AppColors.primary,
                      textColor: AppColors.foregroundColor,
                      fontsize: AppSizes.bodyFontSize(context),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter a group name';
                        }
                        if (value.trim().length < 2) {
                          return 'Group name must be at least 2 characters';
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

              // Group Information Section
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: AppColors.primary),
                    SizedBox(width: 8),
                    Text(
                      'Group Information',
                      style: TextStyle(
                        fontSize: AppSizes.subtitleFontSize(context),
                        fontWeight: FontWeight.bold,
                        color: AppColors.foregroundColor,
                      ),
                    ),
                  ],
                ),
              ),

              Container(
                margin: EdgeInsets.symmetric(horizontal: 16),
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.backgroundColor,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppColors.shadeColor.withOpacity(0.3),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildInfoRow('Group ID', widget.group.id),
                    _buildInfoRow(
                      'Created By',
                      widget.group.createdBy ?? 'Unknown',
                    ),
                    _buildInfoRow(
                      'Members',
                      '${widget.group.participants.length}',
                    ),
                    _buildInfoRow(
                      'Created',
                      widget.group.createdAt.toLocal().toString().split('.')[0],
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

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: TextStyle(
                color: AppColors.shadeColor,
                fontSize: AppSizes.bodyFontSize(context),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                color: AppColors.foregroundColor,
                fontSize: AppSizes.bodyFontSize(context),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
