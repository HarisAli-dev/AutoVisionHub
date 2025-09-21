// Change Password Screen
import 'package:flutter/material.dart';
import 'package:front/controller/users/user_controller.dart';
import 'package:front/utils/app_colors.dart';
import 'package:front/utils/sizes.dart';
import 'package:front/utils/snackbars.dart';

class ChangePasswordScreen extends StatefulWidget {
  final String userId;
  const ChangePasswordScreen({super.key, required this.userId});

  @override
  _ChangePasswordScreenState createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _currentPasswordController =
      TextEditingController();
  final TextEditingController _newPasswordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _changePassword() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      try {
        final response = await UserController.changePassword(
          currentPassword: _currentPasswordController.text,
          newPassword: _newPasswordController.text,
        );

        if (response) {
          CustomSnackbars.showSuccessSnackbar(context, 'Password changed successfully', 1);
          Navigator.pop(context);
        } else {
          CustomSnackbars.showErrorSnackbar(context,  'Error changing password');
        }
      } catch (e) {
        CustomSnackbars.showErrorSnackbar(context, 'An error occurred. Please try again.');
      } finally {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Change Password'),
        backgroundColor: AppColors.appBarColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.only(
            bottomLeft: Radius.circular(16),
            bottomRight: Radius.circular(16),
          ),
        ),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: _currentPasswordController,
                decoration: InputDecoration(labelText: 'Current Password'),
                obscureText: true,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your current password';
                  }
                  return null;
                },
              ),
              SizedBox(height: AppSizes.getScreenHeight(context) * 0.02),
              TextFormField(
                controller: _newPasswordController,
                decoration: InputDecoration(labelText: 'New Password'),
                obscureText: true,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a new password';
                  }
                  if (value.length < 6) {
                    return 'Password must be at least 6 characters long';
                  }
                  return null;
                },
              ),
              SizedBox(height: AppSizes.getScreenHeight(context) * 0.02),
              TextFormField(
                controller: _confirmPasswordController,
                decoration: InputDecoration(labelText: 'Confirm New Password'),
                obscureText: true,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please confirm your new password';
                  }
                  if (value != _newPasswordController.text) {
                    return 'Passwords do not match';
                  }
                  return null;
                },
              ),
              SizedBox(height: AppSizes.getScreenHeight(context) * 0.05),
              ElevatedButton(
                onPressed: _isLoading ? null : _changePassword,
                child: _isLoading
                    ? CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      )
                    : Text('Change Password'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
