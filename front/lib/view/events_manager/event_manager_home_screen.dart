import 'package:front/utils/app_colors.dart';
import 'package:front/utils/hive_utils.dart';
import 'package:front/utils/navigations.dart';
import 'package:flutter/material.dart';

class EventManagerHomeScreen extends StatelessWidget {
  const EventManagerHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    const eventActions = ['Create Event', 'My Events', 'Settings'];

    return Scaffold(
      appBar: AppBar(
        title: Text('Event Manager Home'),
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: Icon(Icons.logout),
            onPressed: () {
              HiveUtils.logOutSession();
              Navigator.pushReplacementNamed(context, '/signin');
            },
          ),
        ],
      ),
      body: Center(
        child: GridView.builder(
          itemCount: eventActions.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: 1.0,
            crossAxisSpacing: 8.0,
            mainAxisSpacing: 8.0,
          ),
          itemBuilder: (context, index) {
            return InkWell(
              onTap: () {
                NavigationUtils.eventNavigation(eventActions[index], context);
              },
              child: Card(
                color: AppColors.appBarColor,
                child: Center(
                  child: Text(
                    eventActions[index],
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
