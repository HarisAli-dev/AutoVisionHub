import 'package:flutter/material.dart';
import 'package:front/utils/app_colors.dart';
import 'package:front/utils/sizes.dart';

class LiveStreamingDetailScreen extends StatelessWidget {
  const LiveStreamingDetailScreen({super.key});

  @override
  Widget build(BuildContext context) {
    AppColors.getBackgroundColor(context);
    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      appBar: AppBar(
        title: const Text('Live Streaming'),
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
                boxShadow: [
                  BoxShadow(
                    offset: const Offset(0, 2),
                    blurRadius: 8,
                    color: Colors.black.withOpacity(0.1),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.redAccent.withOpacity(0.2),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.live_tv,
                          color: Colors.redAccent,
                          size: 24,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        '3 active',
                        style: TextStyle(
                          fontSize: AppSizes.subtitleFontSize(context),
                          fontWeight: FontWeight.bold,
                          color: AppColors.titleColor,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: AppSizes.smallSpacing(context)),
                  Text(
                    'Live Streaming',
                    style: TextStyle(
                      color: AppColors.titleColor,
                      fontWeight: FontWeight.bold,
                      fontSize: AppSizes.subtitleFontSize(context),
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Happening right now',
                    style: TextStyle(
                      color: AppColors.shadeColor,
                      fontSize: AppSizes.bodyFontSize(context),
                    ),
                  ),
                  SizedBox(height: AppSizes.mediumSpacing(context)),
                  Text(
                    'There are currently 3 live streams active. Join these streams to interact with the community, ask questions, and stay updated with the latest automotive events and discussions.',
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
                            'Watch automotive events live as they happen! Event organizers stream car shows, meetups, and discussions in real-time directly from the app. During live streams, you can interact by asking questions in the chat. Our AI chatbot provides instant answers to common questions during the stream. All live streams are automatically recorded and saved, so you can watch the replay later if you missed the live event. Join active streams to connect with the community in real-time.',
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

