import 'package:flutter/material.dart';
import 'package:front/model/marketplace/listing_model.dart';
import 'package:front/utils/app_colors.dart';
import 'package:front/utils/sizes.dart';
import 'package:front/view/community_member/marketplace/listing_detail_screen.dart';
import 'package:front/view/dashboard/widgets/shared/hover_card.dart';
import 'package:front/view/dashboard/widgets/shared/info_banner.dart';
import 'package:front/view/dashboard/widgets/shared/section_header.dart';

class RecentlyViewedSection extends StatelessWidget {
  final List<ListingModel> recentlyViewedListings;
  final bool isLoggedIn;
  final VoidCallback onNavigateToSignIn;
  final void Function(VoidCallback) requireAuth;

  const RecentlyViewedSection({
    super.key,
    required this.recentlyViewedListings,
    required this.isLoggedIn,
    required this.onNavigateToSignIn,
    required this.requireAuth,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(
          title: 'Recently viewed',
          subtitle: 'Pick up where you left off to compare faster.',
        ),
        SizedBox(height: AppSizes.smallSpacing(context)),
        if (!isLoggedIn)
          InfoBanner(
            icon: Icons.lock_outline,
            message: 'Login to keep a history of what you view.',
            actionLabel: 'Login',
            onAction: onNavigateToSignIn,
          )
        else if (recentlyViewedListings.isEmpty)
          InfoBanner(
            icon: Icons.history,
            message: 'Browse the marketplace to start your history.',
          )
        else
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: recentlyViewedListings
                  .map(
                    (listing) => Padding(
                      padding: EdgeInsets.only(
                        right: AppSizes.mediumSpacing(context),
                      ),
                      child: HoverCard(
                        child: _recentlyViewedCard(context, listing),
                      ),
                    ),
                  )
                  .toList(),
            ),
          ),
      ],
    );
  }

  Widget _recentlyViewedCard(BuildContext context, ListingModel listing) {
    final image = listing.images.isNotEmpty ? listing.images.first : '';
    return Container(
      width: 220,
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
                    height: 110,
                    width: double.infinity,
                    fit: BoxFit.cover,
                  )
                : Container(
                    height: 110,
                    color: AppColors.shadeColor.withOpacity(0.2),
                    child: Icon(Icons.directions_car, color: AppColors.shadeColor),
                  ),
          ),
          Padding(
            padding: EdgeInsets.all(AppSizes.mediumPadding(context)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
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
                  listing.formattedPrice,
                  style: TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  listing.location.city,
                  style: TextStyle(
                    color: AppColors.shadeColor,
                    fontSize: AppSizes.smallFontSize(context),
                  ),
                ),
                SizedBox(height: 10),
                TextButton(
                  onPressed: () => requireAuth(() {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ListingDetailScreen(listing: listing),
                      ),
                    );
                  }),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Resume',
                        style: TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Icon(Icons.north_east, size: 16, color: AppColors.primary),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

