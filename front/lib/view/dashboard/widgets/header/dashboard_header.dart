import 'package:flutter/material.dart';
import 'package:front/providers/theme_provider.dart';
import 'package:front/utils/app_colors.dart';
import 'package:front/utils/sizes.dart';
import 'package:front/view/dashboard/widgets/shared/hover_card.dart';
import 'package:provider/provider.dart';

class DashboardHeader extends StatelessWidget {
  const DashboardHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        vertical: AppSizes.largeSpacing(context) * 0.9,
        horizontal: AppSizes.mediumPadding(context),
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primary.withOpacity(0.15),
            AppColors.primary.withOpacity(0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppSizes.cardBorderRadius(context)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(AppSizes.mediumPadding(context)),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.18),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.speed,
                  color: AppColors.primary,
                  size: AppSizes.largeIconSize(context) * 1.2,
                ),
              ),
              const Spacer(),
              HoverCard(
                onTap: () => context.read<ThemeProvider>().toggle(),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.brightness_6, color: AppColors.primary),
                    const SizedBox(width: 8),
                    Text(
                      'Toggle Theme',
                      style: TextStyle(
                        color: AppColors.foregroundColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: AppSizes.mediumSpacing(context)),
          Text(
            'Welcome back to AutoVisionHub',
            style: TextStyle(
              color: AppColors.titleColor,
              fontWeight: FontWeight.bold,
              fontSize: AppSizes.titleFontSize(context),
            ),
          ),
          SizedBox(height: AppSizes.smallSpacing(context)),
          Text(
            'Your personalised hub for discovery, community, events and marketplace deals.',
            style: TextStyle(
              color: AppColors.shadeColor,
              fontSize: AppSizes.bodyFontSize(context),
            ),
          ),
        ],
      ),
    );
  }
}

