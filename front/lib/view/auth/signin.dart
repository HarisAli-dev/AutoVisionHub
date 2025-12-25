import 'package:front/controller/users/auth_controller.dart';
import 'package:front/controller/unban_request_controller.dart';
import 'package:front/utils/app_colors.dart';
import 'package:front/utils/custom_widgets.dart';
import 'package:front/utils/navigations.dart';
import 'package:front/utils/sizes.dart';
import 'package:front/utils/snackbars.dart';
import 'package:front/utils/validation_helpers.dart';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:provider/provider.dart';
import 'package:front/providers/theme_provider.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

class SignInScreen extends StatefulWidget {
  final String? role; // 'community_member' or 'event_manager'
  const SignInScreen({super.key, this.role});

  @override
  State<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isLoading = false;

  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  void _showBannedDialog(BuildContext parentContext, String message) {
    final screenContext = parentContext; // Capture the screen's context
    showDialog(
      context: parentContext,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppColors.backgroundColor,
        title: Row(
          children: [
            Icon(Icons.block, color: AppColors.errorColor, size: 28),
            SizedBox(width: 8),
            Text(
              'Account Banned',
              style: TextStyle(color: AppColors.errorColor, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              message,
              style: TextStyle(color: AppColors.foregroundColor),
            ),
            SizedBox(height: 16),
            Text(
              'You can request an unban by providing details about why you should be unbanned.',
              style: TextStyle(color: AppColors.shadeColor, fontSize: 14),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text('Close', style: TextStyle(color: AppColors.shadeColor)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              _showUnbanRequestDialog(screenContext, _emailController.text);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: AppColors.foregroundColor,
            ),
            child: Text('Request Unban'),
          ),
        ],
      ),
    );
  }

  void _showUnbanRequestDialog(BuildContext screenContext, String email) {
    final TextEditingController messageController = TextEditingController();
    final List<File> selectedImages = [];
    final ImagePicker picker = ImagePicker();

    showDialog(
      context: screenContext,
      builder: (dialogContext) => StatefulBuilder(
        builder: (builderContext, setState) => AlertDialog(
          backgroundColor: AppColors.backgroundColor,
          title: Text(
            'Request Unban',
            style: TextStyle(color: AppColors.titleColor),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Please explain why you should be unbanned:',
                  style: TextStyle(color: AppColors.shadeColor, fontSize: 14),
                ),
                SizedBox(height: 12),
                TextField(
                  controller: messageController,
                  style: TextStyle(color: AppColors.foregroundColor),
                  decoration: InputDecoration(
                    hintText: 'Enter your message...',
                    hintStyle: TextStyle(color: AppColors.shadeColor),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: AppColors.shadeColor),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: AppColors.shadeColor),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: AppColors.primary),
                    ),
                  ),
                  maxLines: 4,
                  maxLength: 500,
                ),
                SizedBox(height: 16),
                Text(
                  'Upload proof (optional):',
                  style: TextStyle(color: AppColors.shadeColor, fontSize: 14),
                ),
                SizedBox(height: 8),
                ElevatedButton.icon(
                  onPressed: () async {
                    final XFile? image = await picker.pickImage(source: ImageSource.gallery);
                    if (image != null) {
                      setState(() {
                        selectedImages.add(File(image.path));
                      });
                    }
                  },
                  icon: Icon(Icons.add_photo_alternate),
                  label: Text('Add Image'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.shadeColor,
                    foregroundColor: AppColors.foregroundColor,
                  ),
                ),
                if (selectedImages.isNotEmpty) ...[
                  SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: selectedImages.map((img) {
                      return Stack(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.file(
                              img,
                              width: 80,
                              height: 80,
                              fit: BoxFit.cover,
                            ),
                          ),
                          Positioned(
                            top: 0,
                            right: 0,
                            child: GestureDetector(
                              onTap: () {
                                setState(() {
                                  selectedImages.remove(img);
                                });
                              },
                              child: Container(
                                padding: EdgeInsets.all(4),
                                decoration: BoxDecoration(
                                  color: Colors.red,
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(Icons.close, size: 16, color: Colors.white),
                              ),
                            ),
                          ),
                        ],
                      );
                    }).toList(),
                  ),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: Text('Cancel', style: TextStyle(color: AppColors.shadeColor)),
            ),
            ElevatedButton(
              onPressed: () async {
                if (messageController.text.trim().isEmpty) {
                  CustomSnackbars.showErrorSnackbar(
                    screenContext,
                    'Please enter a message',
                  );
                  return;
                }

                // Store message and images before closing dialog
                final message = messageController.text.trim();
                final images = List<File>.from(selectedImages);

                Navigator.pop(dialogContext); // Close dialog
                
                // Show loading
                showDialog(
                  context: screenContext,
                  barrierDismissible: false,
                  builder: (_) => Center(child: CustomWidgets.circularProgressIndicator()),
                );

                final result = await UnbanRequestController.createUnbanRequest(
                  email: email,
                  message: message,
                  proofImageFiles: images,
                );

                // Close loading dialog
                if (mounted) {
                  Navigator.of(screenContext).pop();
                }

                // Show result snackbar
                if (mounted) {
                  if (result.contains('success')) {
                    CustomSnackbars.showSuccessSnackbar(
                      screenContext, 
                      'Your unban request has been submitted successfully and is under review.',
                      3,
                    );
                  } else {
                    CustomSnackbars.showErrorSnackbar(screenContext, result);
                  }
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.foregroundColor,
              ),
              child: Text('Submit Request'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    AppColors.getBackgroundColor(context);
    double screenWidth = AppSizes.getScreenWidth(context);
    double screenHeight = AppSizes.getScreenHeight(context);
    // Read role from arguments if not provided directly
    final routeArgs =
        ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    final effectiveRole = widget.role ?? routeArgs?['role'] as String?;

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.only(
            bottomLeft: Radius.circular(16),
            bottomRight: Radius.circular(16),
          ),
        ),
        backgroundColor: AppColors.appBarColor,
        title: Text(
          effectiveRole == 'event_manager'
              ? 'Sign In (Event Manager)'
              : effectiveRole == 'community_member'
              ? 'Sign In (Community Member)'
              : 'Sign In',
          style: TextStyle(color: AppColors.foregroundColor),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(Icons.brightness_6, color: AppColors.foregroundColor),
            onPressed: () {
              context.read<ThemeProvider>().toggle();
            },
          ),
        ],
      ),
      body: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: screenWidth * 0.1,
          vertical: screenHeight * 0.1,
        ),
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                CustomWidgets.customTextFormField(
                  controller: _emailController,
                  label: 'Email',
                  borderColor: AppColors.primary,
                  textColor: AppColors.foregroundColor,
                  fontsize: screenWidth * 0.04,
                  validator: ValidationHelpers.validateEmail,
                ),
                SizedBox(height: screenHeight * 0.02),
                CustomWidgets.customTextFormField(
                  controller: _passwordController,
                  label: 'Password',
                  borderColor: AppColors.primary,
                  textColor: AppColors.foregroundColor,
                  fontsize: screenWidth * 0.04,
                  obscureText: true,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your password';
                    }
                    return null;
                  },
                ),
                SizedBox(height: screenHeight * 0.04),
                _isLoading
                    ? Center(child: CustomWidgets.circularProgressIndicator())
                    : ElevatedButton(
                        onPressed: () async {
                          if (_formKey.currentState!.validate()) {
                            setState(() {
                              _isLoading = true;
                            });
                            String response = await AuthController.signin(
                              _emailController.text,
                              _passwordController.text,
                            );
                            if (response == "Login successful") {
                              CustomSnackbars.showSuccessSnackbar(
                                context,
                                'Login successful',
                                1.5,
                              );
                              var box = await Hive.openBox('sessionBox');
                              String role = box.get('role');
                              NavigationUtils.roleBasedNavigation(
                                role,
                                context,
                              );
                            } else if (response.startsWith("BANNED:")) {
                              // Show banned dialog
                              _showBannedDialog(context, response.substring(7));
                            } else {
                              CustomSnackbars.showErrorSnackbar(
                                context,
                                response,
                              );
                            }
                            setState(() {
                              _isLoading = false;
                            });
                          } else {
                            CustomSnackbars.showErrorSnackbar(
                              context,
                              'Please fill in all fields',
                            );
                          }
                        },
                        style: CustomWidgets.elevatedButtonStyle(context),
                        child: Text(
                          'Sign In',
                          style: TextStyle(
                            color: AppColors.foregroundColor,
                            fontSize: screenWidth * 0.04,
                          ),
                        ),
                      ),
                SizedBox(height: screenHeight * 0.02),
                TextButton(
                  onPressed: () {
                    Navigator.pushNamed(
                      context,
                      '/signup',
                      arguments: {'role': effectiveRole ?? 'community_member'},
                    );
                  },
                  child: Text(
                    'Don\'t have an account? Sign Up',
                    style: TextStyle(color: AppColors.buttonColor),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
