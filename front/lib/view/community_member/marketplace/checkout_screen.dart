import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:front/controller/marketplace/marketplace_controller.dart';
import 'package:front/model/marketplace/listing_model.dart';
import 'package:front/utils/app_colors.dart';
import 'package:front/utils/sizes.dart';
import 'package:front/utils/custom_widgets.dart';
import 'package:front/utils/snackbars.dart';
// import 'package:flutter_stripe/flutter_stripe.dart'; // Uncomment when Stripe is ready

class CheckoutScreen extends StatefulWidget {
  final ListingModel listing;
  final int quantity;

  const CheckoutScreen({super.key, required this.listing, this.quantity = 1});

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  String _selectedPaymentMethod = 'cash'; // cash, stripe

  @override
  Widget build(BuildContext context) {
    AppColors.getBackgroundColor(context);

    final total = (widget.listing.price ?? 0) * widget.quantity;

    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      appBar: AppBar(
        backgroundColor: AppColors.backgroundColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: AppColors.foregroundColor),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Checkout',
          style: TextStyle(
            color: AppColors.titleColor,
            fontSize: AppSizes.titleFontSize(context),
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.all(AppSizes.mediumPadding(context)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Order Summary
              _buildSectionTitle('Order Summary'),
              SizedBox(height: AppSizes.mediumSpacing(context)),
              _buildOrderSummary(),
              SizedBox(height: AppSizes.largeSpacing(context)),

              // Payment Method
              _buildSectionTitle('Payment Method'),
              SizedBox(height: AppSizes.mediumSpacing(context)),
              _buildPaymentMethods(),
              SizedBox(height: AppSizes.largeSpacing(context)),

              // Total
              _buildTotalSection(total),
              SizedBox(height: AppSizes.largeSpacing(context)),

              // Place Order Button
              _buildPlaceOrderButton(total),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: TextStyle(
        color: AppColors.titleColor,
        fontSize: AppSizes.subtitleFontSize(context),
        fontWeight: FontWeight.bold,
      ),
    );
  }

  Widget _buildOrderSummary() {
    return Container(
      padding: EdgeInsets.all(AppSizes.mediumPadding(context)),
      decoration: BoxDecoration(
        color: AppColors.backgroundColor,
        borderRadius: BorderRadius.circular(AppSizes.cardBorderRadius(context)),
        border: Border.all(color: AppColors.shadeColor.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          // Image
          ClipRRect(
            borderRadius: BorderRadius.circular(
              AppSizes.cardBorderRadius(context),
            ),
            child: Image.network(
              widget.listing.images?.isNotEmpty == true
                  ? widget.listing.images!.first
                  : 'https://via.placeholder.com/150',
              width: 80,
              height: 80,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                width: 80,
                height: 80,
                color: AppColors.shadeColor.withOpacity(0.2),
                child: Icon(Icons.image, color: AppColors.shadeColor),
              ),
            ),
          ),
          SizedBox(width: AppSizes.mediumSpacing(context)),
          // Details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.listing.title ?? 'No title',
                  style: TextStyle(
                    color: AppColors.titleColor,
                    fontSize: AppSizes.bodyFontSize(context),
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: AppSizes.smallSpacing(context) / 2),
                Text(
                  'Quantity: ${widget.quantity}',
                  style: TextStyle(
                    color: AppColors.shadeColor,
                    fontSize: AppSizes.bodyFontSize(context),
                  ),
                ),
                SizedBox(height: AppSizes.smallSpacing(context) / 2),
                Text(
                  'PKR ${widget.listing.price.toStringAsFixed(0)} each',
                  style: TextStyle(
                    color: AppColors.primary,
                    fontSize: AppSizes.bodyFontSize(context),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentMethods() {
    return Column(
      children: [
        _buildPaymentOption('cash', 'Cash on Delivery', Icons.money),
        SizedBox(height: AppSizes.mediumSpacing(context)),
        // Stripe option (commented for later activation)
        // _buildPaymentOption(
        //   'stripe',
        //   'Credit/Debit Card (Stripe)',
        //   Icons.credit_card,
        // ),
      ],
    );
  }

  Widget _buildPaymentOption(String value, String label, IconData icon) {
    final isSelected = _selectedPaymentMethod == value;
    return InkWell(
      onTap: () => setState(() => _selectedPaymentMethod = value),
      child: Container(
        padding: EdgeInsets.all(AppSizes.mediumPadding(context)),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary.withOpacity(0.1)
              : AppColors.backgroundColor,
          borderRadius: BorderRadius.circular(
            AppSizes.cardBorderRadius(context),
          ),
          border: Border.all(
            color: isSelected
                ? AppColors.primary
                : AppColors.shadeColor.withOpacity(0.2),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: isSelected ? AppColors.primary : AppColors.shadeColor,
              size: AppSizes.mediumIconSize(context),
            ),
            SizedBox(width: AppSizes.mediumSpacing(context)),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  color: isSelected
                      ? AppColors.primary
                      : AppColors.foregroundColor,
                  fontSize: AppSizes.bodyFontSize(context),
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ),
            if (isSelected)
              Icon(
                Icons.check_circle,
                color: AppColors.primary,
                size: AppSizes.mediumIconSize(context),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildTotalSection(double total) {
    return Container(
      padding: EdgeInsets.all(AppSizes.mediumPadding(context)),
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.1),
        borderRadius: BorderRadius.circular(AppSizes.cardBorderRadius(context)),
        border: Border.all(color: AppColors.primary.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Total Amount',
            style: TextStyle(
              color: AppColors.titleColor,
              fontSize: AppSizes.subtitleFontSize(context),
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            'PKR ${total.toStringAsFixed(0)}',
            style: TextStyle(
              color: AppColors.primary,
              fontSize: AppSizes.subtitleFontSize(context),
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlaceOrderButton(double total) {
    return SizedBox(
      width: double.infinity,
      height: AppSizes.buttonHeight(context),
      child: ElevatedButton(
        onPressed: () => _handlePlaceOrder(total),
        style: CustomWidgets.elevatedButtonStyle(context),
        child: Consumer<MarketplaceController>(
          builder: (context, controller, _) {
            return controller.isLoading
                ? CustomWidgets.circularProgressIndicator()
                : Text(
                    'Place Order',
                    style: TextStyle(
                      color: AppColors.titleColor,
                      fontSize: AppSizes.inputFontSize(context),
                      fontWeight: FontWeight.bold,
                    ),
                  );
          },
        ),
      ),
    );
  }

  Future<void> _handlePlaceOrder(double total) async {
    final controller = Provider.of<MarketplaceController>(
      context,
      listen: false,
    );

    if (_selectedPaymentMethod == 'cash') {
      // Cash on Delivery
      final success = await controller.completeOrder();
      if (!mounted) return;

      if (success) {
        showDialog(
          context: context,
          builder: (_) => AlertDialog(
            backgroundColor: AppColors.backgroundColor,
            title: Text(
              'Order Placed',
              style: TextStyle(color: AppColors.titleColor),
            ),
            content: Text(
              'Your order has been placed successfully. You will pay on delivery.',
              style: TextStyle(color: AppColors.foregroundColor),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context); // Close dialog
                  Navigator.pop(context); // Go back to listing
                },
                child: Text('OK', style: TextStyle(color: AppColors.primary)),
              ),
            ],
          ),
        );
      } else {
        CustomSnackbars.showErrorSnackbar(
          context,
          controller.error ?? 'Failed to place order',
        );
      }
    }
    // Uncomment when Stripe is ready
    // else if (_selectedPaymentMethod == 'stripe') {
    //   try {
    //     // Initialize Stripe payment
    //     await _processStripePayment(total.toInt());
    //
    //     // If payment succeeds, complete the order
    //     final success = await controller.completeOrder();
    //     if (!mounted) return;
    //
    //     if (success) {
    //       showDialog(
    //         context: context,
    //         builder: (_) => AlertDialog(
    //           backgroundColor: AppColors.backgroundColor,
    //           title: Text(
    //             'Payment Successful',
    //             style: TextStyle(color: AppColors.titleColor),
    //           ),
    //           content: Text(
    //             'Your payment was successful and order has been placed.',
    //             style: TextStyle(color: AppColors.foregroundColor),
    //           ),
    //           actions: [
    //             TextButton(
    //               onPressed: () {
    //                 Navigator.pop(context); // Close dialog
    //                 Navigator.pop(context); // Go back to listing
    //               },
    //               child: Text('OK', style: TextStyle(color: AppColors.primary)),
    //             ),
    //           ],
    //         ),
    //       );
    //     }
    //   } catch (e) {
    //     if (!mounted) return;
    //     CustomSnackbars.showErrorSnackbar(
    //       context,
    //       'Payment failed: $e',
    //       2,
    //     );
    //   }
    // }
  }

  // Uncomment when Stripe is ready
  // Future<void> _processStripePayment(int amount) async {
  //   // This is a placeholder for Stripe payment processing
  //   // You'll need to:
  //   // 1. Create payment intent on your backend
  //   // 2. Initialize Stripe payment sheet
  //   // 3. Present payment sheet to user
  //   // 4. Handle the result
  //
  //   // Example implementation:
  //   // final paymentIntentResult = await _createPaymentIntent(amount);
  //   // final clientSecret = paymentIntentResult['clientSecret'];
  //   //
  //   // await Stripe.instance.initPaymentSheet(
  //   //   paymentSheetParameters: SetupPaymentSheetParameters(
  //   //     paymentIntentClientSecret: clientSecret,
  //   //     merchantDisplayName: 'Auto Vision Hub',
  //   //   ),
  //   // );
  //   //
  //   // await Stripe.instance.presentPaymentSheet();
  // }
}
