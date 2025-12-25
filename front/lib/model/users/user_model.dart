class User {
  final String? id;
  final String name;
  final String email;
  final String password;
  final String phoneNumber;
  String? city;
  String? role;
  String? profileImageUrl;
  List<String>? visitedItems;
  bool? isBanned;

  User.empty({
    this.id = '',
    this.name = '',
    this.email = '',
    this.password = '',
    this.phoneNumber = '',
    this.city = '',
    this.role = '',
    this.profileImageUrl = '',
    this.isBanned = false,
  });
  User({
    this.id,
    required this.name,
    required this.email,
    required this.password,
    required this.phoneNumber,
    this.city,
    this.role,
    this.profileImageUrl,
    this.visitedItems,
    this.isBanned = false,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['_id'] ?? '',
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      password: json['password'] ?? '',
      phoneNumber: json['phoneNumber'] ?? '',
      city: json['city'] ?? '',
      role: json['role'] ?? 'community_member',
      profileImageUrl: json['profileImageUrl'] ?? '',
      visitedItems: json['visitedItems'] != null
          ? List<String>.from(
              json['visitedItems'].map((item) => item.toString()),
            )
          : null,
      isBanned: json['isBanned'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'name': name,
      'email': email,
      'password': password,
      'phoneNumber': phoneNumber,
      'city': city,
      'role': role,
      'profilePicture': profileImageUrl,
      'visitedItems': visitedItems,
      'isBanned': isBanned,
    };
  }
}
