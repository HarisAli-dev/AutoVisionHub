import 'package:flutter/material.dart';
import 'package:front/model/marketplace/listing_model.dart';
import 'package:front/utils/sizes.dart';
import 'package:front/view/dashboard/widgets/tab_content/explore/personalized_recommendations_section.dart';
import 'package:front/view/dashboard/widgets/tab_content/explore/recently_viewed_section.dart';
import 'package:front/view/dashboard/widgets/tab_content/explore/trending_section.dart';

class ExploreContent extends StatelessWidget {
  final List<ListingModel> recommendedVehicles;
  final List<ListingModel> recommendedParts;
  final List<ListingModel> recentlyViewedListings;
  final List<ListingModel> trendingListings;
  final List<String> preferenceTags;
  final bool isLoadingRecommendations;
  final bool isLoadingTrending;
  final String? recommendationError;
  final String? userCity;
  final bool isLoggedIn;
  final VoidCallback onRefreshRecommendations;
  final VoidCallback onNavigateToSignIn;
  final void Function(VoidCallback) requireAuth;

  const ExploreContent({
    super.key,
    required this.recommendedVehicles,
    required this.recommendedParts,
    required this.recentlyViewedListings,
    required this.trendingListings,
    required this.preferenceTags,
    required this.isLoadingRecommendations,
    required this.isLoadingTrending,
    this.recommendationError,
    this.userCity,
    required this.isLoggedIn,
    required this.onRefreshRecommendations,
    required this.onNavigateToSignIn,
    required this.requireAuth,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        PersonalizedRecommendationsSection(
          recommendedVehicles: recommendedVehicles,
          recommendedParts: recommendedParts,
          preferenceTags: preferenceTags,
          isLoading: isLoadingRecommendations,
          error: recommendationError,
          onRefresh: onRefreshRecommendations,
          onNavigateToSignIn: onNavigateToSignIn,
          isLoggedIn: isLoggedIn,
          requireAuth: requireAuth,
        ),
        SizedBox(height: AppSizes.largeSpacing(context)),
        RecentlyViewedSection(
          recentlyViewedListings: recentlyViewedListings,
          isLoggedIn: isLoggedIn,
          onNavigateToSignIn: onNavigateToSignIn,
          requireAuth: requireAuth,
        ),
        SizedBox(height: AppSizes.largeSpacing(context)),
        TrendingSection(
          trendingListings: trendingListings,
          isLoading: isLoadingTrending,
          userCity: userCity,
          requireAuth: requireAuth,
        ),
      ],
    );
  }
}

