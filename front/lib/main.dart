import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:front/splash_screen.dart';
import 'package:front/view/auth/signin.dart';
import 'package:front/view/auth/signup.dart';
import 'package:front/view/community_member/community_member_home_screen.dart';
import 'package:front/providers/unified_audio_provider.dart';
import 'package:front/providers/video_player_provider.dart';
import 'package:front/providers/poll_provider.dart';
import 'package:front/providers/seat_provider.dart';
import 'package:flutter/material.dart';
import 'package:hive_flutter/adapters.dart';
import 'package:provider/provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();
  await Hive.openBox('sessionBox');
  Stripe.publishableKey =
      'pk_test_51S9RGbKLSXb0Puxvt6KTbJdYcByY6a0cU1XWQ22cvQdq5SKNKQTNfEM52bfOyuvjx0eeZeh1lybqgRzEBGNtjZUh00F6i2O4zw';
  await Stripe.instance.applySettings();

  runApp(const MyApp());
}

final String apiUrl = "http://192.168.1.36:8080/api";

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
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Flutter Demo',
        theme: ThemeData.light(),
        darkTheme: ThemeData.dark(),
        themeMode: ThemeMode.system,
        home: SplashScreen(),
        routes: {
          '/signin': (context) => SignInScreen(),
          '/signup': (context) => SignupScreen(),
          '/communityMemberHome': (context) => CommunityMemberHomeScreen(),
        },
      ),
    );
  }
}
