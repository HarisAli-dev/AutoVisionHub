import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:front/controller/events/booking_controller.dart';
import 'package:front/model/events/seats_model.dart';
import 'package:front/model/events/booking_model.dart';
import 'package:front/utils/hive_utils.dart';
import 'package:front/utils/app_colors.dart';

enum UserRole { event_manager, community_member }

class SeatProvider extends ChangeNotifier {
  List<Seat> _seats = [];
  final Set<int> _selectedSeats = <int>{};
  UserRole _userRole = UserRole.community_member;
  bool _isLoading = false;
  String? _errorMessage;

  // Getters
  List<Seat> get seats => List.unmodifiable(_seats);
  Set<int> get selectedSeats => Set.unmodifiable(_selectedSeats);
  UserRole get userRole => _userRole;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get hasSelectedSeats => _selectedSeats.isNotEmpty;
  int get selectedSeatsCount => _selectedSeats.length;

  // Get selected seat objects
  List<Seat> get selectedSeatObjects =>
      _seats.where((seat) => _selectedSeats.contains(seat.seatNumber)).toList();

  // Initialize provider with seats and user role
  void initializeSeats(List<Seat> seats, {UserRole? role}) {
    _seats = List.from(seats);
    _selectedSeats.clear();
    _userRole = role ?? _determineUserRole();
    _errorMessage = null;
    notifyListeners();
  }

  // Determine user role based on stored data
  UserRole _determineUserRole() {
    // You can implement logic to determine user role from stored data
    final userType = HiveUtils.getData('userType');
    return userType == 'event_manager'
        ? UserRole.event_manager
        : UserRole.community_member;
  }

  // Set user role manually
  void setUserRole(UserRole role) {
    _userRole = role;
    _selectedSeats.clear(); // Clear selections when role changes
    notifyListeners();
  }

  // Toggle seat selection/state based on user role
  bool toggleSeat(int seatNumber) {
    final seatIndex = _seats.indexWhere(
      (seat) => seat.seatNumber == seatNumber,
    );
    if (seatIndex == -1) return false;

    final seat = _seats[seatIndex];

    if (_userRole == UserRole.event_manager) {
      return _handleEventManagerSeatToggle(seat);
    } else {
      return _handleCustomerSeatToggle(seat);
    }
  }

  // Event Manager can only toggle between empty and reserved
  bool _handleEventManagerSeatToggle(Seat seat) {
    if (seat.state == SeatState.booked) {
      _setError('Cannot modify booked seats');
      return false;
    }

    if (seat.state == SeatState.empty) {
      seat.state = SeatState.reserved;
      _addToSelection(seat.seatNumber);
    } else if (seat.state == SeatState.reserved) {
      seat.state = SeatState.empty;
      _removeFromSelection(seat.seatNumber);
    }

    _clearError();
    notifyListeners();
    return true;
  }

  // Customer can only select empty seats for booking
  bool _handleCustomerSeatToggle(Seat seat) {
    if (seat.state == SeatState.booked) {
      _setError('This seat is already booked');
      return false;
    }

    if (seat.state == SeatState.reserved) {
      _setError('This seat is reserved and cannot be booked');
      return false;
    }

    if (seat.state == SeatState.empty) {
      if (_selectedSeats.contains(seat.seatNumber)) {
        _removeFromSelection(seat.seatNumber);
      } else {
        _addToSelection(seat.seatNumber);
      }
    }

    _clearError();
    notifyListeners();
    return true;
  }

  // Add seat to selection
  void _addToSelection(int seatNumber) {
    _selectedSeats.add(seatNumber);
  }

  // Remove seat from selection
  void _removeFromSelection(int seatNumber) {
    _selectedSeats.remove(seatNumber);
  }

  // Clear all selections
  void clearSelections() {
    _selectedSeats.clear();
    notifyListeners();
  }

  // Check if seat can be interacted with based on user role
  bool canInteractWithSeat(Seat seat) {
    if (_userRole == UserRole.event_manager) {
      return seat.state != SeatState.booked;
    } else {
      return seat.state == SeatState.empty;
    }
  }

  // Get seat color based on state and selection
  Color getSeatColor(Seat seat) {
    // If seat is selected, show a different color
    if (_selectedSeats.contains(seat.seatNumber)) {
      return _userRole == UserRole.event_manager
          ? Colors
                .purple // Purple for manager selections
          : Colors.green; // Green for customer selections
    }

    // Default state colors using AppColors
    switch (seat.state) {
      case SeatState.empty:
        return AppColors.seatEmptyColor;
      case SeatState.booked:
        return AppColors.seatBookedColor;
      case SeatState.reserved:
        return AppColors.seatReservedColor;
    }
  }

