import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:front/config/app_config.dart';
import 'package:front/model/marketplace/listing_model.dart';
import 'package:front/model/marketplace/bid_model.dart';
import 'package:front/model/marketplace/marketplace_chat_model.dart';
import 'package:front/model/marketplace/marketplace_message_model.dart';

class MarketplaceService {
  static String baseUrl = '${AppConfig.apiBaseUrl}/marketplace';

  // Helper method to get headers with auth token
  static Map<String, String> _getHeaders(String? token) {
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  // Helper method to handle API responses
  static Map<String, dynamic> _handleResponse(http.Response response) {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to load data: ${response.statusCode}');
    }
  }

  // LISTING SERVICES

  // Get all listings with filters
  static Future<Map<String, dynamic>> getListings({
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
  }) async {
    final queryParams = <String, String>{
      'page': page.toString(),
      'limit': limit.toString(),
    };

    if (category != null) queryParams['category'] = category;
    if (subcategory != null) queryParams['subcategory'] = subcategory;
    if (brand != null) queryParams['brand'] = brand;
    if (minPrice != null) queryParams['minPrice'] = minPrice.toString();
    if (maxPrice != null) queryParams['maxPrice'] = maxPrice.toString();
    if (condition != null) queryParams['condition'] = condition;
    if (location != null) queryParams['location'] = location;
    if (search != null) queryParams['search'] = search;
    if (sortBy != null) queryParams['sortBy'] = sortBy;
    if (sortOrder != null) queryParams['sortOrder'] = sortOrder;
    if (isAuction != null) queryParams['isAuction'] = isAuction.toString();
    if (isNegotiable != null)
      queryParams['isNegotiable'] = isNegotiable.toString();

    final uri = Uri.parse(
      '$baseUrl/listings',
    ).replace(queryParameters: queryParams);
    final response = await http.get(uri);

    final data = _handleResponse(response);
    return {
      'listings': (data['data']['listings'] as List)
          .map((json) => ListingModel.fromJson(json))
          .toList(),
      'pagination': data['data']['pagination'],
    };
  }

  // Get single listing by ID
  static Future<Map<String, dynamic>> getListingById(
    String id, {
    String? token,
  }) async {
    final response = await http.get(
      Uri.parse('$baseUrl/listings/$id'),
      headers: _getHeaders(token),
    );
    final data = _handleResponse(response);
    return {
      'listing': ListingModel.fromJson(data['data']['listing']),
      'currentBid': data['data']['currentBid'] != null
          ? BidModel.fromJson(data['data']['currentBid'])
          : null,
    };
  }

  // Get recently viewed items
  static Future<Map<String, dynamic>> getRecentlyViewedItems({
    required String token,
    int page = 1,
    int limit = 20,
  }) async {
    final queryParams = <String, String>{
      'page': page.toString(),
      'limit': limit.toString(),
    };

    final uri = Uri.parse('$baseUrl/listings/recently-viewed')
        .replace(queryParameters: queryParams);
    final response = await http.get(
      uri,
      headers: _getHeaders(token),
    );

    final data = _handleResponse(response);
    return {
      'listings': (data['data']['listings'] as List)
          .map((json) => ListingModel.fromJson(json))
          .toList(),
      'pagination': data['data']['pagination'],
    };
  }

  // Create new listing
  static Future<ListingModel> createListing(
    Map<String, dynamic> listingData,
    String token,
  ) async {
    print('=== MARKETPLACE SERVICE DEBUG ===');
    print('API URL: $baseUrl/listings');
    print('Token: ${token.substring(0, 20)}...');
    print('Request data: $listingData');
    print('Headers: ${_getHeaders(token)}');
    print('================================');

    final response = await http.post(
      Uri.parse('$baseUrl/listings'),
      headers: _getHeaders(token),
      body: json.encode(listingData),
    );

    print('=== API RESPONSE DEBUG ===');
    print('Status Code: ${response.statusCode}');
    print('Response Body: ${response.body}');
    print('=========================');

    final data = _handleResponse(response);
    return ListingModel.fromJson(data['data']);
  }

