import 'package:front/controller/users/auth_controller.dart';
import 'package:front/utils/app_colors.dart';
import 'package:front/utils/custom_widgets.dart';
import 'package:front/utils/sizes.dart';
import 'package:front/utils/snackbars.dart';
import 'package:flutter/material.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _cityController = TextEditingController();
  String _selectedRole = 'community_member'; // Default role

  bool _isLoading = false;

  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

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
          'Sign Up',
          style: TextStyle(color: AppColors.foregroundColor),
        ),
        centerTitle: true,
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
                  controller: _nameController,
                  label: 'Name',
                  borderColor: AppColors.primary,
                  textColor: AppColors.foregroundColor,
                  fontsize: screenWidth * 0.04,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your name';
                    }
                    return null;
                  },
                ),
                SizedBox(height: screenHeight * 0.02),
                CustomWidgets.customTextFormField(
                  controller: _emailController,
                  label: 'Email',
                  borderColor: AppColors.primary,
                  textColor: AppColors.foregroundColor,
                  fontsize: screenWidth * 0.04,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your email';
                    }
                    return null;
                  },
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
                SizedBox(height: screenHeight * 0.02),
                CustomWidgets.customTextFormField(
                  controller: _phoneController,
                  label: 'Contact Number',
                  borderColor: AppColors.primary,
                  textColor: AppColors.foregroundColor,
                  fontsize: screenWidth * 0.04,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your contact number';
                    }
                    return null;
                  },
                ),
                SizedBox(height: screenHeight * 0.02),
                CustomWidgets.customTextFormField(
                  controller: _cityController,
                  label: 'City',
                  borderColor: AppColors.primary,
                  textColor: AppColors.foregroundColor,
                  fontsize: screenWidth * 0.04,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your city';
                    }
                    return null;
                  },
                ),
                SizedBox(height: screenHeight * 0.02),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.04),
                  decoration: BoxDecoration(
                    border: Border.all(color: AppColors.foregroundColor),
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                  child: DropdownButton<String>(
                    menuWidth: screenWidth * 0.81,
                    value: _selectedRole,
                    underline: SizedBox(),
                    isExpanded: true,
                    items:
                        <String>[
                          'admin',
                          'event_manager',
                          'community_member',
                        ].map((String role) {
                          return DropdownMenuItem<String>(
                            value: role,
                            child: Text(
                              role,
                              style: TextStyle(
                                color: AppColors.foregroundColor,
                              ),
                            ),
                          );
                        }).toList(),
                    onChanged: (newRole) {
                      setState(() {
                        _selectedRole = newRole!;
                      });
                    },
                    dropdownColor: AppColors.backgroundColor,
                    borderRadius: BorderRadius.circular(16.0),
                    style: TextStyle(color: AppColors.foregroundColor),
                  ),
                ),
                SizedBox(height: 24),
                _isLoading
                    ? Center(child: CircularProgressIndicator())
                    : ElevatedButton(
                        onPressed: () async {
                          if (_formKey.currentState!.validate()) {
                            setState(() {
                              _isLoading = true;
                            });
                            String responseMessage =
                                await AuthController.signup(
                                  _nameController.text,
                                  _emailController.text,
                                  _passwordController.text,
                                  _phoneController.text,
                                  _cityController.text,
                                  _selectedRole,
                                );

                            if (responseMessage == "Signup successful") {
                              CustomSnackbars.showSuccessSnackbar(
                                context,
                                responseMessage,
                                1.5,
                              );
                              Navigator.pushReplacementNamed(
                                context,
                                '/signin',
                              );
                            } else {
                              CustomSnackbars.showErrorSnackbar(
                                context,
                                responseMessage,
                      
                              );
                            }
                            setState(() {
                              _isLoading = false;
                            });
                          }
                        },
                        style: CustomWidgets.elevatedButtonStyle(context),
                        child: Text(
                          'Create Account',
                          style: TextStyle(
                            fontSize: screenWidth * 0.04,
                            color: AppColors.foregroundColor,
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
}
