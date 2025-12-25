import 'package:flutter/material.dart';
import 'package:front/view/dashboard/widgets/shared/clickable_section_card.dart';

class QuickStatsSection extends StatelessWidget {
  final VoidCallback onProfileCompletionTap;
  final VoidCallback onLiveStreamingTap;
  final VoidCallback onDiscussionThreadsTap;
  final VoidCallback onMarketplaceAlertsTap;

  const QuickStatsSection({
    super.key,
    required this.onProfileCompletionTap,
    required this.onLiveStreamingTap,
    required this.onDiscussionThreadsTap,
    required this.onMarketplaceAlertsTap,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ClickableSectionCard(
          icon: Icons.verified_user,
          iconBackgroundColor: Colors.greenAccent.withOpacity(0.2),
          title: 'Profile Completion',
          onTap: onProfileCompletionTap,
        ),
        SizedBox(height: 12),
        ClickableSectionCard(
          icon: Icons.live_tv,
          iconBackgroundColor: Colors.redAccent.withOpacity(0.2),
          title: 'Live Streaming',
          onTap: onLiveStreamingTap,
        ),
        SizedBox(height: 12),
        ClickableSectionCard(
          icon: Icons.forum_outlined,
          iconBackgroundColor: Colors.blueAccent.withOpacity(0.2),
          title: 'Discussion Threads',
          onTap: onDiscussionThreadsTap,
        ),
        SizedBox(height: 12),
        ClickableSectionCard(
          icon: Icons.shopping_bag_outlined,
          iconBackgroundColor: Colors.amberAccent.withOpacity(0.2),
          title: 'Marketplace Alerts',
          onTap: onMarketplaceAlertsTap,
        ),
      ],
    );
  }
}

