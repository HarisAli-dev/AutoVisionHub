import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:front/main.dart';
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
          'ticketIds': numberOfTickets,
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
}
