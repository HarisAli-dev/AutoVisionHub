import 'dart:math';

import 'package:flutter/material.dart';
import 'package:front/utils/app_colors.dart';
import 'package:front/utils/sizes.dart';
import 'package:front/view/dashboard/widgets/shared/hover_card.dart';
import 'package:front/view/dashboard/widgets/shared/section_header.dart';

class MarketplaceContent extends StatelessWidget {
  const MarketplaceContent({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(
          title: 'Marketplace Picks',
          subtitle: 'Bid, buy, or negotiate directly with trusted sellers.',
        ),
        SizedBox(height: AppSizes.smallSpacing(context)),
        Wrap(
          spacing: AppSizes.mediumSpacing(context),
          runSpacing: AppSizes.mediumSpacing(context),
          children: [
            HoverCard(
              child: _listingCard(
                context,
                title: 'Range Rover Sport 2023',
                price: 'PKR 45,000,000',
                badge: 'Auction • 4h left',
                image:
                    'https://images.unsplash.com/photo-1552519507-da3b142c6e3d?w=800&h=600&fit=crop',
              ),
            ),
            HoverCard(
              child: _listingCard(
                context,
                title: 'Tesla Model 3 Performance',
                price: 'PKR 18,200,000',
                badge: 'Instant Buy',
                image:
                    'https://images.unsplash.com/photo-1560958089-b8a1929cea89?w=800&h=600&fit=crop',
              ),
            ),
            HoverCard(
              child: _listingCard(
                context,
                title: 'OEM Carbon Wing (Supra)',
                price: 'PKR 220,000',
                badge: 'Negotiable',
                image:
                    'https://images.unsplash.com/photo-1555215695-3004980ad54e?w=800&h=600&fit=crop',
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _listingCard(
    BuildContext context, {
    required String title,
    required String price,
    required String badge,
    required String image,
  }) {
    return Container(
      width: min(260, MediaQuery.of(context).size.width - 40),
      decoration: BoxDecoration(
        color: AppColors.surfaceColor,
        borderRadius: BorderRadius.circular(AppSizes.cardBorderRadius(context)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Stack(
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
                  errorBuilder: (context, error, stackTrace) => Container(
                    color: AppColors.shadeColor.withOpacity(0.2),
                    child: Icon(Icons.directions_car_filled_outlined,
                        color: AppColors.shadeColor),
                  ),
                ),
              ),
              Positioned(
                top: 12,
                right: 12,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.auto_graph, size: 14, color: Colors.black),
                      const SizedBox(width: 4),
                      Text(
                        badge,
                        style: const TextStyle(
                          color: Colors.black,
                          fontWeight: FontWeight.w600,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
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
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  price,
                  style: TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: AppSizes.smallSpacing(context)),
                Wrap(
                  spacing: AppSizes.smallSpacing(context),
                  runSpacing: AppSizes.smallSpacing(context),
                  children: [
                    _quickActionButton(
                      context,
                      icon: Icons.gavel_outlined,
                      label: 'Bid now',
                    ),
                    _quickActionButton(
                      context,
                      icon: Icons.chat_bubble_outline,
                      label: 'Chat',
                    ),
                    _quickActionButton(
                      context,
                      icon: Icons.view_in_ar,
                      label: 'AR',
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

