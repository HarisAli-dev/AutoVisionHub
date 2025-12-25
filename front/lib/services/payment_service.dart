import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:front/config/app_config.dart';
import 'package:front/utils/hive_utils.dart';

class PaymentService {
  static String baseUrl = '${AppConfig.apiBaseUrl}/payment';

  static String? _getToken() {
    return HiveUtils.getData('token');
  }

  static Map<String, String> _getHeaders() {
    final token = _getToken();
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  // ========== Payment Profile Methods ==========

  /// Create a new payment profile
  static Future<Map<String, dynamic>> createPaymentProfile({
    required String country,
    required String currency,
    required String accountHolderName,
    required String accountHolderType,
    String? email,
    String? businessType,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/profile/create'),
        headers: _getHeaders(),
        body: json.encode({
          'country': country,
          'currency': currency,
          'accountHolderName': accountHolderName,
          'accountHolderType': accountHolderType,
          'email': email,
          'businessType': businessType,
        }),
      );

      if (response.statusCode == 201) {
        return json.decode(response.body);
      }
      throw Exception('Failed to create payment profile: ${response.body}');
    } catch (e) {
      throw Exception('Error creating payment profile: $e');
    }
  }

  /// Get current user's payment profile
  static Future<Map<String, dynamic>> getPaymentProfile() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/profile'),
        headers: _getHeaders(),
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else if (response.statusCode == 404) {
        return {'success': false, 'message': 'Payment profile not found'};
      }
      throw Exception('Failed to get payment profile: ${response.body}');
    } catch (e) {
      throw Exception('Error getting payment profile: $e');
    }
  }

  /// Update payment profile settings
  static Future<Map<String, dynamic>> updatePaymentProfile({
    String? accountHolderName,
    bool? autoPayoutEnabled,
    int? minimumPayoutAmount,
    String? payoutSchedule,
  }) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/profile/update'),
        headers: _getHeaders(),
        body: json.encode({
          if (accountHolderName != null) 'accountHolderName': accountHolderName,
          if (autoPayoutEnabled != null) 'autoPayoutEnabled': autoPayoutEnabled,
          if (minimumPayoutAmount != null)
            'minimumPayoutAmount': minimumPayoutAmount,
          if (payoutSchedule != null) 'payoutSchedule': payoutSchedule,
        }),
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      }
      throw Exception('Failed to update payment profile: ${response.body}');
    } catch (e) {
      throw Exception('Error updating payment profile: $e');
    }
  }

  /// Add a payout method (bank account)
  static Future<Map<String, dynamic>> addPayoutMethod({
    required String accountNumber,
    required String routingNumber,
    required String accountHolderName,
    bool isDefault = false,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/profile/payout-method'),
        headers: _getHeaders(),
        body: json.encode({
          'accountNumber': accountNumber,
          'routingNumber': routingNumber,
          'accountHolderName': accountHolderName,
          'isDefault': isDefault,
        }),
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      }
      throw Exception('Failed to add payout method: ${response.body}');
    } catch (e) {
      throw Exception('Error adding payout method: $e');
    }
  }

  /// Remove a payout method
  static Future<Map<String, dynamic>> removePayoutMethod(
    String bankAccountId,
  ) async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/profile/payout-method/$bankAccountId'),
        headers: _getHeaders(),
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      }
      throw Exception('Failed to remove payout method: ${response.body}');
    } catch (e) {
      throw Exception('Error removing payout method: $e');
    }
  }

  /// Generate new onboarding link for Stripe Connect
  static Future<String> generateOnboardingLink() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/profile/onboarding-link'),
        headers: _getHeaders(),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['data']['onboardingUrl'];
      }
      throw Exception('Failed to generate onboarding link: ${response.body}');
    } catch (e) {
      throw Exception('Error generating onboarding link: $e');
    }
  }

  // ========== Transaction Methods ==========

  /// Create payment intent with automatic transfer to recipient
  static Future<Map<String, dynamic>> createPaymentIntent({
    required int amount,
    required String recipientUserId,
    required String transactionType,
    String? relatedEntityId,
    String? relatedEntityType,
    String? description,
    String currency = 'usd',
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/create-payment-intent'),
        headers: _getHeaders(),
        body: json.encode({
          'amount': amount,
          'currency': currency,
          'recipientUserId': recipientUserId,
          'transactionType': transactionType,
          'relatedEntityId': relatedEntityId,
          'relatedEntityType': relatedEntityType,
          'description': description,
        }),
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      }
      throw Exception('Failed to create payment intent: ${response.body}');
    } catch (e) {
      throw Exception('Error creating payment intent: $e');
    }
  }

  /// Get transaction history
  static Future<Map<String, dynamic>> getTransactionHistory({
    String? type,
    String? status,
    int limit = 50,
    int page = 1,
  }) async {
    try {
      final queryParams = {
        if (type != null) 'type': type,
        if (status != null) 'status': status,
        'limit': limit.toString(),
        'page': page.toString(),
      };

      final uri = Uri.parse(
        '$baseUrl/transactions',
      ).replace(queryParameters: queryParams);

      final response = await http.get(uri, headers: _getHeaders());

      if (response.statusCode == 200) {
        return json.decode(response.body);
      }
      throw Exception('Failed to get transaction history: ${response.body}');
    } catch (e) {
      throw Exception('Error getting transaction history: $e');
    }
  }

  /// Get earnings summary
  static Future<Map<String, dynamic>> getEarningsSummary() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/earnings'),
        headers: _getHeaders(),
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      }
      throw Exception('Failed to get earnings summary: ${response.body}');
    } catch (e) {
      throw Exception('Error getting earnings summary: $e');
    }
  }

  // ========== Helper Methods ==========

  /// Check if user has a payment profile
  static Future<bool> hasPaymentProfile() async {
    try {
      final result = await getPaymentProfile();
      return result['success'] == true;
    } catch (e) {
      return false;
    }
  }

  /// Format amount from cents to dollars
  static String formatAmount(double amountInCents, {String currency = 'USD'}) {
    final dollars = amountInCents / 100;
    return '\$${dollars.toStringAsFixed(2)}';
  }

  /// Convert dollars to cents
  static int dollarsToCents(double dollars) {
    return (dollars * 100).round();
  }
}
