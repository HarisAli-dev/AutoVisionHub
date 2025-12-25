import 'package:flutter/material.dart';
import 'package:front/controller/marketplace/marketplace_controller.dart';
import 'package:front/model/marketplace/listing_model.dart';
import 'package:front/utils/app_colors.dart';
import 'package:front/utils/custom_widgets.dart';
import 'package:front/utils/sizes.dart';
import 'package:front/view/community_member/marketplace/listing_detail_screen.dart';
import 'package:front/view/dashboard/widgets/shared/hover_card.dart';
import 'package:front/view/dashboard/widgets/shared/info_banner.dart';
import 'package:front/view/dashboard/widgets/shared/section_header.dart';
import 'package:provider/provider.dart';

class PersonalizedRecommendationsSection extends StatelessWidget {
  final List<ListingModel> recommendedVehicles;
  final List<ListingModel> recommendedParts;
  final List<String> preferenceTags;
  final bool isLoading;
  final String? error;
  final VoidCallback onRefresh;
  final VoidCallback onNavigateToSignIn;
  final bool isLoggedIn;
  final void Function(VoidCallback) requireAuth;

  const PersonalizedRecommendationsSection({
    super.key,
    required this.recommendedVehicles,
    required this.recommendedParts,
    required this.preferenceTags,
    required this.isLoading,
    this.error,
    required this.onRefresh,
    required this.onNavigateToSignIn,
    required this.isLoggedIn,
    required this.requireAuth,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: SectionHeader(
                title: 'Personalised picks',
                subtitle: 'Vehicles & parts tailored to your garage goals.',
              ),
            ),
            IconButton(
              onPressed: isLoading ? null : onRefresh,
              icon: Icon(Icons.refresh, color: AppColors.primary),
              tooltip: 'Refresh recommendations',
            ),
          ],
        ),
        if (preferenceTags.isNotEmpty) ...[
          SizedBox(height: AppSizes.smallSpacing(context)),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: preferenceTags
                .map(
                  (tag) => Chip(
                    label: Text(
                      tag,
                      style: TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    side: BorderSide(color: AppColors.primary.withOpacity(0.4)),
                    backgroundColor: AppColors.primary.withOpacity(0.08),
                  ),
                )
                .toList(),
          ),
        ],
        SizedBox(height: AppSizes.smallSpacing(context)),
        if (isLoading)
          Center(
            child: Padding(
              padding: EdgeInsets.all(AppSizes.largeSpacing(context)),
              child: CustomWidgets.circularProgressIndicator(),
            ),
          )
        else if (error != null)
          InfoBanner(
            icon: Icons.info_outline,
            message: error!,
            actionLabel: 'Retry',
            onAction: onRefresh,
          )
        else ...[
          _buildRecommendationCarousel(
            context,
            title: 'Vehicle picks',
            subtitle: 'Based on what similar drivers track and buy.',
            listings: recommendedVehicles,
          ),
          SizedBox(height: AppSizes.mediumSpacing(context)),
          _buildRecommendationCarousel(
            context,
            title: 'Performance parts',
            subtitle: 'Parts & accessories aligned with your watchlist.',
            listings: recommendedParts,
          ),
        ],
      ],
    );
  }

  Widget _buildRecommendationCarousel(
    BuildContext context, {
    required String title,
    required String subtitle,
    required List<ListingModel> listings,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            color: AppColors.titleColor,
            fontWeight: FontWeight.bold,
            fontSize: AppSizes.subtitleFontSize(context),
          ),
        ),
        SizedBox(height: 4),
        Text(
          subtitle,
          style: TextStyle(
            color: AppColors.shadeColor,
            fontSize: AppSizes.bodyFontSize(context),
          ),
        ),
        SizedBox(height: AppSizes.smallSpacing(context)),
        if (listings.isEmpty)
          InfoBanner(
            icon: Icons.explore_outlined,
            message: 'No insights yet. Start browsing to personalise.',
            actionLabel: isLoggedIn ? null : 'Login',
            onAction: !isLoggedIn ? onNavigateToSignIn : null,
          )
        else
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: listings
                  .map(
                    (listing) => Padding(
                      padding: EdgeInsets.only(
                        right: AppSizes.mediumSpacing(context),
                      ),
                      child: HoverCard(
                        child: _buildRecommendationCard(context, listing),
                      ),
                    ),
                  )
                  .toList(),
            ),
          ),
      ],
    );
  }

  Widget _buildRecommendationCard(
    BuildContext context,
    ListingModel listing,
  ) {
    final image = listing.images.isNotEmpty ? listing.images.first : '';
    return Container(
      width: 260,
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
            child: image.isNotEmpty
                ? Image.network(
                    image,
                    height: 140,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Container(
                      height: 140,
                      color: AppColors.shadeColor.withOpacity(0.2),
                      child:
                          Icon(Icons.directions_car, color: AppColors.shadeColor),
                    ),
                  )
                : Container(
                    height: 140,
                    color: AppColors.shadeColor.withOpacity(0.2),
                    child: Icon(Icons.directions_car, color: AppColors.shadeColor),
                  ),
          ),
          Padding(
            padding: EdgeInsets.all(AppSizes.mediumPadding(context)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    _buildTagChip(context, listing.category),
                    SizedBox(width: 6),
                    _buildTagChip(context, listing.condition),
                  ],
                ),
                SizedBox(height: 8),
                Text(
                  listing.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: AppColors.titleColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  '${listing.formattedPrice} • ${listing.location.city}',
                  style: TextStyle(
                    color: AppColors.shadeColor,
                    fontSize: AppSizes.smallFontSize(context),
                  ),
                ),
                SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => requireAuth(() {
                          context.read<MarketplaceController>().addToCart(listing);
                        }),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.black,
                        ),
                        child: const Text('Add to cart'),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 8),
                OutlinedButton(
                  onPressed: () => requireAuth(() {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ListingDetailScreen(listing: listing),
                      ),
                    );
                  }),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.primary,
                    side: BorderSide(color: AppColors.primary),
                  ),
                  child: const Text('View details'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTagChip(BuildContext context, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label.toUpperCase(),
        style: TextStyle(
          color: AppColors.primary,
          fontSize: AppSizes.smallFontSize(context),
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

