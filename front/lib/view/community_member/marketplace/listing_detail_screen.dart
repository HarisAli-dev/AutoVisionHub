import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:front/controller/marketplace/marketplace_controller.dart';
import 'package:front/controller/chats/chat_controller.dart';
import 'package:front/controller/report_controller.dart';
import 'package:front/model/marketplace/listing_model.dart';
import 'package:front/services/marketplace_service.dart';
import 'package:front/view/community_member/marketplace/bid_screen.dart';
import 'package:front/view/community_member/marketplace/checkout_screen.dart';
import 'package:front/view/community_member/marketplace/edit_listing_screen.dart';
import 'package:front/view/community_member/chats/chat_screen.dart';
import 'package:front/view/community_member/marketplace/ar_screens/ar_visualization_screen.dart';
import 'package:front/utils/app_colors.dart';
import 'package:front/utils/sizes.dart';
import 'package:front/utils/custom_widgets.dart';
import 'package:front/utils/snackbars.dart';
import 'package:front/utils/hive_utils.dart';

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

class _ListingDetailScreenState extends State<ListingDetailScreen> {
  bool _isFavorited = false;
  String? _currentUserId;

  @override
  void initState() {
    super.initState();
    _currentUserId = HiveUtils.getData('userId');
    _checkFavoriteStatus();
    _loadBids();
    _loadReviews();
    _trackView(); // Track this listing view
  }

  // Track the listing view for recently viewed feature
  Future<void> _trackView() async {
    if (widget.listing.id != null) {
      try {
        final token = HiveUtils.getData('token');
        await MarketplaceService.getListingById(
          widget.listing.id!,
          token: token,
        );
      } catch (e) {
        // Don't show error to user, this is just for tracking
      }
    }
  }

  Future<void> _loadBids() async {
    if (widget.listing.isAuction && widget.listing.id != null) {
      final controller = Provider.of<MarketplaceController>(
        context,
        listen: false,
      );
      await controller.getListingBids(widget.listing.id!);
    }
  }

  Future<void> _loadReviews() async {
    if (widget.listing.id != null) {
      final controller = Provider.of<MarketplaceController>(
        context,
        listen: false,
      );
      await controller.getListingReviews(widget.listing.id!);
      if (mounted) {
        setState(() {});
      }
    }
  }

