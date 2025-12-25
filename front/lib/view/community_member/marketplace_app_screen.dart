import 'package:flutter/material.dart';
import 'package:front/utils/app_colors.dart';
import 'package:front/utils/sizes.dart';
import 'package:front/view/community_member/marketplace/all_listings_tab.dart';
import 'package:front/view/community_member/marketplace/my_listings_tab.dart';
import 'package:front/view/community_member/marketplace/favorites_tab.dart';
import 'package:front/view/community_member/marketplace/recently_viewed_tab.dart';
import 'package:front/view/community_member/marketplace/create_listing_screen.dart';
import 'package:front/controller/marketplace/marketplace_controller.dart';
import 'package:front/utils/custom_widgets.dart';
import 'package:provider/provider.dart';

class MarketplaceAppScreen extends StatefulWidget {
  const MarketplaceAppScreen({super.key});

  @override
  State<MarketplaceAppScreen> createState() => _MarketplaceAppScreenState();
}

class _MarketplaceAppScreenState extends State<MarketplaceAppScreen> {
  int _currentIndex = 0;
  final ScrollController _scrollController = ScrollController();

  final List<String> _titles = [
    'All Listings',
    'My Listings',
    'Favorites',
    'Recent Views',
  ];

  int _currentPage = 1;
  bool _initialLoadDone = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    // Schedule load for after the widget is built
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_initialLoadDone && mounted) {
        _initialLoadDone = true;
        _loadCurrentViewData(refresh: true);
      }
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Ensure data loads if not already loaded
    if (!_initialLoadDone) {
      _initialLoadDone = true;
      Future.microtask(() => _loadCurrentViewData(refresh: true));
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels ==
        _scrollController.position.maxScrollExtent) {
      _loadMoreData();
    }
  }

  Future<void> _loadCurrentViewData({bool refresh = false}) async {
    final controller = Provider.of<MarketplaceController>(
      context,
      listen: false,
    );

    if (refresh) {
      _currentPage = 1;
    }

    // Load favorites in the background to check favorite status on listings
    if (_currentIndex == 0 && controller.favoriteListings.isEmpty) {
      controller.getFavoriteListings(page: 1, refresh: false);
    }

    switch (_currentIndex) {
      case 0:
        await controller.getListings(page: _currentPage, refresh: refresh);
        break;
      case 1:
        await controller.getMyListings(page: _currentPage, refresh: refresh);
        break;
      case 2:
        await controller.getFavoriteListings(
          page: _currentPage,
          refresh: refresh,
        );
        break;
      case 3:
        await controller.getRecentlyViewedItems(limit: 20, refresh: refresh);
        break;
    }
  }

  Future<void> _loadMoreData() async {
    _currentPage++;
    await _loadCurrentViewData();
  }

  Future<void> _refreshData() async {
    await _loadCurrentViewData(refresh: true);
  }

  @override
  Widget build(BuildContext context) {
    AppColors.getBackgroundColor(context);

    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      appBar: AppBar(
        backgroundColor: AppColors.backgroundColor,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: Text(
          _titles[_currentIndex],
          style: TextStyle(
            color: AppColors.titleColor,
            fontSize: AppSizes.titleFontSize(context),
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          // Cart Icon
          Consumer<MarketplaceController>(
            builder: (context, controller, _) => Stack(
              alignment: Alignment.topRight,
              children: [
                IconButton(
                  icon: Icon(
                    Icons.shopping_cart_outlined,
                    color: AppColors.foregroundColor,
                  ),
                  onPressed: () => _showCartSheet(context),
                ),
                if (controller.totalCartItems > 0)
                  Positioned(
                    right: 8,
                    top: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        controller.totalCartItems.toString(),
                        style: TextStyle(
                          color: AppColors.titleColor,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
      body: IndexedStack(
        index: _currentIndex,
        children: [
          AllListingsTab(
            scrollController: _scrollController,
            onLoadMore: _loadMoreData,
            onRefresh: _refreshData,
          ),
          MyListingsTab(
            scrollController: _scrollController,
            onLoadMore: _loadMoreData,
            onRefresh: _refreshData,
          ),
          FavoritesTab(
            scrollController: _scrollController,
            onLoadMore: _loadMoreData,
            onRefresh: _refreshData,
          ),
          RecentlyViewedTab(
            scrollController: _scrollController,
            onLoadMore: _loadMoreData,
            onRefresh: _refreshData,
          ),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: AppColors.backgroundColor,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: AppColors.shadeColor,
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
            _currentPage = 1;
          });
          _loadCurrentViewData(refresh: true);
        },
        type: BottomNavigationBarType.fixed,
        elevation: 8,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.storefront_outlined),
            activeIcon: Icon(Icons.storefront),
            label: 'All Items',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.inventory_2_outlined),
            activeIcon: Icon(Icons.inventory_2),
            label: 'My Listings',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.favorite_outline),
            activeIcon: Icon(Icons.favorite),
            label: 'Favorites',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.history),
            activeIcon: Icon(Icons.history),
            label: 'Recent',
          ),
        ],
      ),
      floatingActionButton: _currentIndex == 1
          ? FloatingActionButton.extended(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const CreateListingScreen(),
                  ),
                ).then((_) => _refreshData());
              },
              backgroundColor: AppColors.primary,
              icon: Icon(Icons.add, color: AppColors.titleColor),
              label: Text(
                'Add Listing',
                style: TextStyle(color: AppColors.titleColor),
              ),
            )
          : null,
    );
  }

  void _showCartSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.backgroundColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppSizes.cardBorderRadius(context)),
        ),
      ),
      builder: (ctx) {
        return Consumer<MarketplaceController>(
          builder: (context, controller, child) {
            return Padding(
              padding: EdgeInsets.only(
                left: AppSizes.mediumPadding(context),
                right: AppSizes.mediumPadding(context),
                top: AppSizes.mediumPadding(context),
                bottom:
                    MediaQuery.of(context).viewInsets.bottom +
                    AppSizes.mediumPadding(context),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Text(
                        'Your Cart',
                        style: TextStyle(
                          color: AppColors.titleColor,
                          fontSize: AppSizes.subtitleFontSize(context),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Spacer(),
                      IconButton(
                        icon: Icon(
                          Icons.close,
                          color: AppColors.foregroundColor,
                        ),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                  SizedBox(height: AppSizes.smallSpacing(context)),
                  if (controller.cartItems.isEmpty)
                    Padding(
                      padding: EdgeInsets.symmetric(
                        vertical: AppSizes.largeSpacing(context),
                      ),
                      child: Text(
                        'Your cart is empty',
                        style: TextStyle(color: AppColors.shadeColor),
                      ),
                    )
                  else
                    Flexible(
                      child: ListView.builder(
                        shrinkWrap: true,
                        itemCount: controller.cartItems.length,
                        itemBuilder: (context, index) {
                          final item = controller.cartItems[index];
                          final qty = controller.getCartQuantity(item.id ?? '');
                          return Container(
                            margin: EdgeInsets.only(
                              bottom: AppSizes.smallSpacing(context),
                            ),
                            padding: EdgeInsets.all(
                              AppSizes.smallPadding(context),
                            ),
                            decoration: BoxDecoration(
                              border: Border.all(
                                color: AppColors.shadeColor.withOpacity(0.2),
                              ),
                              borderRadius: BorderRadius.circular(
                                AppSizes.inputBorderRadius(context),
                              ),
                            ),
                            child: Row(
                              children: [
                                if (item.images.isNotEmpty)
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: Image.network(
                                      item.images.first,
                                      width: 56,
                                      height: 56,
                                      fit: BoxFit.cover,
                                    ),
                                  )
                                else
                                  Icon(
                                    Icons.image,
                                    size: 40,
                                    color: AppColors.shadeColor,
                                  ),
                                SizedBox(
                                  width: AppSizes.mediumSpacing(context),
                                ),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        item.title,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          color: AppColors.titleColor,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      Text(
                                        'PKR ${item.price.toStringAsFixed(0)}',
                                        style: TextStyle(
                                          color: AppColors.primary,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Row(
                                  children: [
                                    IconButton(
                                      icon: Icon(
                                        Icons.remove,
                                        color: AppColors.foregroundColor,
                                      ),
                                      onPressed: () =>
                                          controller.updateCartQuantity(
                                            item.id ?? '',
                                            qty - 1,
                                          ),
                                    ),
                                    Text(
                                      qty.toString(),
                                      style: TextStyle(
                                        color: AppColors.titleColor,
                                      ),
                                    ),
                                    IconButton(
                                      icon: Icon(
                                        Icons.add,
                                        color: AppColors.foregroundColor,
                                      ),
                                      onPressed: () =>
                                          controller.updateCartQuantity(
                                            item.id ?? '',
                                            qty + 1,
                                          ),
                                    ),
                                  ],
                                ),
                                IconButton(
                                  icon: Icon(
                                    Icons.delete_outline,
                                    color: AppColors.errorColor,
                                  ),
                                  onPressed: () =>
                                      controller.removeFromCart(item.id ?? ''),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                  SizedBox(height: AppSizes.mediumSpacing(context)),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Total',
                        style: TextStyle(
                          color: AppColors.titleColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'PKR ${controller.cartTotalAmount.toStringAsFixed(0)}',
                        style: TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: AppSizes.mediumSpacing(context)),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: controller.cartItems.isEmpty
                          ? null
                          : () async {
                              final ok = await controller.completeOrder();
                              if (!context.mounted) return;
                              Navigator.pop(context);
                              showDialog(
                                context: context,
                                builder: (_) => AlertDialog(
                                  backgroundColor: AppColors.backgroundColor,
                                  title: Text(
                                    ok ? 'Order Successful' : 'Order Failed',
                                    style: TextStyle(
                                      color: AppColors.titleColor,
                                    ),
                                  ),
                                  content: Text(
                                    ok
                                        ? 'Your payment was initiated successfully.'
                                        : (controller.error ??
                                              'Something went wrong.'),
                                    style: TextStyle(
                                      color: AppColors.foregroundColor,
                                    ),
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.pop(context),
                                      child: Text(
                                        'OK',
                                        style: TextStyle(
                                          color: AppColors.primary,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                      style: CustomWidgets.elevatedButtonStyle(context),
                      child: Text(
                        'Complete Order',
                        style: TextStyle(color: AppColors.titleColor),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
