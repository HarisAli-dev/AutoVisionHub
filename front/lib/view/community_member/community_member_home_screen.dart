import 'package:front/providers/index_provider.dart';
import 'package:front/view/settings/setting.dart';
import 'package:front/utils/app_colors.dart';
import 'package:front/utils/hive_utils.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class CommunityMemberHomeScreen extends StatelessWidget {
  const CommunityMemberHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<BottomNavIndexProvider>(
      create: (_) => BottomNavIndexProvider(),
      child: Consumer<BottomNavIndexProvider>(
        builder: (context, navProvider, child) {
          String userName = HiveUtils.getData('name');
          return Scaffold(
            appBar: AppBar(
              title: Text('Welcome $userName'),
              automaticallyImplyLeading: false,
              actions: [
                IconButton(
                  icon: Icon(Icons.settings),
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
            body: navProvider.screens[navProvider.index],
            bottomNavigationBar: BottomNavigationBar(
              backgroundColor: AppColors.shadeColor,
              selectedItemColor: AppColors.primary,
              unselectedItemColor: AppColors.foregroundColor,
              type: BottomNavigationBarType.fixed,
              currentIndex: navProvider.index,
              onTap: (index) {
                navProvider.setIndex(index);
              },
              items: [
                BottomNavigationBarItem(
                  icon: Icon(Icons.chat_outlined),
                  label: 'Chats',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.group_outlined),
                  label: 'Groups',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.emoji_events_outlined),
                  label: 'Events',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.shopping_cart_outlined),
                  label: 'Market',
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
