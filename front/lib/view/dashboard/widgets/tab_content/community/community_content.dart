import 'dart:math';

import 'package:flutter/material.dart';
import 'package:front/utils/app_colors.dart';
import 'package:front/utils/sizes.dart';
import 'package:front/view/dashboard/widgets/shared/hover_card.dart';
import 'package:front/view/dashboard/widgets/shared/section_header.dart';

class CommunityContent extends StatelessWidget {
  const CommunityContent({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(
          title: 'Community Feed',
          subtitle: 'Stay in the loop with discussions, polls, and threads.',
        ),
        SizedBox(height: AppSizes.smallSpacing(context)),
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
                  image:
                      'https://images.unsplash.com/photo-1516321497487-e288fb19713f?q=80&w=870&auto=format&fit=crop&ixlib=rb-4.1.0&ixid=M3wxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8fA%3D%3D',
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
                  image:
                      'https://images.unsplash.com/photo-1503376780353-7e6692767b70?q=80&w=870&auto=format&fit=crop&ixlib=rb-4.1.0&ixid=M3wxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8fA%3D%3D',
                  stats: const ['987 views', '42 replies', '12 upvotes'],
                ),
              ),
            ),
            SizedBox(
              width: min(340, MediaQuery.of(context).size.width - 40),
              child: HoverCard(
                child: _pollCard(context),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _feedCard(
    BuildContext context, {
    required String title,
    required String author,
    required String image,
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
          ClipRRect(
            borderRadius: BorderRadius.vertical(
              top: Radius.circular(AppSizes.cardBorderRadius(context)),
            ),
            child: Image.network(
              image,
              height: 140,
              width: double.infinity,
              fit: BoxFit.cover,
              loadingBuilder: (context, child, loadingProgress) {
                if (loadingProgress == null) return child;
                return Container(
                  height: 140,
                  color: AppColors.shadeColor.withOpacity(0.2),
                  child: Center(
                    child: CircularProgressIndicator(
                      value: loadingProgress.expectedTotalBytes != null
                          ? loadingProgress.cumulativeBytesLoaded /
                              loadingProgress.expectedTotalBytes!
                          : null,
                      color: AppColors.primary,
                    ),
                  ),
                );
              },
              errorBuilder: (context, error, stackTrace) => Container(
                color: AppColors.shadeColor.withOpacity(0.2),
                child: Icon(Icons.image_not_supported,
                    color: AppColors.shadeColor),
              ),
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

  Widget _pollCard(BuildContext context) {
    final options = [
      _PollOption('Toyota', 40),
      _PollOption('Tesla', 35),
      _PollOption('Ford', 25),
    ];
    return Container(
      padding: EdgeInsets.all(AppSizes.mediumPadding(context)),
      decoration: BoxDecoration(
        color: AppColors.surfaceColor,
        borderRadius: BorderRadius.circular(AppSizes.cardBorderRadius(context)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Poll: What is your favourite car brand?',
            style: TextStyle(
              color: AppColors.titleColor,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: AppSizes.mediumSpacing(context)),
          ...options.map((option) => _pollOption(context, option)).toList(),
          SizedBox(height: AppSizes.smallSpacing(context)),
          Text(
            '132 votes • Ends in 6h',
            style: TextStyle(
              color: AppColors.shadeColor,
              fontSize: AppSizes.smallFontSize(context),
            ),
          ),
        ],
      ),
    );
  }

  Widget _pollOption(BuildContext context, _PollOption option) {
    return Padding(
      padding: EdgeInsets.only(bottom: AppSizes.smallSpacing(context)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Stack(
                  children: [
                    Container(
                      height: 32,
                      decoration: BoxDecoration(
                        color: AppColors.shadeColor.withOpacity(0.15),
                        borderRadius:
                            BorderRadius.circular(AppSizes.inputBorderRadius(context)),
                      ),
                    ),
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 500),
                      height: 32,
                      width: option.percentage.toDouble(),
                      constraints: BoxConstraints(
                        maxWidth: MediaQuery.of(context).size.width,
                      ),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            AppColors.primary,
                            AppColors.primary.withOpacity(0.7),
                          ],
                        ),
                        borderRadius:
                            BorderRadius.circular(AppSizes.inputBorderRadius(context)),
                      ),
                    ),
                    Positioned.fill(
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          child: Text(
                            option.label,
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(width: 12),
              Text(
                '${option.percentage}%',
                style: TextStyle(
                  color: AppColors.titleColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
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

class _PollOption {
  final String label;
  final int percentage;

  _PollOption(this.label, this.percentage);
}

