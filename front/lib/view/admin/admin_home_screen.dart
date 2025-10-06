import 'package:flutter/material.dart';
import 'package:front/controller/users/auth_controller.dart';
import 'package:front/utils/app_colors.dart';
import 'package:front/utils/navigations.dart';

class AdminHomeScreen extends StatelessWidget {
  const AdminHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    const adminActions = ['Create Group', 'Edit Groups'];
    return Scaffold(
      appBar: AppBar(
        title: Text('Admin Home'),
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: Icon(Icons.logout),
            onPressed: () async {
              await AuthController.logout();
              Navigator.pushReplacementNamed(context, '/signin');
            },
          ),
        ],
      ),
      body: Center(
        child: GridView.builder(
          itemCount: adminActions.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: 1,
            crossAxisSpacing: 8,
            mainAxisSpacing: 8,
          ),
          itemBuilder: (context, index) {
            return InkWell(
              onTap: () {
                NavigationUtils.adminNavigation(adminActions[index], context);
              },
              child: Card(
                color: AppColors.appBarColor,
                child: Center(
                  child: Text(
                    adminActions[index],
                    style: TextStyle(
                      color: AppColors.foregroundColor,
                      fontSize: 18,
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
