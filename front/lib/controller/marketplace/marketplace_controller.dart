import 'package:flutter/foundation.dart';
import 'package:flutter/scheduler.dart';
import 'package:front/model/marketplace/listing_model.dart';
import 'package:front/model/marketplace/bid_model.dart';
import 'package:front/model/marketplace/marketplace_chat_model.dart';
import 'package:front/model/marketplace/marketplace_message_model.dart';
import 'package:front/services/marketplace_service.dart';
import 'package:front/services/payment_service.dart';
import 'package:front/utils/hive_utils.dart';
import 'package:front/config/firebase_api.dart';

class MarketplaceController extends ChangeNotifier {
  // State variables
  List<ListingModel> _listings = [];
  List<ListingModel> _myListings = [];
  List<ListingModel> _favoriteListings = [];
  List<ListingModel> _recentlyViewedItems = [];
  List<BidModel> _bids = [];
  List<MarketplaceChatModel> _chats = [];
  List<MarketplaceMessageModel> _messages = [];
  // Reviews cache - fetched from backend
  final Map<String, Map<String, dynamic>> _listingReviewsCache = {};

  bool _isLoading = false;
  String? _error;
  Map<String, dynamic>? _pagination;
  // Cart state
  final List<ListingModel> _cartItems = [];
  final Map<String, int> _cartQuantities = {};

  // Getters
  List<ListingModel> get listings => _listings;
  List<ListingModel> get myListings => _myListings;
  List<ListingModel> get favoriteListings => _favoriteListings;
  List<ListingModel> get recentlyViewedItems => _recentlyViewedItems;
  List<BidModel> get bids => _bids;
  List<MarketplaceChatModel> get chats => _chats;
  List<MarketplaceMessageModel> get messages => _messages;

  bool get isLoading => _isLoading;
  String? get error => _error;
  Map<String, dynamic>? get pagination => _pagination;
  List<ListingModel> get cartItems => List.unmodifiable(_cartItems);
  int getCartQuantity(String listingId) => _cartQuantities[listingId] ?? 0;
  int get totalCartItems => _cartQuantities.values.fold(0, (a, b) => a + b);
  double get cartTotalAmount => _cartItems.fold(0.0, (sum, item) {
    final qty = _cartQuantities[item.id ?? ''] ?? 1;
    return sum + (item.price * qty);
  });

  // REVIEW METHODS

  // Get reviews for a listing from backend
  Future<Map<String, dynamic>> getListingReviews(String listingId) async {
    try {
      // Check cache first
      if (_listingReviewsCache.containsKey(listingId)) {
        return _listingReviewsCache[listingId]!;
      }

      final result = await MarketplaceService.getListingReviews(
        listingId: listingId,
      );

      print('DEBUG: Raw reviews result: $result');

      // Transform reviews to match UI expectations
      final reviewsData = result['data'];
      final rawReviews = reviewsData['reviews'] as List<dynamic>;

      final transformedReviews = rawReviews.map((review) {
        // Extract user ID from userId object (populated field)
        final user = review['userId'];
        final userId = user is Map ? user['_id'] ?? user['id'] : null;
        final userName = user is Map ? user['name'] : 'Anonymous';

        return {
          'rating': review['rating'],
          'review': review['review'] ?? '',
          'userId': userId,
          'userName': userName,
          'createdAt': review['createdAt'],
          'updatedAt': review['updatedAt'],
          '_id': review['_id'],
        };
      }).toList();

      final transformedData = {
        'reviews': transformedReviews,
        'averageRating': reviewsData['averageRating'] ?? 0.0,
        'totalReviews': reviewsData['totalReviews'] ?? 0,
      };

      print('DEBUG: Transformed ${transformedReviews.length} reviews');

      // Cache the transformed result
      _listingReviewsCache[listingId] = transformedData;

      notifyListeners();

      return transformedData;
    } catch (e, stackTrace) {
      print('Error fetching reviews: $e');
      print('Stack trace: $stackTrace');
      return {'reviews': [], 'averageRating': 0.0, 'totalReviews': 0};
    }
  }

