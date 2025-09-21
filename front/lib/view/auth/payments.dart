import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:front/main.dart';
import 'package:front/utils/hive_utils.dart';
import 'package:http/http.dart' as http;

class PaymentScreen extends StatefulWidget {
  const PaymentScreen({super.key});

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  Future<void> makePayment(int amount) async {
    try {
      // 1. Create Payment Intent on the server
      final paymentIntentResult = await _createPaymentIntent(
        amount: amount,
        currency: 'PKR',
      );
      if (paymentIntentResult == null || paymentIntentResult['error'] != null) {
        _showError('Failed to create payment intent.');
        return;
      }

      final clientSecret = paymentIntentResult['clientSecret'];

      // 2. Initialize the Payment Sheet
      await Stripe.instance.initPaymentSheet(
        paymentSheetParameters: SetupPaymentSheetParameters(
          paymentIntentClientSecret: clientSecret,
          merchantDisplayName: 'Auto Vision Hub',
        ),
      );

      // 3. Present the Payment Sheet
      await Stripe.instance.presentPaymentSheet();

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Payment Successful!')));
    } on StripeException catch (e) {
      _showError('Payment failed: ${e.error.localizedMessage}');
    } catch (e) {
      _showError('An unexpected error occurred: $e');
    }
  }

  Future<Map<String, dynamic>?> _createPaymentIntent({
    required int amount,
    required String currency,
  }) async {
    try {
      final token = HiveUtils.getData('token');
      final response = await http.post(
        Uri.parse('$apiUrl/payment/create-payment-intent'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'amount': amount, // e.g., 1000 for $10.00
          'currency': currency,
        }),
      );
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
    } catch (e) {
      print('Error creating payment intent: $e');
    }
    return null;
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Stripe Payment')),
      body: Center(
        child: ElevatedButton(
          onPressed: () => makePayment(
            20000,
          ), // Pass the amount in the smallest currency unit
          child: const Text('Pay Rs 200.00'),
        ),
      ),
    );
  }
}
