import 'package:flutter/material.dart';
import 'package:front/utils/app_colors.dart';
import 'package:front/utils/sizes.dart';
import 'package:front/utils/hive_utils.dart';
import 'package:front/view/community_member/chats/chats_list_screen.dart';
import 'package:front/view/community_member/chats/new_chat_screen.dart';
import 'package:front/view/community_member/groups/group_list_screen.dart';
import 'package:front/view/community_member/groups/join_group_screen.dart';

class ChatsAppScreen extends StatefulWidget {
  const ChatsAppScreen({super.key});

  @override
  State<ChatsAppScreen> createState() => _ChatsAppScreenState();
}

class _ChatsAppScreenState extends State<ChatsAppScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    const ChatsListScreen(),
    const GroupListScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      appBar: AppBar(
        backgroundColor: AppColors.backgroundColor,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: Text(
          _currentIndex == 0 ? 'Conversations' : 'Groups',
          style: TextStyle(
            color: AppColors.titleColor,
            fontSize: AppSizes.titleFontSize(context),
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: _screens[_currentIndex],
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          if (_currentIndex == 0) {
            // Chats tab - navigate to new chat
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => NewChatScreen()),
            );
          } else {
            // Groups tab - navigate to join/create group
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => JoinGroupScreen(
                  currentUserId: HiveUtils.getData('userId') ?? '',
                ),
              ),
            );
          }
        },
        backgroundColor: AppColors.primary,
        child: Icon(
          _currentIndex == 0 ? Icons.chat : Icons.group_add,
          color: AppColors.foregroundColor,
        ),
      ),
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
}
