// Update Profile Screen which takes user model as input and allows user to update their profile using text fields(From custom widgets) and image picker
import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:front/controller/users/user_controller.dart';
import 'package:front/services/cloudinary_service.dart';
import 'package:front/utils/app_colors.dart';
import 'package:front/utils/custom_widgets.dart';
import 'package:front/utils/hive_utils.dart';
import 'package:front/utils/image_picker.dart';
import 'package:front/utils/sizes.dart';
import 'package:front/utils/validation_helpers.dart';
import 'package:flutter/material.dart';
import 'package:front/model/users/user_model.dart';
import 'package:front/utils/snackbars.dart';
import 'package:image_picker/image_picker.dart';

class UpdateProfileScreen extends StatefulWidget {
  final User user;
  const UpdateProfileScreen({super.key, required this.user});

  @override
  State<UpdateProfileScreen> createState() => _UpdateProfileScreenState();
}

class _UpdateProfileScreenState extends State<UpdateProfileScreen> {
  late TextEditingController _nameController;
  late TextEditingController _emailController;
  late TextEditingController _phoneController;
  late TextEditingController _cityController;
  String? _profileImageUrl;
  bool _isLoading = false;

  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.user.name);
    _emailController = TextEditingController(text: widget.user.email);
    _phoneController = TextEditingController(text: widget.user.phoneNumber);
    _cityController = TextEditingController(text: widget.user.city ?? '');
    _profileImageUrl = widget.user.profileImageUrl;
    debugPrint('Profile Image URL: $_profileImageUrl');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _cityController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    double screenWidth = AppSizes.getScreenWidth(context);
    double screenHeight = AppSizes.getScreenHeight(context);
    return Scaffold(
      appBar: AppBar(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.only(
            bottomLeft: Radius.circular(16),
            bottomRight: Radius.circular(16),
          ),
        ),
        backgroundColor: AppColors.appBarColor,
        title: Text(
          'Update Profile',
          style: TextStyle(color: AppColors.foregroundColor),
        ),
        centerTitle: true,
      ),
      body: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: screenWidth * 0.1,
          vertical: screenHeight * 0.05,
        ),
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                //Profile Image (not custom widget)
                Center(
                  child: Stack(
                    children: [
                      _isLoading
                          ? CircularProgressIndicator()
                          : CircleAvatar(
                              radius: screenWidth * 0.15,
                              backgroundColor: AppColors.disabledInputFillColor,
                              backgroundImage:
                                  _profileImageUrl != null &&
                                      _profileImageUrl!.isNotEmpty
                                  ? CachedNetworkImageProvider(
                                          _profileImageUrl!,
                                        )
                                        as ImageProvider
                                  : const AssetImage(
                                      'assets/images/default_profile.png',
                                    ),
                            ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: InkWell(
                          onTap: () {
                            // dailog to choose between camera and gallery
                            showDialog(
                              context: context,
                              builder: (context) {
                                return AlertDialog(
                                  title: Text('Choose Image Source'),
                                  actions: [
                                    TextButton(
                                      onPressed: () {
                                        Navigator.of(context).pop();
                                        ImagePickerHelper.pickImage(
                                          ImageSource.camera,
                                        ).then((file) async {
                                          setState(() {
                                            _isLoading = true;
                                          });
                                          final newImage =
                                              await _uploadProfileImage(
                                                File(file!.path),
                                              );
                                          if ((newImage).isNotEmpty) {
                                            setState(() {
                                              _profileImageUrl = newImage;
                                              _isLoading = false;
                                            });
                                            CustomSnackbars.showSuccessSnackbar(
                                              context,
                                              'Profile image updated successfully',
                                              1,
                                            );
                                          } else {
                                            CustomSnackbars.showErrorSnackbar(
                                              context,
                                              'Failed to upload image',
                                            );
                                          }
                                        });
                                      },
                                      child: Text(
                                        "Camera",
                                        style: CustomWidgets.textStyle(context),
                                      ),
                                    ),
                                    TextButton(
                                      onPressed: () {
                                        Navigator.of(context).pop();
                                        ImagePickerHelper.pickImage(
                                          ImageSource.gallery,
                                        ).then((file) async {
                                          setState(() {
                                            _isLoading = true;
                                          });
                                          final newImage =
                                              await _uploadProfileImage(
                                                File(file!.path),
                                              );
                                          if ((newImage).isNotEmpty) {
                                            setState(() {
                                              _profileImageUrl = newImage;
                                              _isLoading = false;
                                            });
                                            if (mounted) {
                                              CustomSnackbars.showSuccessSnackbar(
                                                context,
                                                'Profile image updated successfully',
                                                1,
                                              );
                                            }
                                          } else {
                                            CustomSnackbars.showErrorSnackbar(
                                              context,
                                              'Failed to upload image',
                                            );
                                          }
                                        });
                                      },
                                      child: Text(
                                        "Gallery",
                                        style: CustomWidgets.textStyle(context),
                                      ),
                                    ),
                                  ],
                                );
                              },
                            );
                          },
                          child: CircleAvatar(
                            radius: screenWidth * 0.05,
                            backgroundColor: AppColors.primary,
                            child: Icon(
                              Icons.camera_alt,
                              color: AppColors.foregroundColor,
                              size: screenWidth * 0.05,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: screenHeight * 0.03),
                CustomWidgets.customTextFormField(
                  controller: _nameController,
                  label: 'Name',
                  borderColor: AppColors.primary,
                  textColor: AppColors.foregroundColor,
                  fontsize: screenWidth * 0.04,
                  validator: ValidationHelpers.validateName,
                ),
                SizedBox(height: screenHeight * 0.02),
                CustomWidgets.customTextFormField(
                  controller: _emailController,
                  label: 'Email',
                  borderColor: AppColors.primary,
                  textColor: AppColors.foregroundColor,
                  fontsize: screenWidth * 0.04,
                  disabled: true,
                ),
                SizedBox(height: screenHeight * 0.02),
                CustomWidgets.customTextFormField(
                  controller: _phoneController,
                  label: 'Phone',
                  borderColor: AppColors.primary,
                  textColor: AppColors.foregroundColor,
                  fontsize: screenWidth * 0.04,
                  isphone: true,
                  validator: ValidationHelpers.validatePhoneNumber,
                ),
                SizedBox(height: screenHeight * 0.02),
                CustomWidgets.customTextFormField(
                  controller: _cityController,
                  label: 'City',
                  borderColor: AppColors.primary,
                  textColor: AppColors.foregroundColor,
                  fontsize: screenWidth * 0.04,
                  validator: ValidationHelpers.validateCity,
                ),
                SizedBox(height: screenHeight * 0.04),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    padding: EdgeInsets.symmetric(
                      vertical: screenHeight * 0.02,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  onPressed: () async {
                    if (_formKey.currentState!.validate()) {
                      final response = await UserController.updateProfile(
                        name: _nameController.text,
                        phoneNumber: _phoneController.text,
                        city: _cityController.text,
                        profileImageUrl: _profileImageUrl,
                      );
                      if (!response) {
                        CustomSnackbars.showErrorSnackbar(
                          context,
                          'Failed to update profile',
                        );
                        return;
                      }
                      HiveUtils.putData('name', _nameController.text);
                      CustomSnackbars.showSuccessSnackbar(
                        context,
                        'Profile updated successfully',
                        1,
                      );

                      Navigator.pop(context);
                    }
                  },
                  child: Text(
                    'Update Profile',
                    style: TextStyle(
                      color: AppColors.foregroundColor,
                      fontSize: screenWidth * 0.045,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<String> _uploadProfileImage(File file) async {
    final result = await CloudinaryService.uploadFile(
      file: file,
      fileType: 'image',
    );
    if (result.containsKey('url')) {
      return result['url'];
    } else {
      debugPrint('Upload failed for ${file.path}: No URL in response');
      CustomSnackbars.showErrorSnackbar(context, 'Failed to upload image');
    }
    return '';
  }
}