  // Get reviews list for UI (synchronous, from cache)
  List<Map<String, dynamic>> getReviews(String listingId) {
    final cached = _listingReviewsCache[listingId];
    if (cached != null && cached['reviews'] != null) {
      return List<Map<String, dynamic>>.from(cached['reviews']);
    }
    return [];
  }

  // Get average rating (synchronous, from cache)
  double getAverageRating(String listingId) {
    final cached = _listingReviewsCache[listingId];
    if (cached != null && cached['averageRating'] != null) {
      return (cached['averageRating'] as num).toDouble();
    }
    return 0.0;
  }

  // Add or update review
  Future<bool> addOrUpdateReview(
    String listingId, {
    required double rating,
    String? review,
  }) async {
    if (_authToken == null) {
      _setError('Authentication required');
      return false;
    }

    try {
      _setLoading(true);
      _error = null;

      // Create review
      await MarketplaceService.createReview(
        listingId: listingId,
        rating: rating,
        review: review,
        token: _authToken!,
      );

      // Clear cache to force refresh
      _listingReviewsCache.remove(listingId);

      // Fetch updated reviews
      await getListingReviews(listingId);

      _setLoading(false);
      notifyListeners();
      return true;
    } catch (e) {
      _setError('Failed to add/update review: $e');
      return false;
    }
  }

  // Delete review
  Future<bool> deleteReview(String reviewId, String listingId) async {
    if (_authToken == null) {
      _setError('Authentication required');
      return false;
    }

    try {
      _setLoading(true);
      _error = null;

      await MarketplaceService.deleteReview(
        reviewId: reviewId,
        token: _authToken!,
      );

      // Clear cache to force refresh
      _listingReviewsCache.remove(listingId);

      // Fetch updated reviews
      await getListingReviews(listingId);

      _setLoading(false);
      notifyListeners();
      return true;
    } catch (e) {
      _setError('Failed to delete review: $e');
      return false;
    }
  }

  // Get auth token from HiveUtils
  String? get _authToken => HiveUtils.getData('token');

  // Clear error
  void clearError() {
    _error = null;
    notifyListeners();
  }

  // CART METHODS
  void addToCart(ListingModel listing, {int quantity = 1}) {
    final id = listing.id;
    if (id == null) return;
    if (!_cartItems.any((l) => l.id == id)) {
      _cartItems.add(listing);
    }
    _cartQuantities[id] = (_cartQuantities[id] ?? 0) + quantity;
    notifyListeners();
  }

  void removeFromCart(String listingId) {
    _cartItems.removeWhere((l) => l.id == listingId);
    _cartQuantities.remove(listingId);
    notifyListeners();
  }

  void updateCartQuantity(String listingId, int quantity) {
    if (quantity <= 0) {
      removeFromCart(listingId);
    } else {
      _cartQuantities[listingId] = quantity;
      notifyListeners();
    }
  }

  void clearCart() {
    _cartItems.clear();
    _cartQuantities.clear();
    notifyListeners();
  }

  Future<bool> completeOrder() async {
    if (_authToken == null) {
      _setError('Authentication required');
      return false;
    }
    if (_cartItems.isEmpty) {
      _setError('Cart is empty');
      return false;
    }

    try {
      _setLoading(true);
      _error = null;
      // Convert amount to cents (minor unit). Prices are in PKR in UI; for demo use USD.
      final amountInCents = (cartTotalAmount * 100).round();
      final totalAmount = cartTotalAmount;

      // Get the seller's user ID from the first cart item (assuming all items from same seller)
      if (_cartItems.isEmpty) {
        throw Exception('Cart is empty');
      }
      final sellerId = _cartItems.first.seller?.id ?? '';
      if (sellerId.isEmpty) {
        throw Exception('Seller information not available');
      }

      final intent = await PaymentService.createPaymentIntent(
        amount: amountInCents,
        recipientUserId: sellerId,
        transactionType: 'marketplace_purchase',
        relatedEntityId: _cartItems.first.id!,
        relatedEntityType: 'Listing',
        description: 'Marketplace purchase',
        currency: 'usd',
      );

      // Normally, we'd confirm payment with Stripe SDK. For now, consider intent creation success as order success.
      clearCart();
      _setLoading(false);
      if (intent['clientSecret'] != null) {
        _notifyUser(
          'Order initiated',
          'Your order for PKR ${totalAmount.toStringAsFixed(0)} is being processed.',
        );
        return true;
      }
      return false;
    } catch (e) {
      _setError('Failed to complete order: $e');
      return false;
    }
  }

