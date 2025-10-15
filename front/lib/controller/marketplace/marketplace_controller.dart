import 'package:flutter/foundation.dart';
import 'package:front/model/marketplace/listing_model.dart';
import 'package:front/model/marketplace/bid_model.dart';
import 'package:front/model/marketplace/offer_model.dart';
import 'package:front/model/marketplace/marketplace_chat_model.dart';
import 'package:front/model/marketplace/marketplace_message_model.dart';
import 'package:front/services/marketplace_service.dart';
import 'package:front/utils/hive_utils.dart';

class MarketplaceController extends ChangeNotifier {
  // State variables
  List<ListingModel> _listings = [];
  List<ListingModel> _myListings = [];
  List<ListingModel> _favoriteListings = [];
  List<BidModel> _bids = [];
  List<OfferModel> _offers = [];
  List<MarketplaceChatModel> _chats = [];
  List<MarketplaceMessageModel> _messages = [];

  bool _isLoading = false;
  String? _error;
  Map<String, dynamic>? _pagination;

  // Getters
  List<ListingModel> get listings => _listings;
  List<ListingModel> get myListings => _myListings;
  List<ListingModel> get favoriteListings => _favoriteListings;
  List<BidModel> get bids => _bids;
  List<OfferModel> get offers => _offers;
  List<MarketplaceChatModel> get chats => _chats;
  List<MarketplaceMessageModel> get messages => _messages;

  bool get isLoading => _isLoading;
  String? get error => _error;
  Map<String, dynamic>? get pagination => _pagination;

  // Get auth token from HiveUtils
  String? get _authToken => HiveUtils.getData('token');

  // Clear error
  void clearError() {
    _error = null;
    notifyListeners();
  }

  // Set loading state
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  // Set error
  void _setError(String error) {
    _error = error;
    _isLoading = false;
    notifyListeners();
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
        print('DEBUG: Updated favorite count for listing at index $listingIndex');
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
      final List<dynamic> favoritesData = result['data']['favorites'] ?? [];
      print('DEBUG: Found ${favoritesData.length} favorites in response');

      // Convert to ListingModel objects
      final List<ListingModel> favoriteListings = favoritesData
          .map((data) => ListingModel.fromJson(data))
          .toList();

      print('DEBUG: Converted to ${favoriteListings.length} ListingModel objects');

      if (refresh || page == 1) {
        _favoriteListings = favoriteListings;
      } else {
        _favoriteListings.addAll(favoriteListings);
      }

      print('DEBUG: _favoriteListings now has ${_favoriteListings.length} items');
      
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
    } catch (e) {
      print('DEBUG: Error in getFavoriteListings: $e');
      _setError('Failed to load favorite listings: $e');
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

  // OFFER METHODS

  // Make an offer
  Future<bool> makeOffer(
    String listingId,
    Map<String, dynamic> offerData,
  ) async {
    if (_authToken == null) {
      _setError('Authentication required');
      return false;
    }

    try {
      _setLoading(true);
      _error = null;

      final offer = await MarketplaceService.makeOffer(
        listingId,
        offerData,
        _authToken!,
      );
      _offers.insert(0, offer);
      _setLoading(false);
      return true;
    } catch (e) {
      _setError('Failed to make offer: $e');
      return false;
    }
  }

  // Get offers for a listing
  Future<void> getListingOffers(
    String listingId, {
    int page = 1,
    int limit = 20,
    String? status,
  }) async {
    if (_authToken == null) {
      _setError('Authentication required');
      return;
    }

    try {
      _setLoading(true);
      _error = null;

      final result = await MarketplaceService.getListingOffers(
        listingId,
        token: _authToken!,
        page: page,
        limit: limit,
        status: status,
      );
      _offers = result['offers'];
      _pagination = result['pagination'];
      _setLoading(false);
    } catch (e) {
      _setError('Failed to load offers: $e');
    }
  }

  // Get user's offers
  Future<void> getUserOffers({
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

      final result = await MarketplaceService.getUserOffers(
        token: _authToken!,
        page: page,
        limit: limit,
        status: status,
      );

      if (refresh || page == 1) {
        _offers = result['offers'];
      } else {
        _offers.addAll(result['offers']);
      }

      _pagination = result['pagination'];
      _setLoading(false);
    } catch (e) {
      _setError('Failed to load your offers: $e');
    }
  }

  // Accept an offer
  Future<bool> acceptOffer(String offerId, {String? responseMessage}) async {
    if (_authToken == null) {
      _setError('Authentication required');
      return false;
    }

    try {
      _setLoading(true);
      _error = null;

      await MarketplaceService.acceptOffer(
        offerId,
        responseMessage: responseMessage,
        token: _authToken!,
      );

      // Update offer status
      final index = _offers.indexWhere((o) => o.id == offerId);
      if (index != -1) {
        _offers[index].status = 'accepted';
      }

      _setLoading(false);
      return true;
    } catch (e) {
      _setError('Failed to accept offer: $e');
      return false;
    }
  }

  // Reject an offer
  Future<bool> rejectOffer(String offerId, {String? responseMessage}) async {
    if (_authToken == null) {
      _setError('Authentication required');
      return false;
    }

    try {
      _setLoading(true);
      _error = null;

      await MarketplaceService.rejectOffer(
        offerId,
        responseMessage: responseMessage,
        token: _authToken!,
      );

      // Update offer status
      final index = _offers.indexWhere((o) => o.id == offerId);
      if (index != -1) {
        _offers[index].status = 'rejected';
      }

      _setLoading(false);
      return true;
    } catch (e) {
      _setError('Failed to reject offer: $e');
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
    _offers.clear();
    _chats.clear();
    _messages.clear();
    _pagination = null;
    _error = null;
    _isLoading = false;
    notifyListeners();
  }
}
