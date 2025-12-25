import 'package:flutter/material.dart';
import 'package:front/utils/app_colors.dart';
import 'package:front/utils/hive_utils.dart';
import 'package:front/utils/sizes.dart';
import 'package:front/controller/marketplace/marketplace_controller.dart';
import 'package:front/model/marketplace/listing_model.dart';
import 'package:front/view/dashboard/hooks/dashboard_recommendations_hook.dart';
import 'package:front/view/dashboard/widgets/header/dashboard_header.dart';
import 'package:front/view/dashboard/widgets/stats/quick_stats_section.dart';
import 'package:front/view/dashboard/widgets/role_highlights/role_highlights_section.dart';
import 'package:front/view/dashboard/widgets/recommendation_intro/recommendation_intro_section.dart';
import 'package:front/view/dashboard/widgets/quick_actions/quick_actions_section.dart';
import 'package:front/view/dashboard/widgets/tab_content/tab_switcher.dart';
import 'package:front/view/dashboard/widgets/tab_content/explore/explore_content.dart';
import 'package:front/view/dashboard/widgets/tab_content/community/community_content.dart';
import 'package:front/view/dashboard/widgets/tab_content/events/events_content.dart';
import 'package:front/view/dashboard/widgets/tab_content/marketplace/marketplace_content.dart';
import 'package:front/view/dashboard/screens/recommendations_detail_screen.dart';
import 'package:front/view/dashboard/screens/profile_completion_detail_screen.dart';
import 'package:front/view/dashboard/screens/live_streaming_detail_screen.dart';
import 'package:front/view/dashboard/screens/discussion_threads_detail_screen.dart';
import 'package:front/view/dashboard/screens/marketplace_alerts_detail_screen.dart';
import 'package:front/view/dashboard/screens/role_highlights_detail_screen.dart';
import 'package:provider/provider.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  static const int _marketplaceTabIndex = 3;
  final List<String> _tabs = ['Explore', 'Community', 'Events', 'Marketplace'];
  int _selectedTab = 0;
  List<ListingModel> _trendingListings = [];
  bool _isLoadingTrending = false;
  final ScrollController _scrollController = ScrollController();
  final GlobalKey _personalizedSectionKey = GlobalKey();
  final GlobalKey _recentSectionKey = GlobalKey();
  final GlobalKey _trendingSectionKey = GlobalKey();
  List<ListingModel> _recommendedVehicles = [];
  List<ListingModel> _recommendedParts = [];
  List<ListingModel> _recentlyViewedListings = [];
  List<String> _preferenceTags = [];
  bool _isLoadingRecommendations = false;
  String? _recommendationError;

  String get _role =>
      (HiveUtils.getData('role') as String? ?? 'guest').toLowerCase();

  String? get _userCity => HiveUtils.getData('city') as String?;
  String? get _token => HiveUtils.getData('token') as String?;
  bool get _isLoggedIn => (_token != null && _token!.isNotEmpty);

  @override
  void initState() {
    super.initState();
    _loadTrendingListings();
    _loadDashboardRecommendations();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadTrendingListings() async {
    final controller = Provider.of<MarketplaceController>(
      context,
      listen: false,
    );
    
    setState(() => _isLoadingTrending = true);
    
    try {
      // Fetch trending listings (sorted by popularity) in user's city
      await controller.getListings(
        page: 1,
        limit: 10,
        location: _userCity,
        sortBy: 'trending',
        refresh: true,
      );
      
      // Get the top 3-5 trending listings
      final listings = controller.listings;
      setState(() {
        _trendingListings = listings.take(5).toList();
        _isLoadingTrending = false;
      });
    } catch (e) {
      setState(() => _isLoadingTrending = false);
      debugPrint('Error loading trending listings: $e');
    }
  }

  Future<void> _loadDashboardRecommendations({bool silent = false}) async {
    if (!silent) {
      setState(() {
        _isLoadingRecommendations = true;
        _recommendationError = null;
      });
    }

    try {
      final payload = await DashboardRecommendationsHook.load(
        token: _token,
        city: _userCity,
      );

      setState(() {
        _recommendedVehicles = payload.vehicleListings;
        _recommendedParts = payload.partListings;
        _recentlyViewedListings = payload.recentlyViewed;
        _preferenceTags = payload.preferenceTags;
        _isLoadingRecommendations = false;
      });
    } catch (e) {
      setState(() {
        _recommendationError = 'Unable to load recommendations';
        _isLoadingRecommendations = false;
      });
      debugPrint('Error loading dashboard recommendations: $e');
    }
  }

  void _navigateToMarketplaceSignIn() {
    Navigator.pushNamed(
      context,
      '/signin',
      arguments: {'redirectCommunityTab': _marketplaceTabIndex},
    );
  }

  void _requireAuth(VoidCallback onAuthenticated) {
    if (!_isLoggedIn) {
      _navigateToMarketplaceSignIn();
      return;
    }
    onAuthenticated();
  }

  void _jumpToSection(GlobalKey targetKey) {
    setState(() => _selectedTab = 0);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final context = targetKey.currentContext;
      if (context != null) {
        Scrollable.ensureVisible(
          context,
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    AppColors.getBackgroundColor(context);
    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final double horizontalPadding =
                constraints.maxWidth > 900 ? 32 : 20;
            return SingleChildScrollView(
              controller: _scrollController,
              padding: EdgeInsets.symmetric(
                horizontal: horizontalPadding,
                vertical: AppSizes.mediumPadding(context),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const DashboardHeader(),
                  SizedBox(height: AppSizes.largeSpacing(context)),
                  QuickStatsSection(
                    onProfileCompletionTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const ProfileCompletionDetailScreen(),
                      ),
                    ),
                    onLiveStreamingTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const LiveStreamingDetailScreen(),
                      ),
                    ),
                    onDiscussionThreadsTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const DiscussionThreadsDetailScreen(),
                      ),
                    ),
                    onMarketplaceAlertsTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const MarketplaceAlertsDetailScreen(),
                      ),
                    ),
                  ),
                  SizedBox(height: AppSizes.mediumSpacing(context)),
                  RoleHighlightsSection(
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const RoleHighlightsDetailScreen(),
                      ),
                    ),
                  ),
                  SizedBox(height: AppSizes.mediumSpacing(context)),
                  RecommendationIntroSection(
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const RecommendationsDetailScreen(),
                      ),
                    ),
                  ),
                  SizedBox(height: AppSizes.largeSpacing(context)),
                  TabSwitcher(
                    tabs: _tabs,
                    selectedTab: _selectedTab,
                    onTabChanged: (index) {
                      setState(() => _selectedTab = index);
                    },
                  ),
                  SizedBox(height: AppSizes.mediumSpacing(context)),
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 350),
                    child: _buildTabContent(context, _selectedTab),
                  ),
                  SizedBox(height: AppSizes.largeSpacing(context)),
                  const QuickActionsSection(),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildTabContent(BuildContext context, int index) {
    switch (index) {
      case 0:
        return KeyedSubtree(
          key: const ValueKey('explore'),
          child: ExploreContent(
            recommendedVehicles: _recommendedVehicles,
            recommendedParts: _recommendedParts,
            recentlyViewedListings: _recentlyViewedListings,
            trendingListings: _trendingListings,
            preferenceTags: _preferenceTags,
            isLoadingRecommendations: _isLoadingRecommendations,
            isLoadingTrending: _isLoadingTrending,
            recommendationError: _recommendationError,
            userCity: _userCity,
            isLoggedIn: _isLoggedIn,
            onRefreshRecommendations: () => _loadDashboardRecommendations(),
            onNavigateToSignIn: _navigateToMarketplaceSignIn,
            requireAuth: _requireAuth,
          ),
        );
      case 1:
        return KeyedSubtree(
          key: const ValueKey('community'),
          child: const CommunityContent(),
        );
      case 2:
        return KeyedSubtree(
          key: const ValueKey('events'),
          child: const EventsContent(),
        );
      case 3:
      default:
        return KeyedSubtree(
          key: const ValueKey('marketplace'),
          child: const MarketplaceContent(),
        );
    }
  }
}