  // Set loading state
  void _setLoading(bool loading) {
    if (_isLoading == loading) return;
    _isLoading = loading;
    if (!hasListeners) return;
    final schedulerPhase = SchedulerBinding.instance.schedulerPhase;
    if (schedulerPhase == SchedulerPhase.idle ||
        schedulerPhase == SchedulerPhase.postFrameCallbacks) {
      notifyListeners();
    } else {
      SchedulerBinding.instance.addPostFrameCallback((_) {
        if (hasListeners) notifyListeners();
      });
    }
  }

  // Set error
  void _setError(String error) {
    _error = error;
    _isLoading = false;
    notifyListeners();
  }

  void _notifyUser(String title, String body) {
    if (kIsWeb) {
      debugPrint('[MarketplaceController] $title — $body');
      return;
    }
    FirebaseApi.showSimpleNotification(title: title, body: body);
  }

  // LISTING METHODS

  // Get all listings with filters
  Future<void> getListings({
    int page = 1,
    int limit = 20,
    String? category,
    String? subcategory,
    String? brand,
    double? minPrice,
    double? maxPrice,
    String? condition,
    String? location,
    String? search,
    String? sortBy,
    String? sortOrder,
    bool? isAuction,
    bool? isNegotiable,
    bool refresh = false,
  }) async {
    try {
      _setLoading(true);
      _error = null;

      // Convert frontend sort options to backend format
      String? backendSortBy;
      String? backendSortOrder;

      switch (sortBy) {
        case 'newest':
          backendSortBy = 'createdAt';
          backendSortOrder = 'desc';
          break;
        case 'oldest':
          backendSortBy = 'createdAt';
          backendSortOrder = 'asc';
          break;
        case 'price_low':
          backendSortBy = 'price';
          backendSortOrder = 'asc';
          break;
        case 'price_high':
          backendSortBy = 'price';
          backendSortOrder = 'desc';
          break;
        case 'most_viewed':
          backendSortBy = 'viewCount';
          backendSortOrder = 'desc';
          break;
        case 'trending':
        case 'popular':
          backendSortBy = 'popularity';
          backendSortOrder = 'desc';
          break;
        default:
          backendSortBy = 'createdAt';
          backendSortOrder = 'desc';
      }

      final result = await MarketplaceService.getListings(
        page: page,
        limit: limit,
        category: category,
        subcategory: subcategory,
        brand: brand,
        minPrice: minPrice,
        maxPrice: maxPrice,
        condition: condition,
        location: location,
        search: search,
        sortBy: backendSortBy,
        sortOrder: backendSortOrder,
        isAuction: isAuction,
        isNegotiable: isNegotiable,
      );

      if (refresh || page == 1) {
        _listings = result['listings'];
      } else {
        _listings.addAll(result['listings']);
      }

      _pagination = result['pagination'];
      _setLoading(false);
    } catch (e) {
      _setError('Failed to load listings: $e');
    }
  }

  // Get single listing by ID
  Future<ListingModel?> getListingById(String id) async {
    try {
      _setLoading(true);
      _error = null;

      final result = await MarketplaceService.getListingById(id);
      _setLoading(false);
      return result['listing'];
    } catch (e) {
      _setError('Failed to load listing: $e');
      return null;
    }
  }

  // Create new listing
  Future<bool> createListing(Map<String, dynamic> listingData) async {
    final token = _authToken;

    print('=== MARKETPLACE CONTROLLER DEBUG ===');
    print('Auth token exists: ${token != null}');
    print('Auth token: ${token?.substring(0, 20) ?? 'null'}...');
    print('Listing data: $listingData');
    print('===================================');

    if (token == null) {
      _setError('Authentication required - please login');
      return false;
    }

    try {
      _setLoading(true);
      _error = null;

      final listing = await MarketplaceService.createListing(
        listingData,
        token,
      );
      _myListings.insert(0, listing);
      _setLoading(false);
      return true;
    } catch (e) {
      print('=== MARKETPLACE CONTROLLER ERROR ===');
      print('Error: $e');
      print('===================================');
      _setError('Failed to create listing: $e');
      return false;
    }
  }

