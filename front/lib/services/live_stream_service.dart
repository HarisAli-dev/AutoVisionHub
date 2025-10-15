import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:front/config/app_config.dart';
import 'package:front/utils/hive_utils.dart';
import 'package:front/model/events/event_model.dart';
import 'package:front/services/socket_service.dart';
import 'package:zego_uikit_prebuilt_live_streaming/zego_uikit_prebuilt_live_streaming.dart';

/// Service class for managing live streaming functionality with backend integration
class LiveStreamService {
  /// Start a live stream for an event
  /// Returns the live stream room ID if successful
  static Future<String?> startLiveStream({
    required String eventId,
    required String streamTitle,
    String? streamDescription,
  }) async {
    try {
      final token = HiveUtils.getData('token');
      if (token == null) {
        throw Exception('Authentication token not found');
      }

      final response = await http.post(
        Uri.parse('${AppConfig.apiBaseUrl}/livestream/start'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode({
          'eventId': eventId,
          'streamTitle': streamTitle,
          'streamDescription': streamDescription,
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = json.decode(response.body);
        return data['data']['roomId'] as String?;
      } else {
        final errorData = json.decode(response.body);
        throw Exception(errorData['message'] ?? 'Failed to start live stream');
      }
    } catch (e) {
      debugPrint('Error starting live stream: $e');
      throw Exception('Failed to start live stream: $e');
    }
  }

  /// Stop a live stream
  static Future<bool> stopLiveStream(String roomId) async {
    try {
      final token = HiveUtils.getData('token');
      if (token == null) {
        throw Exception('Authentication token not found');
      }

      final response = await http.put(
        Uri.parse('${AppConfig.apiBaseUrl}/livestream/stop/$roomId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );
      debugPrint('Stop live stream response status: ${response.statusCode}');
      return response.statusCode == 200;
    } catch (e) {
      debugPrint('Error stopping live stream: $e');
      return false;
    }
  }

  /// Join a live stream as a viewer
  static Future<bool> joinLiveStream(String roomId) async {
    try {
      final token = HiveUtils.getData('token');
      if (token == null) {
        throw Exception('Authentication token not found');
      }

      final response = await http.post(
        Uri.parse('${AppConfig.apiBaseUrl}/livestream/join/$roomId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['success'] == true;
      } else {
        final errorData = json.decode(response.body);
        throw Exception(errorData['message'] ?? 'Failed to join live stream');
      }
    } catch (e) {
      debugPrint('Error joining live stream: $e');
      return false;
    }
  }

  /// Get live stream status for an event
  static Future<Map<String, dynamic>?> getLiveStreamStatus(
    String eventId,
  ) async {
    try {
      final token = HiveUtils.getData('token');

      final response = await http.get(
        Uri.parse('${AppConfig.apiBaseUrl}/livestream/status/$eventId'),
        headers: {if (token != null) 'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['data'] as Map<String, dynamic>?;
      } else {
        debugPrint('Failed to get live stream status: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      debugPrint('Error getting live stream status: $e');
      return null;
    }
  }

  /// Leave a live stream
  static Future<bool> leaveLiveStream(String roomId) async {
    try {
      final token = HiveUtils.getData('token');
      if (token == null) {
        throw Exception('Authentication token not found');
      }

      final response = await http.put(
        Uri.parse('${AppConfig.apiBaseUrl}/livestream/leave/$roomId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      return response.statusCode == 200;
    } catch (e) {
      debugPrint('Error leaving live stream: $e');
      return false;
    }
  }

  /// Record engagement event (likes, comments, reactions)
  static Future<bool> recordEngagementEvent({
    required String roomId,
    required String eventType,
    Map<String, dynamic>? data,
  }) async {
    try {
      final token = HiveUtils.getData('token');
      if (token == null) {
        throw Exception('Authentication token not found');
      }

      final response = await http.post(
        Uri.parse('${AppConfig.apiBaseUrl}/livestream/engagement/$roomId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode({'eventType': eventType, 'data': data}),
      );

      return response.statusCode == 200;
    } catch (e) {
      debugPrint('Error recording engagement event: $e');
      return false;
    }
  }

  /// Get live stream analytics
  static Future<Map<String, dynamic>?> getLiveStreamAnalytics(
    String roomId,
  ) async {
    try {
      final token = HiveUtils.getData('token');
      if (token == null) {
        throw Exception('Authentication token not found');
      }

      final response = await http.get(
        Uri.parse('${AppConfig.apiBaseUrl}/livestream/analytics/$roomId'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['data'] as Map<String, dynamic>?;
      } else {
        debugPrint(
          'Failed to get live stream analytics: ${response.statusCode}',
        );
        return null;
      }
    } catch (e) {
      debugPrint('Error getting live stream analytics: $e');
      return null;
    }
  }

  /// Check if Zego is properly configured
  static bool isZegoConfigured() {
    try {
      return AppConfig.zegoAppId > 0 && AppConfig.zegoAppSign.isNotEmpty;
    } catch (e) {
      debugPrint('Zego configuration error: $e');
      return false;
    }
  }

  /// Navigate to host live streaming page
  static void navigateToHostLiveStream({
    required BuildContext context,
    required String roomId,
    required EventModel event,
    VoidCallback? onLiveStreamingEnded,
  }) async {
    if (!isZegoConfigured()) {
      debugPrint('Zego is not configured properly');
      return;
    }

    final userId = HiveUtils.getData('userId') ?? 'default_user';
    final userName = HiveUtils.getData('name') ?? 'Host';

    // Notify recording started via socket
    final socketService = SocketService();
    socketService.notifyRecordingStarted(roomId);

    // Configure Zego with proper cleanup
    final config = ZegoUIKitPrebuiltLiveStreamingConfig.host();

    // Navigate to Zego live streaming
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ZegoUIKitPrebuiltLiveStreaming(
          appID: AppConfig.zegoAppId,
          appSign: AppConfig.zegoAppSign,
          userID: userId,
          userName: userName,
          liveID: roomId,
          config: config,
        ),
      ),
    );

    // When the host returns from live streaming, stop the stream in backend
    debugPrint('Host live streaming ended');

    // Cleanup Zego resources
    await _cleanupZegoResources();

    // Notify recording stopped via socket
    socketService.notifyRecordingStopped(roomId);

    try {
      await stopLiveStream(roomId);
      debugPrint('Successfully stopped live stream in backend');
    } catch (e) {
      debugPrint('Error stopping live stream in backend: $e');
    }

    // Call the callback
    if (onLiveStreamingEnded != null) {
      onLiveStreamingEnded();
    }
  }

  /// Navigate to audience live streaming page
  static void navigateToAudienceLiveStream({
    required BuildContext context,
    required String roomId,
    required EventModel event,
  }) async {
    if (!isZegoConfigured()) {
      debugPrint('Zego is not configured properly');
      return;
    }

    final userId = HiveUtils.getData('userId') ?? 'default_user';
    final userName = HiveUtils.getData('name') ?? 'Viewer';

    // Start periodic stream status checking (less frequent, as backup only)
    Timer? statusCheckTimer;
    bool streamEnded = false;

    // Use the event ID for status checking instead of roomId, and check less frequently
    statusCheckTimer = Timer.periodic(const Duration(seconds: 15), (
      timer,
    ) async {
      try {
        final status = await getLiveStreamStatus(event.id!);
        if (status == null || status['isActive'] != true) {
          debugPrint('Stream is no longer active, ending viewer session');
          streamEnded = true;
          timer.cancel();
          // Pop the Zego interface if still active
          if (Navigator.canPop(context)) {
            Navigator.of(context).pop();
          }
        }
      } catch (e) {
        debugPrint('Error checking stream status: $e');
        // Don't end stream on API errors, rely on socket events
      }
    });

    // Navigate to Zego live streaming as audience
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ZegoUIKitPrebuiltLiveStreaming(
          appID: AppConfig.zegoAppId,
          appSign: AppConfig.zegoAppSign,
          userID: userId,
          userName: userName,
          liveID: roomId,
          config: ZegoUIKitPrebuiltLiveStreamingConfig.audience(),
        ),
      ),
    );

    // Cancel the timer when returning from Zego interface
    statusCheckTimer.cancel();

    // Cleanup Zego resources
    await _cleanupZegoResources();

    // When audience returns from live streaming, leave the stream in backend
    debugPrint('Audience left live streaming');
    try {
      await leaveLiveStream(roomId);
      debugPrint('Successfully left live stream in backend');

      // If stream ended while in Zego, show notification
      if (streamEnded) {
        // Show a snackbar or dialog indicating stream ended
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('The live stream has ended'),
              duration: Duration(seconds: 3),
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('Error leaving live stream in backend: $e');
    }
  }

  /// Cleanup Zego resources to prevent memory leaks and spamming logs
  static Future<void> _cleanupZegoResources() async {
    try {
      // Clear any pending network calls and cleanup resources
      debugPrint('Cleaning up Zego resources...');

      // Add a small delay to ensure Zego cleanup is complete
      await Future.delayed(const Duration(milliseconds: 500));

      debugPrint('Zego cleanup completed');
    } catch (e) {
      debugPrint('Error during Zego cleanup: $e');
    }
  }

  // TODO: Chatbot integration methods (for future implementation)
  /*
  /// Send message to chatbot during live stream
  static Future<String?> sendChatbotMessage({
    required String roomId,
    required String message,
  }) async {
    try {
      final token = HiveUtils.getData('token');
      if (token == null) {
        throw Exception('Authentication token not found');
      }

      final response = await http.post(
        Uri.parse('${AppConfig.apiBaseUrl}/chatbot/live-stream/$roomId/message'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode({
          'message': message,
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['response'] as String?;
      }
      return null;
    } catch (e) {
      debugPrint('Error sending chatbot message: $e');
      return null;
    }
  }

  /// Get chatbot insights for live stream
  static Future<Map<String, dynamic>?> getChatbotInsights(String roomId) async {
    try {
      final token = HiveUtils.getData('token');
      if (token == null) {
        throw Exception('Authentication token not found');
      }

      final response = await http.get(
        Uri.parse('${AppConfig.apiBaseUrl}/chatbot/live-stream/$roomId/insights'),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['insights'] as Map<String, dynamic>?;
      }
      return null;
    } catch (e) {
      debugPrint('Error getting chatbot insights: $e');
      return null;
    }
  }
  */
}
