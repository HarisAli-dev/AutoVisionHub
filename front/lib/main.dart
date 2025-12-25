import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:front/controller/marketplace/marketplace_controller.dart';
import 'package:front/splash_screen.dart';
import 'package:front/view/auth/signin.dart';
import 'package:front/view/auth/signup.dart';
import 'package:front/view/community_member/community_member_home_screen.dart';

import 'package:front/view/community_member/chats/chat_screen.dart';
import 'package:front/view/community_member/groups/group_screen.dart';
import 'package:front/view/community_member/events/view_event_screen.dart';
import 'package:front/view/dashboard/dashboard_screen.dart';
import 'package:front/view/payment/payment_profile_screen.dart';
import 'package:front/config/firebase_api.dart';
import 'package:front/providers/unified_audio_provider.dart';
import 'package:front/providers/video_player_provider.dart';
import 'package:front/providers/poll_provider.dart';
import 'package:front/providers/seat_provider.dart';
import 'package:front/providers/theme_provider.dart';
import 'package:front/config/app_config.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:hive_flutter/adapters.dart';
import 'package:provider/provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load environment variables
  await AppConfig.loadEnv();

  // Initialize Firebase and notifications (skip on web if not configured)
  if (!kIsWeb) {
    try {
      await FirebaseApi.initNotifications();
    } catch (_) {}
  }

  // Initialize Hive
  await Hive.initFlutter();
  await Hive.openBox('sessionBox');

  // Initialize Stripe (mobile only; skip on web)
  if (!kIsWeb) {
    try {
      Stripe.publishableKey = AppConfig.stripePublishableKey;
      await Stripe.instance.applySettings();
    } catch (_) {}
  }

  runApp(const MyApp());
}

// Use environment variable for API URL
final String apiUrl = AppConfig.apiBaseUrl;

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AudioProvider()),
        ChangeNotifierProvider(create: (_) => VideoPlayerProvider()),
        ChangeNotifierProvider(create: (_) => PollProvider()),
        ChangeNotifierProvider(create: (_) => SeatProvider()),
        ChangeNotifierProvider(create: (_) => MarketplaceController()),
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, _) => MaterialApp(
          navigatorKey: FirebaseApi.navigatorKey,
          debugShowCheckedModeBanner: false,
          title: 'Flutter Demo',
          theme: ThemeData.light(),
          darkTheme: ThemeData.dark(),
          themeMode: themeProvider.mode,
          home: SplashScreen(),
          routes: {
            '/signin': (context) => SignInScreen(),
            '/signup': (context) => SignupScreen(),
            '/communityMemberHome': (context) => CommunityMemberHomeScreen(),
            '/payment-profile': (context) => PaymentProfileScreen(),
            '/dashboard': (context) => DashboardScreen(),
          },
          onGenerateRoute: (settings) {
            final args = settings.arguments as Map<String, dynamic>?;

            switch (settings.name) {
              case '/chat':
                return MaterialPageRoute(
                  builder: (context) => ChatScreen(
                    chatId: args?['chatId'] ?? '',
                    chatName: args?['chatName'] ?? 'Chat',
                  ),
                );
              case '/group':
                return MaterialPageRoute(
                  builder: (context) => GroupScreen(
                    groupId: args?['groupId'] ?? '',
                    groupName: args?['groupName'] ?? 'Group',
                    currentUserId: args?['currentUserId'] ?? '',
                    groupImage: args?['groupImage'] ?? '',
                  ),
                );
              case '/event':
                if (args?['event'] != null) {
                  return MaterialPageRoute(
                    builder: (context) =>
                        ViewEventScreen(event: args!['event']),
                  );
                }
                return null;
              default:
                return null;
            }
          },
        ),
      ),
    );
  }
}
