import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:front/controller/marketplace/marketplace_controller.dart';
import 'package:front/model/marketplace/listing_model.dart';
import 'package:front/view/community_member/marketplace/bid_screen.dart';
import 'package:front/view/community_member/marketplace/offer_screen.dart';
import 'package:front/view/community_member/marketplace/chat_screen.dart';
import 'package:front/utils/app_colors.dart';
import 'package:front/utils/sizes.dart';
import 'package:front/utils/custom_widgets.dart';
import 'package:front/utils/snackbars.dart';

class ListingDetailScreen extends StatefulWidget {
  final ListingModel listing;

  const ListingDetailScreen({
    super.key,
    required this.listing,
    String? listingId,
  });

  @override
  State<ListingDetailScreen> createState() => _ListingDetailScreenState();
}

class _ListingDetailScreenState extends State<ListingDetailScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isFavorited = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _checkFavoriteStatus();
    _loadBidsAndOffers();

    // Add listener to refresh data when switching to bids/offers tab
    _tabController.addListener(() {
      if (_tabController.index == 1) {
        // Bids/Offers tab
        _loadBidsAndOffers();
      }
    });
  }

  Future<void> _loadBidsAndOffers() async {
    final controller = Provider.of<MarketplaceController>(
      context,
      listen: false,
    );
    if (widget.listing.id != null) {
      if (widget.listing.isAuction) {
        // Load bids for auction listings
        await controller.getListingBids(widget.listing.id!);
      } else {
        // Load offers for regular listings
        await controller.getListingOffers(widget.listing.id!);
      }
    }
  }

  void _checkFavoriteStatus() async {
    final controller = Provider.of<MarketplaceController>(
      context,
      listen: false,
    );

    // Only fetch if favorites list is empty, otherwise use existing data
    if (controller.favoriteListings.isEmpty) {
      await controller.getFavoriteListings();
    }

    if (mounted) {
      setState(() {
        _isFavorited = controller.favoriteListings.any(
          (listing) => listing.id == widget.listing.id,
        );
      });
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Initialize theme colors
    AppColors.getBackgroundColor(context);

    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      body: CustomScrollView(
        slivers: [
          // App Bar with Image
          SliverAppBar(
            expandedHeight: AppSizes.imageHeight(context) * 1.2,
            pinned: true,
            backgroundColor: AppColors.backgroundColor,
            leading: IconButton(
              icon: Icon(Icons.arrow_back, color: AppColors.foregroundColor),
              onPressed: () => Navigator.pop(context),
            ),
            actions: [
              IconButton(
                icon: Icon(
                  _isFavorited ? Icons.favorite : Icons.favorite_border,
                  color: _isFavorited
                      ? AppColors.errorColor
                      : AppColors.foregroundColor,
                ),
                onPressed: () async {
                  if (widget.listing.id == null) {
                    CustomSnackbars.showErrorSnackbar(
                      context,
                      'Cannot favorite this listing',
                    );
                    return;
                  }

                  final controller = Provider.of<MarketplaceController>(
                    context,
                    listen: false,
                  );

                  print('DEBUG: Favorite button pressed - current state: $_isFavorited, listing ID: ${widget.listing.id}');

                  setState(() {
                    _isFavorited = !_isFavorited;
                  });

                  try {
                    final result = await controller.toggleFavorite(widget.listing.id!);
                    print('DEBUG: toggleFavorite returned: $result');
                  } catch (e) {
                    print('DEBUG: toggleFavorite failed: $e');
                    // Revert the UI state if the API call fails
                    setState(() {
                      _isFavorited = !_isFavorited;
                    });

                    if (mounted) {
                      CustomSnackbars.showErrorSnackbar(
                        context,
                        'Failed to update favorite: $e',
                      );
                    }
                  }
                },
              ),
              IconButton(
                icon: Icon(Icons.share, color: AppColors.foregroundColor),
                onPressed: () {
                  // TODO: Implement share
                },
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: widget.listing.images.isNotEmpty
                  ? Image.network(
                      widget.listing.images.first,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          color: AppColors.shadeColor,
                          child: Center(
                            child: Icon(
                              Icons.image,
                              size: AppSizes.extraLargeIconSize(context),
                              color: AppColors.shadeColor,
                            ),
                          ),
                        );
                      },
                    )
                  : Container(
                      color: AppColors.shadeColor,
                      child: Center(
                        child: Icon(
                          Icons.image,
                          size: AppSizes.extraLargeIconSize(context),
                          color: AppColors.shadeColor,
                        ),
                      ),
                    ),
            ),
          ),

          // Content
          SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title and Price
                Padding(
                  padding: EdgeInsets.all(AppSizes.mediumPadding(context)),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.listing.title,
                        style: TextStyle(
                          color: AppColors.titleColor,
                          fontSize: AppSizes.largeFontSize(context),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: AppSizes.smallSpacing(context)),
                      Row(
                        children: [
                          Text(
                            widget.listing.formattedPrice,
                            style: TextStyle(
                              color: AppColors.primary,
                              fontSize: AppSizes.headerFontSize(context),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          if (widget.listing.originalPrice != null) ...[
                            SizedBox(width: AppSizes.mediumSpacing(context)),
                            Text(
                              widget.listing.formattedOriginalPrice,
                              style: TextStyle(
                                color: AppColors.shadeColor,
                                fontSize: AppSizes.subtitleFontSize(context),
                                decoration: TextDecoration.lineThrough,
                              ),
                            ),
                          ],
                        ],
                      ),
                      SizedBox(height: AppSizes.smallSpacing(context)),
                      // Stock Status
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: AppSizes.mediumPadding(context),
                          vertical: AppSizes.smallPadding(context) / 2,
                        ),
                        decoration: BoxDecoration(
                          color: widget.listing.isInStock
                              ? AppColors.primary.withOpacity(0.1)
                              : Colors.red.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(
                            AppSizes.cardBorderRadius(context),
                          ),
                          border: Border.all(
                            color: widget.listing.isInStock
                                ? AppColors.primary.withOpacity(0.3)
                                : Colors.red.withOpacity(0.3),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              widget.listing.isInStock
                                  ? Icons.inventory
                                  : Icons.warning,
                              color: widget.listing.isInStock
                                  ? AppColors.primary
                                  : Colors.red,
                              size: AppSizes.smallIconSize(context),
                            ),
                            SizedBox(width: AppSizes.smallSpacing(context) / 2),
                            Text(
                              widget.listing.stockStatus,
                              style: TextStyle(
                                color: widget.listing.isInStock
                                    ? AppColors.primary
                                    : Colors.red,
                                fontSize: AppSizes.smallFontSize(context),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (widget.listing.isAuction) ...[
                        SizedBox(height: AppSizes.smallSpacing(context)),
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: AppSizes.mediumPadding(context),
                            vertical: AppSizes.smallPadding(context) / 2,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.primary,
                            borderRadius: BorderRadius.circular(
                              AppSizes.cardBorderRadius(context),
                            ),
                          ),
                          child: Text(
                            'Auction ends in: ${widget.listing.auctionTimeRemaining}',
                            style: TextStyle(
                              color: AppColors.titleColor,
                              fontSize: AppSizes.bodyFontSize(context),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),

                // Action Buttons
                Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: AppSizes.mediumPadding(context),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    ChatScreen(listing: widget.listing),
                              ),
                            );
                          },
                          icon: Icon(
                            Icons.chat,
                            size: AppSizes.mediumIconSize(context),
                          ),
                          label: Text(
                            'Chat',
                            style: TextStyle(
                              fontSize: AppSizes.inputFontSize(context),
                            ),
                          ),
                          style: CustomWidgets.elevatedButtonStyle(context),
                        ),
                      ),
                      SizedBox(width: AppSizes.mediumSpacing(context)),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () {
                            if (widget.listing.isAuction) {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      BidScreen(listing: widget.listing),
                                ),
                              );
                            } else {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      OfferScreen(listing: widget.listing),
                                ),
                              );
                            }
                          },
                          icon: Icon(
                            widget.listing.isAuction
                                ? Icons.gavel
                                : Icons.attach_money,
                            size: AppSizes.mediumIconSize(context),
                          ),
                          label: Text(
                            widget.listing.isAuction ? 'Bid' : 'Make Offer',
                            style: TextStyle(
                              fontSize: AppSizes.inputFontSize(context),
                            ),
                          ),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.foregroundColor,
                            side: BorderSide(color: AppColors.shadeColor),
                            padding: EdgeInsets.symmetric(
                              vertical: AppSizes.mediumSpacing(context),
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(
                                AppSizes.inputBorderRadius(context),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                SizedBox(height: AppSizes.largeSpacing(context)),

                // Tabs
                Container(
                  margin: EdgeInsets.symmetric(
                    horizontal: AppSizes.mediumPadding(context),
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.backgroundColor,
                    borderRadius: BorderRadius.circular(
                      AppSizes.cardBorderRadius(context),
                    ),
                    border: Border.all(
                      color: AppColors.shadeColor.withOpacity(0.3),
                    ),
                  ),
                  child: TabBar(
                    controller: _tabController,
                    indicatorColor: AppColors.primary,
                    labelColor: AppColors.primary,
                    unselectedLabelColor: AppColors.shadeColor,
                    labelStyle: TextStyle(
                      fontSize: AppSizes.inputFontSize(context),
                    ),
                    tabs: const [
                      Tab(text: 'Details'),
                      Tab(text: 'Bids/Offers'),
                    ],
                  ),
                ),

                SizedBox(height: AppSizes.mediumSpacing(context)),

                // Tab Content
                SizedBox(
                  height: 400,
                  child: TabBarView(
                    controller: _tabController,
                    children: [_buildDetailsTab(), _buildBidsOffersTab()],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailsTab() {
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: AppSizes.mediumPadding(context),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Description
          Text(
            'Description',
            style: TextStyle(
              color: AppColors.titleColor,
              fontSize: AppSizes.subtitleFontSize(context),
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: AppSizes.smallSpacing(context)),
          Text(
            widget.listing.description,
            style: TextStyle(
              color: AppColors.shadeColor,
              fontSize: AppSizes.inputFontSize(context),
            ),
          ),

          SizedBox(height: AppSizes.largeSpacing(context)),

          // Specifications
          Text(
            'Specifications',
            style: TextStyle(
              color: AppColors.titleColor,
              fontSize: AppSizes.subtitleFontSize(context),
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: AppSizes.mediumSpacing(context)),

          _buildSpecItem('Brand', widget.listing.brand),
          if (widget.listing.year != null)
            _buildSpecItem('Year', widget.listing.year.toString()),
          _buildSpecItem('Condition', widget.listing.condition),
          if (widget.listing.mileage != null)
            _buildSpecItem('Mileage', widget.listing.formattedMileage),
          if (widget.listing.fuelType != null)
            _buildSpecItem('Fuel Type', widget.listing.fuelType!),
          if (widget.listing.transmission != null)
            _buildSpecItem('Transmission', widget.listing.transmission!),
          if (widget.listing.color != null)
            _buildSpecItem('Color', widget.listing.color!),
          _buildSpecItem('Location', widget.listing.location.city),

          SizedBox(height: AppSizes.largeSpacing(context)),

          // Seller Info
          Text(
            'Seller Information',
            style: TextStyle(
              color: AppColors.titleColor,
              fontSize: AppSizes.subtitleFontSize(context),
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: AppSizes.mediumSpacing(context)),

          if (widget.listing.seller != null)
            Container(
              padding: EdgeInsets.all(AppSizes.mediumPadding(context)),
              decoration: BoxDecoration(
                color: AppColors.backgroundColor,
                borderRadius: BorderRadius.circular(
                  AppSizes.cardBorderRadius(context),
                ),
                border: Border.all(
                  color: AppColors.shadeColor.withOpacity(0.3),
                ),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: AppSizes.avatarRadius(context),
                    backgroundColor: AppColors.primary,
                    child: Text(
                      widget.listing.seller!.name.isNotEmpty
                          ? widget.listing.seller!.name[0].toUpperCase()
                          : 'U',
                      style: TextStyle(
                        color: AppColors.titleColor,
                        fontSize: AppSizes.titleFontSize(context),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  SizedBox(width: AppSizes.mediumSpacing(context)),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.listing.seller!.name,
                          style: TextStyle(
                            color: AppColors.titleColor,
                            fontSize: AppSizes.inputFontSize(context),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          widget.listing.seller!.city ?? '',
                          style: TextStyle(
                            color: AppColors.shadeColor,
                            fontSize: AppSizes.bodyFontSize(context),
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.phone, color: AppColors.primary),
                    onPressed: () {
                      // TODO: Implement call
                    },
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSpecItem(String label, String value) {
    return Padding(
      padding: EdgeInsets.only(bottom: AppSizes.smallSpacing(context)),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              color: AppColors.shadeColor,
              fontSize: AppSizes.bodyFontSize(context),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              color: AppColors.titleColor,
              fontSize: AppSizes.bodyFontSize(context),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBidsOffersTab() {
    return Consumer<MarketplaceController>(
      builder: (context, controller, child) {
        if (controller.isLoading) {
          return Center(
            child: CircularProgressIndicator(color: AppColors.primary),
          );
        }

        return RefreshIndicator(
          color: AppColors.primary,
          backgroundColor: AppColors.backgroundColor,
          onRefresh: () async {
            await _loadBidsAndOffers();
          },
          child: _buildBidsOffersContent(controller),
        );
      },
    );
  }

  Widget _buildBidsOffersContent(MarketplaceController controller) {
    if (widget.listing.isAuction) {
      // Show bids for auction
      if (controller.bids.isEmpty) {
        return Center(
          child: Text(
            'No bids yet',
            style: TextStyle(
              color: AppColors.shadeColor,
              fontSize: AppSizes.inputFontSize(context),
            ),
          ),
        );
      }

      return ListView.builder(
        padding: EdgeInsets.all(AppSizes.mediumPadding(context)),
        itemCount: controller.bids.length,
        itemBuilder: (context, index) {
          final bid = controller.bids[index];
          return Container(
            margin: EdgeInsets.only(bottom: AppSizes.mediumSpacing(context)),
            padding: EdgeInsets.all(AppSizes.mediumPadding(context)),
            decoration: BoxDecoration(
              color: AppColors.backgroundColor,
              borderRadius: BorderRadius.circular(
                AppSizes.cardBorderRadius(context),
              ),
              border: bid.isWinning
                  ? Border.all(color: AppColors.primary, width: 2)
                  : Border.all(color: AppColors.shadeColor.withOpacity(0.3)),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: AppSizes.smallAvatarRadius(context),
                  backgroundColor: bid.isWinning
                      ? AppColors.primary
                      : AppColors.shadeColor,
                  child: Text(
                    bid.bidder?.name.isNotEmpty == true
                        ? bid.bidder!.name[0].toUpperCase()
                        : 'B',
                    style: TextStyle(
                      color: AppColors.titleColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                SizedBox(width: AppSizes.mediumSpacing(context)),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        bid.bidder?.name ?? 'Anonymous',
                        style: TextStyle(
                          color: AppColors.titleColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        bid.timeAgo,
                        style: TextStyle(
                          color: AppColors.shadeColor,
                          fontSize: AppSizes.smallFontSize(context),
                        ),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      bid.formattedAmount,
                      style: TextStyle(
                        color: AppColors.primary,
                        fontSize: AppSizes.subtitleFontSize(context),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (bid.isWinning)
                      Text(
                        'Winning',
                        style: TextStyle(
                          color: AppColors.primary,
                          fontSize: AppSizes.smallFontSize(context),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                  ],
                ),
              ],
            ),
          );
        },
      );
    } else {
      // Show offers for regular listing
      if (controller.offers.isEmpty) {
        return Center(
          child: Text(
            'No offers yet',
            style: TextStyle(
              color: AppColors.shadeColor,
              fontSize: AppSizes.inputFontSize(context),
            ),
          ),
        );
      }

      return ListView.builder(
        padding: EdgeInsets.all(AppSizes.mediumPadding(context)),
        itemCount: controller.offers.length,
        itemBuilder: (context, index) {
          final offer = controller.offers[index];
          return Container(
            margin: EdgeInsets.only(bottom: AppSizes.mediumSpacing(context)),
            padding: EdgeInsets.all(AppSizes.mediumPadding(context)),
            decoration: BoxDecoration(
              color: AppColors.backgroundColor,
              borderRadius: BorderRadius.circular(
                AppSizes.cardBorderRadius(context),
              ),
              border: Border.all(color: AppColors.shadeColor.withOpacity(0.3)),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: Colors.grey[600],
                  child: Text(
                    offer.buyer?.name.isNotEmpty == true
                        ? offer.buyer!.name[0].toUpperCase()
                        : 'O',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        offer.buyer?.name ?? 'Anonymous',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        offer.timeAgo,
                        style: const TextStyle(
                          color: Colors.grey,
                          fontSize: 12,
                        ),
                      ),
                      if (offer.message != null)
                        Text(
                          offer.message!,
                          style: const TextStyle(
                            color: Colors.grey,
                            fontSize: 12,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      offer.formattedAmount,
                      style: const TextStyle(
                        color: Color(0xFFFF6B35),
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: _getStatusColor(offer.status),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        offer.status.toUpperCase(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      );
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'accepted':
        return Colors.green;
      case 'rejected':
        return Colors.red;
      case 'countered':
        return Colors.orange;
      case 'pending':
      default:
        return Colors.grey;
    }
  }
}
