import 'package:flutter/material.dart';
import 'package:front/utils/custom_widgets.dart';
import 'package:provider/provider.dart';
import 'package:front/controller/marketplace/marketplace_controller.dart';
import 'package:front/model/marketplace/listing_model.dart';
import 'package:front/view/community_member/marketplace/listing_detail_screen.dart';
import 'package:front/utils/app_colors.dart';
import 'package:front/utils/sizes.dart';
import 'package:front/utils/hive_utils.dart';

class AllListingsTab extends StatefulWidget {
  final ScrollController scrollController;
  final VoidCallback onLoadMore;
  final VoidCallback onRefresh;

  const AllListingsTab({
    super.key,
    required this.scrollController,
    required this.onLoadMore,
    required this.onRefresh,
  });

  @override
  State<AllListingsTab> createState() => _AllListingsTabState();
}

late List<ListingModel> listings;

class _AllListingsTabState extends State<AllListingsTab> {
  @override
  void initState() {
    super.initState();
    listings = _getFilteredListings();
    widget.scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    if (widget.scrollController.position.pixels ==
        widget.scrollController.position.maxScrollExtent) {
      widget.onLoadMore();
    }
  }

  List<ListingModel> _getFilteredListings() {
    final controller = Provider.of<MarketplaceController>(
      context,
      listen: false,
    );
    final currentUserId = HiveUtils.getData('userId');

    // Filter out current user's listings from "All Items" view
    if (currentUserId != null) {
      return controller.listings
          .where((listing) => listing.seller?.id != currentUserId)
          .toList();
    }
    return controller.listings;
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<MarketplaceController>(
      builder: (context, controller, child) {
        listings = _getFilteredListings();
        if (controller.isLoading && listings.isEmpty) {
          return Center(
            child: CustomWidgets.circularProgressIndicator(),
          );
        }

        if (listings.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.storefront_outlined,
                  size: AppSizes.extraLargeIconSize(context) * 2,
                  color: AppColors.shadeColor,
                ),
                SizedBox(height: AppSizes.mediumSpacing(context)),
                Text(
                  'No items found',
                  style: TextStyle(
                    color: AppColors.shadeColor,
                    fontSize: AppSizes.subtitleFontSize(context),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: AppSizes.smallSpacing(context)),
                Text(
                  'Try adjusting your search or filters',
                  style: TextStyle(
                    color: AppColors.shadeColor,
                    fontSize: AppSizes.bodyFontSize(context),
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        }

        return RefreshIndicator(
          color: AppColors.primary,
          backgroundColor: AppColors.backgroundColor,
          onRefresh: () async => widget.onRefresh(),
          child: Padding(
            padding: EdgeInsets.all(AppSizes.mediumPadding(context)),
            child: LayoutBuilder(
              builder: (context, constraints) {
                // Calculate responsive aspect ratio based on screen size
                final screenWidth = MediaQuery.of(context).size.width;
                // Adjust aspect ratio for different screen sizes
                double aspectRatio = 0.75;
                if (screenWidth > 600) {
                  // Tablets - slightly wider cards
                  aspectRatio = 0.7;
                } else if (screenWidth < 360) {
                  // Very small phones - taller cards
                  aspectRatio = 0.8;
                }

                return GridView.builder(
                  controller: widget.scrollController,
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: aspectRatio,
                    crossAxisSpacing: AppSizes.mediumSpacing(context),
                    mainAxisSpacing: AppSizes.mediumSpacing(context),
                  ),
                  itemCount: listings.length,
                  itemBuilder: (context, index) {
                    final listing = listings[index];
                    return _buildListingCard(listing);
                  },
                );
              },
            ),
          ),
        );
      },
    );
  }

  Widget _buildListingCard(ListingModel listing) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ListingDetailScreen(listing: listing),
          ),
        );
      },
      child: Card(
        color: AppColors.backgroundColor,
        elevation: AppSizes.cardElevation(context),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(
            AppSizes.cardBorderRadius(context),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image
            Expanded(
              flex: 3,
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.vertical(
                    top: Radius.circular(AppSizes.cardBorderRadius(context)),
                  ),
                  color: AppColors.shadeColor,
                ),
                child: listing.images.isNotEmpty
                    ? ClipRRect(
                        borderRadius: BorderRadius.vertical(
                          top: Radius.circular(
                            AppSizes.cardBorderRadius(context),
                          ),
                        ),
                        child: Image.network(
                          listing.images.first,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Icon(
                              Icons.broken_image,
                              color: AppColors.shadeColor,
                              size: AppSizes.largeIconSize(context),
                            );
                          },
                        ),
                      )
                    : Icon(
                        Icons.image_not_supported,
                        color: AppColors.shadeColor,
                        size: AppSizes.largeIconSize(context),
                      ),
              ),
            ),
            // Content
            Expanded(
              flex: 2,
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: AppSizes.smallPadding(context) * 0.7,
                  vertical: AppSizes.smallPadding(context) * 0.5,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Top content (title, price, stock)
                    Flexible(
                      flex: 2,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Title
                          Text(
                            listing.title,
                            style: TextStyle(
                              color: AppColors.titleColor,
                              fontSize: AppSizes.bodyFontSize(context) * 0.9,
                              fontWeight: FontWeight.bold,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          SizedBox(
                            height: AppSizes.smallSpacing(context) * 0.1,
                          ),
                          // Price
                          Text(
                            'PKR ${listing.price.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')}',
                            style: TextStyle(
                              color: AppColors.primary,
                              fontSize: AppSizes.smallFontSize(context) * 0.9,
                              fontWeight: FontWeight.bold,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          SizedBox(
                            height: AppSizes.smallSpacing(context) * 0.1,
                          ),
                          // Stock status
                          Text(
                            listing.stockStatus,
                            style: TextStyle(
                              color: listing.isInStock
                                  ? AppColors.shadeColor
                                  : Colors.red,
                              fontSize: AppSizes.smallFontSize(context) * 0.8,
                              fontWeight: listing.quantity <= 5
                                  ? FontWeight.w500
                                  : FontWeight.normal,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    // Bottom content (location + add to cart)
                    Flexible(
                      flex: 1,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.location_on,
                            color: AppColors.shadeColor,
                            size: AppSizes.smallIconSize(context) * 0.75,
                          ),
                          SizedBox(width: AppSizes.smallSpacing(context) * 0.2),
                          Expanded(
                            child: Text(
                              listing.location.city,
                              style: TextStyle(
                                color: AppColors.shadeColor,
                                fontSize: AppSizes.smallFontSize(context) * 0.8,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          IconButton(
                            padding: EdgeInsets.all(4),
                            constraints: BoxConstraints(
                              minWidth: 32,
                              minHeight: 32,
                            ),
                            tooltip: 'Add to cart',
                            icon: Icon(
                              Icons.add_shopping_cart,
                              color: AppColors.primary,
                              size: AppSizes.smallIconSize(context) * 0.9,
                            ),
                            onPressed: () {
                              final controller =
                                  Provider.of<MarketplaceController>(
                                    context,
                                    listen: false,
                                  );
                              controller.addToCart(listing);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Added to cart'),
                                  duration: Duration(seconds: 1),
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