  // Get user's listings
  Future<void> getMyListings({
    int page = 1,
    int limit = 20,
    String? status,
    bool refresh = false,
  }) async {
    if (_authToken == null) {
      _setError('Authentication required');
      return;
    }

    try {
      _setLoading(true);
      _error = null;

      final result = await MarketplaceService.getMyListings(
        token: _authToken!,
        page: page,
        limit: limit,
        status: status,
      );

      if (refresh || page == 1) {
        _myListings = result['listings'];
      } else {
        _myListings.addAll(result['listings']);
      }

      _pagination = result['pagination'];
      _setLoading(false);
    } catch (e) {
      _setError('Failed to load your listings: $e');
    }
  }

  // Update listing
  Future<bool> updateListing(String id, Map<String, dynamic> updateData) async {
    if (_authToken == null) {
      _setError('Authentication required');
      return false;
    }

    try {
      _setLoading(true);
      _error = null;

      final listing = await MarketplaceService.updateListing(
        id,
        updateData,
        _authToken!,
      );

      // Update in myListings
      final index = _myListings.indexWhere((l) => l.id == id);
      if (index != -1) {
        _myListings[index] = listing;
      }

      // Update in listings if present
      final listingsIndex = _listings.indexWhere((l) => l.id == id);
      if (listingsIndex != -1) {
        _listings[listingsIndex] = listing;
      }

      _setLoading(false);
      return true;
    } catch (e) {
      _setError('Failed to update listing: $e');
      return false;
    }
  }

  // Delete listing
  Future<bool> deleteListing(String id) async {
    if (_authToken == null) {
      _setError('Authentication required');
      return false;
    }

    try {
      _setLoading(true);
      _error = null;

      await MarketplaceService.deleteListing(id, _authToken!);

      // Remove from lists
      _myListings.removeWhere((l) => l.id == id);
      _listings.removeWhere((l) => l.id == id);
      _favoriteListings.removeWhere((l) => l.id == id);

      _setLoading(false);
      return true;
    } catch (e) {
      _setError('Failed to delete listing: $e');
      return false;
    }
  }

  // Toggle favorite
  Future<bool> toggleFavorite(String listingId) async {
    print('DEBUG: toggleFavorite called with listingId: $listingId');
    if (_authToken == null) {
      print('DEBUG: No auth token available');
      _setError('Authentication required');
      return false;
    }

    try {
      _setLoading(true);
      _error = null;
      print('DEBUG: Calling MarketplaceService.toggleFavorite');

      final result = await MarketplaceService.toggleFavorite(
        listingId,
        _authToken!,
      );

      print('DEBUG: toggleFavorite result: $result');

      // Update favorite count in listings
      final listingIndex = _listings.indexWhere((l) => l.id == listingId);
      if (listingIndex != -1) {
        _listings[listingIndex].favoriteCount += result['isFavorited'] ? 1 : -1;
        print(
          'DEBUG: Updated favorite count for listing at index $listingIndex',
        );
      }

      // Refresh the favorites list to keep it in sync
      print('DEBUG: Refreshing favorites list');
      await getFavoriteListings(refresh: true);

      _setLoading(false);
      return result['isFavorited'];
    } catch (e) {
      _setError('Failed to toggle favorite: $e');
      return false;
    }
  }

