import 'package:front/model/events/seats_model.dart';

class LayoutModel {
  String? id;
  String layoutName;
  int gridWidth;
  int gridHeight;
  List<Seat> seatList;
  final DateTime? createdAt;
  DateTime? updatedAt;

  LayoutModel({
    this.id,
    required this.layoutName,
    required this.gridWidth,
    required this.gridHeight,
    required this.seatList,
    this.createdAt,
    this.updatedAt,
  });

  // Factory constructor to create from JSON
  factory LayoutModel.fromJson(Map<String, dynamic> json) {
    return LayoutModel(
      id: json['_id'] ?? json['id'],
      layoutName: json['layoutName'] ?? '',
      gridWidth: json['gridWidth'] ?? 0,
      gridHeight: json['gridHeight'] ?? 0,
      seatList: json['seatList'] != null
          ? (json['seatList'] as List).map((seatJson) => Seat.fromJson(seatJson)).toList()
          : [],
      createdAt: json['createdAt'] != null ? DateTime.parse(json['createdAt']) : null,
      updatedAt: json['updatedAt'] != null ? DateTime.parse(json['updatedAt']) : null,
    );
  }

  // Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'layoutName': layoutName,
      'gridWidth': gridWidth,
      'gridHeight': gridHeight,
      'seatList': seatList.map((seat) => seat.toJson()).toList(),
    };
  }

  // Get total number of seats
  int get totalSeats => seatList.length;

  // Get number of booked seats
  int get bookedSeats => seatList.where((seat) => seat.state == SeatState.booked).length;

  // Get number of reserved seats
  int get reservedSeats => seatList.where((seat) => seat.state == SeatState.reserved).length;

  // Get number of available seats
  int get availableSeats => seatList.where((seat) => seat.state == SeatState.empty).length;

  // Get booking percentage
  double get bookingPercentage => totalSeats > 0 ? (bookedSeats / totalSeats) * 100 : 0;

  // Check if layout is valid (no seats outside grid bounds)
  bool get isValid {
    return seatList.every((seat) =>
      seat.gridX >= 0 &&
      seat.gridX < gridWidth &&
      seat.gridY >= 0 &&
      seat.gridY < gridHeight
    );
  }

  // Get seat at specific grid position
  Seat? getSeatAt(int gridX, int gridY) {
    try {
      return seatList.firstWhere((seat) => seat.gridX == gridX && seat.gridY == gridY);
    } catch (e) {
      return null;
    }
  }

  // Add a seat to the layout
  void addSeat(Seat seat) {
    // Check if seat already exists at this position
    if (getSeatAt(seat.gridX, seat.gridY) == null) {
      seatList.add(seat);
      updatedAt = DateTime.now();
    }
  }

  // Remove seat at specific position
  bool removeSeatAt(int gridX, int gridY) {
    final seatToRemove = getSeatAt(gridX, gridY);
    if (seatToRemove != null) {
      seatList.remove(seatToRemove);
      updatedAt = DateTime.now();
      return true;
    }
    return false;
  }

  // Remove seat by seat number
  bool removeSeatByNumber(int seatNumber) {
    final seatToRemove = seatList.where((seat) => seat.seatNumber == seatNumber).firstOrNull;
    if (seatToRemove != null) {
      seatList.remove(seatToRemove);
      updatedAt = DateTime.now();
      return true;
    }
    return false;
  }

  // Update seat state at specific position
  bool updateSeatState(int gridX, int gridY, SeatState newState) {
    final seat = getSeatAt(gridX, gridY);
    if (seat != null) {
      seat.state = newState;
      updatedAt = DateTime.now();
      return true;
    }
    return false;
  }

  // Re-index all seats (useful after adding/removing seats)
  void reIndexSeats() {
    // Sort seats by row (gridY) then by column (gridX)
    seatList.sort((a, b) {
      if (a.gridY != b.gridY) {
        return a.gridY.compareTo(b.gridY);
      }
      return a.gridX.compareTo(b.gridX);
    });

    // Re-assign seat numbers
    for (int i = 0; i < seatList.length; i++) {
      seatList[i].seatNumber = i;
    }
    
    updatedAt = DateTime.now();
  }
}