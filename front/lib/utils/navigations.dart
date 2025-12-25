// Admin routes intentionally not imported to hide/remove admin access from app flows
import 'package:front/view/admin/admin_home_screen.dart';
import 'package:front/view/admin/create_group_screen.dart';
import 'package:front/view/admin/edit_group_list_screen.dart';
import 'package:front/view/admin/manage_users_screen.dart';
import 'package:front/view/admin/view_reports_screen.dart';
import 'package:front/view/community_member/chats/chats_list_screen.dart';
import 'package:front/view/community_member/community_member_home_screen.dart';
import 'package:front/view/community_member/groups/group_list_screen.dart';
import 'package:front/view/events_manager/create_event_screen.dart';
import 'package:front/view/events_manager/event_manager_home_screen.dart';
import 'package:front/view/settings/customer_support_screen.dart';
import 'package:front/utils/hive_utils.dart';
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

  // Admin navigation
  static void adminNavigation(String action, BuildContext context) {
    switch (action) {
      case 'Create Group':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => CreateGroupScreen()),
        );
        break;
      case 'Edit Groups':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => EditGroupListScreen()),
        );
        break;
      case 'Manage Users':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => ManageUsersScreen()),
        );
        break;
      case 'View Reports':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => ViewReportsScreen()),
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
      case 'Customer Support':
        final userId = HiveUtils.getData('userId') ?? '';
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => CustomerSupportScreen(userId: userId),
          ),
        );
        break;
      case 'Payment Profile':
        Navigator.pushNamed(context, '/payment-profile');
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
