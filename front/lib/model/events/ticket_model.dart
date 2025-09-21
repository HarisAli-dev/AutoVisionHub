import 'package:front/model/events/booking_model.dart';

class TicketModel {
  String? id;
  final int ticketNumber;
  bool? isBooked;
  BookingModel? booking;

  TicketModel({
    this.id,
    required this.ticketNumber,
    this.isBooked,
    this.booking,
  });

  TicketModel.empty(int ticketNum)
    : id = '',
      ticketNumber = ticketNum,
      isBooked = false,
      booking = BookingModel.empty();

  factory TicketModel.fromJson(Map<String, dynamic> json) {
    return TicketModel(
      id: json['_id'] ?? json['id'] ?? '',
      ticketNumber: json['ticketNumber'],
      isBooked: json['isBooked'],
      booking: json['booking'] != null
          ? BookingModel.fromJson(json['booking'])
          : null,
    );
  }
  Map<String, dynamic> toJson() => {
    'id': id,
    'ticketNumber': ticketNumber,
    'booking': booking?.toJson(),
    'isBooked': isBooked,
  };
}