  void _checkFavoriteStatus() async {
    final controller = Provider.of<MarketplaceController>(
      context,
      listen: false,
    );

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

  Future<void> _showReportDialog() async {
    final TextEditingController reasonController = TextEditingController();
    final List<File> selectedImages = [];
    final ImagePicker picker = ImagePicker();

    final result = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          backgroundColor: AppColors.backgroundColor,
          title: Text(
            'Report Listing',
            style: TextStyle(color: AppColors.titleColor),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Please tell us why you are reporting this listing:',
                  style: TextStyle(
                    fontSize: AppSizes.subtitleFontSize(context),
                    color: AppColors.shadeColor,
                  ),
                ),
                SizedBox(height: AppSizes.mediumSpacing(context)),
                TextField(
                  controller: reasonController,
                  style: TextStyle(color: AppColors.foregroundColor),
                  decoration: InputDecoration(
                    hintText: 'Enter reason...',
                    hintStyle: TextStyle(color: AppColors.shadeColor),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: AppColors.shadeColor),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: AppColors.shadeColor),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: AppColors.primary),
                    ),
                  ),
                  maxLines: 3,
                  maxLength: 200,
                ),
                SizedBox(height: 16),
                Text(
                  'Upload proof (optional):',
                  style: TextStyle(
                    fontSize: AppSizes.subtitleFontSize(context),
                    color: AppColors.shadeColor,
                  ),
                ),
                SizedBox(height: 8),
                ElevatedButton.icon(
                  onPressed: () async {
                    final XFile? image = await picker.pickImage(source: ImageSource.gallery);
                    if (image != null) {
                      setState(() {
                        selectedImages.add(File(image.path));
                      });
                    }
                  },
                  icon: Icon(Icons.add_photo_alternate),
                  label: Text('Add Image'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.shadeColor,
                    foregroundColor: AppColors.foregroundColor,
                  ),
                ),
                if (selectedImages.isNotEmpty) ...[
                  SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: selectedImages.map((img) {
                      return Stack(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.file(
                              img,
                              width: 80,
                              height: 80,
                              fit: BoxFit.cover,
                            ),
                          ),
                          Positioned(
                            top: 0,
                            right: 0,
                            child: GestureDetector(
                              onTap: () {
                                setState(() {
                                  selectedImages.remove(img);
                                });
                              },
                              child: Container(
                                padding: EdgeInsets.all(4),
                                decoration: BoxDecoration(
                                  color: Colors.red,
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(Icons.close, size: 16, color: Colors.white),
                              ),
                            ),
                          ),
                        ],
                      );
                    }).toList(),
                  ),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: Text(
                'Cancel',
                style: TextStyle(color: AppColors.shadeColor),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                if (reasonController.text.trim().isEmpty) {
                  CustomSnackbars.showErrorSnackbar(
                    context,
                    'Please enter a reason',
                  );
                  return;
                }
                Navigator.pop(dialogContext, true);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.errorColor,
                foregroundColor: AppColors.foregroundColor,
              ),
              child: const Text('Submit Report'),
            ),
          ],
        ),
      ),
    );

    if (result == true && mounted) {
      // Show loading
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator()),
      );

      final reportResult = await ReportController.reportListItem(
        listItemId: widget.listing.id!,
        reason: reasonController.text.trim(),
        proofImageFiles: selectedImages,
      );

      if (mounted) {
        Navigator.pop(context); // Close loading

        if (reportResult.contains('success')) {
          CustomSnackbars.showSuccessSnackbar(context, reportResult, 2);
        } else {
          CustomSnackbars.showErrorSnackbar(context, reportResult);
        }
      }
    }

    reasonController.dispose();
  }

  @override
  Widget build(BuildContext context) {
    AppColors.getBackgroundColor(context);

    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      body: CustomScrollView(
        slivers: [
          // Image Header
          _buildImageHeader(),

          // Content
          SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildTitlePriceSection(),
                // Show inactive banner if listing is inactive and user is the owner
                if (!widget.listing.isActive &&
                    widget.listing.seller?.id == _currentUserId)
                  _buildInactiveBanner(),
                _buildActionButtons(),
                if (!widget.listing.isAuction &&
                    widget.listing.seller?.id != _currentUserId)
                  _buildPurchaseSection(),
                if (widget.listing.category.toLowerCase() == 'parts' ||
                    widget.listing.category.toLowerCase() == 'part')
                  _buildARButton(),
                SizedBox(height: AppSizes.largeSpacing(context)),
                _buildDetailsSection(),
                _buildSpecificationsSection(),
                _buildSellerSection(),
                _buildReviewsSection(),
                if (widget.listing.isAuction) _buildBidsSection(),
                SizedBox(height: AppSizes.largeSpacing(context) * 2),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImageHeader() {
    return SliverAppBar(
      expandedHeight: AppSizes.imageHeight(context) * 1.2,
      pinned: true,
      backgroundColor: AppColors.backgroundColor,
      leading: IconButton(
        icon: Icon(Icons.arrow_back, color: AppColors.foregroundColor),
        onPressed: () => Navigator.pop(context),
      ),
      actions: [
        // Show edit button if user is the owner
        if (widget.listing.seller?.id == _currentUserId)
          IconButton(
            icon: Icon(Icons.edit, color: AppColors.foregroundColor),
            onPressed: () async {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) =>
                      EditListingScreen(listing: widget.listing),
                ),
              );

              // Refresh screen if edited
              if (result == true && mounted) {
                setState(() {
                  _loadReviews();
                });
              }
            },
          ),
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

            setState(() => _isFavorited = !_isFavorited);

            try {
              final controller = Provider.of<MarketplaceController>(
                context,
                listen: false,
              );
              await controller.toggleFavorite(widget.listing.id!);
            } catch (e) {
              setState(() => _isFavorited = !_isFavorited);
              if (mounted) {
                CustomSnackbars.showErrorSnackbar(
                  context,
                  'Failed to update favorite: $e',
                );
              }
            }
          },
        ),
        // Report button (only show if not own listing)
        if (widget.listing.seller?.id != _currentUserId)
          IconButton(
            icon: Icon(Icons.flag_outlined, color: AppColors.foregroundColor),
            onPressed: () => _showReportDialog(),
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
    );
  }

  Widget _buildInactiveBanner() {
    return Container(
      margin: EdgeInsets.all(AppSizes.mediumPadding(context)),
      padding: EdgeInsets.all(AppSizes.mediumPadding(context)),
      decoration: BoxDecoration(
        color: AppColors.errorColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(AppSizes.cardBorderRadius(context)),
        border: Border.all(color: AppColors.errorColor, width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.block,
                color: AppColors.errorColor,
                size: AppSizes.mediumIconSize(context),
              ),
              SizedBox(width: AppSizes.mediumSpacing(context)),
              Expanded(
                child: Text(
                  'This listing is currently inactive',
                  style: TextStyle(
                    color: AppColors.errorColor,
                    fontSize: AppSizes.subtitleFontSize(context),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: AppSizes.mediumSpacing(context)),
          Text(
            'Your listing was removed by an admin. You can request reactivation below.',
            style: TextStyle(
              color: AppColors.shadeColor,
              fontSize: AppSizes.bodyFontSize(context),
            ),
          ),
          SizedBox(height: AppSizes.mediumSpacing(context)),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _showReactivationDialog,
              icon: Icon(Icons.refresh, size: AppSizes.mediumIconSize(context)),
              label: Text('Request Reactivation'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.foregroundColor,
                padding: EdgeInsets.symmetric(
                  vertical: AppSizes.mediumPadding(context),
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(
                    AppSizes.cardBorderRadius(context),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showReactivationDialog() async {
    final TextEditingController reasonController = TextEditingController();

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.backgroundColor,
        title: Text(
          'Request Reactivation',
          style: TextStyle(color: AppColors.titleColor),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Please explain why this listing should be reactivated:',
              style: TextStyle(
                fontSize: AppSizes.subtitleFontSize(context),
                color: AppColors.shadeColor,
              ),
            ),
            SizedBox(height: AppSizes.mediumSpacing(context)),
            TextField(
              controller: reasonController,
              style: TextStyle(color: AppColors.foregroundColor),
              decoration: InputDecoration(
                hintText: 'Enter reason...',
                hintStyle: TextStyle(color: AppColors.shadeColor),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: AppColors.shadeColor),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: AppColors.shadeColor),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: AppColors.primary),
                ),
              ),
              maxLines: 3,
              maxLength: 200,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              'Cancel',
              style: TextStyle(color: AppColors.shadeColor),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              if (reasonController.text.trim().isEmpty) {
                CustomSnackbars.showErrorSnackbar(
                  context,
                  'Please enter a reason',
                );
                return;
              }
              Navigator.pop(context, true);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: AppColors.foregroundColor,
            ),
            child: Text('Submit'),
          ),
        ],
      ),
    );

    if (result == true && mounted) {
      final reason = reasonController.text.trim();

      // Show loading indicator
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
          ),
        ),
      );

      final message = await ReportController.requestReactivation(
        listItemId: widget.listing.id!,
        reason: reason,
      );

      if (mounted) {
        Navigator.pop(context); // Close loading

        if (message.contains('success') || message.contains('submitted')) {
          CustomSnackbars.showSuccessSnackbar(context, message, 2);
        } else {
          CustomSnackbars.showErrorSnackbar(context, message);
        }
      }
    }
  }

  Widget _buildTitlePriceSection() {
    return Container(
      padding: EdgeInsets.all(AppSizes.mediumPadding(context)),
      decoration: BoxDecoration(
        color: AppColors.backgroundColor,
        border: Border(
          bottom: BorderSide(
            color: AppColors.shadeColor.withOpacity(0.1),
            width: 1,
          ),
        ),
      ),
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
          SizedBox(height: AppSizes.mediumSpacing(context)),
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
          SizedBox(height: AppSizes.mediumSpacing(context)),
          Row(
            children: [
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: AppSizes.mediumPadding(context),
                  vertical: AppSizes.smallPadding(context) / 2,
                ),
                decoration: BoxDecoration(
                  color: widget.listing.isInStock
                      ? AppColors.successColor.withOpacity(0.1)
                      : AppColors.errorColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(
                    AppSizes.cardBorderRadius(context),
                  ),
                  border: Border.all(
                    color: widget.listing.isInStock
                        ? AppColors.successColor
                        : AppColors.errorColor,
                    width: 1.5,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      widget.listing.isInStock
                          ? Icons.check_circle
                          : Icons.warning,
                      color: widget.listing.isInStock
                          ? AppColors.successColor
                          : AppColors.errorColor,
                      size: AppSizes.smallIconSize(context),
                    ),
                    SizedBox(width: AppSizes.smallSpacing(context) / 2),
                    Text(
                      widget.listing.stockStatus,
                      style: TextStyle(
                        color: widget.listing.isInStock
                            ? AppColors.successColor
                            : AppColors.errorColor,
                        fontSize: AppSizes.bodyFontSize(context),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              if (widget.listing.isAuction) ...[
                SizedBox(width: AppSizes.mediumSpacing(context)),
                Expanded(
                  child: Container(
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
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.timer,
                          color: AppColors.titleColor,
                          size: AppSizes.smallIconSize(context),
                        ),
                        SizedBox(width: AppSizes.smallSpacing(context) / 2),
                        Expanded(
                          child: Text(
                            'Ends: ${widget.listing.auctionTimeRemaining}',
                            style: TextStyle(
                              color: AppColors.titleColor,
                              fontSize: AppSizes.bodyFontSize(context),
                              fontWeight: FontWeight.w600,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    final isOwner = widget.listing.seller?.id == _currentUserId;

    return Padding(
      padding: EdgeInsets.all(AppSizes.mediumPadding(context)),
      child: Column(
        children: [
          if (!isOwner) ...[
            SizedBox(
              width: double.infinity,
              height: AppSizes.buttonHeight(context),
              child: OutlinedButton.icon(
                onPressed: () async {
                  if (widget.listing.seller?.id == null) {
                    CustomSnackbars.showErrorSnackbar(
                      context,
                      'Seller information not available',
                    );
                    return;
                  }

                  try {
                    // Show loading indicator
                    showDialog(
                      context: context,
                      barrierDismissible: false,
                      builder: (context) =>
                          const Center(child: CircularProgressIndicator()),
                    );

                    // Fetch all user's chats to check if one already exists with this seller
                    final allChats = await ChatController.fetchChats();

                    // Check if a chat already exists with this seller
                    final existingChat = allChats.firstWhere(
                      (chat) => chat.participants.any(
                        (participant) =>
                            participant.id == widget.listing.seller!.id,
                      ),
                      orElse: () => throw Exception('not_found'),
                    );

                    String chatId;

                    try {
                      // If we found an existing chat, use it
                      chatId = existingChat.id;
                    } catch (e) {
                      // No existing chat found, create a new one
                      final newChat = await ChatController.createChatWithUser(
                        widget.listing.seller!.id!,
                      );
                      chatId = newChat.id;
                    }

                    // Close loading dialog
                    if (mounted) Navigator.pop(context);

                    // Navigate to chat screen
                    if (mounted) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ChatScreen(
                            chatId: chatId,
                            chatName: widget.listing.seller!.name,
                          ),
                        ),
                      );
                    }
                  } catch (e) {
                    // Close loading dialog
                    if (mounted) Navigator.pop(context);

                    if (mounted) {
                      CustomSnackbars.showErrorSnackbar(
                        context,
                        'Failed to open chat: $e',
                      );
                    }
                  }
                },
                icon: Icon(
                  Icons.chat_bubble_outline,
                  size: AppSizes.mediumIconSize(context),
                  color: AppColors.primary,
                ),
                label: Text(
                  'Chat with Seller',
                  style: TextStyle(
                    fontSize: AppSizes.inputFontSize(context),
                    color: AppColors.primary,
                    fontWeight: FontWeight.w600,
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
          ],
          if (widget.listing.isAuction && !isOwner) ...[
            SizedBox(height: AppSizes.mediumSpacing(context)),
            SizedBox(
              width: double.infinity,
              height: AppSizes.buttonHeight(context),
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => BidScreen(listing: widget.listing),
                    ),
                  );
                },
                icon: Icon(
                  Icons.gavel,
                  size: AppSizes.mediumIconSize(context),
                  color: AppColors.titleColor,
                ),
                label: Text(
                  'Place Bid',
                  style: TextStyle(
                    fontSize: AppSizes.inputFontSize(context),
                    color: AppColors.titleColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                style: CustomWidgets.elevatedButtonStyle(context),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPurchaseSection() {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: AppSizes.mediumPadding(context),
      ),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(
            color: AppColors.shadeColor.withOpacity(0.1),
            width: 1,
          ),
          bottom: BorderSide(
            color: AppColors.shadeColor.withOpacity(0.1),
            width: 1,
          ),
        ),
      ),
      child: Column(
        children: [
          SizedBox(height: AppSizes.mediumSpacing(context)),
          SizedBox(
            width: double.infinity,
            height: AppSizes.buttonHeight(context),
            child: ElevatedButton.icon(
              onPressed: widget.listing.isInStock
                  ? () {
                      // Check if this is an auction listing
                      if (widget.listing.isAuction == true) {
                        // Navigate to bidding page
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => BidScreen(listing: widget.listing),
                          ),
                        );
                      } else {
                        // Navigate to checkout page
                        final controller = Provider.of<MarketplaceController>(
                          context,
                          listen: false,
                        );
                        controller.addToCart(widget.listing);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => CheckoutScreen(
                              listing: widget.listing,
                              quantity: 1,
                            ),
                          ),
                        );
                      }
                    }
                  : null,
              icon: Icon(
                widget.listing.isAuction == true
                    ? Icons.gavel
                    : Icons.shopping_bag,
                color: AppColors.titleColor,
              ),
              label: Text(
                widget.listing.isAuction == true ? 'Place Bid' : 'Buy Now',
                style: TextStyle(
                  fontSize: AppSizes.inputFontSize(context),
                  color: AppColors.titleColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
              style: CustomWidgets.elevatedButtonStyle(context),
            ),
          ),
          SizedBox(height: AppSizes.mediumSpacing(context)),
          SizedBox(
            width: double.infinity,
            height: AppSizes.buttonHeight(context),
            child: OutlinedButton.icon(
              onPressed: widget.listing.isInStock
                  ? () {
                      final controller = Provider.of<MarketplaceController>(
                        context,
                        listen: false,
                      );
                      controller.addToCart(widget.listing);
                      CustomSnackbars.showSuccessSnackbar(
                        context,
                        'Added to cart',
                        1.5,
                      );
                    }
                  : null,
              icon: Icon(
                Icons.add_shopping_cart,
                color: AppColors.foregroundColor,
              ),
              label: Text(
                'Add to Cart',
                style: TextStyle(
                  fontSize: AppSizes.inputFontSize(context),
                  color: AppColors.foregroundColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: AppColors.shadeColor, width: 1.5),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(
                    AppSizes.inputBorderRadius(context),
                  ),
                ),
              ),
            ),
          ),
          SizedBox(height: AppSizes.mediumSpacing(context)),
        ],
      ),
    );
  }

  Widget _buildARButton() {
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: AppSizes.mediumPadding(context),
        vertical: AppSizes.smallSpacing(context),
      ),
      child: SizedBox(
        width: double.infinity,
        height: AppSizes.buttonHeight(context),
        child: ElevatedButton.icon(
          onPressed: widget.listing.images.isNotEmpty
              ? () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          ARVisualizationScreen(listing: widget.listing),
                    ),
                  );
                }
              : null,
          icon: Icon(Icons.view_in_ar, size: AppSizes.mediumIconSize(context)),
          label: Text(
            'Visualize in AR',
            style: TextStyle(
              fontSize: AppSizes.inputFontSize(context),
              fontWeight: FontWeight.bold,
            ),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.purple,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(
                AppSizes.inputBorderRadius(context),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDetailsSection() {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: AppSizes.mediumPadding(context)),
      padding: EdgeInsets.all(AppSizes.mediumPadding(context)),
      decoration: BoxDecoration(
        color: AppColors.backgroundColor,
        borderRadius: BorderRadius.circular(AppSizes.cardBorderRadius(context)),
        border: Border.all(color: AppColors.shadeColor.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.description,
                color: AppColors.primary,
                size: AppSizes.mediumIconSize(context),
              ),
              SizedBox(width: AppSizes.smallSpacing(context)),
              Text(
                'Description',
                style: TextStyle(
                  color: AppColors.titleColor,
                  fontSize: AppSizes.subtitleFontSize(context),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          SizedBox(height: AppSizes.mediumSpacing(context)),
          Text(
            widget.listing.description,
            style: TextStyle(
              color: AppColors.foregroundColor,
              fontSize: AppSizes.bodyFontSize(context),
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSpecificationsSection() {
    return Container(
      margin: EdgeInsets.all(AppSizes.mediumPadding(context)),
      padding: EdgeInsets.all(AppSizes.mediumPadding(context)),
      decoration: BoxDecoration(
        color: AppColors.backgroundColor,
        borderRadius: BorderRadius.circular(AppSizes.cardBorderRadius(context)),
        border: Border.all(color: AppColors.shadeColor.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.featured_play_list,
                color: AppColors.primary,
                size: AppSizes.mediumIconSize(context),
              ),
              SizedBox(width: AppSizes.smallSpacing(context)),
              Text(
                'Specifications',
                style: TextStyle(
                  color: AppColors.titleColor,
                  fontSize: AppSizes.subtitleFontSize(context),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
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
        ],
      ),
    );
  }

  Widget _buildSpecItem(String label, String value) {
    return Padding(
      padding: EdgeInsets.only(bottom: AppSizes.mediumSpacing(context)),
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
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSellerSection() {
    if (widget.listing.seller == null) return const SizedBox.shrink();

    return Container(
      margin: EdgeInsets.symmetric(horizontal: AppSizes.mediumPadding(context)),
      padding: EdgeInsets.all(AppSizes.mediumPadding(context)),
      decoration: BoxDecoration(
        color: AppColors.backgroundColor,
        borderRadius: BorderRadius.circular(AppSizes.cardBorderRadius(context)),
        border: Border.all(color: AppColors.shadeColor.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.person,
                color: AppColors.primary,
                size: AppSizes.mediumIconSize(context),
              ),
              SizedBox(width: AppSizes.smallSpacing(context)),
              Text(
                'Seller Information',
                style: TextStyle(
                  color: AppColors.titleColor,
                  fontSize: AppSizes.subtitleFontSize(context),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          SizedBox(height: AppSizes.mediumSpacing(context)),
          Row(
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
        ],
      ),
    );
  }

  Widget _buildReviewsSection() {
    return Container(
      margin: EdgeInsets.all(AppSizes.mediumPadding(context)),
      padding: EdgeInsets.all(AppSizes.mediumPadding(context)),
      decoration: BoxDecoration(
        color: AppColors.backgroundColor,
        borderRadius: BorderRadius.circular(AppSizes.cardBorderRadius(context)),
        border: Border.all(color: AppColors.shadeColor.withOpacity(0.2)),
      ),
      child: Consumer<MarketplaceController>(
        builder: (context, controller, _) {
          final listingId = widget.listing.id ?? '';
          final reviews = controller.getReviews(listingId);
          final avg = controller.getAverageRating(listingId);
          final isOwner = widget.listing.seller?.id == _currentUserId;

          // Check if current user has reviewed
          final userReview = reviews.firstWhere(
            (r) => r['userId'] == _currentUserId,
            orElse: () => <String, dynamic>{},
          );
          final hasUserReviewed = userReview.isNotEmpty;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.star,
                    color: Colors.amber,
                    size: AppSizes.mediumIconSize(context),
                  ),
                  SizedBox(width: AppSizes.smallSpacing(context)),
                  Flexible(
                    child: Text(
                      'Reviews & Ratings',
                      style: TextStyle(
                        color: AppColors.titleColor,
                        fontSize: AppSizes.subtitleFontSize(context),
                        fontWeight: FontWeight.bold,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  SizedBox(width: AppSizes.smallSpacing(context)),
                  _Stars(rating: avg),
                  SizedBox(width: 6),
                  Text(
                    avg.toStringAsFixed(1),
                    style: TextStyle(
                      color: AppColors.shadeColor,
                      fontWeight: FontWeight.w600,
                      fontSize: AppSizes.bodyFontSize(context),
                    ),
                  ),
                ],
              ),
              SizedBox(height: AppSizes.mediumSpacing(context)),
              // Only show add/edit review if user is not the owner
              if (!isOwner)
                _AddOrEditReview(
                  listingId: listingId,
                  existingReview: hasUserReviewed ? userReview : null,
                  currentUserId: _currentUserId,
                ),
              if (reviews.isNotEmpty) ...[
                SizedBox(height: AppSizes.mediumSpacing(context)),
                Divider(color: AppColors.shadeColor.withOpacity(0.2)),
                SizedBox(height: AppSizes.smallSpacing(context)),
                ...reviews.map((r) {
                  final isUserReview = r['userId'] == _currentUserId;
                  return Padding(
                    padding: EdgeInsets.only(
                      bottom: AppSizes.mediumSpacing(context),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            _Stars(rating: (r['rating'] as num).toDouble()),
                            SizedBox(width: AppSizes.smallSpacing(context)),
                            Flexible(
                              child: Text(
                                r['createdAt'],
                                style: TextStyle(
                                  color: AppColors.shadeColor,
                                  fontSize: AppSizes.smallFontSize(context),
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (isUserReview) ...[
                              SizedBox(width: AppSizes.smallSpacing(context)),
                              Container(
                                padding: EdgeInsets.symmetric(
                                  horizontal: AppSizes.smallPadding(context),
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.primary.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  'You',
                                  style: TextStyle(
                                    color: AppColors.primary,
                                    fontSize: AppSizes.smallFontSize(context),
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                        if ((r['review'] as String?)?.isNotEmpty == true) ...[
                          SizedBox(height: AppSizes.smallSpacing(context) / 2),
                          Text(
                            r['review'],
                            style: TextStyle(
                              color: AppColors.foregroundColor,
                              fontSize: AppSizes.bodyFontSize(context),
                            ),
                            softWrap: true,
                          ),
                        ],
                      ],
                    ),
                  );
                }),
              ],
            ],
          );
        },
      ),
    );
  }

  Widget _buildBidsSection() {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: AppSizes.mediumPadding(context)),
      padding: EdgeInsets.all(AppSizes.mediumPadding(context)),
      decoration: BoxDecoration(
        color: AppColors.backgroundColor,
        borderRadius: BorderRadius.circular(AppSizes.cardBorderRadius(context)),
        border: Border.all(color: AppColors.shadeColor.withOpacity(0.2)),
      ),
      child: Consumer<MarketplaceController>(
        builder: (context, controller, _) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.gavel,
                    color: AppColors.primary,
                    size: AppSizes.mediumIconSize(context),
                  ),
                  SizedBox(width: AppSizes.smallSpacing(context)),
                  Text(
                    'Auction Bids',
                    style: TextStyle(
                      color: AppColors.titleColor,
                      fontSize: AppSizes.subtitleFontSize(context),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Spacer(),
                  Text(
                    '${controller.bids.length} bids',
                    style: TextStyle(
                      color: AppColors.shadeColor,
                      fontSize: AppSizes.bodyFontSize(context),
                    ),
                  ),
                ],
              ),
              SizedBox(height: AppSizes.mediumSpacing(context)),
              if (controller.bids.isEmpty)
                Center(
                  child: Padding(
                    padding: EdgeInsets.all(AppSizes.mediumPadding(context)),
                    child: Text(
                      'No bids yet. Be the first to bid!',
                      style: TextStyle(
                        color: AppColors.shadeColor,
                        fontSize: AppSizes.bodyFontSize(context),
                      ),
                    ),
                  ),
                )
              else
                ...controller.bids.map(
                  (bid) => Container(
                    margin: EdgeInsets.only(
                      bottom: AppSizes.mediumSpacing(context),
                    ),
                    padding: EdgeInsets.all(AppSizes.mediumPadding(context)),
                    decoration: BoxDecoration(
                      color: bid.isWinning
                          ? AppColors.primary.withOpacity(0.1)
                          : AppColors.shadeColor.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(
                        AppSizes.cardBorderRadius(context),
                      ),
                      border: Border.all(
                        color: bid.isWinning
                            ? AppColors.primary
                            : AppColors.shadeColor.withOpacity(0.2),
                        width: bid.isWinning ? 2 : 1,
                      ),
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
                              Container(
                                padding: EdgeInsets.symmetric(
                                  horizontal: AppSizes.smallPadding(context),
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.primary,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  'Winning',
                                  style: TextStyle(
                                    color: AppColors.titleColor,
                                    fontSize: AppSizes.smallFontSize(context),
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

class _Stars extends StatelessWidget {
  final double rating;
  const _Stars({required this.rating});

  @override
  Widget build(BuildContext context) {
    final full = rating.floor();
    final half = (rating - full) >= 0.5;
    final starSize = AppSizes.smallIconSize(context);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (i) {
        if (i < full)
          return Icon(Icons.star, color: Colors.amber, size: starSize);
        if (i == full && half)
          return Icon(Icons.star_half, color: Colors.amber, size: starSize);
        return Icon(Icons.star_border, color: Colors.amber, size: starSize);
      }),
    );
  }
}

class _AddOrEditReview extends StatefulWidget {
  final String listingId;
  final Map<String, dynamic>? existingReview;
  final String? currentUserId;

  const _AddOrEditReview({
    required this.listingId,
    this.existingReview,
    this.currentUserId,
  });

  @override
  State<_AddOrEditReview> createState() => _AddOrEditReviewState();
}

class _AddOrEditReviewState extends State<_AddOrEditReview> {
  late double _rating;
  late TextEditingController _controller;
  bool _isEditing = false;
  bool _showForm = true;

  @override
  void initState() {
    super.initState();
    _rating = widget.existingReview?['rating']?.toDouble() ?? 0.0;
    _controller = TextEditingController(
      text: widget.existingReview?['review'] ?? '',
    );
    _isEditing = widget.existingReview != null;
    _showForm =
        widget.existingReview == null; // Hide form if user already reviewed
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    AppColors.getBackgroundColor(context);

    // If user has reviewed and form is hidden, show edit button
    if (_isEditing && !_showForm) {
      return Container(
        padding: EdgeInsets.all(AppSizes.mediumPadding(context)),
        decoration: BoxDecoration(
          color: AppColors.primary.withOpacity(0.05),
          borderRadius: BorderRadius.circular(
            AppSizes.cardBorderRadius(context),
          ),
          border: Border.all(color: AppColors.primary.withOpacity(0.3)),
        ),
        child: Row(
          children: [
            Icon(
              Icons.edit,
              color: AppColors.primary,
              size: AppSizes.mediumIconSize(context),
            ),
            SizedBox(width: AppSizes.smallSpacing(context)),
            Expanded(
              child: Text(
                'You have already reviewed this item',
                style: TextStyle(
                  color: AppColors.foregroundColor,
                  fontSize: AppSizes.bodyFontSize(context),
                ),
              ),
            ),
            TextButton(
              onPressed: () => setState(() => _showForm = true),
              child: Text(
                'Edit Review',
                style: TextStyle(
                  color: AppColors.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: EdgeInsets.all(AppSizes.mediumPadding(context)),
      decoration: BoxDecoration(
        color: AppColors.shadeColor.withOpacity(0.05),
        borderRadius: BorderRadius.circular(AppSizes.cardBorderRadius(context)),
        border: Border.all(color: AppColors.shadeColor.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              Text(
                _isEditing ? 'Your Rating:' : 'Rate this item:',
                style: TextStyle(
                  color: AppColors.foregroundColor,
                  fontSize: AppSizes.bodyFontSize(context),
                  fontWeight: FontWeight.w600,
                ),
              ),
              SizedBox(width: AppSizes.smallSpacing(context)),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: List.generate(5, (i) {
                  return IconButton(
                    padding: EdgeInsets.zero,
                    constraints: BoxConstraints(
                      minWidth: AppSizes.mediumIconSize(context),
                      minHeight: AppSizes.mediumIconSize(context),
                    ),
                    icon: Icon(
                      i < _rating ? Icons.star : Icons.star_border,
                      color: Colors.amber,
                      size: AppSizes.mediumIconSize(context),
                    ),
                    onPressed: () =>
                        setState(() => _rating = (i + 1).toDouble()),
                  );
                }),
              ),
            ],
          ),
          SizedBox(height: AppSizes.smallSpacing(context)),
          TextField(
            controller: _controller,
            maxLines: 3,
            decoration: InputDecoration(
              hintText: 'Write your review (optional)',
              hintStyle: TextStyle(color: AppColors.shadeColor),
              filled: true,
              fillColor: AppColors.backgroundColor,
              enabledBorder: OutlineInputBorder(
                borderSide: BorderSide(
                  color: AppColors.shadeColor.withOpacity(0.3),
                ),
                borderRadius: BorderRadius.circular(
                  AppSizes.inputBorderRadius(context),
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderSide: BorderSide(color: AppColors.primary),
                borderRadius: BorderRadius.circular(
                  AppSizes.inputBorderRadius(context),
                ),
              ),
            ),
            style: TextStyle(color: AppColors.foregroundColor),
          ),
          SizedBox(height: AppSizes.smallSpacing(context)),
          Align(
            alignment: Alignment.centerRight,
            child: ElevatedButton(
              onPressed: _rating == 0
                  ? null
                  : () async {
                      final controller = Provider.of<MarketplaceController>(
                        context,
                        listen: false,
                      );

                      // Show loading
                      showDialog(
                        context: context,
                        barrierDismissible: false,
                        builder: (context) =>
                            const Center(child: CircularProgressIndicator()),
                      );

                      final success = await controller.addOrUpdateReview(
                        widget.listingId,
                        rating: _rating,
                        review: _controller.text.trim(),
                      );

                      // Close loading dialog
                      if (mounted) Navigator.pop(context);

                      if (success) {
                        if (mounted) {
                          CustomSnackbars.showSuccessSnackbar(
                            context,
                            _isEditing ? 'Review updated' : 'Review submitted',
                            1.5,
                          );
                          setState(() {
                            if (!_isEditing) {
                              _rating = 0;
                              _controller.clear();
                            }
                            _isEditing = true;
                            _showForm = false; // Hide form after submission
                          });
                        }
                      } else {
                        if (mounted) {
                          CustomSnackbars.showErrorSnackbar(
                            context,
                            'Failed to submit review',
                          );
                        }
                      }
                    },
              style: CustomWidgets.elevatedButtonStyle(context),
              child: Text(
                _isEditing ? 'Update Review' : 'Submit Review',
                style: TextStyle(color: AppColors.titleColor),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
