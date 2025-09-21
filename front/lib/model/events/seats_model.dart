import 'package:front/model/events/booking_model.dart';

enum SeatState { empty, booked, reserved }

// Data model for each seat
class Seat {
  String? id;
  int seatNumber;
  int gridX;
  int gridY;
  SeatState state;
  BookingModel? booking; // Made nullable to fix the error

  Seat({
    this.id,
    required this.seatNumber,
    required this.gridX,
    required this.gridY,
    this.state = SeatState.empty,
    this.booking,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'seatNumber': seatNumber,
      'gridX': gridX,
      'gridY': gridY,
      'state': state.toString().split('.').last,
      'booking': booking?.toJson(),
    };
  }

  factory Seat.fromJson(Map<String, dynamic> json) {
    return Seat(
      id: json['_id'] ?? json['id'] ?? '',
      seatNumber: json['seatNumber'],
      gridX: json['gridX'],
      gridY: json['gridY'],
      state: json['state'] == 'booked'
          ? SeatState.booked
          : json['state'] == 'reserved'
          ? SeatState.reserved
          : SeatState.empty,
      booking: json['booking'] != null
          ? BookingModel.fromJson(json['booking'])
          : null,
    );
  }
}
