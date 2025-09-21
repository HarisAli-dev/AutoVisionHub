import 'package:front/view/admin/admin_home_screen.dart';
import 'package:front/view/admin/create_group_screen.dart';
import 'package:front/view/community_member/chats/chats_list_screen.dart';
import 'package:front/view/community_member/community_member_home_screen.dart';
import 'package:front/view/community_member/groups/group_list_screen.dart';
import 'package:front/view/events_manager/create_event_screen.dart';
import 'package:front/view/events_manager/event_manager_home_screen.dart';
import 'package:flutter/material.dart';
import 'package:front/view/events_manager/my_events_screen.dart';

class NavigationUtils {
  static void roleBasedNavigation(String role, BuildContext context) {
    if (role == 'admin') {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => AdminHomeScreen()),
      );
    } else if (role == 'event_manager') {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => EventManagerHomeScreen()),
      );
    } else {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => CommunityMemberHomeScreen()),
      );
    }
  }

  //admin navigation based on user actions
  static void adminNavigation(String action, BuildContext context) {
    switch (action) {
      case 'Create Group':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => CreateGroupScreen()),
        );
        break;
    }
  }

  static void eventNavigation(String action, BuildContext context) {
    switch (action) {
      case 'Create Event':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => CreateEventScreen()),
        );
        break;
      case 'My Events':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => MyEventsScreen()),
        );
        break;
    }
  }

  static void communityMemberNavigation(int index, BuildContext context) {
    switch (index) {
      case 0:
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => ChatsListScreen()),
        );
        break;
      case 1:
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => GroupListScreen()),
        );
    }
  }
}