  // Get user's listings
  static Future<Map<String, dynamic>> getMyListings({
    required String token,
    int page = 1,
    int limit = 20,
    String? status,
  }) async {
    final queryParams = <String, String>{
      'page': page.toString(),
      'limit': limit.toString(),
    };
    if (status != null) queryParams['status'] = status;

    final uri = Uri.parse(
      '$baseUrl/listings/my/listings',
    ).replace(queryParameters: queryParams);
    final response = await http.get(uri, headers: _getHeaders(token));

    final data = _handleResponse(response);
    return {
      'listings': (data['data']['listings'] as List)
          .map((json) => ListingModel.fromJson(json))
          .toList(),
      'pagination': data['data']['pagination'],
    };
  }

  // Update listing
  static Future<ListingModel> updateListing(
    String id,
    Map<String, dynamic> updateData,
    String token,
  ) async {
    final response = await http.put(
      Uri.parse('$baseUrl/listings/$id'),
      headers: _getHeaders(token),
      body: json.encode(updateData),
    );
    final data = _handleResponse(response);
    return ListingModel.fromJson(data['data']);
  }

  // Delete listing
  static Future<void> deleteListing(String id, String token) async {
    final response = await http.delete(
      Uri.parse('$baseUrl/listings/$id'),
      headers: _getHeaders(token),
    );
    _handleResponse(response);
  }

  // Toggle favorite
  static Future<Map<String, dynamic>> toggleFavorite(
    String listingId,
    String token,
  ) async {
    print('DEBUG: MarketplaceService.toggleFavorite called with listingId: $listingId');
    final url = '$baseUrl/listings/$listingId/favorite';
    print('DEBUG: Making POST request to: $url');
    
    final response = await http.post(
      Uri.parse(url),
      headers: _getHeaders(token),
    );
    
    print('DEBUG: Response status: ${response.statusCode}');
    print('DEBUG: Response body: ${response.body}');
    
    final data = _handleResponse(response);
    print('DEBUG: Parsed response data: $data');
    return {'isFavorited': data['isFavorited'], 'message': data['message']};
  }

  // Get favorite listings
  static Future<Map<String, dynamic>> getFavoriteListings({
    required String token,
    int page = 1,
    int limit = 20,
  }) async {
    print('DEBUG: MarketplaceService.getFavoriteListings called - page: $page, limit: $limit');
    final queryParams = <String, String>{
      'page': page.toString(),
      'limit': limit.toString(),
    };

    final uri = Uri.parse(
      '$baseUrl/listings/my/favorites',
    ).replace(queryParameters: queryParams);
    
    print('DEBUG: Making GET request to: $uri');
    final response = await http.get(uri, headers: _getHeaders(token));

    print('DEBUG: Favorites response status: ${response.statusCode}');
    print('DEBUG: Favorites response body: ${response.body}');

    final data = _handleResponse(response);
    
    print('DEBUG: Parsed response, returning raw data');
    
    return data;
  }

  // BID SERVICES

  // Place a bid
  static Future<BidModel> placeBid(
    String listingId,
    Map<String, dynamic> bidData,
    String token,
  ) async {
    final response = await http.post(
      Uri.parse('$baseUrl/bids/$listingId'),
      headers: _getHeaders(token),
      body: json.encode(bidData),
    );
    final data = _handleResponse(response);
    return BidModel.fromJson(data['data']);
  }

  // Get bids for a listing
  static Future<Map<String, dynamic>> getListingBids(
    String listingId, {
    String? token,
    int page = 1,
    int limit = 20,
  }) async {
    final queryParams = <String, String>{
      'page': page.toString(),
      'limit': limit.toString(),
    };

    final uri = Uri.parse(
      '$baseUrl/bids/listing/$listingId',
    ).replace(queryParameters: queryParams);
    final response = await http.get(uri, headers: _getHeaders(token));

    final data = _handleResponse(response);
    return {
      'bids': (data['data']['bids'] as List)
          .map((json) => BidModel.fromJson(json))
          .toList(),
      'pagination': data['data']['pagination'],
    };
  }

  // Get user's bids
  static Future<Map<String, dynamic>> getUserBids({
    required String token,
    int page = 1,
    int limit = 20,
    String? status,
  }) async {
    final queryParams = <String, String>{
      'page': page.toString(),
      'limit': limit.toString(),
    };
    if (status != null) queryParams['status'] = status;

    final uri = Uri.parse(
      '$baseUrl/bids/my/bids',
    ).replace(queryParameters: queryParams);
    final response = await http.get(uri, headers: _getHeaders(token));

    final data = _handleResponse(response);
    return {
      'bids': (data['data']['bids'] as List)
          .map((json) => BidModel.fromJson(json))
          .toList(),
      'pagination': data['data']['pagination'],
    };
  }

