import 'package:flutter/material.dart';
import 'package:front/utils/app_colors.dart';
import 'package:front/utils/hive_utils.dart';
import 'package:front/utils/sizes.dart';
import 'package:front/view/dashboard/widgets/shared/hover_card.dart';

class RoleHighlightsDetailScreen extends StatelessWidget {
  const RoleHighlightsDetailScreen({super.key});

  String get _role =>
      (HiveUtils.getData('role') as String? ?? 'guest').toLowerCase();

  @override
  Widget build(BuildContext context) {
    AppColors.getBackgroundColor(context);
    
    final roleSections = {
      'community_member': [
        _FeatureCardData(
          title: 'Community Feed',
          description: 'Join the latest discussions and connect with your crew.',
          icon: Icons.people_alt_outlined,
          appInfo:
              'Join city-based or interest-based automotive groups to connect with like-minded enthusiasts! Participate in group discussions, share photos and videos in group chats, and get answers to your car-related questions. Create polls within groups to gather opinions from members. Upvote helpful posts and content that you find valuable. Stay updated with activity alerts for new posts, replies, and group updates.',
        ),
        _FeatureCardData(
          title: 'Live Events',
          description: 'RSVP and watch automotive events live.',
          icon: Icons.event_available,
          appInfo:
              'Browse and RSVP to automotive events happening in your area! Find car shows, meetups, workshops, and automotive gatherings. RSVP to events you want to attend. Watch events live through the app if the organizer is streaming. Interact with other attendees in real-time during live events. Receive automatic reminders before events start so you never miss an important gathering.',
        ),
      ],
      'event_manager': [
        _FeatureCardData(
          title: 'Event Planner',
          description: 'Create, edit, and track attendee stats effortlessly.',
          icon: Icons.event_note,
          appInfo:
              'Create and manage automotive events with ease! Add event details, location, and descriptions. Track RSVPs and see who\'s attending. Send automatic reminders to attendees and update event information anytime. Cancel or reschedule events with one click.',
        ),
        _FeatureCardData(
          title: 'Engagement Insights',
          description: 'Monitor RSVPs, check-ins, and live interactions.',
          icon: Icons.analytics_outlined,
          appInfo:
              'Get detailed insights into your event\'s performance! See how many people RSVP\'d, track check-ins at the venue, and monitor real-time interactions during live streams. Analyze engagement metrics to understand what works best for your audience.',
        ),
        _FeatureCardData(
          title: 'Live Stream Studio',
          description: 'Go live with one tap and interact with your audience.',
          icon: Icons.videocam_outlined,
          appInfo:
              'Stream your events live directly from the app! Start a live stream with one tap and engage with your audience in real-time. Our AI chatbot helps answer viewer questions during the stream. All streams are automatically recorded so viewers can watch them later.',
        ),
      ],
      'admin': [
        _FeatureCardData(
          title: 'User Reports',
          description: 'Review flagged posts and user behaviour quickly.',
          icon: Icons.report_outlined,
          appInfo:
              'Keep the platform safe and welcoming! Review user reports and flagged content. Block or ban users who violate community guidelines. Monitor all platform activity to ensure a positive experience for everyone.',
        ),
        _FeatureCardData(
          title: 'Marketplace Approvals',
          description: 'Verify new listings and manage marketplace quality.',
          icon: Icons.verified_outlined,
          appInfo:
              'Maintain marketplace quality and trust! Review and approve new vehicle and parts listings. Most listings are approved automatically, but flagged items require manual review. Verify listing details and ensure all content meets platform standards.',
        ),
        _FeatureCardData(
          title: 'Platform Analytics',
          description: 'Stay on top of growth and engagement metrics.',
          icon: Icons.insights_outlined,
          appInfo:
              'Get comprehensive insights into platform performance! Track user growth, engagement rates, and content popularity. Monitor which features are most used and analyze trends to make data-driven decisions for platform improvements.',
        ),
      ],
    };

    final items = roleSections[_role] ?? roleSections['community_member']!;
    final subtitle = _role == 'event_manager'
        ? 'Manage events, audiences, and live experiences.'
        : _role == 'admin'
            ? 'Keep the AutoVisionHub ecosystem safe and thriving.'
            : 'Engage with the community and explore tailored content.';

    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      appBar: AppBar(
        title: Text(_role == 'event_manager'
            ? 'Event Manager Highlights'
            : _role == 'admin'
                ? 'Admin Highlights'
                : 'Community Highlights'),
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
                    'Highlights for you',
                    style: TextStyle(
                      color: AppColors.titleColor,
                      fontWeight: FontWeight.bold,
                      fontSize: AppSizes.subtitleFontSize(context),
                    ),
                  ),
                  SizedBox(height: AppSizes.smallSpacing(context)),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: AppColors.shadeColor,
                      fontSize: AppSizes.bodyFontSize(context),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: AppSizes.largeSpacing(context)),
            ...items.map((feature) => Padding(
                  padding: EdgeInsets.only(bottom: AppSizes.mediumSpacing(context)),
                  child: HoverCard(
                    child: _buildFeatureCard(context, feature),
                  ),
                )),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureCard(BuildContext context, _FeatureCardData data) {
    return Container(
      padding: EdgeInsets.all(AppSizes.mediumPadding(context)),
      decoration: BoxDecoration(
        color: AppColors.surfaceColor,
        borderRadius: BorderRadius.circular(AppSizes.cardBorderRadius(context)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(data.icon, color: AppColors.primary, size: 32),
              SizedBox(width: AppSizes.mediumSpacing(context)),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      data.title,
                      style: TextStyle(
                        color: AppColors.titleColor,
                        fontWeight: FontWeight.bold,
                        fontSize: AppSizes.subtitleFontSize(context),
                      ),
                    ),
                    SizedBox(height: 6),
                    Text(
                      data.description,
                      style: TextStyle(
                        color: AppColors.shadeColor,
                        fontSize: AppSizes.bodyFontSize(context),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (data.appInfo != null) ...[
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
                      data.appInfo!,
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
        ],
      ),
    );
  }
}

class _FeatureCardData {
  final String title;
  final String description;
  final IconData icon;
  final String? appInfo;

  _FeatureCardData({
    required this.title,
    required this.description,
    required this.icon,
    this.appInfo,
  });
}

