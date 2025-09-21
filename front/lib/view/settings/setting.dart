//setting page with options to change profile and logout
import 'package:front/controller/users/user_controller.dart';
import 'package:front/model/users/user_model.dart';
import 'package:front/utils/app_colors.dart';
import 'package:front/utils/hive_utils.dart';

import 'package:flutter/material.dart';
import 'package:front/view/settings/change_password.dart';
import 'package:front/view/settings/update_profile_screen.dart';

class SettingsScreen extends StatelessWidget {
  final String userId;
  const SettingsScreen({super.key, required this.userId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Settings'),
        backgroundColor: AppColors.appBarColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.only(
            bottomLeft: Radius.circular(16),
            bottomRight: Radius.circular(16),
          ),
        ),
        centerTitle: true,
      ),
      body: Center(
        child: ListView(
          children: [
            ListTile(
              leading: Icon(Icons.person, color: AppColors.primary),
              title: Text('Change Profile'),
              onTap: () async {
                User user = await getUser(userId);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => UpdateProfileScreen(user: user),
                  ),
                );
              },
            ),
            // change password option can be added here
            ListTile(
              leading: Icon(Icons.lock, color: AppColors.primary),
              title: Text('Change Password'),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ChangePasswordScreen(userId: userId),
                  ),
                );
              },
            ),
            ListTile(
              leading: Icon(Icons.logout, color: AppColors.primary),
              title: Text('Logout'),
              onTap: () {
                // Clear session and navigate to sign-in screen
                HiveUtils.logOutSession();
                Navigator.pushReplacementNamed(context, '/signin');
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<User> getUser(String userId) async {
    return await UserController.getProfile(userId);
  }
}
