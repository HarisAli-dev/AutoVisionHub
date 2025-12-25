import 'package:flutter/material.dart';
import 'package:front/utils/app_colors.dart';
import 'package:front/utils/sizes.dart';
import 'package:front/utils/hive_utils.dart';
import 'package:front/view/community_member/chats/chats_list_screen.dart';
import 'package:front/view/community_member/chats/new_chat_screen.dart';
import 'package:front/view/community_member/groups/group_list_screen.dart';
import 'package:front/view/community_member/groups/join_group_screen.dart';
import 'package:front/view/events_manager/my_events_screen.dart';
import 'package:front/view/events_manager/create_event_screen.dart';
import 'package:front/view/settings/setting.dart';

class EventManagerHomeScreen extends StatefulWidget {
  const EventManagerHomeScreen({super.key});

  @override
  State<EventManagerHomeScreen> createState() => _EventManagerHomeScreenState();
}

class _EventManagerHomeScreenState extends State<EventManagerHomeScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    const MyEventsScreen(),
    const ChatsListScreen(),
    const GroupListScreen(),
  ];

  final List<String> _titles = ['My Events', 'Chats', 'Groups'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      appBar: AppBar(
        title: Text(
          _titles[_currentIndex],
          style: TextStyle(
            color: AppColors.titleColor,
            fontSize: AppSizes.titleFontSize(context),
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: false,
        automaticallyImplyLeading: false,
        backgroundColor: AppColors.appBarColor,
        elevation: 0,
        actions: [
          // Show info button only when on Events tab (index 0)
          if (_currentIndex == 0)
            IconButton(
              icon: Icon(Icons.info_outline, color: AppColors.foregroundColor),
              tooltip: 'Controls Info',
              onPressed: () {
                // Show info dialog for events controls
                _showEventsInfoDialog(context);
              },
            ),
          IconButton(
            icon: Icon(Icons.settings, color: AppColors.foregroundColor),
            tooltip: 'Settings',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) =>
                      SettingsScreen(userId: HiveUtils.getData('userId')),
                ),
              );
            },
          ),
        ],
      ),
      body: _screens[_currentIndex],
      floatingActionButton: _buildFloatingActionButton(),
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: AppColors.backgroundColor,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: AppColors.shadeColor,
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() => _currentIndex = index);
        },
        type: BottomNavigationBarType.fixed,
        elevation: 8,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.event_outlined),
            activeIcon: Icon(Icons.event),
            label: 'Events',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.chat_outlined),
            activeIcon: Icon(Icons.chat),
            label: 'Chats',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.group_outlined),
            activeIcon: Icon(Icons.group),
            label: 'Groups',
          ),
        ],
      ),
    );
  }

  Widget? _buildFloatingActionButton() {
    switch (_currentIndex) {
      case 0: // Events
        return FloatingActionButton(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const CreateEventScreen(),
              ),
            );
          },
          backgroundColor: AppColors.primary,
          child: const Icon(Icons.add, color: Colors.white),
        );
      case 1: // Chats
        return FloatingActionButton(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => NewChatScreen()),
            );
          },
          backgroundColor: AppColors.primary,
          child: const Icon(Icons.add_comment, color: Colors.white),
        );
      case 2: // Groups
        return FloatingActionButton(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => JoinGroupScreen(
                  currentUserId: HiveUtils.getData('userId') ?? '',
                ),
              ),
            );
          },
          backgroundColor: AppColors.primary,
          child: const Icon(Icons.group_add, color: Colors.white),
        );
      default:
        return null;
    }
  }

  void _showEventsInfoDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Row(
            children: [
              Icon(Icons.info_outline, color: AppColors.primary),
              SizedBox(width: AppSizes.smallSpacing(context)),
              Text(
                'Events Controls Guide',
                style: TextStyle(
                  fontSize: AppSizes.titleFontSize(context) * 0.9,
                  color: AppColors.foregroundColor,
                ),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildInfoItem(
                  Icons.touch_app,
                  'Tap on event card',
                  'View all bookings for the event',
                ),
                SizedBox(height: AppSizes.smallSpacing(context)),
                _buildInfoItem(
                  Icons.gesture,
                  'Long press on event card',
                  'Delete the event',
                ),
                SizedBox(height: AppSizes.smallSpacing(context)),
                _buildInfoItem(
                  Icons.more_vert,
                  'Three-dot menu',
                  'Edit event or start live stream',
                ),
                SizedBox(height: AppSizes.smallSpacing(context)),
                _buildInfoItem(
                  Icons.add,
                  'Create Event button',
                  'Add a new event',
                ),
              ],
            ),
          ),
          backgroundColor: AppColors.backgroundColor,
          actions: [
            TextButton(
              child: Text('Got it', style: TextStyle(color: AppColors.primary)),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  Widget _buildInfoItem(IconData icon, String action, String description) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          size: AppSizes.extraLargeIconSize(context),
          color: AppColors.primary,
        ),
        SizedBox(width: AppSizes.smallSpacing(context)),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                action,
                style: TextStyle(
                  fontSize: AppSizes.bodyFontSize(context),
                  fontWeight: FontWeight.bold,
                  color: AppColors.foregroundColor,
                ),
              ),
              SizedBox(height: AppSizes.smallSpacing(context)),
              Text(
                description,
                style: TextStyle(
                  fontSize: AppSizes.bodyFontSize(context),
                  color: AppColors.shadeColor,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