  // Cancel a bid
  static Future<void> cancelBid(String bidId, String token) async {
    final response = await http.delete(
      Uri.parse('$baseUrl/bids/$bidId'),
      headers: _getHeaders(token),
    );
    _handleResponse(response);
  }

  // Get auction statistics
  static Future<Map<String, dynamic>> getAuctionStats(String listingId) async {
    final response = await http.get(
      Uri.parse('$baseUrl/bids/stats/$listingId'),
    );
    final data = _handleResponse(response);
    return data['data'];
  }

  // OFFER SERVICES

  // Make an offer
  static Future<Map<String, dynamic>> makeOffer(
    String listingId,
    Map<String, dynamic> offerData,
    String token,
  ) async {
    final response = await http.post(
      Uri.parse('$baseUrl/offers/$listingId'),
      headers: _getHeaders(token),
      body: json.encode(offerData),
    );
    final data = _handleResponse(response);
    return data['data'];
  }

  // Get offers for a listing (seller's view)
  static Future<Map<String, dynamic>> getListingOffers(
    String listingId, {
    required String token,
    int page = 1,
    int limit = 20,
    String? status,
  }) async {
    final queryParams = <String, String>{
      'page': page.toString(),
      'limit': limit.toString(),
    };
    if (status != null) queryParams['status'] = status;

    final uri = Uri.parse(
      '$baseUrl/offers/listing/$listingId',
    ).replace(queryParameters: queryParams);
    final response = await http.get(uri, headers: _getHeaders(token));

    final data = _handleResponse(response);
    return {
      'offers': data['data']['offers'] as List,
      'pagination': data['data']['pagination'],
    };
  }

  // Get user's offers (buyer's view)
  static Future<Map<String, dynamic>> getUserOffers({
    required String token,
    int page = 1,
    int limit = 20,
    String? status,
  }) async {
    final queryParams = <String, String>{
      'page': page.toString(),
      'limit': limit.toString(),
    };
    if (status != null) queryParams['status'] = status;

    final uri = Uri.parse(
      '$baseUrl/offers/my/offers',
    ).replace(queryParameters: queryParams);
    final response = await http.get(uri, headers: _getHeaders(token));

    final data = _handleResponse(response);
    return {
      'offers': data['data']['offers'] as List,
      'pagination': data['data']['pagination'],
    };
  }

  // Accept an offer
  static Future<Map<String, dynamic>> acceptOffer(
    String offerId, {
    String? responseMessage,
    required String token,
  }) async {
    final response = await http.put(
      Uri.parse('$baseUrl/offers/$offerId/accept'),
      headers: _getHeaders(token),
      body: json.encode({'responseMessage': responseMessage}),
    );
    final data = _handleResponse(response);
    return data['data'];
  }

  // Reject an offer
  static Future<void> rejectOffer(
    String offerId, {
    String? responseMessage,
    required String token,
  }) async {
    final response = await http.put(
      Uri.parse('$baseUrl/offers/$offerId/reject'),
      headers: _getHeaders(token),
      body: json.encode({'responseMessage': responseMessage}),
    );
    _handleResponse(response);
  }

  // Make a counter offer
  static Future<Map<String, dynamic>> makeCounterOffer(
    String offerId,
    Map<String, dynamic> counterData,
    String token,
  ) async {
    final response = await http.put(
      Uri.parse('$baseUrl/offers/$offerId/counter'),
      headers: _getHeaders(token),
      body: json.encode(counterData),
    );
    final data = _handleResponse(response);
    return data['data'];
  }

  // Accept counter offer
  static Future<void> acceptCounterOffer(String offerId, String token) async {
    final response = await http.put(
      Uri.parse('$baseUrl/offers/$offerId/accept-counter'),
      headers: _getHeaders(token),
    );
    _handleResponse(response);
  }

  // Cancel an offer
  static Future<void> cancelOffer(String offerId, String token) async {
    final response = await http.delete(
      Uri.parse('$baseUrl/offers/$offerId'),
      headers: _getHeaders(token),
    );
    _handleResponse(response);
  }

  // CHAT SERVICES

  // Create or get chat for a listing
  static Future<MarketplaceChatModel> createOrGetChat(
    String listingId,
    String token,
  ) async {
    final response = await http.post(
      Uri.parse('$baseUrl/chat/listing/$listingId'),
      headers: _getHeaders(token),
    );
    final data = _handleResponse(response);
    return MarketplaceChatModel.fromJson(data['data']);
  }

