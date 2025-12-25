import 'dart:math';
import 'package:flutter/material.dart';
import 'package:front/utils/app_colors.dart';
import 'package:front/utils/sizes.dart';
import 'package:front/view/dashboard/widgets/shared/hover_card.dart';

class DiscussionThreadsDetailScreen extends StatelessWidget {
  const DiscussionThreadsDetailScreen({super.key});

  @override
  Widget build(BuildContext context) {
    AppColors.getBackgroundColor(context);
    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      appBar: AppBar(
        title: const Text('Discussion Threads'),
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
                          color: Colors.blueAccent.withOpacity(0.2),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.forum_outlined,
                          color: Colors.blueAccent,
                          size: 24,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        '12 new',
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
                    'Discussion Threads',
                    style: TextStyle(
                      color: AppColors.titleColor,
                      fontWeight: FontWeight.bold,
                      fontSize: AppSizes.subtitleFontSize(context),
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Catch up with the community',
                    style: TextStyle(
                      color: AppColors.shadeColor,
                      fontSize: AppSizes.bodyFontSize(context),
                    ),
                  ),
                  SizedBox(height: AppSizes.mediumSpacing(context)),
                  Text(
                    'There are 12 new discussion threads in the community. Engage with fellow members, share your experiences, and get answers to your automotive questions.',
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
                            'Start or join discussion threads on any automotive topic! Create threads about car modifications, parts reviews, maintenance tips, or general automotive discussions. All threads are organized by categories like "General", "Modifications", "Parts & Accessories", and "Reviews" for easy browsing. Participate in group chats where you can share photos and videos. Create polls to gather community opinions on topics. Upvote helpful posts to help others find valuable information. Get notified when someone replies to your threads or when new discussions are created in your groups.',
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
            SizedBox(height: AppSizes.largeSpacing(context)),
            Text(
              'Recent Discussions',
              style: TextStyle(
                color: AppColors.titleColor,
                fontWeight: FontWeight.bold,
                fontSize: AppSizes.subtitleFontSize(context),
              ),
            ),
            SizedBox(height: AppSizes.mediumSpacing(context)),
            Wrap(
              spacing: AppSizes.mediumSpacing(context),
              runSpacing: AppSizes.mediumSpacing(context),
              children: [
                SizedBox(
                  width: min(340, MediaQuery.of(context).size.width - 40),
                  child: HoverCard(
                    child: _feedCard(
                      context,
                      title: 'Join the Discussion: Future of EVs',
                      author: '@AutoEnthusiast',
                      stats: const ['1.2K views', '65 replies', '18 upvotes'],
                    ),
                  ),
                ),
                SizedBox(
                  width: min(340, MediaQuery.of(context).size.width - 40),
                  child: HoverCard(
                    child: _feedCard(
                      context,
                      title: 'Best AWD SUVs for 2025',
                      author: '@UrbanDriver',
                      stats: const ['987 views', '42 replies', '12 upvotes'],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _feedCard(
    BuildContext context, {
    required String title,
    required String author,
    required List<String> stats,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceColor,
        borderRadius: BorderRadius.circular(AppSizes.cardBorderRadius(context)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 140,
            width: double.infinity,
            decoration: BoxDecoration(
              color: AppColors.shadeColor.withOpacity(0.2),
              borderRadius: BorderRadius.vertical(
                top: Radius.circular(AppSizes.cardBorderRadius(context)),
              ),
            ),
            child: Icon(
              Icons.image_not_supported,
              color: AppColors.shadeColor,
              size: 40,
            ),
          ),
          Padding(
            padding: EdgeInsets.all(AppSizes.mediumPadding(context)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: AppColors.titleColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 6),
                Text(
                  author,
                  style: TextStyle(
                    color: AppColors.shadeColor,
                    fontSize: AppSizes.smallFontSize(context),
                  ),
                ),
                SizedBox(height: 8),
                Row(
                  children: stats
                      .map(
                        (stat) => Padding(
                          padding: const EdgeInsets.only(right: 12),
                          child: Row(
                            children: [
                              Icon(Icons.circle,
                                  size: 6, color: AppColors.primary),
                              const SizedBox(width: 4),
                              Text(
                                stat,
                                style: TextStyle(
                                  color: AppColors.shadeColor,
                                  fontSize: AppSizes.smallFontSize(context),
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                      .toList(),
                ),
                SizedBox(height: 12),
                Wrap(
                  spacing: AppSizes.smallSpacing(context),
                  runSpacing: AppSizes.smallSpacing(context),
                  children: [
                    _quickActionButton(
                      context,
                      icon: Icons.thumb_up_alt_outlined,
                      label: 'Upvote',
                    ),
                    _quickActionButton(
                      context,
                      icon: Icons.alternate_email_outlined,
                      label: 'Mention',
                    ),
                    _quickActionButton(
                      context,
                      icon: Icons.report_outlined,
                      label: 'Report',
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _quickActionButton(BuildContext context,
      {required IconData icon, required String label}) {
    return HoverCard(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: AppColors.primary),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: AppColors.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

