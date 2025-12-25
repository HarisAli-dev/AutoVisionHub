class BookingModel {
  String? userId;
  String? userName;
  String? userEmail;
  String? userPhoneNumber;
  String? eventId;
  String bookingType;
  DateTime? bookingDate;
  int ticketOrSeatNumber;
  DateTime? createdAt;
  DateTime? updatedAt;

  BookingModel.empty()
    : userId = '',
      userName = '',
      userEmail = '',
      userPhoneNumber = '',
      eventId = '',
      bookingType = '',
      ticketOrSeatNumber = 0,
      bookingDate = DateTime.now(),
      createdAt = null,
      updatedAt = null;

  BookingModel({
    this.userId,
    this.userName,
    this.userEmail,
    this.userPhoneNumber,
    this.eventId,
    required this.bookingType,
    this.bookingDate,
    required this.ticketOrSeatNumber,
    this.createdAt,
    this.updatedAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'userName': userName,
      'userEmail': userEmail,
      'userPhoneNumber': userPhoneNumber,
      'eventId': eventId,
      'bookingType': bookingType,
      'ticketOrSeatNumber': ticketOrSeatNumber,
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }

  factory BookingModel.fromJson(Map<String, dynamic> json) {
    return BookingModel(
      userId: json['userId'] as String?,
      userName: json['userName'] as String?,
      userEmail: json['userEmail'] as String?,
      userPhoneNumber: json['userPhoneNumber'] as String?,
      eventId: json['eventId'] as String?,
      bookingType: json['bookingType'] as String? ?? '',
      bookingDate: json['bookingDate'] != null
          ? DateTime.parse(json['bookingDate'])
          : null,
      ticketOrSeatNumber: json['ticketOrSeatNumber'] as int? ?? 0,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : null,
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'])
          : null,
    );
  }
}
