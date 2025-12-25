import 'package:flutter/material.dart';
import 'package:front/utils/app_colors.dart';
import 'package:front/utils/sizes.dart';
import 'package:front/utils/hive_utils.dart';
import 'package:front/view/community_member/chats_app_screen.dart';
import 'package:front/view/community_member/events_app_screen.dart';
import 'package:front/view/community_member/marketplace_app_screen.dart';
import 'package:front/view/community_member/welcome_animation_screen.dart';
import 'package:front/view/community_member/threads/threads_list_screen.dart';
import 'package:front/view/settings/setting.dart';

enum AppSection { marketplace, events, chats, discussions }

class CommunityHubScreen extends StatefulWidget {
  const CommunityHubScreen({super.key});

  @override
  State<CommunityHubScreen> createState() => _CommunityHubScreenState();
}

class _CommunityHubScreenState extends State<CommunityHubScreen>
    with SingleTickerProviderStateMixin {
  AppSection currentApp = AppSection.marketplace;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  bool _isAnimating = false;
  bool _showWelcomeAnimation = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.1), end: Offset.zero).animate(
          CurvedAnimation(
            parent: _animationController,
            curve: Curves.easeOutCubic,
          ),
        );

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _switchApp(AppSection newApp) async {
    if (currentApp == newApp || _isAnimating) return;

    setState(() => _isAnimating = true);

    // Fade out current screen
    await _animationController.reverse();

    // Switch app first
    setState(() {
      currentApp = newApp;
    });

    // Show welcome animation for the NEW app
    setState(() => _showWelcomeAnimation = true);

    // Wait for welcome animation to show
    await Future.delayed(const Duration(milliseconds: 1000));

    // Hide welcome animation
    setState(() => _showWelcomeAnimation = false);

    // Fade in new screen
    await _animationController.forward();

    setState(() => _isAnimating = false);
  }

  Widget _getCurrentAppScreen() {
    switch (currentApp) {
      case AppSection.marketplace:
        return const MarketplaceAppScreen();
      case AppSection.events:
        return const EventsAppScreen();
      case AppSection.chats:
        return const ChatsAppScreen();
      case AppSection.discussions:
        return const ThreadsListScreen();
    }
  }

  IconData _getAppIcon(AppSection app) {
    switch (app) {
      case AppSection.marketplace:
        return Icons.shopping_bag_outlined;
      case AppSection.events:
        return Icons.emoji_events_outlined;
      case AppSection.chats:
        return Icons.chat_bubble_outline;
      case AppSection.discussions:
        return Icons.forum_outlined;
    }
  }

  String _getAppName(AppSection app) {
    switch (app) {
      case AppSection.marketplace:
        return 'Market';
      case AppSection.events:
        return 'Events';
      case AppSection.chats:
        return 'Chats';
      case AppSection.discussions:
        return 'Discuss';
    }
  }

  @override
  Widget build(BuildContext context) {
    AppColors.getBackgroundColor(context);
    String userName = HiveUtils.getData('name') ?? 'User';

    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      appBar: AppBar(
        backgroundColor: AppColors.backgroundColor,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: Text(
          'Welcome $userName',
          style: TextStyle(
            color: AppColors.titleColor,
            fontSize: AppSizes.titleFontSize(context),
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.settings, color: AppColors.foregroundColor),
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
      body: Column(
        children: [
          // App Switcher Row
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: AppSizes.mediumPadding(context),
              vertical: AppSizes.smallPadding(context),
            ),
            decoration: BoxDecoration(
              color: AppColors.backgroundColor,
              boxShadow: [
                BoxShadow(
                  color: AppColors.shadeColor.withOpacity(0.1),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: AppSection.values.map((app) {
                final isSelected = currentApp == app;
                return Expanded(
                  child: GestureDetector(
                    onTap: () => _switchApp(app),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      margin: EdgeInsets.symmetric(
                        horizontal: AppSizes.smallSpacing(context) / 2,
                      ),
                      padding: EdgeInsets.symmetric(
                        vertical: AppSizes.mediumPadding(context),
                      ),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppColors.primary
                            : AppColors.shadeColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(
                          AppSizes.cardBorderRadius(context),
                        ),
                        border: isSelected
                            ? Border.all(color: AppColors.primary, width: 2)
                            : null,
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            _getAppIcon(app),
                            color: isSelected
                                ? AppColors.titleColor
                                : AppColors.foregroundColor,
                            size: AppSizes.getScreenWidth(context) * 0.06,
                          ),
                          SizedBox(height: AppSizes.smallSpacing(context) / 2),
                          Text(
                            _getAppName(app),
                            style: TextStyle(
                              color: isSelected
                                  ? AppColors.titleColor
                                  : AppColors.foregroundColor,
                              fontSize: AppSizes.bodyFontSize(context) * 0.9,
                              fontWeight: isSelected
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),

          // App Content with Animation
          Expanded(
            child: Stack(
              children: [
                FadeTransition(
                  opacity: _fadeAnimation,
                  child: SlideTransition(
                    position: _slideAnimation,
                    child: _getCurrentAppScreen(),
                  ),
                ),
                if (_showWelcomeAnimation)
                  WelcomeAnimationScreen(
                    appName: _getAppName(currentApp),
                    appIcon: _getAppIcon(currentApp),
                    appColor: AppColors.primary,
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
