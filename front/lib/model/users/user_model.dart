class User {
  final String? id;
  final String name;
  final String email;
  final String password;
  final String phoneNumber;
  String? city;
  String? role;
  String? profileImageUrl;

  User.empty({
    this.id = '',
    this.name = '',
    this.email = '',
    this.password = '',
    this.phoneNumber = '',
    this.city = '',
    this.role = '',
    this.profileImageUrl = '',
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
    };
  }
}
