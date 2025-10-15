import 'package:flutter_dotenv/flutter_dotenv.dart';

class AppConfig {
  // Firebase Configuration
  static String get firebaseProjectId =>
      dotenv.env['FIREBASE_PROJECT_ID'] ?? 'auto-vision-hub';
  static String get firebaseApiKey => dotenv.env['FIREBASE_API_KEY'] ?? '';
  static String get firebaseAuthDomain =>
      dotenv.env['FIREBASE_AUTH_DOMAIN'] ?? 'auto-vision-hub.firebaseapp.com';
  static String get firebaseStorageBucket =>
      dotenv.env['FIREBASE_STORAGE_BUCKET'] ?? 'auto-vision-hub.appspot.com';
  static String get firebaseMessagingSenderId =>
      dotenv.env['FIREBASE_MESSAGING_SENDER_ID'] ?? '';
  static String get firebaseAppId => dotenv.env['FIREBASE_APP_ID'] ?? '';

  // API Configuration
  static String get apiBaseUrl =>
      dotenv.env['API_BASE_URL'] ?? 'https://auto-vision-hub-nkilh.ondigitalocean.app/api';

  // Stripe Configuration
  static String get stripePublishableKey =>
      dotenv.env['STRIPE_PUBLISHABLE_KEY'] ??
      'pk_test_51S9RGbKLSXb0Puxvt6KTbJdYcByY6a0cU1XWQ22cvQdq5SKNKQTNfEM52bfOyuvjx0eeZeh1lybqgRzEBGNtjZUh00F6i2O4zw';

  // Zego Live Streaming Configuration
  static int get zegoAppId =>
      int.tryParse(dotenv.env['ZEGO_UITK_APP_ID'] ?? '') ?? 0;
  static String get zegoAppSign => dotenv.env['ZEGO_UITK_APP_SIGN'] ?? '';

  // Load environment variables
  static Future<void> loadEnv() async {
    await dotenv.load(fileName: ".env");
  }
}
