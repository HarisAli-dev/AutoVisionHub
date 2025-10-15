import 'package:flutter/material.dart';
import 'package:front/view/community_member/chats/chats_list_screen.dart';
import 'package:front/view/community_member/events/event_list_screen.dart';
import 'package:front/view/community_member/groups/group_list_screen.dart';
import 'package:front/view/community_member/marketplace/marketplace_home_screen.dart';

class BottomNavIndexProvider extends ChangeNotifier {
  int _index = 0;
  int get index => _index;
  //screens for navigation
  final List<Widget> screens = [
    ChatsListScreen(),
    GroupListScreen(),
    EventListScreen(),
    MarketplaceHomeScreen(),
  ];
  void setIndex(int i) {
    _index = i;
    notifyListeners();
  }
}
