import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:front/firebase_options.dart';
import 'package:front/utils/hive_utils.dart';
import 'package:front/services/notification_service.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

class FirebaseApi {
  // Firebase Messaging instance
  static final FirebaseMessaging _firebaseMessaging =
      FirebaseMessaging.instance;

  // Local notifications plugin
  static final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  static AndroidNotificationDetails _getAndroidNotificationDetails({
    String? largeIconPath,
    StyleInformation? styleInformation,
  }) {
    return AndroidNotificationDetails(
      'autovisionhub_channel',
      'AutoVisionHub Notifications',
      channelDescription: 'Notifications for messages and updates',
      importance: Importance.high,
      priority: Priority.high,
      icon:
          '@mipmap/ic_launcher', // Small icon (left side - must be drawable resource)
      color: const Color(0xFFFF6B35),
      largeIcon: largeIconPath != null
          ? FilePathAndroidBitmap(largeIconPath)
          : null,
      styleInformation: styleInformation,
      // Show large icon as avatar (makes it circular and prominent)
      showWhen: true,
      // This makes the large icon appear in place of the small app icon visually
      visibility: NotificationVisibility.public,
    );
  }

  static const DarwinNotificationDetails _iosNotificationDetails =
      DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );

  // Navigation key for handling navigation from notifications
  static final GlobalKey<NavigatorState> navigatorKey =
      GlobalKey<NavigatorState>();

  /// Initialize Firebase and notification services
  static Future<void> initNotifications() async {
    try {
      // Initialize Firebase
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );

      // Request notification permissions
      await _requestPermissions();

      // Initialize local notifications
      await _initLocalNotifications();

      // Configure Firebase Messaging
      await _configureFirebaseMessaging();

      // Get and store FCM token
      await _getFCMToken();

      // Listen for token refresh
      _firebaseMessaging.onTokenRefresh.listen((String token) async {
        print('FCM token refreshed: $token');
        await NotificationService.updateFCMToken(token);
      });

      print('Firebase notifications initialized successfully');
    } catch (e) {
      print('Error initializing Firebase notifications: $e');
    }
  }

  /// Request notification permissions
  static Future<void> _requestPermissions() async {
    // Request FCM permissions
    final NotificationSettings settings = await _firebaseMessaging
        .requestPermission(
          alert: true,
          announcement: false,
          badge: true,
          carPlay: false,
          criticalAlert: false,
          provisional: false,
          sound: true,
        );

    // Request system notification permissions (Android 13+)
    if (!kIsWeb) {
      await Permission.notification.request();
    }

    print('Notification permission status: ${settings.authorizationStatus}');
  }

  /// Initialize local notifications
  static Future<void> _initLocalNotifications() async {
    // Android initialization settings
    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    // iOS initialization settings
    const DarwinInitializationSettings iosSettings =
        DarwinInitializationSettings(
          requestAlertPermission: true,
          requestBadgePermission: true,
          requestSoundPermission: true,
        );

    // Combined initialization settings
    const InitializationSettings initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    // Initialize the plugin
    await _localNotifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    // Create notification channel for Android
    await _createNotificationChannel();
  }

  /// Create notification channel for Android
  static Future<void> _createNotificationChannel() async {
    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      'autovisionhub_channel',
      'AutoVisionHub Notifications',
      description: 'Notifications for messages and updates',
      importance: Importance.high,
      sound: RawResourceAndroidNotificationSound('notification'),
    );

    await _localNotifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.createNotificationChannel(channel);
  }

  static FlutterLocalNotificationsPlugin get localNotificationsPlugin =>
      _localNotifications;

  static NotificationDetails _getNotificationDetails({
    String? largeIconPath,
    StyleInformation? styleInformation,
  }) {
    return NotificationDetails(
      android: _getAndroidNotificationDetails(
        largeIconPath: largeIconPath,
        styleInformation: styleInformation,
      ),
      iOS: _iosNotificationDetails,
    );
  }

  static NotificationDetails get defaultNotificationDetails =>
      _getNotificationDetails();

  /// Configure Firebase Messaging
  static Future<void> _configureFirebaseMessaging() async {
    // Handle foreground messages
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

    // Handle background messages
    FirebaseMessaging.onBackgroundMessage(_handleBackgroundMessage);

    // Handle notification taps when app is in background/terminated
    FirebaseMessaging.onMessageOpenedApp.listen(_handleNotificationTap);

    // Handle initial message when app is opened from notification
    final RemoteMessage? initialMessage = await _firebaseMessaging
        .getInitialMessage();
    if (initialMessage != null) {
      _handleNotificationTap(initialMessage);
    }
  }

  /// Get and store FCM token
  static Future<String?> _getFCMToken() async {
    try {
      final String? token = await _firebaseMessaging.getToken();
      if (token != null) {
        print('FCM Token: $token');

        // Send token to server and store locally
        await NotificationService.updateFCMToken(token);

        return token;
      }
    } catch (e) {
      print('Error getting FCM token: $e');
    }
    return null;
  }

  /// Send FCM token to backend server
  static Future<void> _sendTokenToServer(String token) async {
    try {
      final String? userId = HiveUtils.getData('userId');
      if (userId != null) {
        // TODO: Implement API call to save token to backend
        // await UserController.updateFCMToken(userId, token);
        print('Token sent to server for user: $userId');
      }
    } catch (e) {
      print('Error sending token to server: $e');
    }
  }

  /// Handle foreground messages
  static Future<void> _handleForegroundMessage(RemoteMessage message) async {
    print('Handling foreground message: ${message.messageId}');

    // Show local notification when app is in foreground
    await _showLocalNotification(message);
  }

  /// Handle background messages
  @pragma('vm:entry-point')
  static Future<void> _handleBackgroundMessage(RemoteMessage message) async {
    print('Handling background message: ${message.messageId}');
    // Background messages are automatically shown by FCM
  }

  /// Handle notification tap
  static void _handleNotificationTap(RemoteMessage message) {
    print('Notification tapped: ${message.messageId}');
    _navigateToScreen(message);
  }

  /// Handle local notification tap
  static void _onNotificationTapped(NotificationResponse response) {
    print('Local notification tapped: ${response.payload}');

    if (response.payload != null) {
      try {
        final Map<String, dynamic> data = jsonDecode(response.payload!);
        _navigateFromData(data);
      } catch (e) {
        print('Error parsing notification payload: $e');
      }
    }
  }

  /// Show local notification
  static Future<void> _showLocalNotification(RemoteMessage message) async {
    final Map<String, dynamic> data = message.data;
    final String title = message.notification?.title ?? 'AutoVisionHub';
    final String body = message.notification?.body ?? 'You have a new message';

    // Get sender info from data payload (not from notification object)
    final String? senderName = data['senderName'];
    final String? profileImageUrl = data['profileImageUrl'];

    // Download or create icon
    String? largeIconPath;
    if (profileImageUrl != null &&
        profileImageUrl.isNotEmpty &&
        profileImageUrl.startsWith('http')) {
      largeIconPath = await _downloadAndSaveProfileImage(profileImageUrl);
    } else if (senderName != null && senderName.isNotEmpty) {
      largeIconPath = await _createLetterIcon(senderName[0].toUpperCase());
    }

    // Use MessagingStyleInformation for chat-like appearance with profile picture
    final Person sender = Person(
      name: title,
      icon: largeIconPath != null
          ? BitmapFilePathAndroidIcon(largeIconPath)
          : null,
    );

    final MessagingStyleInformation messagingStyle = MessagingStyleInformation(
      sender,
      conversationTitle:
          null, // Don't show conversation title to avoid duplication
      messages: [Message(body, DateTime.now(), sender)],
    );

    await _localNotifications.show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title,
      body,
      _getNotificationDetails(
        largeIconPath: largeIconPath,
        styleInformation: messagingStyle,
      ),
      payload: jsonEncode(data),
    );
  }

  /// Navigate to appropriate screen based on message data
  static void _navigateToScreen(RemoteMessage message) {
    _navigateFromData(message.data);
  }

  /// Download and save profile image for notification icon
  static Future<String?> _downloadAndSaveProfileImage(String imageUrl) async {
    try {
      if (kIsWeb) return null;

      final http.Response response = await http.get(Uri.parse(imageUrl));
      if (response.statusCode != 200) return null;

      final Directory tempDir = await getTemporaryDirectory();
      final String fileName =
          'notification_${DateTime.now().millisecondsSinceEpoch}.png';
      final File file = File('${tempDir.path}/$fileName');

      await file.writeAsBytes(response.bodyBytes);
      return file.path;
    } catch (e) {
      print('Error downloading profile image: $e');
      return null;
    }
  }

  /// Create a letter icon for notification
  static Future<String?> _createLetterIcon(String letter) async {
    try {
      if (kIsWeb) return null;

      // For Android, we'll rely on the app icon with the letter in the title
      // Creating dynamic bitmap icons requires platform-specific code
      // which is complex for this use case
      return null;
    } catch (e) {
      print('Error creating letter icon: $e');
      return null;
    }
  }

  static Future<void> showSimpleNotification({
    required String title,
    required String body,
    String? payload,
  }) async {
    if (kIsWeb) {
      debugPrint('[FirebaseApi] Notification skipped on web: $title');
      return;
    }

    await _localNotifications.show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title,
      body,
      defaultNotificationDetails,
      payload: payload,
    );
  }

  /// Navigate based on data
  static void _navigateFromData(Map<String, dynamic> data) {
    final BuildContext? context = navigatorKey.currentContext;
    if (context == null) return;

    final String? type = data['type'];
    final String? targetId = data['targetId'];

    switch (type) {
      case 'chat_message':
        if (targetId != null) {
          Navigator.of(context).pushNamed(
            '/chat',
            arguments: {
              'chatId': targetId,
              'chatName': data['chatName'] ?? 'Chat',
            },
          );
        }
        break;

      case 'group_message':
        if (targetId != null) {
          Navigator.of(context).pushNamed(
            '/group',
            arguments: {
              'groupId': targetId,
              'groupName': data['groupName'] ?? 'Group',
            },
          );
        }
        break;

      case 'event_booking':
        if (targetId != null) {
          Navigator.of(
            context,
          ).pushNamed('/event', arguments: {'eventId': targetId});
        }
        break;

      default:
        // Navigate to home screen
        Navigator.of(
          context,
        ).pushNamedAndRemoveUntil('/communityMemberHome', (route) => false);
        break;
    }
  }

  /// Subscribe to topic
  static Future<void> subscribeToTopic(String topic) async {
    try {
      await _firebaseMessaging.subscribeToTopic(topic);
      print('Subscribed to topic: $topic');
    } catch (e) {
      print('Error subscribing to topic: $e');
    }
  }

  /// Unsubscribe from topic
  static Future<void> unsubscribeFromTopic(String topic) async {
    try {
      await _firebaseMessaging.unsubscribeFromTopic(topic);
      print('Unsubscribed from topic: $topic');
    } catch (e) {
      print('Error unsubscribing from topic: $e');
    }
  }

  /// Get current FCM token
  static Future<String?> getCurrentToken() async {
    return await _firebaseMessaging.getToken();
  }

  /// Refresh FCM token
  static Future<void> refreshToken() async {
    try {
      await _firebaseMessaging.deleteToken();
      await _getFCMToken();
    } catch (e) {
      print('Error refreshing token: $e');
    }
  }

  /// Send notification for chat message
  static Future<void> sendChatMessageNotification({
    required String recipientUserId,
    required String senderName,
    required String message,
    required String chatId,
    required String chatName,
  }) async {
    try {
      // TODO: Implement API call to send notification via backend
      final Map<String, dynamic> notificationData = {
        'type': 'chat_message',
        'targetId': chatId,
        'chatName': chatName,
        'senderName': senderName,
        'message': message,
        'recipientUserId': recipientUserId,
      };

      // This would be sent to your backend API which handles FCM
      print('Sending chat notification: $notificationData');
    } catch (e) {
      print('Error sending chat notification: $e');
    }
  }

  /// Send notification for group message
  static Future<void> sendGroupMessageNotification({
    required String groupId,
    required String groupName,
    required String senderName,
    required String message,
    required List<String> memberIds,
  }) async {
    try {
      // TODO: Implement API call to send notification via backend
      final Map<String, dynamic> notificationData = {
        'type': 'group_message',
        'targetId': groupId,
        'groupName': groupName,
        'senderName': senderName,
        'message': message,
        'memberIds': memberIds,
      };

      // This would be sent to your backend API which handles FCM
      print('Sending group notification: $notificationData');
    } catch (e) {
      print('Error sending group notification: $e');
    }
  }

  /// Clear all notifications
  static Future<void> clearAllNotifications() async {
    await _localNotifications.cancelAll();
  }

  /// Clear specific notification
  static Future<void> clearNotification(int id) async {
    await _localNotifications.cancel(id);
  }
}
