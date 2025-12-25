import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:front/main.dart';
import 'package:front/model/events/booking_model.dart';
import 'package:front/utils/hive_utils.dart';
import 'package:http/http.dart' as http;

class BookingController {
  static Future<bool> bookSeat(
    String eventId,
    int seatNumber,
    String userName,
    String userEmail,
    String userPhone,
  ) async {
    try {
      final token = HiveUtils.getData('token');
      final response = await http.post(
        Uri.parse('$apiUrl/event/bookSeat/$eventId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'seatNumber': seatNumber,
          'userName': userName,
          'userEmail': userEmail,
          'userPhone': userPhone,
        }),
      );
      debugPrint('Booking response status: ${response.statusCode}');
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        debugPrint('Booking response data: $data');
        return data['success'];
      } else {
        final error = jsonDecode(response.body);
        throw Exception('Failed to book seat: ${error['message']}');
      }
    } catch (e, stackTrace) {
      debugPrint('Error booking seat: $e');
      debugPrint('Stack trace: $stackTrace');
      return false;
    }
  }

  // book tickets
  static Future<bool> bookTickets(
    String eventId,
    int numberOfTickets,
    String userName,
    String userEmail,
    String userPhone,
  ) async {
    try {
      final token = HiveUtils.getData('token');
      final response = await http.post(
        Uri.parse('$apiUrl/event/bookTickets/$eventId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'numberOfTickets': numberOfTickets,
          'userName': userName,
          'userEmail': userEmail,
          'userPhone': userPhone,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['success'];
      } else {
        final error = jsonDecode(response.body);
        throw Exception('Failed to book tickets: ${error['message']}');
      }
    } catch (e, stackTrace) {
      debugPrint('Error booking tickets: $e');
      debugPrint('Stack trace: $stackTrace');
      return false;
    }
  }

  // Fetch all bookings for a specific event
  static Future<List<BookingModel>> fetchEventBookings(String eventId) async {
    try {
      final token = HiveUtils.getData('token');
      final response = await http.get(
        Uri.parse('$apiUrl/event/getEventBookings/$eventId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      debugPrint('Fetch bookings response status: ${response.statusCode}');
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        debugPrint('Fetch bookings response data: $data');

        if (data['success'] == true && data['data'] != null) {
          List<BookingModel> bookings = (data['data'] as List)
              .map((booking) => BookingModel.fromJson(booking))
              .toList();
          return bookings;
        }
        return [];
      } else {
        final error = jsonDecode(response.body);
        throw Exception('Failed to fetch bookings: ${error['message']}');
      }
    } catch (e, stackTrace) {
      debugPrint('Error fetching bookings: $e');
      debugPrint('Stack trace: $stackTrace');
      return [];
    }
  }

  // Delete a booking
  static Future<bool> deleteBooking(
    String eventId,
    String bookingType,
    int ticketOrSeatNumber,
  ) async {
    try {
      final token = HiveUtils.getData('token');
      final response = await http.delete(
        Uri.parse('$apiUrl/event/deleteBooking/$eventId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'bookingType': bookingType,
          'ticketOrSeatNumber': ticketOrSeatNumber,
        }),
      );

      debugPrint('Delete booking response status: ${response.statusCode}');
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        debugPrint('Delete booking response data: $data');
        return data['success'];
      } else {
        final error = jsonDecode(response.body);
        throw Exception('Failed to delete booking: ${error['message']}');
      }
    } catch (e, stackTrace) {
      debugPrint('Error deleting booking: $e');
      debugPrint('Stack trace: $stackTrace');
      return false;
    }
  }
}
