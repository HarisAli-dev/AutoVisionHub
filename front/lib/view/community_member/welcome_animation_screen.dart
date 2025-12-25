import 'package:flutter/material.dart';
import 'package:front/utils/app_colors.dart';
import 'package:front/utils/sizes.dart';

class WelcomeAnimationScreen extends StatefulWidget {
  final String appName;
  final IconData appIcon;
  final Color appColor;

  const WelcomeAnimationScreen({
    super.key,
    required this.appName,
    required this.appIcon,
    required this.appColor,
  });

  @override
  State<WelcomeAnimationScreen> createState() => _WelcomeAnimationScreenState();
}

class _WelcomeAnimationScreenState extends State<WelcomeAnimationScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;
  late Animation<double> _rotateAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _scaleAnimation = Tween<double>(begin: 0.5, end: 1.2).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.6, curve: Curves.elasticOut),
      ),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.5, curve: Curves.easeIn),
      ),
    );

    _rotateAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.3, 0.8, curve: Curves.easeInOut),
      ),
    );

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.backgroundColor.withOpacity(0.95),
      child: Center(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AnimatedBuilder(
                animation: _controller,
                builder: (context, child) {
                  return Transform.scale(
                    scale: _scaleAnimation.value,
                    child: Transform.rotate(
                      angle: _rotateAnimation.value * 0.5,
                      child: Container(
                        padding: EdgeInsets.all(
                          AppSizes.getScreenWidth(context) * 0.1,
                        ),
                        decoration: BoxDecoration(
                          color: widget.appColor.withOpacity(0.2),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          widget.appIcon,
                          size: AppSizes.getScreenWidth(context) * 0.2,
                          color: widget.appColor,
                        ),
                      ),
                    ),
                  );
                },
              ),
              SizedBox(height: AppSizes.largeSpacing(context)),
              ScaleTransition(
                scale: _scaleAnimation,
                child: Text(
                  widget.appName,
                  style: TextStyle(
                    fontSize: AppSizes.titleFontSize(context) * 1.5,
                    fontWeight: FontWeight.bold,
                    color: widget.appColor,
                    letterSpacing: 2,
                  ),
                ),
              ),
              SizedBox(height: AppSizes.smallSpacing(context)),
              FadeTransition(
                opacity: _fadeAnimation,
                child: Text(
                  'Welcome',
                  style: TextStyle(
                    fontSize: AppSizes.bodyFontSize(context),
                    color: AppColors.shadeColor,
                    letterSpacing: 1.5,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
