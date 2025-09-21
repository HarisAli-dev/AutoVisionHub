import 'package:front/controller/users/auth_controller.dart';
import 'package:front/utils/app_colors.dart';
import 'package:front/utils/custom_widgets.dart';
import 'package:front/utils/navigations.dart';
import 'package:front/utils/sizes.dart';
import 'package:front/utils/snackbars.dart';
import 'package:front/view/auth/signup.dart';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';

class SignInScreen extends StatefulWidget {
  const SignInScreen({super.key});

  @override
  State<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isLoading = false;

  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  @override
  Widget build(BuildContext context) {
    AppColors.getBackgroundColor(context);
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
          'Sign In',
          style: TextStyle(color: AppColors.foregroundColor),
        ),
        centerTitle: true,
        automaticallyImplyLeading: false,
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
                SizedBox(height: screenHeight * 0.04),
                _isLoading
                    ? Center(child: CircularProgressIndicator())
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
                    // Navigate to Sign Up screen
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => SignupScreen()),
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
