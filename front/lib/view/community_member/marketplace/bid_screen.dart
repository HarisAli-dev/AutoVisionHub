import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:front/controller/marketplace/marketplace_controller.dart';
import 'package:front/model/marketplace/listing_model.dart';
import 'package:front/view/community_member/marketplace/checkout_screen.dart';
import 'package:front/utils/app_colors.dart';
import 'package:front/utils/sizes.dart';
import 'package:front/utils/custom_widgets.dart';
import 'package:front/utils/snackbars.dart';

class BidScreen extends StatefulWidget {
  final ListingModel listing;

  const BidScreen({super.key, required this.listing});

  @override
  State<BidScreen> createState() => _BidScreenState();
}

class _BidScreenState extends State<BidScreen> {
  final _bidController = TextEditingController();

  @override
  void initState() {
    super.initState();
    final minimumBid =
        widget.listing.currentBid ?? widget.listing.startingBid ?? 0;
    final increment = widget.listing.bidIncrement ?? 1000;
    _bidController.text = (minimumBid + increment).toString();

    // Load bids for this listing
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final controller = Provider.of<MarketplaceController>(
        context,
        listen: false,
      );
      controller.getListingBids(widget.listing.id!);
    });
  }

  @override
  void dispose() {
    _bidController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Initialize theme colors
    AppColors.getBackgroundColor(context);

    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      appBar: AppBar(
        backgroundColor: AppColors.backgroundColor,
        elevation: 0,
        title: Text(
          widget.listing.title,
          style: TextStyle(
            color: AppColors.primary,
            fontSize: AppSizes.titleFontSize(context),
            fontWeight: FontWeight.bold,
          ),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: AppColors.foregroundColor),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(AppSizes.mediumPadding(context)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Current Bid Info
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(AppSizes.largePadding(context)),
              decoration: BoxDecoration(
                color: AppColors.backgroundColor,
                borderRadius: BorderRadius.circular(
                  AppSizes.cardBorderRadius(context),
                ),
                border: Border.all(color: AppColors.primary, width: 2),
              ),
              child: Column(
                children: [
                  Text(
                    'Current Highest Bid',
                    style: TextStyle(
                      color: AppColors.shadeColor,
                      fontSize: AppSizes.inputFontSize(context),
                    ),
                  ),
                  SizedBox(height: AppSizes.smallSpacing(context)),
                  Text(
                    'PKR ${(widget.listing.currentBid ?? widget.listing.startingBid ?? 0).toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')}',
                    style: TextStyle(
                      color: AppColors.primary,
                      fontSize: AppSizes.titleFontSize(context) * 1.5,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),

            SizedBox(height: AppSizes.largeSpacing(context)),

            // Auction Timer
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(AppSizes.mediumPadding(context)),
              decoration: BoxDecoration(
                color: AppColors.backgroundColor,
                borderRadius: BorderRadius.circular(
                  AppSizes.cardBorderRadius(context),
                ),
                border: Border.all(color: AppColors.shadeColor),
              ),
              child: Column(
                children: [
                  Text(
                    'Auction ends in:',
                    style: TextStyle(
                      color: AppColors.shadeColor,
                      fontSize: AppSizes.inputFontSize(context),
                    ),
                  ),
                  SizedBox(height: AppSizes.smallSpacing(context)),
                  Text(
                    widget.listing.auctionTimeRemaining,
                    style: TextStyle(
                      color: AppColors.primary,
                      fontSize: AppSizes.titleFontSize(context),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),

            SizedBox(height: AppSizes.largeSpacing(context)),

            // Bid Input
            Text(
              'Your Bid',
              style: TextStyle(
                color: AppColors.titleColor,
                fontSize: AppSizes.subtitleFontSize(context),
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: AppSizes.mediumSpacing(context)),

            CustomWidgets.customTextFormField(
              controller: _bidController,
              label: 'Bid Amount (PKR)',
              borderColor: AppColors.primary,
              textColor: AppColors.foregroundColor,
              fontsize: AppSizes.inputFontSize(context),
              isnumber: true,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter a bid amount';
                }
                if (double.tryParse(value) == null) {
                  return 'Please enter a valid amount';
                }
                return null;
              },
            ),

            SizedBox(height: AppSizes.smallSpacing(context)),

            // Quick increment buttons
            Row(
              children: [
                Expanded(child: _buildQuickIncrementButton('+1K', 1000)),
                SizedBox(width: AppSizes.smallSpacing(context)),
                Expanded(child: _buildQuickIncrementButton('+5K', 5000)),
                SizedBox(width: AppSizes.smallSpacing(context)),
                Expanded(child: _buildQuickIncrementButton('+10K', 10000)),
              ],
            ),

            SizedBox(height: AppSizes.largeSpacing(context)),

            // Place Bid Button
            SizedBox(
              width: double.infinity,
              height: AppSizes.buttonHeight(context),
              child: ElevatedButton(
                onPressed: _placeBid,
                style: CustomWidgets.elevatedButtonStyle(context),
                child: Consumer<MarketplaceController>(
                  builder: (context, controller, child) {
                    return controller.isLoading
                        ? CustomWidgets.circularProgressIndicator()
                        : Text(
                            'Place Bid',
                            style: TextStyle(
                              color: AppColors.titleColor,
                              fontSize: AppSizes.inputFontSize(context),
                              fontWeight: FontWeight.bold,
                            ),
                          );
                  },
                ),
              ),
            ),

            SizedBox(height: AppSizes.mediumSpacing(context)),

            // Divider
            Row(
              children: [
                Expanded(child: Divider(color: AppColors.shadeColor)),
                Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: AppSizes.mediumPadding(context),
                  ),
                  child: Text(
                    'OR',
                    style: TextStyle(
                      color: AppColors.shadeColor,
                      fontSize: AppSizes.bodyFontSize(context),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Expanded(child: Divider(color: AppColors.shadeColor)),
              ],
            ),

            SizedBox(height: AppSizes.mediumSpacing(context)),

            // Buy Now Button
            SizedBox(
              width: double.infinity,
              height: AppSizes.buttonHeight(context),
              child: OutlinedButton.icon(
                onPressed: _showBuyNowConfirmation,
                icon: Icon(Icons.shopping_bag, color: AppColors.primary),
                label: Text(
                  'Buy Now (Skip Bidding)',
                  style: TextStyle(
                    color: AppColors.primary,
                    fontSize: AppSizes.inputFontSize(context),
                    fontWeight: FontWeight.bold,
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: AppColors.primary, width: 2),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(
                      AppSizes.inputBorderRadius(context),
                    ),
                  ),
                ),
              ),
            ),

            SizedBox(height: AppSizes.largeSpacing(context)),

            // Info note
            Container(
              padding: EdgeInsets.all(AppSizes.mediumPadding(context)),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(
                  AppSizes.cardBorderRadius(context),
                ),
                border: Border.all(color: AppColors.primary.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    color: AppColors.primary,
                    size: AppSizes.mediumIconSize(context),
                  ),
                  SizedBox(width: AppSizes.smallSpacing(context)),
                  Expanded(
                    child: Text(
                      'Buy Now will charge 10% more than the item price to skip the auction process.',
                      style: TextStyle(
                        color: AppColors.primary,
                        fontSize: AppSizes.smallFontSize(context),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showBuyNowConfirmation() {
    final itemPrice = widget.listing.price;
    final buyNowPrice = itemPrice * 1.1; // 10% more than item price

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: AppColors.backgroundColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(
              AppSizes.cardBorderRadius(context),
            ),
          ),
          title: Row(
            children: [
              Icon(
                Icons.shopping_bag,
                color: AppColors.primary,
                size: AppSizes.mediumIconSize(context),
              ),
              SizedBox(width: AppSizes.smallSpacing(context)),
              Expanded(
                child: Text(
                  'Buy Now Confirmation',
                  style: TextStyle(
                    color: AppColors.titleColor,
                    fontSize: AppSizes.subtitleFontSize(context),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'You are about to purchase this item instantly, skipping the auction process.',
                style: TextStyle(
                  color: AppColors.foregroundColor,
                  fontSize: AppSizes.bodyFontSize(context),
                ),
              ),
              SizedBox(height: AppSizes.mediumSpacing(context)),
              Container(
                padding: EdgeInsets.all(AppSizes.mediumPadding(context)),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(
                    AppSizes.cardBorderRadius(context),
                  ),
                  border: Border.all(color: AppColors.primary.withOpacity(0.3)),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Item Price:',
                          style: TextStyle(
                            color: AppColors.foregroundColor,
                            fontSize: AppSizes.bodyFontSize(context),
                          ),
                        ),
                        Text(
                          'PKR ${itemPrice.toStringAsFixed(0)}',
                          style: TextStyle(
                            color: AppColors.foregroundColor,
                            fontSize: AppSizes.bodyFontSize(context),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: AppSizes.smallSpacing(context)),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Buy Fee (10%):',
                          style: TextStyle(
                            color: AppColors.foregroundColor,
                            fontSize: AppSizes.bodyFontSize(context),
                          ),
                        ),
                        Text(
                          'PKR ${(itemPrice * 0.1).toStringAsFixed(0)}',
                          style: TextStyle(
                            color: AppColors.foregroundColor,
                            fontSize: AppSizes.bodyFontSize(context),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    Divider(color: AppColors.shadeColor),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Total:',
                          style: TextStyle(
                            color: AppColors.primary,
                            fontSize: AppSizes.subtitleFontSize(context),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'PKR ${buyNowPrice.toStringAsFixed(0)}',
                          style: TextStyle(
                            color: AppColors.primary,
                            fontSize: AppSizes.subtitleFontSize(context),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'Cancel',
                style: TextStyle(color: AppColors.shadeColor),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context); // Close dialog
                // Navigate to checkout with modified listing
                final modifiedListing = ListingModel(
                  id: widget.listing.id,
                  title: widget.listing.title,
                  description: widget.listing.description,
                  price: buyNowPrice,
                  originalPrice: widget.listing.originalPrice,
                  category: widget.listing.category,
                  subcategory: widget.listing.subcategory,
                  brand: widget.listing.brand,
                  year: widget.listing.year,
                  condition: widget.listing.condition,
                  mileage: widget.listing.mileage,
                  fuelType: widget.listing.fuelType,
                  transmission: widget.listing.transmission,
                  color: widget.listing.color,
                  images: widget.listing.images,
                  location: widget.listing.location,
                  seller: widget.listing.seller,
                  isActive: widget.listing.isActive,
                  isFeatured: widget.listing.isFeatured,
                  viewCount: widget.listing.viewCount,
                  favoriteCount: widget.listing.favoriteCount,
                  clickCount: widget.listing.clickCount,
                  quantity: widget.listing.quantity,
                  originalQuantity: widget.listing.originalQuantity,
                  isAuction: false, // Mark as non-auction for checkout
                  status: widget.listing.status,
                  soldTo: widget.listing.soldTo,
                  soldAt: widget.listing.soldAt,
                  soldPrice: widget.listing.soldPrice,
                  createdAt: widget.listing.createdAt,
                  updatedAt: widget.listing.updatedAt,
                );

                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (_) =>
                        CheckoutScreen(listing: modifiedListing, quantity: 1),
                  ),
                );
              },
              style: CustomWidgets.elevatedButtonStyle(context),
              child: Text(
                'Confirm & Buy',
                style: TextStyle(color: AppColors.titleColor),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildQuickIncrementButton(String label, double amount) {
    return ElevatedButton(
      onPressed: () {
        final currentBid = double.tryParse(_bidController.text) ?? 0;
        setState(() {
          _bidController.text = (currentBid + amount).toStringAsFixed(0);
        });
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.backgroundColor,
        padding: EdgeInsets.symmetric(vertical: AppSizes.smallPadding(context)),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(
            AppSizes.inputBorderRadius(context),
          ),
          side: BorderSide(color: AppColors.primary),
        ),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: AppColors.primary,
          fontSize: AppSizes.smallFontSize(context),
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  void _placeBid() async {
    final bidAmount = double.tryParse(_bidController.text);
    if (bidAmount == null || bidAmount <= 0) {
      CustomSnackbars.showErrorSnackbar(
        context,
        'Please enter a valid bid amount',
      );
      return;
    }

    final minimumBid =
        (widget.listing.currentBid ?? widget.listing.startingBid ?? 0) +
        (widget.listing.bidIncrement ?? 1000);
    if (bidAmount < minimumBid) {
      CustomSnackbars.showErrorSnackbar(
        context,
        'Bid must be at least PKR ${minimumBid.toStringAsFixed(0)}',
      );
      return;
    }

    final controller = Provider.of<MarketplaceController>(
      context,
      listen: false,
    );

    final bidData = {'amount': bidAmount};

    final success = await controller.placeBid(widget.listing.id!, bidData);

    if (success) {
      CustomSnackbars.showSuccessSnackbar(
        context,
        'Bid placed successfully!',
        2.0,
      );
      Navigator.pop(context);
    } else {
      CustomSnackbars.showErrorSnackbar(
        context,
        controller.error ?? 'Failed to place bid',
      );
    }
  }
}
