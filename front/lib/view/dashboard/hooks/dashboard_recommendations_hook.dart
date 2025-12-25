import 'package:front/model/marketplace/listing_model.dart';
import 'package:front/services/marketplace_service.dart';

class DashboardRecommendationPayload {
  final List<ListingModel> vehicleListings;
  final List<ListingModel> partListings;
  final List<ListingModel> recentlyViewed;
  final List<String> preferenceTags;

  DashboardRecommendationPayload({
    required this.vehicleListings,
    required this.partListings,
    required this.recentlyViewed,
    required this.preferenceTags,
  });
}

class _PreferenceBreakdown {
  final Map<String, int> categoryCounts;
  final Map<String, int> brandCounts;

  _PreferenceBreakdown({
    required this.categoryCounts,
    required this.brandCounts,
  });

  factory _PreferenceBreakdown.fromListings(List<ListingModel> listings) {
    final categoryCounts = <String, int>{};
    final brandCounts = <String, int>{};

    for (final listing in listings) {
      if (listing.category.isNotEmpty) {
        categoryCounts.update(
          listing.category.toLowerCase(),
          (value) => value + 1,
          ifAbsent: () => 1,
        );
      }
      if (listing.brand.isNotEmpty) {
        brandCounts.update(
          listing.brand.toLowerCase(),
          (value) => value + 1,
          ifAbsent: () => 1,
        );
      }
    }

    return _PreferenceBreakdown(
      categoryCounts: categoryCounts,
      brandCounts: brandCounts,
    );
  }

  List<String> get topCategories => _sortedKeys(categoryCounts);
  List<String> get topBrands => _sortedKeys(brandCounts);

  static List<String> _sortedKeys(Map<String, int> source) {
    final entries = source.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return entries.map((entry) => entry.key).toList();
  }
}

class DashboardRecommendationsHook {
  static Future<DashboardRecommendationPayload> load({
    required String? token,
    required String? city,
  }) async {
    if (token == null || token.isEmpty) {
      return DashboardRecommendationPayload(
        vehicleListings: [],
        partListings: [],
        recentlyViewed: [],
        preferenceTags: ['Popular picks', 'Curated for you'],
      );
    }

    try {
      // Use REAL recommendation APIs
      final recentlyViewed = await _fetchRecentlyViewed(token);
      
      // Get personalized recommendations (combines all methods)
      final personalizedFuture = MarketplaceService.getPersonalizedRecommendations(
        token: token,
        limit: 12,
        includeCollaborative: true,
        includeContentBased: true,
        includeTrending: true,
      );

      // Get trending in city
      final trendingFuture = MarketplaceService.getTrendingInCity(
        token: token,
        limit: 6,
      );

      // Get user preferences for tags
      final preferencesFuture = MarketplaceService.getUserPreferences(token: token);

      final results = await Future.wait([
        personalizedFuture,
        trendingFuture,
        preferencesFuture,
      ]);

      final personalized = results[0] as Map<String, dynamic>;
      final trending = results[1] as Map<String, dynamic>;
      final preferences = results[2] as Map<String, dynamic>;

      final allRecommendations = personalized['recommendations'] as List<ListingModel>;
      final trendingListings = trending['listings'] as List<ListingModel>;

      // Split recommendations by category
      final vehicleListings = allRecommendations
          .where((l) => l.category == 'vehicle')
          .take(6)
          .toList();
      
      final partListings = allRecommendations
          .where((l) => l.category == 'part' || l.category == 'accessory')
          .take(6)
          .toList();

      // Build preference tags from user preferences
      final topBrands = (preferences['topBrands'] as List<dynamic>?)
          ?.map((b) => b['brand'] as String)
          .toList() ?? [];
      final topCategories = (preferences['topCategories'] as List<dynamic>?)
          ?.map((c) => c['category'] as String)
          .toList() ?? [];

      final tags = _buildPreferenceTags(topCategories, topBrands);

      return DashboardRecommendationPayload(
        vehicleListings: vehicleListings.isNotEmpty 
            ? vehicleListings 
            : trendingListings.where((l) => l.category == 'vehicle').take(3).toList(),
        partListings: partListings.isNotEmpty 
            ? partListings 
            : trendingListings.where((l) => l.category != 'vehicle').take(3).toList(),
        recentlyViewed: recentlyViewed,
        preferenceTags: tags,
      );
    } catch (e) {
      // Fallback to old method if new APIs fail
      return _fallbackLoad(token, city);
    }
  }

  // Fallback method using old approach
  static Future<DashboardRecommendationPayload> _fallbackLoad(
    String? token,
    String? city,
  ) async {
    final recentlyViewed = await _fetchRecentlyViewed(token);
    final preferenceBreakdown =
        _PreferenceBreakdown.fromListings(recentlyViewed);

    final vehicleFuture = _fetchCategoryRecommendations(
      category: 'vehicle',
      city: city,
      preferredBrands: preferenceBreakdown.topBrands,
    );

    final partFuture = _fetchCategoryRecommendations(
      category: 'part',
      city: city,
      preferredBrands: preferenceBreakdown.topBrands,
      fallbackCategory: 'accessory',
    );

    final results = await Future.wait([vehicleFuture, partFuture]);

    final tags = _buildPreferenceTags(
      preferenceBreakdown.topCategories,
      preferenceBreakdown.topBrands,
    );

    return DashboardRecommendationPayload(
      vehicleListings: results[0],
      partListings: results[1],
      recentlyViewed: recentlyViewed,
      preferenceTags: tags,
    );
  }

  static Future<List<ListingModel>> _fetchRecentlyViewed(String? token) async {
    if (token == null || token.isEmpty) {
      return [];
    }

    try {
      final result = await MarketplaceService.getRecentlyViewedItems(
        token: token,
        limit: 8,
      );
      return result['listings'] as List<ListingModel>;
    } catch (_) {
      return [];
    }
  }

  static Future<List<ListingModel>> _fetchCategoryRecommendations({
    required String category,
    required String? city,
    required List<String> preferredBrands,
    String? fallbackCategory,
  }) async {
    final preferredBrand = preferredBrands.isNotEmpty
        ? preferredBrands.first
        : null;

    try {
      final result = await MarketplaceService.getListings(
        page: 1,
        limit: 6,
        category: category,
        brand: preferredBrand,
        location: city,
        sortBy: 'trending',
        sortOrder: 'desc',
      );

      final listings = result['listings'] as List<ListingModel>;
      if (listings.isNotEmpty) {
        return listings;
      }

      if (fallbackCategory != null) {
        final fallbackResult = await MarketplaceService.getListings(
          page: 1,
          limit: 6,
          category: fallbackCategory,
          location: city,
          sortBy: 'trending',
          sortOrder: 'desc',
        );
        return fallbackResult['listings'] as List<ListingModel>;
      }
    } catch (_) {
      // Ignore errors for recommendation fetch; fall back to empty list.
    }

    return [];
  }

  static List<String> _buildPreferenceTags(
    List<String> categories,
    List<String> brands,
  ) {
    final tags = <String>{};

    if (categories.isNotEmpty) {
      tags.add('${_capitalize(categories.first)} vibes');
    }
    if (brands.isNotEmpty) {
      tags.add('${_capitalize(brands.first)} fan');
    }

    if (tags.isEmpty) {
      tags.addAll(['Popular picks', 'Curated for you']);
    }

    return tags.take(3).toList();
  }

  static String _capitalize(String value) {
    if (value.isEmpty) return value;
    return value[0].toUpperCase() + value.substring(1);
  }
}
