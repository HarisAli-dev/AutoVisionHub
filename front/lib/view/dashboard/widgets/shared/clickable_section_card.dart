import 'package:flutter/material.dart';
import 'package:front/utils/app_colors.dart';
import 'package:front/utils/sizes.dart';

class ClickableSectionCard extends StatelessWidget {
  final IconData icon;
  final Color iconBackgroundColor;
  final String title;
  final VoidCallback onTap;

  const ClickableSectionCard({
    super.key,
    required this.icon,
    required this.iconBackgroundColor,
    required this.title,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(AppSizes.mediumPadding(context)),
        decoration: BoxDecoration(
          color: AppColors.surfaceColor,
          borderRadius: BorderRadius.circular(AppSizes.cardBorderRadius(context)),
          boxShadow: [
            BoxShadow(
              offset: const Offset(0, 2),
              blurRadius: 8,
              color: Colors.black.withOpacity(0.1),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: iconBackgroundColor,
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                color: AppColors.foregroundColor,
                size: 24,
              ),
            ),
            SizedBox(width: AppSizes.mediumSpacing(context)),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  color: AppColors.titleColor,
                  fontWeight: FontWeight.w600,
                  fontSize: AppSizes.bodyFontSize(context),
                ),
              ),
            ),
            Icon(
              Icons.chevron_right,
              color: AppColors.shadeColor,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}

