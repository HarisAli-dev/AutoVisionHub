import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:front/controller/marketplace/marketplace_controller.dart';
import 'package:front/view/community_member/marketplace/create_listing_screen.dart';
import 'package:front/view/community_member/marketplace/all_listings_tab.dart';
import 'package:front/view/community_member/marketplace/my_listings_tab.dart';
import 'package:front/view/community_member/marketplace/favorites_tab.dart';
import 'package:front/utils/app_colors.dart';
import 'package:front/utils/sizes.dart';
import 'package:front/utils/custom_widgets.dart';

enum MarketplaceView { all, myListings, favorites }

class MarketplaceHomeScreen extends StatefulWidget {
  const MarketplaceHomeScreen({super.key});

  @override
  State<MarketplaceHomeScreen> createState() => _MarketplaceHomeScreenState();
}

class _MarketplaceHomeScreenState extends State<MarketplaceHomeScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  MarketplaceView _currentView = MarketplaceView.all;
  String _selectedCategory = 'All';
  String _selectedCondition = 'All';
  String _selectedSortBy = 'newest';
  double _minPrice = 0;
  double _maxPrice = 10000000;
  String _selectedLocation = 'All';
  bool _auctionOnly = false;
  bool _negotiableOnly = false;

  int _currentPage = 1;
  final List<String> _categories = ['All', 'Vehicles', 'Parts', 'Accessories'];
  final List<String> _conditions = ['All', 'Excellent', 'Good', 'Fair', 'Poor'];
  final List<String> _locations = [
    'All',
    'Karachi',
    'Lahore',
    'Islamabad',
    'Rawalpindi',
    'Faisalabad',
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(_onTabChanged);
    _scrollController.addListener(_onScroll);
    _loadCurrentViewData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onTabChanged() {
    if (!_tabController.indexIsChanging) {
      final newView = MarketplaceView.values[_tabController.index];
      if (newView != _currentView) {
        setState(() {
          _currentView = newView;
          _currentPage = 1;
        });
        _loadCurrentViewData(refresh: true);
      }
    }
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

    switch (_currentView) {
      case MarketplaceView.all:
        await controller.getListings(
          page: _currentPage,
          refresh: refresh,
          category: _selectedCategory != 'All' ? _selectedCategory : null,
          condition: _selectedCondition != 'All' ? _selectedCondition : null,
          minPrice: _minPrice > 0 ? _minPrice : null,
          maxPrice: _maxPrice < 10000000 ? _maxPrice : null,
          location: _selectedLocation != 'All' ? _selectedLocation : null,
          search: _searchController.text.isNotEmpty
              ? _searchController.text
              : null,
          sortBy: _selectedSortBy,
          isAuction: _auctionOnly ? true : null,
          isNegotiable: _negotiableOnly ? true : null,
        );
        break;
      case MarketplaceView.myListings:
        await controller.getMyListings(page: _currentPage, refresh: refresh);
        break;
      case MarketplaceView.favorites:
        await controller.getFavoriteListings(
          page: _currentPage,
          refresh: refresh,
        );
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

  void _showFilterDialog() {
    showDialog(
      context: context,
      builder: (context) => _FilterDialog(
        searchController: _searchController,
        selectedCategory: _selectedCategory,
        selectedCondition: _selectedCondition,
        selectedSortBy: _selectedSortBy,
        minPrice: _minPrice,
        maxPrice: _maxPrice,
        selectedLocation: _selectedLocation,
        auctionOnly: _auctionOnly,
        negotiableOnly: _negotiableOnly,
        categories: _categories,
        conditions: _conditions,
        locations: _locations,
        onApply: (filters) {
          setState(() {
            _searchController.text = filters['search'] ?? '';
            _selectedCategory = filters['category'];
            _selectedCondition = filters['condition'];
            _selectedSortBy = filters['sortBy'];
            _minPrice = filters['minPrice'];
            _maxPrice = filters['maxPrice'];
            _selectedLocation = filters['location'];
            _auctionOnly = filters['auctionOnly'];
            _negotiableOnly = filters['negotiableOnly'];
          });
          _refreshData();
        },
        onClear: () {
          setState(() {
            _searchController.clear();
            _selectedCategory = 'All';
            _selectedCondition = 'All';
            _selectedSortBy = 'newest';
            _minPrice = 0;
            _maxPrice = 10000000;
            _selectedLocation = 'All';
            _auctionOnly = false;
            _negotiableOnly = false;
          });
          _refreshData();
        },
      ),
    );
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
          'Marketplace',
          style: TextStyle(
            color: AppColors.primary,
            fontSize: AppSizes.titleFontSize(context),
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          // Filter button
          IconButton(
            icon: Icon(Icons.filter_list, color: AppColors.foregroundColor),
            onPressed: _showFilterDialog,
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppColors.primary,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.shadeColor,
          labelStyle: TextStyle(
            fontSize: AppSizes.inputFontSize(context),
            fontWeight: FontWeight.bold,
          ),
          unselectedLabelStyle: TextStyle(
            fontSize: AppSizes.inputFontSize(context),
            fontWeight: FontWeight.normal,
          ),
          tabs: [
            Tab(
              icon: Icon(Icons.storefront),
              text: 'All Items',
            ),
            Tab(
              icon: Icon(Icons.inventory_2),
              text: 'My Listings',
            ),
            Tab(
              icon: Icon(Icons.favorite),
              text: 'Favorites',
            ),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
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
        ],
      ),
      floatingActionButton: _currentView == MarketplaceView.myListings
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
}

class _FilterDialog extends StatefulWidget {
  final TextEditingController searchController;
  final String selectedCategory;
  final String selectedCondition;
  final String selectedSortBy;
  final double minPrice;
  final double maxPrice;
  final String selectedLocation;
  final bool auctionOnly;
  final bool negotiableOnly;
  final List<String> categories;
  final List<String> conditions;
  final List<String> locations;
  final Function(Map<String, dynamic>) onApply;
  final VoidCallback onClear;

  const _FilterDialog({
    required this.searchController,
    required this.selectedCategory,
    required this.selectedCondition,
    required this.selectedSortBy,
    required this.minPrice,
    required this.maxPrice,
    required this.selectedLocation,
    required this.auctionOnly,
    required this.negotiableOnly,
    required this.categories,
    required this.conditions,
    required this.locations,
    required this.onApply,
    required this.onClear,
  });

  @override
  State<_FilterDialog> createState() => _FilterDialogState();
}

class _FilterDialogState extends State<_FilterDialog> {
  late TextEditingController _searchController;
  late String _selectedCategory;
  late String _selectedCondition;
  late String _selectedSortBy;
  late double _minPrice;
  late double _maxPrice;
  late String _selectedLocation;
  late bool _auctionOnly;
  late bool _negotiableOnly;

  final List<String> _sortOptions = [
    'newest',
    'oldest',
    'price_low',
    'price_high',
    'most_viewed',
  ];

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController(
      text: widget.searchController.text,
    );
    _selectedCategory = widget.selectedCategory;
    _selectedCondition = widget.selectedCondition;
    _selectedSortBy = widget.selectedSortBy;
    _minPrice = widget.minPrice;
    _maxPrice = widget.maxPrice;
    _selectedLocation = widget.selectedLocation;
    _auctionOnly = widget.auctionOnly;
    _negotiableOnly = widget.negotiableOnly;
  }

  @override
  Widget build(BuildContext context) {
    // Initialize theme colors
    AppColors.getBackgroundColor(context);

    return Dialog(
      backgroundColor: AppColors.backgroundColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSizes.cardBorderRadius(context)),
      ),
      child: Container(
        constraints: BoxConstraints(
          maxHeight: AppSizes.getScreenHeight(context) * 0.8,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              padding: EdgeInsets.all(AppSizes.mediumPadding(context)),
              decoration: BoxDecoration(
                color: AppColors.shadeColor.withOpacity(0.1),
                borderRadius: BorderRadius.vertical(
                  top: Radius.circular(AppSizes.cardBorderRadius(context)),
                ),
              ),
              child: Row(
                children: [
                  Text(
                    'Filters',
                    style: TextStyle(
                      color: AppColors.primary,
                      fontSize: AppSizes.titleFontSize(context),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  TextButton(
                    onPressed: () {
                      widget.onClear();
                      Navigator.pop(context);
                    },
                    child: Text(
                      'Clear',
                      style: TextStyle(color: AppColors.primary),
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.close, color: AppColors.foregroundColor),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            // Content
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.all(AppSizes.mediumPadding(context)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Search Bar
                    CustomWidgets.customTextFormField(
                      controller: _searchController,
                      label: 'Search vehicles, parts...',
                      borderColor: AppColors.primary,
                      textColor: AppColors.foregroundColor,
                      fontsize: AppSizes.inputFontSize(context),
                    ),
                    SizedBox(height: AppSizes.largeSpacing(context)),
                    // Category Filter
                    _buildSectionTitle('Category'),
                    SizedBox(height: AppSizes.mediumSpacing(context)),
                    _buildChipFilter(widget.categories, _selectedCategory, (
                      value,
                    ) {
                      setState(() => _selectedCategory = value);
                    }),
                    SizedBox(height: AppSizes.largeSpacing(context)),
                    // Condition Filter
                    _buildSectionTitle('Condition'),
                    SizedBox(height: AppSizes.mediumSpacing(context)),
                    _buildChipFilter(widget.conditions, _selectedCondition, (
                      value,
                    ) {
                      setState(() => _selectedCondition = value);
                    }),
                    SizedBox(height: AppSizes.largeSpacing(context)),
                    // Price Range
                    _buildSectionTitle('Price Range'),
                    SizedBox(height: AppSizes.mediumSpacing(context)),
                    Container(
                      padding: EdgeInsets.all(AppSizes.mediumPadding(context)),
                      decoration: BoxDecoration(
                        color: AppColors.shadeColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(
                          AppSizes.cardBorderRadius(context),
                        ),
                      ),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'PKR ${_minPrice.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')}',
                                style: TextStyle(
                                  color: AppColors.titleColor,
                                  fontSize: AppSizes.bodyFontSize(context),
                                ),
                              ),
                              Text(
                                'PKR ${_maxPrice.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')}',
                                style: TextStyle(
                                  color: AppColors.titleColor,
                                  fontSize: AppSizes.bodyFontSize(context),
                                ),
                              ),
                            ],
                          ),
                          RangeSlider(
                            values: RangeValues(_minPrice, _maxPrice),
                            min: 0,
                            max: 10000000,
                            divisions: 100,
                            activeColor: AppColors.primary,
                            onChanged: (values) {
                              setState(() {
                                _minPrice = values.start;
                                _maxPrice = values.end;
                              });
                            },
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: AppSizes.largeSpacing(context)),
                    // Location Filter
                    _buildSectionTitle('Location'),
                    SizedBox(height: AppSizes.mediumSpacing(context)),
                    _buildChipFilter(widget.locations, _selectedLocation, (
                      value,
                    ) {
                      setState(() => _selectedLocation = value);
                    }),
                    SizedBox(height: AppSizes.largeSpacing(context)),
                    // Sort By
                    _buildSectionTitle('Sort By'),
                    SizedBox(height: AppSizes.mediumSpacing(context)),
                    Container(
                      padding: EdgeInsets.all(AppSizes.smallPadding(context)),
                      decoration: BoxDecoration(
                        color: AppColors.shadeColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(
                          AppSizes.cardBorderRadius(context),
                        ),
                      ),
                      child: Column(
                        children: _sortOptions.map((option) {
                          return RadioListTile<String>(
                            title: Text(
                              _getSortDisplayName(option),
                              style: TextStyle(
                                color: AppColors.titleColor,
                                fontSize: AppSizes.bodyFontSize(context),
                              ),
                            ),
                            value: option,
                            groupValue: _selectedSortBy,
                            onChanged: (value) {
                              setState(() => _selectedSortBy = value!);
                            },
                            activeColor: AppColors.primary,
                            contentPadding: EdgeInsets.zero,
                          );
                        }).toList(),
                      ),
                    ),
                    SizedBox(height: AppSizes.largeSpacing(context)),
                    // Additional Filters
                    _buildSectionTitle('Additional Filters'),
                    SizedBox(height: AppSizes.mediumSpacing(context)),
                    Container(
                      decoration: BoxDecoration(
                        color: AppColors.shadeColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(
                          AppSizes.cardBorderRadius(context),
                        ),
                      ),
                      child: Column(
                        children: [
                          SwitchListTile(
                            title: Text(
                              'Auction Only',
                              style: TextStyle(
                                color: AppColors.titleColor,
                                fontSize: AppSizes.bodyFontSize(context),
                              ),
                            ),
                            value: _auctionOnly,
                            onChanged: (value) =>
                                setState(() => _auctionOnly = value),
                            activeColor: AppColors.primary,
                          ),
                          SwitchListTile(
                            title: Text(
                              'Negotiable Only',
                              style: TextStyle(
                                color: AppColors.titleColor,
                                fontSize: AppSizes.bodyFontSize(context),
                              ),
                            ),
                            value: _negotiableOnly,
                            onChanged: (value) =>
                                setState(() => _negotiableOnly = value),
                            activeColor: AppColors.primary,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // Apply button
            Container(
              padding: EdgeInsets.all(AppSizes.mediumPadding(context)),
              decoration: BoxDecoration(
                color: AppColors.shadeColor.withOpacity(0.1),
                borderRadius: BorderRadius.vertical(
                  bottom: Radius.circular(AppSizes.cardBorderRadius(context)),
                ),
              ),
              child: SizedBox(
                width: double.infinity,
                height: AppSizes.buttonHeight(context),
                child: ElevatedButton(
                  onPressed: () {
                    widget.onApply({
                      'search': _searchController.text,
                      'category': _selectedCategory,
                      'condition': _selectedCondition,
                      'sortBy': _selectedSortBy,
                      'minPrice': _minPrice,
                      'maxPrice': _maxPrice,
                      'location': _selectedLocation,
                      'auctionOnly': _auctionOnly,
                      'negotiableOnly': _negotiableOnly,
                    });
                    Navigator.pop(context);
                  },
                  style: CustomWidgets.elevatedButtonStyle(context),
                  child: Text(
                    'Apply Filters',
                    style: TextStyle(
                      color: AppColors.titleColor,
                      fontSize: AppSizes.inputFontSize(context),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: TextStyle(
        color: AppColors.titleColor,
        fontSize: AppSizes.inputFontSize(context),
        fontWeight: FontWeight.bold,
      ),
    );
  }

  Widget _buildChipFilter(
    List<String> options,
    String selected,
    Function(String) onChanged,
  ) {
    return Wrap(
      spacing: AppSizes.smallSpacing(context),
      runSpacing: AppSizes.smallSpacing(context),
      children: options.map((option) {
        final isSelected = option == selected;
        return GestureDetector(
          onTap: () => onChanged(option),
          child: Container(
            padding: EdgeInsets.symmetric(
              horizontal: AppSizes.mediumPadding(context),
              vertical: AppSizes.smallPadding(context) / 2,
            ),
            decoration: BoxDecoration(
              color: isSelected ? AppColors.primary : AppColors.backgroundColor,
              borderRadius: BorderRadius.circular(
                AppSizes.cardBorderRadius(context),
              ),
              border: isSelected
                  ? null
                  : Border.all(color: AppColors.shadeColor),
            ),
            child: Text(
              option,
              style: TextStyle(
                color: isSelected ? AppColors.titleColor : AppColors.shadeColor,
                fontSize: AppSizes.smallFontSize(context),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  String _getSortDisplayName(String option) {
    switch (option) {
      case 'newest':
        return 'Newest First';
      case 'oldest':
        return 'Oldest First';
      case 'price_low':
        return 'Price: Low to High';
      case 'price_high':
        return 'Price: High to Low';
      case 'most_viewed':
        return 'Most Viewed';
      default:
        return option;
    }
  }
}
