import 'package:front/model/users/user_model.dart';

class ListingModel {
  String? id;
  String title;
  String description;
  double price;
  double? originalPrice;
  String category;
  String? subcategory;
  String brand;
  int? year;
  String condition;
  int? mileage;
  String? fuelType;
  String? transmission;
  String? color;
  List<String> images;
  ListingLocation location;
  User? seller;
  bool isActive;
  bool isFeatured;
  int viewCount;
  int favoriteCount;
  bool isAuction;
  DateTime? auctionEndTime;
  double? startingBid;
  double? currentBid;
  int? bidIncrement;
  bool isNegotiable;
  double? minimumOffer;
  int quantity;
  int originalQuantity;
  String status;
  String? soldTo;
  DateTime? soldAt;
  double? soldPrice;
  DateTime? createdAt;
  DateTime? updatedAt;

  ListingModel({
    this.id,
    required this.title,
    required this.description,
    required this.price,
    this.originalPrice,
    required this.category,
    this.subcategory,
    required this.brand,
    this.year,
    required this.condition,
    this.mileage,
    this.fuelType,
    this.transmission,
    this.color,
    required this.images,
    required this.location,
    this.seller,
    this.isActive = true,
    this.isFeatured = false,
    this.viewCount = 0,
    this.favoriteCount = 0,
    this.isAuction = false,
    this.auctionEndTime,
    this.startingBid,
    this.currentBid,
    this.bidIncrement,
    this.isNegotiable = true,
    this.minimumOffer,
    this.quantity = 1,
    this.originalQuantity = 1,
    this.status = 'active',
    this.soldTo,
    this.soldAt,
    this.soldPrice,
    this.createdAt,
    this.updatedAt,
  });

  factory ListingModel.fromJson(Map<String, dynamic> json) {
    return ListingModel(
      id: json['_id'] ?? json['id'] ?? '',
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      price: (json['price'] as num).toDouble(),
      originalPrice: json['originalPrice'] != null
          ? (json['originalPrice'] as num).toDouble()
          : null,
      category: json['category'] ?? '',
      subcategory: json['subcategory'],
      brand: json['brand'] ?? '',
      year: json['year'],
      condition: json['condition'] ?? '',
      mileage: json['mileage'],
      fuelType: json['fuelType'],
      transmission: json['transmission'],
      color: json['color'],
      images: List<String>.from(json['images'] ?? []),
      location: ListingLocation.fromJson(json['location'] ?? {}),
      seller: json['seller'] != null ? User.fromJson(json['seller']) : null,
      isActive: json['isActive'] ?? true,
      isFeatured: json['isFeatured'] ?? false,
      viewCount: json['viewCount'] ?? 0,
      favoriteCount: json['favoriteCount'] ?? 0,
      isAuction: json['isAuction'] ?? false,
      auctionEndTime: json['auctionEndTime'] != null
          ? DateTime.parse(json['auctionEndTime'])
          : null,
      startingBid: json['startingBid'] != null
          ? (json['startingBid'] as num).toDouble()
          : null,
      currentBid: json['currentBid'] != null
          ? (json['currentBid'] as num).toDouble()
          : null,
      bidIncrement: json['bidIncrement'],
      isNegotiable: json['isNegotiable'] ?? true,
      minimumOffer: json['minimumOffer'] != null
          ? (json['minimumOffer'] as num).toDouble()
          : null,
      quantity: json['quantity'] ?? 1, // Default to 1 to match backend schema
      originalQuantity:
          json['originalQuantity'] ?? 1, // Default to 1 to match backend schema
      status: json['status'] ?? 'active',
      soldTo: json['soldTo'],
      soldAt: json['soldAt'] != null ? DateTime.parse(json['soldAt']) : null,
      soldPrice: json['soldPrice'] != null
          ? (json['soldPrice'] as num).toDouble()
          : null,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : null,
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'])
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'description': description,
    'price': price,
    'originalPrice': originalPrice,
    'category': category,
    'subcategory': subcategory,
    'brand': brand,
    'year': year,
    'condition': condition,
    'mileage': mileage,
    'fuelType': fuelType,
    'transmission': transmission,
    'color': color,
    'images': images,
    'location': location.toJson(),
    'seller': seller?.toJson(),
    'isActive': isActive,
    'isFeatured': isFeatured,
    'viewCount': viewCount,
    'favoriteCount': favoriteCount,
    'isAuction': isAuction,
    'auctionEndTime': auctionEndTime?.toIso8601String(),
    'startingBid': startingBid,
    'currentBid': currentBid,
    'bidIncrement': bidIncrement,
    'isNegotiable': isNegotiable,
    'minimumOffer': minimumOffer,
    'quantity': quantity,
    'originalQuantity': originalQuantity,
    'status': status,
    'soldTo': soldTo,
    'soldAt': soldAt?.toIso8601String(),
    'soldPrice': soldPrice,
    'createdAt': createdAt?.toIso8601String(),
    'updatedAt': updatedAt?.toIso8601String(),
  };

  // Helper methods
  String get formattedPrice =>
      'PKR ${price.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')}';

  String get formattedOriginalPrice => originalPrice != null
      ? 'PKR ${originalPrice!.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')}'
      : '';

  String get formattedMileage => mileage != null
      ? '${mileage!.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')} km'
      : '';

  String get auctionTimeRemaining {
    if (!isAuction || auctionEndTime == null) return '';
    final now = DateTime.now();
    final difference = auctionEndTime!.difference(now);

    if (difference.isNegative) return 'Auction ended';

    final days = difference.inDays;
    final hours = difference.inHours % 24;
    final minutes = difference.inMinutes % 60;

    if (days > 0) {
      return '${days}d ${hours}h ${minutes}m';
    } else if (hours > 0) {
      return '${hours}h ${minutes}m';
    } else {
      return '${minutes}m';
    }
  }

  bool get isAuctionActive =>
      isAuction &&
      auctionEndTime != null &&
      DateTime.now().isBefore(auctionEndTime!);

  bool get isInStock => quantity > 0;

  String get stockStatus {
    if (quantity <= 0) return 'Out of stock';
    if (quantity == 1) return 'Last item';
    if (quantity <= 5) return 'Only ${quantity} left';
    return 'In stock (${quantity} available)';
  }
}

class ListingLocation {
  String city;
  String? address;

  ListingLocation({required this.city, this.address});

  factory ListingLocation.fromJson(Map<String, dynamic> json) {
    return ListingLocation(city: json['city'] ?? '', address: json['address']);
  }

  Map<String, dynamic> toJson() => {'city': city, 'address': address};
}
