import 'package:flutter/material.dart';
import 'package:front/model/marketplace/listing_model.dart';
import 'package:front/utils/app_colors.dart';
import 'package:front/utils/custom_widgets.dart';
import 'package:front/utils/sizes.dart';
import 'package:front/view/community_member/marketplace/listing_detail_screen.dart';
import 'package:front/view/dashboard/widgets/shared/hover_card.dart';
import 'package:front/view/dashboard/widgets/shared/section_header.dart';

class TrendingSection extends StatelessWidget {
  final List<ListingModel> trendingListings;
  final bool isLoading;
  final String? userCity;
  final void Function(VoidCallback) requireAuth;

  const TrendingSection({
    super.key,
    required this.trendingListings,
    required this.isLoading,
    this.userCity,
    required this.requireAuth,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(
          title: "Trending near ${userCity ?? 'you'}",
          subtitle: 'Listings getting the most traction in your region.',
        ),
        SizedBox(height: AppSizes.smallSpacing(context)),
        if (isLoading)
          Center(
            child: Padding(
              padding: EdgeInsets.all(AppSizes.largeSpacing(context)),
              child: CustomWidgets.circularProgressIndicator(),
            ),
          )
        else if (trendingListings.isEmpty)
          Center(
            child: Padding(
              padding: EdgeInsets.all(AppSizes.largeSpacing(context)),
              child: Column(
                children: [
                  Icon(
                    Icons.trending_up,
                    size: AppSizes.extraLargeIconSize(context),
                    color: AppColors.shadeColor,
                  ),
                  SizedBox(height: AppSizes.mediumSpacing(context)),
                  Text(
                    'No trending items yet',
                    style: TextStyle(
                      color: AppColors.shadeColor,
                      fontSize: AppSizes.bodyFontSize(context),
                    ),
                  ),
                ],
              ),
            ),
          )
        else
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: trendingListings
                  .map(
                    (listing) => Padding(
                      padding: EdgeInsets.only(
                        right: AppSizes.mediumSpacing(context),
                      ),
                      child: HoverCard(
                        child: _compactHighlight(
                          context,
                          title: listing.title,
                          subtitle:
                              'PKR ${listing.price.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')} • ${listing.location.city}',
                          image: listing.images.isNotEmpty
                              ? listing.images.first
                              : '',
                          listing: listing,
                        ),
                      ),
                    ),
                  )
                  .toList(),
            ),
          ),
      ],
    );
  }

  Widget _compactHighlight(
    BuildContext context, {
    required String title,
    required String subtitle,
    required String image,
    ListingModel? listing,
  }) {
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
                    height: 120,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return Container(
                        height: 120,
                        color: AppColors.shadeColor.withOpacity(0.2),
                        child: Center(
                          child: CircularProgressIndicator(
                            color: AppColors.primary,
                            value: loadingProgress.expectedTotalBytes != null
                                ? loadingProgress.cumulativeBytesLoaded /
                                      loadingProgress.expectedTotalBytes!
                                : null,
                          ),
                        ),
                      );
                    },
                    errorBuilder: (context, error, stackTrace) => Container(
                      height: 120,
                      color: AppColors.shadeColor.withOpacity(0.2),
                      child: Icon(Icons.directions_car,
                          color: AppColors.shadeColor),
                    ),
                  )
                : Container(
                    height: 120,
                    color: AppColors.shadeColor.withOpacity(0.2),
                    child: Icon(Icons.directions_car,
                        color: AppColors.shadeColor),
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
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: AppColors.shadeColor,
                    fontSize: AppSizes.smallFontSize(context),
                  ),
                ),
                SizedBox(height: 12),
                Row(
                  children: [
                    Icon(Icons.trending_up,
                        size: 16, color: AppColors.primary),
                    const SizedBox(width: 6),
                    Text(
                      'Trending',
                      style: TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const Spacer(),
                    if (listing != null)
                      GestureDetector(
                        onTap: () => requireAuth(() {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  ListingDetailScreen(listing: listing),
                            ),
                          );
                        }),
                        child: Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: AppSizes.smallPadding(context),
                            vertical: AppSizes.smallPadding(context) / 2,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.primary,
                            borderRadius: BorderRadius.circular(
                              AppSizes.inputBorderRadius(context),
                            ),
                          ),
                          child: Text(
                            'View',
                            style: TextStyle(
                              color: AppColors.titleColor,
                              fontSize: AppSizes.smallFontSize(context),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
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
}

