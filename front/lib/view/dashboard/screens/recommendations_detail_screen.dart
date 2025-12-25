import 'package:flutter/material.dart';
import 'package:front/utils/app_colors.dart';
import 'package:front/utils/sizes.dart';

class RecommendationsDetailScreen extends StatelessWidget {
  const RecommendationsDetailScreen({super.key});

  @override
  Widget build(BuildContext context) {
    AppColors.getBackgroundColor(context);
    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      appBar: AppBar(
        title: const Text('Smart Recommendations'),
        backgroundColor: AppColors.appBarColor,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(AppSizes.mediumPadding(context)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: EdgeInsets.all(AppSizes.mediumPadding(context)),
              decoration: BoxDecoration(
                color: AppColors.surfaceColor,
                borderRadius: BorderRadius.circular(AppSizes.cardBorderRadius(context)),
                border: Border.all(color: AppColors.primary.withOpacity(0.15)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'How Recommendations Work',
                    style: TextStyle(
                      color: AppColors.titleColor,
                      fontWeight: FontWeight.bold,
                      fontSize: AppSizes.subtitleFontSize(context),
                    ),
                  ),
                  SizedBox(height: AppSizes.smallSpacing(context)),
                  Text(
                    'Our smart recommendation system analyzes your preferences, browsing history, and location to provide personalized vehicle and parts suggestions. It tracks your recently viewed items for quick access and highlights trending listings in your area to ensure you never miss popular options.',
                    style: TextStyle(
                      color: AppColors.shadeColor,
                      fontSize: AppSizes.bodyFontSize(context),
                      height: 1.5,
                    ),
                  ),
                  SizedBox(height: AppSizes.mediumSpacing(context)),
                  Container(
                    padding: EdgeInsets.all(AppSizes.mediumPadding(context)),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.primary.withOpacity(0.3)),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.info_outline,
                          color: AppColors.primary,
                          size: 20,
                        ),
                        SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'AutoVisionHub uses advanced algorithms to analyze your preferences, browsing history, and location. It recommends vehicles and parts that match your interests, shows your recently viewed items for easy comparison, and highlights trending listings in your area. The more you use the app, the better the recommendations become!',
                            style: TextStyle(
                              color: AppColors.shadeColor,
                              fontSize: AppSizes.bodyFontSize(context),
                              height: 1.6,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

}

