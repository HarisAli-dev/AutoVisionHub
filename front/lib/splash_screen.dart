import 'package:front/controller/users/auth_controller.dart';
import 'package:front/utils/app_colors.dart';
import 'package:front/utils/navigations.dart';
import 'package:front/utils/permission_manager.dart';
import 'package:front/utils/sizes.dart';
import 'package:front/view/auth/signin.dart';
import 'package:flutter/material.dart';
import 'package:hive_flutter/adapters.dart';
import 'package:permission_handler/permission_handler.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeInAnimation;

  @override
  void initState() {
    super.initState();

    // Request all permissions needed by the app
    _requestPermissions();

    // Initialize the animation controller
    _controller = AnimationController(
      duration: Duration(seconds: 2), // 2 seconds for the animation
      vsync: this,
    );

    // Define the fade-in animation
    _fadeInAnimation = Tween(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeIn));

    // Start the animation
    _controller.forward();

    // Navigate to the next screen after the splash screen duration
    Future.delayed(Duration(seconds: 2), () async {
      var box = await Hive.openBox('sessionBox');
      String userRole = box.get('role', defaultValue: 'guest');
      bool isLoggedIn = box.get('isLoggedIn', defaultValue: false);
      String token = box.get('token', defaultValue: '');
      bool isFirstTime = box.get('isFirstTime', defaultValue: true);
      print('User Role: $userRole');
      print('Is Logged In: $isLoggedIn');
      print('Token: $token');
      print('Is First Time: $isFirstTime');

      // Check if this is the first time opening the app
      if (isFirstTime) {
        // Mark as not first time anymore
        await box.put('isFirstTime', false);
        // Navigate to dashboard
        Navigator.pushReplacementNamed(context, '/dashboard');
        return;
      }

      if (isLoggedIn && token.isNotEmpty) {
        final isTokenValid = await AuthController.checkTokenExpiry(token);
        if (isTokenValid) {
          NavigationUtils.roleBasedNavigation(userRole, context);
        } else {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => SignInScreen()),
          );
        }
      } else {
        Navigator.pushReplacementNamed(context, '/signin');
      }
    });
  }

  /// Request all permissions needed by the app
  Future<void> _requestPermissions() async {
    // Use the PermissionManager to request all needed permissions
    final permissionManager = PermissionManager();
    debugPrint('Requesting all permissions...');
    final response = await permissionManager.requestAllPermissions();
    debugPrint('Permission request response: $response');

    // Check if storage permission is permanently denied
    final storageStatus = await Permission.storage.status;
    if (storageStatus.isPermanentlyDenied && mounted) {
      // Show dialog to guide user to settings
      await permissionManager.showPermissionRationaleDialog(
        context,
        title: 'Storage Permission Required',
        message:
            'Storage permission is required for recording and saving media. Please enable it in app settings.',
      );
    }
  }

  @override
  void dispose() {
    _controller.dispose(); // Clean up the controller when not needed
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    AppColors.getBackgroundColor(context);
    return Scaffold(
      body: Center(
        child: FadeTransition(
          opacity: _fadeInAnimation,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: AppSizes.getScreenWidth(context) * 0.3,
                height: AppSizes.getScreenHeight(context) * 0.3,
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                ),
                child: ClipOval(
                  child: Image.asset(
                    'assets/icons/appstore.png',
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Icon(
                        Icons.directions_car,
                        color: AppColors.foregroundColor,
                        size: AppSizes.getScreenWidth(context) * 0.15,
                      );
                    },
                  ),
                ),
              ),
              SizedBox(height: AppSizes.getScreenHeight(context) * 0.02),
              Text(
                'AutoVisionHub',
                style: TextStyle(
                  color: AppColors.foregroundColor,
                  fontSize: AppSizes.titleFontSize(context),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
