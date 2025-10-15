import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:front/controller/marketplace/marketplace_controller.dart';
import 'package:front/model/marketplace/listing_model.dart';
import 'package:front/utils/app_colors.dart';
import 'package:front/utils/sizes.dart';
import 'package:front/utils/custom_widgets.dart';
import 'package:front/utils/snackbars.dart';

class OfferScreen extends StatefulWidget {
  final ListingModel listing;

  const OfferScreen({super.key, required this.listing});

  @override
  State<OfferScreen> createState() => _OfferScreenState();
}

class _OfferScreenState extends State<OfferScreen> {
  final _offerController = TextEditingController();
  final _messageController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Set initial offer to 80% of listing price
    _offerController.text = (widget.listing.price * 0.8).toStringAsFixed(0);
  }

  @override
  void dispose() {
    _offerController.dispose();
    _messageController.dispose();
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
            // Listing Info Card
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(AppSizes.largePadding(context)),
              decoration: BoxDecoration(
                color: AppColors.backgroundColor,
                borderRadius: BorderRadius.circular(
                  AppSizes.cardBorderRadius(context),
                ),
                border: Border.all(color: AppColors.shadeColor),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.listing.title,
                    style: TextStyle(
                      color: AppColors.titleColor,
                      fontSize: AppSizes.subtitleFontSize(context),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: AppSizes.smallSpacing(context)),
                  Text(
                    widget.listing.formattedPrice,
                    style: TextStyle(
                      color: AppColors.primary,
                      fontSize: AppSizes.titleFontSize(context),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: AppSizes.smallSpacing(context)),
                  Text(
                    'Condition: ${widget.listing.condition.toUpperCase()}',
                    style: TextStyle(
                      color: AppColors.shadeColor,
                      fontSize: AppSizes.smallFontSize(context),
                    ),
                  ),
                ],
              ),
            ),

            SizedBox(height: AppSizes.largeSpacing(context) * 1.5),

            // Offer Input
            Text(
              'Make Your Offer',
              style: TextStyle(
                color: AppColors.titleColor,
                fontSize: AppSizes.subtitleFontSize(context),
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: AppSizes.mediumSpacing(context)),

            CustomWidgets.customTextFormField(
              controller: _offerController,
              label: 'Offer Amount',
              borderColor: AppColors.primary,
              textColor: AppColors.foregroundColor,
              fontsize: AppSizes.inputFontSize(context),
              isnumber: true,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter an offer amount';
                }
                if (double.tryParse(value) == null) {
                  return 'Please enter a valid amount';
                }
                return null;
              },
            ),

            SizedBox(height: AppSizes.mediumSpacing(context)),

            // Quick Offer Buttons
            Text(
              'Quick Offers',
              style: TextStyle(
                color: AppColors.shadeColor,
                fontSize: AppSizes.smallFontSize(context),
              ),
            ),
            SizedBox(height: AppSizes.smallSpacing(context)),

            Row(
              children: [
                Expanded(
                  child: _buildQuickOfferButton(
                    '70%',
                    widget.listing.price * 0.7,
                  ),
                ),
                SizedBox(width: AppSizes.smallSpacing(context)),
                Expanded(
                  child: _buildQuickOfferButton(
                    '80%',
                    widget.listing.price * 0.8,
                  ),
                ),
                SizedBox(width: AppSizes.smallSpacing(context)),
                Expanded(
                  child: _buildQuickOfferButton(
                    '90%',
                    widget.listing.price * 0.9,
                  ),
                ),
              ],
            ),

            SizedBox(height: AppSizes.largeSpacing(context)),

            // Message Input
            Text(
              'Message (Optional)',
              style: TextStyle(
                color: AppColors.titleColor,
                fontSize: AppSizes.inputFontSize(context),
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: AppSizes.smallSpacing(context)),

            CustomWidgets.customTextFormField(
              controller: _messageController,
              label: 'Add a message to your offer',
              borderColor: AppColors.primary,
              textColor: AppColors.foregroundColor,
              fontsize: AppSizes.inputFontSize(context),
              maxLine: 4,
            ),

            SizedBox(height: AppSizes.largeSpacing(context) * 1.5),

            // Offer Guidelines
            Container(
              padding: EdgeInsets.all(AppSizes.mediumPadding(context)),
              decoration: BoxDecoration(
                color: AppColors.backgroundColor,
                borderRadius: BorderRadius.circular(
                  AppSizes.cardBorderRadius(context),
                ),
                border: Border.all(color: AppColors.shadeColor),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Offer Guidelines',
                    style: TextStyle(
                      color: AppColors.titleColor,
                      fontSize: AppSizes.inputFontSize(context),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: AppSizes.smallSpacing(context)),
                  Text(
                    '• Your offer should be reasonable and competitive\n'
                    '• The seller can accept, reject, or counter your offer\n'
                    '• You can negotiate until both parties agree\n'
                    '• Be respectful in your messages',
                    style: TextStyle(
                      color: AppColors.shadeColor,
                      fontSize: AppSizes.smallFontSize(context),
                    ),
                  ),
                ],
              ),
            ),

            SizedBox(height: AppSizes.largeSpacing(context) * 1.5),

            // Make Offer Button
            SizedBox(
              width: double.infinity,
              height: AppSizes.buttonHeight(context),
              child: ElevatedButton(
                onPressed: _makeOffer,
                style: CustomWidgets.elevatedButtonStyle(context),
                child: Consumer<MarketplaceController>(
                  builder: (context, controller, child) {
                    return controller.isLoading
                        ? CircularProgressIndicator(color: AppColors.titleColor)
                        : Text(
                            'Make Offer',
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
              'By making an offer, you agree to the terms and conditions. If your offer is accepted, you are obligated to complete the purchase.',
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

  Widget _buildQuickOfferButton(String percentage, double amount) {
    return GestureDetector(
      onTap: () {
        _offerController.text = amount.toStringAsFixed(0);
      },
      child: Container(
        padding: EdgeInsets.symmetric(
          vertical: AppSizes.smallPadding(context),
          horizontal: AppSizes.smallPadding(context),
        ),
        decoration: BoxDecoration(
          color: AppColors.backgroundColor,
          borderRadius: BorderRadius.circular(
            AppSizes.inputBorderRadius(context),
          ),
          border: Border.all(color: AppColors.shadeColor),
        ),
        child: Column(
          children: [
            Text(
              percentage,
              style: TextStyle(
                color: AppColors.titleColor,
                fontSize: AppSizes.smallFontSize(context),
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              'PKR ${amount.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')}',
              style: TextStyle(
                color: AppColors.shadeColor,
                fontSize: AppSizes.smallFontSize(context) * 0.8,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _makeOffer() async {
    final offerAmount = double.tryParse(_offerController.text);
    if (offerAmount == null || offerAmount <= 0) {
      CustomSnackbars.showErrorSnackbar(
        context,
        'Please enter a valid offer amount',
      );
      return;
    }

    if (offerAmount >= widget.listing.price) {
      CustomSnackbars.showErrorSnackbar(
        context,
        'Offer must be less than the listing price',
      );
      return;
    }

    if (widget.listing.minimumOffer != null &&
        offerAmount < widget.listing.minimumOffer!) {
      CustomSnackbars.showErrorSnackbar(
        context,
        'Minimum offer is PKR ${widget.listing.minimumOffer!.toStringAsFixed(0)}',
      );
      return;
    }

    final controller = Provider.of<MarketplaceController>(
      context,
      listen: false,
    );

    final offerData = {
      'amount': offerAmount,
      'message': _messageController.text.trim().isNotEmpty
          ? _messageController.text.trim()
          : null,
    };

    final success = await controller.makeOffer(widget.listing.id!, offerData);

    if (success) {
      CustomSnackbars.showSuccessSnackbar(
        context,
        'Offer made successfully!',
        2.0,
      );
      Navigator.pop(context);
    } else {
      CustomSnackbars.showErrorSnackbar(
        context,
        controller.error ?? 'Failed to make offer',
      );
    }
  }
}