  // Book selected seats (Customer only)
  Future<bool> bookSelectedSeats({
    required String eventId,
    required String userName,
    required String userEmail,
    required String userPhone,
  }) async {
    if (_userRole != UserRole.community_member) {
      _setError('Only community members can book seats');
      return false;
    }

    if (_selectedSeats.isEmpty) {
      _setError('No seats selected');
      return false;
    }

    _setLoading(true);

    try {
      final userId = HiveUtils.getData('userId');

      // Book each selected seat
      for (final seatNumber in _selectedSeats) {
        final seatIndex = _seats.indexWhere(
          (seat) => seat.seatNumber == seatNumber,
        );
        if (seatIndex != -1) {
          final seat = _seats[seatIndex];

          // Create booking
          seat.booking = BookingModel(
            userId: userId,
            userName: userName,
            userEmail: userEmail,
            userPhoneNumber: userPhone,
            eventId: eventId,
            bookingType: 'seat',
            ticketOrSeatNumber: seatNumber,
            bookingDate: DateTime.now(),
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          );

          seat.state = SeatState.booked;
        }

      if(await BookingController.bookSeat(
          eventId,
          seatNumber,
          userName,
          userEmail,
          userPhone,
        )) {
          debugPrint('Seat $seatNumber booked successfully');
        } else {
          throw Exception('Failed to book seat $seatNumber');
      }
    }

      _selectedSeats.clear();
      _clearError();
      _setLoading(false);
      notifyListeners();
      return true;
    } catch (e) {
      _setError('Failed to book seats: $e');
      _setLoading(false);
      return false;
    }
  }

  // Reserve selected seats (Event Manager only)
  Future<bool> reserveSelectedSeats() async {
    if (_userRole != UserRole.event_manager) {
      _setError('Only event managers can reserve seats');
      return false;
    }

    if (_selectedSeats.isEmpty) {
      _setError('No seats selected');
      return false;
    }

    _setLoading(true);

    try {
      // Reserve each selected seat
      for (final seatNumber in _selectedSeats) {
        final seatIndex = _seats.indexWhere(
          (seat) => seat.seatNumber == seatNumber,
        );
        if (seatIndex != -1) {
          _seats[seatIndex].state = SeatState.reserved;
        }
      }

      // TODO: Make API call to backend
      // await SeatController.reserveSeats(...);

      _selectedSeats.clear();
      _clearError();
      _setLoading(false);
      notifyListeners();
      return true;
    } catch (e) {
      _setError('Failed to reserve seats: $e');
      _setLoading(false);
      return false;
    }
  }

  // Unreserve seats (Event Manager only)
  Future<bool> unreserveSeats(List<int> seatNumbers) async {
    if (_userRole != UserRole.event_manager) {
      _setError('Only event managers can unreserve seats');
      return false;
    }

    _setLoading(true);

    try {
      for (final seatNumber in seatNumbers) {
        final seatIndex = _seats.indexWhere(
          (seat) => seat.seatNumber == seatNumber,
        );
        if (seatIndex != -1 && _seats[seatIndex].state == SeatState.reserved) {
          _seats[seatIndex].state = SeatState.empty;
        }
      }

      // TODO: Make API call to backend
      // await SeatController.unreserveSeats(...);

      _clearError();
      _setLoading(false);
      notifyListeners();
      return true;
    } catch (e) {
      _setError('Failed to unreserve seats: $e');
      _setLoading(false);
      return false;
    }
  }

  // Get statistics
  Map<String, int> getSeatStatistics() {
    final stats = <String, int>{
      'total': _seats.length,
      'empty': 0,
      'booked': 0,
      'reserved': 0,
      'selected': _selectedSeats.length,
    };

    for (final seat in _seats) {
      switch (seat.state) {
        case SeatState.empty:
          stats['empty'] = stats['empty']! + 1;
          break;
        case SeatState.booked:
          stats['booked'] = stats['booked']! + 1;
          break;
        case SeatState.reserved:
          stats['reserved'] = stats['reserved']! + 1;
          break;
      }
    }

    return stats;
  }

  // Helper methods
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String error) {
    _errorMessage = error;
    notifyListeners();
  }

  void _clearError() {
    _errorMessage = null;
  }

  // Update single seat state
  void updateSeatState(int seatNumber, SeatState newState) {
    final seatIndex = _seats.indexWhere(
      (seat) => seat.seatNumber == seatNumber,
    );
    if (seatIndex != -1) {
      _seats[seatIndex].state = newState;
      notifyListeners();
    }
  }

  // Get seat by number
  Seat? getSeatByNumber(int seatNumber) {
    try {
      return _seats.firstWhere((seat) => seat.seatNumber == seatNumber);
    } catch (e) {
      return null;
    }
  }

  // Check if any seats are available for booking
  bool get hasAvailableSeats =>
      _seats.any((seat) => seat.state == SeatState.empty);

  // Get available seats count
  int get availableSeatsCount =>
      _seats.where((seat) => seat.state == SeatState.empty).length;

  // Dispose
  @override
  void dispose() {
    _seats.clear();
    _selectedSeats.clear();
    super.dispose();
  }
}