  // Get favorite listings
  Future<void> getFavoriteListings({
    int page = 1,
    int limit = 20,
    bool refresh = false,
  }) async {
    print('DEBUG: getFavoriteListings called - page: $page, refresh: $refresh');
    if (_authToken == null) {
      print('DEBUG: No auth token available for favorites');
      _setError('Authentication required');
      return;
    }

    try {
      _setLoading(true);
      _error = null;

      print('DEBUG: Calling MarketplaceService.getFavoriteListings');
      final result = await MarketplaceService.getFavoriteListings(
        token: _authToken!,
        page: page,
        limit: limit,
      );

      print('DEBUG: Raw API result: $result');

      // Extract the favorites from the correct path: data.favorites
      final dataResult = result['data'];
      if (dataResult == null) {
        print('DEBUG: result[data] is null, setting empty list');
        if (refresh || page == 1) {
          _favoriteListings = [];
        }
        _setLoading(false);
        notifyListeners();
        return;
      }

      final List<dynamic> favoritesData = dataResult['favorites'] ?? [];
      print('DEBUG: Found ${favoritesData.length} favorites in response');

      // Filter out null items and convert to ListingModel objects
      final List<ListingModel> favoriteListings = favoritesData
          .where((data) => data != null)
          .map((data) {
            try {
              return ListingModel.fromJson(data as Map<String, dynamic>);
            } catch (e) {
              print('DEBUG: Error parsing listing: $e');
              return null;
            }
          })
          .where((listing) => listing != null)
          .cast<ListingModel>()
          .toList();

      print(
        'DEBUG: Converted to ${favoriteListings.length} ListingModel objects',
      );

      if (refresh || page == 1) {
        _favoriteListings = favoriteListings;
      } else {
        _favoriteListings.addAll(favoriteListings);
      }

      print(
        'DEBUG: _favoriteListings now has ${_favoriteListings.length} items',
      );

      // Set pagination if available, otherwise use simple logic
      if (result.containsKey('pagination')) {
        _pagination = result['pagination'];
      } else {
        // Simple pagination based on data length
        _pagination = {
          'currentPage': page,
          'totalPages': favoritesData.length < limit ? page : page + 1,
          'hasMore': favoritesData.length == limit,
        };
      }

      _setLoading(false);
      notifyListeners();
      print('DEBUG: Finished getFavoriteListings, notified listeners');
    } catch (e, stackTrace) {
      print('DEBUG: Error in getFavoriteListings: $e, stackTrace: $stackTrace');
      _setError('Failed to load favorite listings: $e');
      _setLoading(false);
    }
  }

  // Get recently viewed items with timestamps
  Future<void> getRecentlyViewedItems({
    int limit = 20,
    bool refresh = false,
  }) async {
    if (_authToken == null) {
      _setError('Authentication required');
      return;
    }

    try {
      _setLoading(true);
      _error = null;

      final result = await MarketplaceService.getRecentlyViewedItems(
        token: _authToken!,
        limit: limit,
      );

      _recentlyViewedItems = result['listings'] as List<ListingModel>;

      _setLoading(false);
      notifyListeners();
    } catch (e) {
      _setError('Failed to load recently viewed items: $e');
      _setLoading(false);
    }
  }

  // BID METHODS

  // Place a bid
  Future<bool> placeBid(String listingId, Map<String, dynamic> bidData) async {
    if (_authToken == null) {
      _setError('Authentication required');
      return false;
    }

    try {
      _setLoading(true);
      _error = null;

      await MarketplaceService.placeBid(listingId, bidData, _authToken!);

      // Refresh the bid list to show the updated bids including the new one
      await getListingBids(listingId);

      _setLoading(false);
      _notifyUser('Bid placed', 'Your bid was submitted successfully.');
      return true;
    } catch (e) {
      _setError('Failed to place bid: $e');
      return false;
    }
  }

  // Get bids for a listing
  Future<void> getListingBids(
    String listingId, {
    int page = 1,
    int limit = 20,
  }) async {
    if (_authToken == null) {
      _setError('Authentication required');
      return;
    }

    try {
      _setLoading(true);
      _error = null;

      final result = await MarketplaceService.getListingBids(
        listingId,
        token: _authToken!,
        page: page,
        limit: limit,
      );
      _bids = result['bids'];
      _pagination = result['pagination'];
      _setLoading(false);
    } catch (e) {
      _setError('Failed to load bids: $e');
    }
  }