  // Get user's chats
  static Future<Map<String, dynamic>> getUserChats({
    required String token,
    int page = 1,
    int limit = 20,
  }) async {
    final queryParams = <String, String>{
      'page': page.toString(),
      'limit': limit.toString(),
    };

    final uri = Uri.parse(
      '$baseUrl/chat/my/chats',
    ).replace(queryParameters: queryParams);
    final response = await http.get(uri, headers: _getHeaders(token));

    final data = _handleResponse(response);
    return {
      'chats': (data['data']['chats'] as List)
          .map((json) => MarketplaceChatModel.fromJson(json))
          .toList(),
      'pagination': data['data']['pagination'],
    };
  }

  // Get chat messages
  static Future<Map<String, dynamic>> getChatMessages(
    String chatId, {
    required String token,
    int page = 1,
    int limit = 50,
  }) async {
    final queryParams = <String, String>{
      'page': page.toString(),
      'limit': limit.toString(),
    };

    final uri = Uri.parse(
      '$baseUrl/chat/$chatId/messages',
    ).replace(queryParameters: queryParams);
    final response = await http.get(uri, headers: _getHeaders(token));

    final data = _handleResponse(response);
    return {
      'messages': (data['data']['messages'] as List)
          .map((json) => MarketplaceMessageModel.fromJson(json))
          .toList(),
      'pagination': data['data']['pagination'],
    };
  }

  // Send a message
  static Future<MarketplaceMessageModel> sendMessage(
    String chatId,
    Map<String, dynamic> messageData,
    String token,
  ) async {
    final response = await http.post(
      Uri.parse('$baseUrl/chat/$chatId/message'),
      headers: _getHeaders(token),
      body: json.encode(messageData),
    );
    final data = _handleResponse(response);
    return MarketplaceMessageModel.fromJson(data['data']);
  }

  // Send offer message
  static Future<MarketplaceMessageModel> sendOfferMessage(
    String chatId,
    Map<String, dynamic> offerData,
    String token,
  ) async {
    final response = await http.post(
      Uri.parse('$baseUrl/chat/$chatId/offer'),
      headers: _getHeaders(token),
      body: json.encode(offerData),
    );
    final data = _handleResponse(response);
    return MarketplaceMessageModel.fromJson(data['data']);
  }

  // Delete a message
  static Future<void> deleteMessage(String messageId, String token) async {
    final response = await http.delete(
      Uri.parse('$baseUrl/chat/message/$messageId'),
      headers: _getHeaders(token),
    );
    _handleResponse(response);
  }

  // Mark chat as read
  static Future<void> markChatAsRead(String chatId, String token) async {
    final response = await http.put(
      Uri.parse('$baseUrl/chat/$chatId/read'),
      headers: _getHeaders(token),
    );
    _handleResponse(response);
  }

  // RECOMMENDATION SERVICES

  // Get personalized recommendations
  static Future<Map<String, dynamic>> getPersonalizedRecommendations({
    required String token,
    int limit = 20,
    bool includeCollaborative = true,
    bool includeContentBased = true,
    bool includeTrending = true,
  }) async {
    final queryParams = <String, String>{
      'limit': limit.toString(),
      'includeCollaborative': includeCollaborative.toString(),
      'includeContentBased': includeContentBased.toString(),
      'includeTrending': includeTrending.toString(),
    };

    final uri = Uri.parse('${AppConfig.apiBaseUrl}/marketplace/recommendations/personalized')
        .replace(queryParameters: queryParams);
    final response = await http.get(uri, headers: _getHeaders(token));

    final data = _handleResponse(response);
    return {
      'recommendations': (data['data']['recommendations'] as List)
          .map((json) => ListingModel.fromJson(json))
          .toList(),
      'count': data['data']['count'],
    };
  }

  // Get trending in city
  static Future<Map<String, dynamic>> getTrendingInCity({
    required String token,
    int limit = 10,
  }) async {
    final queryParams = <String, String>{
      'limit': limit.toString(),
    };

    final uri = Uri.parse('${AppConfig.apiBaseUrl}/marketplace/recommendations/trending')
        .replace(queryParameters: queryParams);
    final response = await http.get(uri, headers: _getHeaders(token));

    final data = _handleResponse(response);
    return {
      'listings': (data['data']['listings'] as List)
          .map((json) => ListingModel.fromJson(json))
          .toList(),
      'city': data['data']['city'],
      'count': data['data']['count'],
    };
  }

