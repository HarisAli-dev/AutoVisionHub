import 'dart:math';
import 'package:flutter/material.dart';
import 'package:front/utils/app_colors.dart';
import 'package:front/utils/sizes.dart';
import 'package:front/view/dashboard/widgets/shared/hover_card.dart';

class MarketplaceAlertsDetailScreen extends StatelessWidget {
  const MarketplaceAlertsDetailScreen({super.key});

  @override
  Widget build(BuildContext context) {
    AppColors.getBackgroundColor(context);
    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      appBar: AppBar(
        title: const Text('Marketplace Alerts'),
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
                          color: Colors.amberAccent.withOpacity(0.2),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.shopping_bag_outlined,
                          color: Colors.amberAccent,
                          size: 24,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        '5 updates',
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
                    'Marketplace Alerts',
                    style: TextStyle(
                      color: AppColors.titleColor,
                      fontWeight: FontWeight.bold,
                      fontSize: AppSizes.subtitleFontSize(context),
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'New bids & offers in your watchlist',
                    style: TextStyle(
                      color: AppColors.shadeColor,
                      fontSize: AppSizes.bodyFontSize(context),
                    ),
                  ),
                  SizedBox(height: AppSizes.mediumSpacing(context)),
                  Text(
                    'You have 5 new updates in your marketplace watchlist. Check out new bids, offers, and price changes on items you\'re interested in.',
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
                            'Never miss important marketplace updates! Get instant alerts when someone places a bid on your listing or makes an offer. Receive notifications when prices drop on items in your watchlist. Get alerts for new listings that match your saved search criteria. You\'ll also be notified about bid deadlines, offer expirations, and seller responses. All marketplace alerts are centralized here - view, manage, and respond to all your marketplace activity from one convenient location.',
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
              'Marketplace Picks',
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
                HoverCard(
                  child: _listingCard(
                    context,
                    title: 'Range Rover Sport 2023',
                    price: 'PKR 45,000,000',
                    badge: 'Auction • 4h left',
                    showAR: true,
                  ),
                ),
                HoverCard(
                  child: _listingCard(
                    context,
                    title: 'Tesla Model 3 Performance',
                    price: 'PKR 18,200,000',
                    badge: 'Instant Buy',
                    showAR: true,
                  ),
                ),
                HoverCard(
                  child: _listingCard(
                    context,
                    title: 'OEM Carbon Wing (Supra)',
                    price: 'PKR 220,000',
                    badge: 'Negotiable',
                    showAR: false,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _listingCard(
    BuildContext context, {
    required String title,
    required String price,
    required String badge,
    required bool showAR,
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
                  Icons.directions_car_filled_outlined,
                  color: AppColors.shadeColor,
                  size: 40,
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
                    if (showAR)
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