  // Get user's bids
  Future<void> getUserBids({
    int page = 1,
    int limit = 20,
    String? status,
    bool refresh = false,
  }) async {
    if (_authToken == null) {
      _setError('Authentication required');
      return;
    }

    try {
      _setLoading(true);
      _error = null;

      final result = await MarketplaceService.getUserBids(
        token: _authToken!,
        page: page,
        limit: limit,
        status: status,
      );

      if (refresh || page == 1) {
        _bids = result['bids'];
      } else {
        _bids.addAll(result['bids']);
      }

      _pagination = result['pagination'];
      _setLoading(false);
    } catch (e) {
      _setError('Failed to load your bids: $e');
    }
  }

  // Cancel a bid
  Future<bool> cancelBid(String bidId) async {
    if (_authToken == null) {
      _setError('Authentication required');
      return false;
    }

    try {
      _setLoading(true);
      _error = null;

      await MarketplaceService.cancelBid(bidId, _authToken!);
      _bids.removeWhere((b) => b.id == bidId);
      _setLoading(false);
      return true;
    } catch (e) {
      _setError('Failed to cancel bid: $e');
      return false;
    }
  }

  // CHAT METHODS

  // Create or get chat for a listing
  Future<MarketplaceChatModel?> createOrGetChat(String listingId) async {
    if (_authToken == null) {
      _setError('Authentication required');
      return null;
    }

    try {
      _setLoading(true);
      _error = null;

      final chat = await MarketplaceService.createOrGetChat(
        listingId,
        _authToken!,
      );
      _setLoading(false);
      return chat;
    } catch (e) {
      _setError('Failed to create/get chat: $e');
      return null;
    }
  }

  // Get user's chats
  Future<void> getUserChats({
    int page = 1,
    int limit = 20,
    bool refresh = false,
  }) async {
    if (_authToken == null) {
      _setError('Authentication required');
      return;
    }

    try {
      _setLoading(true);
      _error = null;

      final result = await MarketplaceService.getUserChats(
        token: _authToken!,
        page: page,
        limit: limit,
      );

      if (refresh || page == 1) {
        _chats = result['chats'];
      } else {
        _chats.addAll(result['chats']);
      }

      _pagination = result['pagination'];
      _setLoading(false);
    } catch (e) {
      _setError('Failed to load chats: $e');
    }
  }

  // Get chat messages
  Future<void> getChatMessages(
    String chatId, {
    int page = 1,
    int limit = 50,
    bool refresh = false,
  }) async {
    if (_authToken == null) {
      _setError('Authentication required');
      return;
    }

    try {
      _setLoading(true);
      _error = null;

      final result = await MarketplaceService.getChatMessages(
        chatId,
        token: _authToken!,
        page: page,
        limit: limit,
      );

      if (refresh || page == 1) {
        _messages = result['messages'];
      } else {
        _messages.addAll(result['messages']);
      }

      _pagination = result['pagination'];
      _setLoading(false);
    } catch (e) {
      _setError('Failed to load messages: $e');
    }
  }

  // Send a message
  Future<bool> sendMessage(
    String chatId,
    Map<String, dynamic> messageData,
  ) async {
    if (_authToken == null) {
      _setError('Authentication required');
      return false;
    }

    try {
      _setLoading(true);
      _error = null;

      final message = await MarketplaceService.sendMessage(
        chatId,
        messageData,
        _authToken!,
      );
      _messages.add(message);
      _setLoading(false);
      return true;
    } catch (e) {
      _setError('Failed to send message: $e');
      return false;
    }
  }

  // Send offer message
  Future<bool> sendOfferMessage(
    String chatId,
    Map<String, dynamic> offerData,
  ) async {
    if (_authToken == null) {
      _setError('Authentication required');
      return false;
    }

    try {
      _setLoading(true);
      _error = null;

      final message = await MarketplaceService.sendOfferMessage(
        chatId,
        offerData,
        _authToken!,
      );
      _messages.add(message);
      _setLoading(false);
      _notifyUser('Offer shared', 'Offer details have been shared in chat.');
      return true;
    } catch (e) {
      _setError('Failed to send offer message: $e');
      return false;
    }
  }

  // Clear all data
  void clearAllData() {
    _listings.clear();
    _myListings.clear();
    _favoriteListings.clear();
    _bids.clear();
    _chats.clear();
    _messages.clear();
    _pagination = null;
    _error = null;
    _isLoading = false;
    notifyListeners();
  }
}