  // Get collaborative recommendations
  static Future<Map<String, dynamic>> getCollaborativeRecommendations({
    required String token,
    int limit = 10,
  }) async {
    final queryParams = <String, String>{
      'limit': limit.toString(),
    };

    final uri = Uri.parse('${AppConfig.apiBaseUrl}/marketplace/recommendations/collaborative')
        .replace(queryParameters: queryParams);
    final response = await http.get(uri, headers: _getHeaders(token));

    final data = _handleResponse(response);
    return {
      'recommendations': (data['data']['recommendations'] as List)
          .map((json) => ListingModel.fromJson(json))
          .toList(),
      'count': data['data']['count'],
    };
  }

  // Get content-based recommendations
  static Future<Map<String, dynamic>> getContentBasedRecommendations({
    required String token,
    int limit = 10,
  }) async {
    final queryParams = <String, String>{
      'limit': limit.toString(),
    };

    final uri = Uri.parse('${AppConfig.apiBaseUrl}/marketplace/recommendations/content-based')
        .replace(queryParameters: queryParams);
    final response = await http.get(uri, headers: _getHeaders(token));

    final data = _handleResponse(response);
    return {
      'recommendations': (data['data']['recommendations'] as List)
          .map((json) => ListingModel.fromJson(json))
          .toList(),
      'count': data['data']['count'],
    };
  }

  // Get user preferences
  static Future<Map<String, dynamic>> getUserPreferences({
    required String token,
  }) async {
    final uri = Uri.parse('${AppConfig.apiBaseUrl}/marketplace/recommendations/preferences');
    final response = await http.get(uri, headers: _getHeaders(token));

    final data = _handleResponse(response);
    return data['data'];
  }

  // Track listing click
  static Future<void> trackListingClick({
    required String listingId,
    required String token,
  }) async {
    final response = await http.post(
      Uri.parse('${AppConfig.apiBaseUrl}/marketplace/recommendations/track-click'),
      headers: _getHeaders(token),
      body: json.encode({'listingId': listingId}),
    );
    _handleResponse(response);
  }

  // REVIEW SERVICES

  static Future<Map<String, dynamic>> getListingReviews({
    required String listingId,
    int page = 1,
    int limit = 10,
    String? token,
  }) async {
    final uri = Uri.parse(
      '${AppConfig.apiBaseUrl}/marketplace/reviews/listing/$listingId',
    ).replace(queryParameters: {
      'page': page.toString(),
      'limit': limit.toString(),
    });

    final response = await http.get(uri, headers: _getHeaders(token));
    final data = _handleResponse(response);
    return data['data'];
  }

  static Future<Map<String, dynamic>> createReview({
    required String listingId,
    required double rating,
    String? review,
    required String token,
  }) async {
    final response = await http.post(
      Uri.parse('${AppConfig.apiBaseUrl}/marketplace/reviews'),
      headers: _getHeaders(token),
      body: json.encode({
        'listingId': listingId,
        'rating': rating,
        'comment': review,
      }),
    );
    final data = _handleResponse(response);
    return data['data'];
  }

  static Future<Map<String, dynamic>> updateReview({
    required String reviewId,
    required String token,
    double? rating,
    String? review,
  }) async {
    final body = <String, dynamic>{};
    if (rating != null) body['rating'] = rating;
    if (review != null) body['comment'] = review;

    final response = await http.put(
      Uri.parse('${AppConfig.apiBaseUrl}/marketplace/reviews/$reviewId'),
      headers: _getHeaders(token),
      body: json.encode(body),
    );
    final data = _handleResponse(response);
    return data['data'];
  }

  static Future<void> deleteReview({
    required String reviewId,
    required String token,
  }) async {
    final response = await http.delete(
      Uri.parse('${AppConfig.apiBaseUrl}/marketplace/reviews/$reviewId'),
      headers: _getHeaders(token),
    );
    _handleResponse(response);
  }

  static Future<void> reportReview({
    required String reviewId,
    required String token,
    String? reason,
    String? description,
  }) async {
    final response = await http.post(
      Uri.parse('${AppConfig.apiBaseUrl}/marketplace/reviews/$reviewId/report'),
      headers: _getHeaders(token),
      body: json.encode({
        if (reason != null) 'reason': reason,
        if (description != null) 'description': description,
      }),
    );
    _handleResponse(response);
  }
}
