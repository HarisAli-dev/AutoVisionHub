import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:front/controller/marketplace/marketplace_controller.dart';
import 'package:front/model/marketplace/listing_model.dart';
import 'package:front/view/community_member/marketplace/listing_detail_screen.dart';
import 'package:front/view/community_member/marketplace/create_listing_screen.dart';
import 'package:front/utils/app_colors.dart';
import 'package:front/utils/sizes.dart';
import 'package:front/utils/hive_utils.dart';
import 'package:front/utils/snackbars.dart';

class MyListingsTab extends StatefulWidget {
  final ScrollController scrollController;
  final VoidCallback onLoadMore;
  final VoidCallback onRefresh;

  const MyListingsTab({
    super.key,
    required this.scrollController,
    required this.onLoadMore,
    required this.onRefresh,
  });

  @override
  State<MyListingsTab> createState() => _MyListingsTabState();
}

class _MyListingsTabState extends State<MyListingsTab> {
  @override
  void initState() {
    super.initState();
    widget.scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    if (widget.scrollController.position.pixels ==
        widget.scrollController.position.maxScrollExtent) {
      widget.onLoadMore();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<MarketplaceController>(
      builder: (context, controller, child) {
        final listings = controller.myListings;

        if (controller.isLoading && listings.isEmpty) {
          return Center(
            child: CircularProgressIndicator(color: AppColors.primary),
          );
        }

        if (listings.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.inventory_2_outlined,
                  size: AppSizes.extraLargeIconSize(context) * 2,
                  color: AppColors.shadeColor,
                ),
                SizedBox(height: AppSizes.mediumSpacing(context)),
                Text(
                  'No listings yet',
                  style: TextStyle(
                    color: AppColors.shadeColor,
                    fontSize: AppSizes.subtitleFontSize(context),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: AppSizes.smallSpacing(context)),
                Text(
                  'Create your first listing to get started',
                  style: TextStyle(
                    color: AppColors.shadeColor,
                    fontSize: AppSizes.bodyFontSize(context),
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: AppSizes.largeSpacing(context)),
                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const CreateListingScreen(),
                      ),
                    ).then((_) => widget.onRefresh());
                  },
                  icon: Icon(Icons.add, color: AppColors.titleColor),
                  label: Text(
                    'Create Listing',
                    style: TextStyle(color: AppColors.titleColor),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    padding: EdgeInsets.symmetric(
                      horizontal: AppSizes.largePadding(context),
                      vertical: AppSizes.mediumPadding(context),
                    ),
                  ),
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
            child: GridView.builder(
              controller: widget.scrollController,
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 0.75,
                crossAxisSpacing: AppSizes.mediumSpacing(context),
                mainAxisSpacing: AppSizes.mediumSpacing(context),
              ),
              itemCount: listings.length,
              itemBuilder: (context, index) {
                final listing = listings[index];
                return _buildMyListingCard(listing);
              },
            ),
          ),
        );
      },
    );
  }

  Widget _buildMyListingCard(ListingModel listing) {
    final currentUserId = HiveUtils.getData('userId');
    final isMyListing = listing.seller?.id == currentUserId;

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ListingDetailScreen(listing: listing),
          ),
        );
      },
      onLongPress: isMyListing ? () => _showDeleteDialog(listing) : null,
      child: Card(
        color: AppColors.backgroundColor,
        elevation: AppSizes.cardElevation(context),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(
            AppSizes.cardBorderRadius(context),
          ),
          side: BorderSide(color: AppColors.primary.withOpacity(0.3), width: 1),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image
            Expanded(
              flex: 2,
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
                padding: EdgeInsets.all(AppSizes.smallPadding(context)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Top content (title, price, stock)
                    Flexible(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Title
                          Text(
                            listing.title,
                            style: TextStyle(
                              color: AppColors.titleColor,
                              fontSize: AppSizes.bodyFontSize(context),
                              fontWeight: FontWeight.bold,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          SizedBox(height: AppSizes.smallSpacing(context) / 3),
                          // Price
                          Text(
                            'PKR ${listing.price.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')}',
                            style: TextStyle(
                              color: AppColors.primary,
                              fontSize: AppSizes.inputFontSize(context),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: AppSizes.smallSpacing(context) / 4),
                          // Stock status
                          Text(
                            listing.stockStatus,
                            style: TextStyle(
                              color: listing.isInStock
                                  ? AppColors.shadeColor
                                  : Colors.red,
                              fontSize: AppSizes.smallFontSize(context),
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
                    // Bottom content (location)
                    Row(
                      children: [
                        Icon(
                          Icons.location_on,
                          color: AppColors.shadeColor,
                          size: AppSizes.smallIconSize(context),
                        ),
                        SizedBox(width: AppSizes.smallSpacing(context) / 4),
                        Expanded(
                          child: Text(
                            listing.location.city,
                            style: TextStyle(
                              color: AppColors.shadeColor,
                              fontSize: AppSizes.smallFontSize(context),
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
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

  void _showDeleteDialog(ListingModel listing) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: AppColors.backgroundColor,
          title: Text(
            'Delete Listing',
            style: TextStyle(
              color: AppColors.titleColor,
              fontSize: AppSizes.subtitleFontSize(context),
              fontWeight: FontWeight.bold,
            ),
          ),
          content: Text(
            'Are you sure you want to delete "${listing.title}"? This action cannot be undone.',
            style: TextStyle(
              color: AppColors.foregroundColor,
              fontSize: AppSizes.bodyFontSize(context),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                'Cancel',
                style: TextStyle(color: AppColors.shadeColor),
              ),
            ),
            TextButton(
              onPressed: () async {
                Navigator.of(context).pop();
                await _deleteListing(listing);
              },
              child: Text('Delete', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }

  Future<void> _deleteListing(ListingModel listing) async {
    final controller = Provider.of<MarketplaceController>(
      context,
      listen: false,
    );

    // Show loading indicator
    final snackBar = CustomSnackbars.showLoadingSnackbar('Deleting listing...');
    ScaffoldMessenger.of(context).showSnackBar(snackBar);

    final success = await controller.deleteListing(listing.id!);

    // Hide loading snackbar
    ScaffoldMessenger.of(context).hideCurrentSnackBar();

    if (success) {
      CustomSnackbars.showSuccessSnackbar(
        context,
        'Listing deleted successfully',
        2.0,
      );
      // Refresh the current view to update the list
      widget.onRefresh();
    } else {
      CustomSnackbars.showErrorSnackbar(
        context,
        controller.error ?? 'Failed to delete listing',
      );
    }
  }
}