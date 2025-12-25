import 'package:front/controller/users/auth_controller.dart';
import 'package:front/utils/app_colors.dart';
import 'package:front/utils/custom_widgets.dart';
import 'package:front/utils/sizes.dart';
import 'package:front/utils/snackbars.dart';
import 'package:front/utils/validation_helpers.dart';
import 'package:flutter/material.dart';
import 'package:front/providers/theme_provider.dart';
import 'package:provider/provider.dart';
import 'package:intl_mobile_field/intl_mobile_field.dart';

class SignupScreen extends StatefulWidget {
  final String? role; // 'community_member' or 'event_manager'
  const SignupScreen({super.key, this.role});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _cityController = TextEditingController();
  String _selectedRole = 'event_manager';

  bool _isLoading = false;

  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  @override
  Widget build(BuildContext context) {
    final routeArgs =
        ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    if (routeArgs != null && routeArgs['role'] is String) {
      _selectedRole = routeArgs['role'];
    } else if (widget.role != null) {
      _selectedRole = widget.role!;
    }
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
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios_new,
            color: AppColors.foregroundColor,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Sign Up',
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
                  validator: ValidationHelpers.validatePassword,
                ),
                SizedBox(height: screenHeight * 0.02),
                IntlMobileField(
                  controller: _phoneController,
                  decoration: InputDecoration(
                    labelText: 'Contact Number',
                    labelStyle: TextStyle(color: AppColors.foregroundColor),
                    border: OutlineInputBorder(
                      borderSide: BorderSide(color: AppColors.primary),
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: AppColors.primary),
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(
                        color: AppColors.primary,
                        width: 2,
                      ),
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                  ),
                  style: TextStyle(
                    color: AppColors.foregroundColor,
                    fontSize: screenWidth * 0.04,
                  ),
                  dropdownTextStyle: TextStyle(
                    color: AppColors.foregroundColor,
                  ),
                  initialCountryCode: 'PK',
                  disableLengthCheck: false,
                  autovalidateMode: AutovalidateMode.disabled,
                  validator: (value) {
                    if (value == null || value.completeNumber.isEmpty) {
                      return 'Please enter your phone number';
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
                  validator: ValidationHelpers.validateCity,
                ),
                SizedBox(height: screenHeight * 0.02),
                DropdownButtonFormField<String>(
                  value: _selectedRole,
                  decoration: InputDecoration(
                    labelText: 'Role',
                    labelStyle: TextStyle(color: AppColors.foregroundColor),
                    border: OutlineInputBorder(
                      borderSide: BorderSide(color: AppColors.primary),
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: AppColors.primary),
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(
                        color: AppColors.primary,
                        width: 2,
                      ),
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                  ),
                  dropdownColor: AppColors.backgroundColor,
                  style: TextStyle(
                    color: AppColors.foregroundColor,
                    fontSize: screenWidth * 0.04,
                  ),
                  items: [
                    DropdownMenuItem(
                      value: 'community_member',
                      child: Text('Community Member'),
                    ),
                    DropdownMenuItem(
                      value: 'event_manager',
                      child: Text('Event Manager'),
                    ),
                  ],
                  onChanged: (value) {
                    setState(() {
                      _selectedRole = value!;
                    });
                  },
                ),
                SizedBox(height: 24),
                _isLoading
                    ? Center(child: CustomWidgets.circularProgressIndicator())
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
