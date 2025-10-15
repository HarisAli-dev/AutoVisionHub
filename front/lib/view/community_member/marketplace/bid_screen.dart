import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:front/controller/marketplace/marketplace_controller.dart';
import 'package:front/model/marketplace/listing_model.dart';
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
            // Auction Info Card
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
                  SizedBox(height: AppSizes.smallSpacing(context)),
                  Text(
                    'by @user123 • 2 hours ago',
                    style: TextStyle(
                      color: AppColors.shadeColor,
                      fontSize: AppSizes.smallFontSize(context),
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

            SizedBox(height: AppSizes.largeSpacing(context) * 1.5),

            // Bid Input with Increment Buttons
            Text(
              'Your Bid',
              style: TextStyle(
                color: AppColors.titleColor,
                fontSize: AppSizes.subtitleFontSize(context),
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: AppSizes.mediumSpacing(context)),

            // Bid input with increment/decrement buttons
            Row(
              children: [
                // Decrement button
                Container(
                  height: AppSizes.buttonHeight(context),
                  width: AppSizes.buttonHeight(context),
                  child: ElevatedButton(
                    onPressed: () => _adjustBid(false),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary.withOpacity(0.2),
                      padding: EdgeInsets.zero,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(
                          AppSizes.inputBorderRadius(context),
                        ),
                        side: BorderSide(color: AppColors.primary),
                      ),
                    ),
                    child: Icon(
                      Icons.remove,
                      color: AppColors.primary,
                      size: AppSizes.mediumIconSize(context),
                    ),
                  ),
                ),
                SizedBox(width: AppSizes.smallSpacing(context)),

                // Bid input field
                Expanded(
                  child: CustomWidgets.customTextFormField(
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
                ),
                SizedBox(width: AppSizes.smallSpacing(context)),

                // Increment button
                Container(
                  height: AppSizes.buttonHeight(context),
                  width: AppSizes.buttonHeight(context),
                  child: ElevatedButton(
                    onPressed: () => _adjustBid(true),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary.withOpacity(0.2),
                      padding: EdgeInsets.zero,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(
                          AppSizes.inputBorderRadius(context),
                        ),
                        side: BorderSide(color: AppColors.primary),
                      ),
                    ),
                    child: Icon(
                      Icons.add,
                      color: AppColors.primary,
                      size: AppSizes.mediumIconSize(context),
                    ),
                  ),
                ),
              ],
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
                SizedBox(width: AppSizes.smallSpacing(context)),
                Expanded(child: _buildQuickIncrementButton('+50K', 50000)),
              ],
            ),

            SizedBox(height: AppSizes.largeSpacing(context)),

            // Show current bid increment info
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
                      'Minimum increment: PKR ${(widget.listing.bidIncrement ?? 1000).toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')}',
                      style: TextStyle(
                        color: AppColors.primary,
                        fontSize: AppSizes.smallFontSize(context),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            SizedBox(height: AppSizes.largeSpacing(context) * 1.5),

            // Bid History
            Text(
              'Bid History',
              style: TextStyle(
                color: AppColors.titleColor,
                fontSize: AppSizes.subtitleFontSize(context),
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: AppSizes.mediumSpacing(context)),

            Consumer<MarketplaceController>(
              builder: (context, controller, child) {
                if (controller.isLoading) {
                  return Center(
                    child: CircularProgressIndicator(color: AppColors.primary),
                  );
                }

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
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: controller.bids.length,
                  itemBuilder: (context, index) {
                    final bid = controller.bids[index];
                    return Container(
                      margin: EdgeInsets.only(
                        bottom: AppSizes.smallSpacing(context),
                      ),
                      padding: EdgeInsets.all(AppSizes.smallPadding(context)),
                      decoration: BoxDecoration(
                        color: AppColors.backgroundColor,
                        borderRadius: BorderRadius.circular(
                          AppSizes.cardBorderRadius(context),
                        ),
                        border: bid.isWinning
                            ? Border.all(color: AppColors.primary, width: 2)
                            : Border.all(color: AppColors.shadeColor),
                      ),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: AppSizes.mediumIconSize(context),
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
                                fontSize: AppSizes.inputFontSize(context),
                              ),
                            ),
                          ),
                          SizedBox(width: AppSizes.smallSpacing(context)),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  bid.bidder?.name ?? 'Anonymous',
                                  style: TextStyle(
                                    color: AppColors.titleColor,
                                    fontWeight: FontWeight.bold,
                                    fontSize: AppSizes.inputFontSize(context),
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
                                  fontSize: AppSizes.inputFontSize(context),
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
              },
            ),

            SizedBox(height: AppSizes.largeSpacing(context) * 1.5),

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
                        ? CircularProgressIndicator(color: AppColors.titleColor)
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

            // Terms and Conditions
            Text(
              'By placing a bid, you agree to the terms and conditions. If you win the auction, you are obligated to complete the purchase.',
              style: TextStyle(
                color: AppColors.shadeColor,
                fontSize: AppSizes.smallFontSize(context),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  void _adjustBid(bool increment) {
    final currentBid = double.tryParse(_bidController.text) ?? 0;
    final bidIncrement = widget.listing.bidIncrement ?? 1000;

    final newBid = increment
        ? currentBid + bidIncrement
        : currentBid - bidIncrement;

    // Ensure the bid doesn't go below the minimum required bid
    final minimumBid =
        (widget.listing.currentBid ?? widget.listing.startingBid ?? 0) +
        bidIncrement;
    final finalBid = newBid < minimumBid ? minimumBid : newBid;

    setState(() {
      _bidController.text = finalBid.toStringAsFixed(0);
    });
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
