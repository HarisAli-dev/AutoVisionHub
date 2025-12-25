import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:zego_express_engine/zego_express_engine.dart';
import 'package:front/config/app_config.dart';
import 'package:front/utils/hive_utils.dart';

/// Service for managing ZEGOCLOUD low-level SDK integration
class ZegoService {
  static ZegoService? _instance;
  static ZegoService get instance => _instance ??= ZegoService._();

  ZegoService._();

  bool _isEngineCreated = false;
  String? _currentRoomId;
  StreamSubscription? _roomStateSubscription;
  StreamSubscription? _messageSubscription;

  // Callbacks
  void Function(List<ZegoBarrageMessageInfo>)? onMessageReceived;
  void Function(String roomId, ZegoRoomState state, int errorCode)?
  onRoomStateChanged;
  void Function(String streamId, ZegoRemoteStreamState state)?
  onRemoteStreamStateUpdate;
  void Function()? onStreamEnded;

  /// Initialize the ZEGO Express Engine
  Future<void> initEngine() async {
    if (_isEngineCreated) {
      debugPrint('🔧 ZEGO Engine already created');
      return;
    }

    try {
      debugPrint('🚀 Initializing ZEGO Express Engine...');

      // Create engine with profile
      await ZegoExpressEngine.createEngineWithProfile(
        ZegoEngineProfile(
          AppConfig.zegoAppId,
          ZegoScenario.Broadcast,
          appSign: AppConfig.zegoAppSign,
        ),
      );

      _isEngineCreated = true;
      debugPrint('✅ ZEGO Engine created successfully');

      // Set up event handlers
      _setupEventHandlers();
    } catch (e) {
      debugPrint('❌ Failed to create ZEGO engine: $e');
      rethrow;
    }
  }

  /// Set up event handlers for ZEGO callbacks
  void _setupEventHandlers() {
    // Room state changes
    ZegoExpressEngine.onRoomStateChanged =
        (
          String roomID,
          ZegoRoomStateChangedReason reason,
          int errorCode,
          Map<String, dynamic> extendedData,
        ) {
          debugPrint(
            '🏠 Room state changed: $roomID, reason: $reason, error: $errorCode',
          );

          ZegoRoomState state;
          if (errorCode == 0) {
            if (reason == ZegoRoomStateChangedReason.Logining) {
              state = ZegoRoomState.Connecting;
            } else if (reason == ZegoRoomStateChangedReason.Logined) {
              state = ZegoRoomState.Connected;
            } else if (reason == ZegoRoomStateChangedReason.Logout) {
              state = ZegoRoomState.Disconnected;
            } else {
              state = ZegoRoomState.Disconnected;
            }
          } else {
            state = ZegoRoomState.Disconnected;
          }

          onRoomStateChanged?.call(roomID, state, errorCode);
        };

    // Barrage (chat) messages
    ZegoExpressEngine.onIMRecvBarrageMessage =
        (String roomID, List<ZegoBarrageMessageInfo> messageList) {
          debugPrint(
            '💬 Received ${messageList.length} messages in room $roomID',
          );
          onMessageReceived?.call(messageList);
        };

    // Remote stream state update (using player state callback)
    ZegoExpressEngine.onPlayerStateUpdate =
        (
          String streamID,
          ZegoPlayerState state,
          int errorCode,
          Map<String, dynamic> extendedData,
        ) {
          debugPrint('📺 Player $streamID state: $state, error: $errorCode');

          ZegoRemoteStreamState remoteState;
          if (state == ZegoPlayerState.Playing) {
            remoteState = ZegoRemoteStreamState.Playing;
          } else {
            remoteState = ZegoRemoteStreamState.NoPlay;
          }

          onRemoteStreamStateUpdate?.call(streamID, remoteState);
        };

    // Room user update
    ZegoExpressEngine.onRoomUserUpdate =
        (String roomID, ZegoUpdateType updateType, List<ZegoUser> userList) {
          if (updateType == ZegoUpdateType.Add) {
            debugPrint(
              '👥 Users joined: ${userList.map((u) => u.userName).join(", ")}',
            );
          } else {
            debugPrint(
              '👋 Users left: ${userList.map((u) => u.userName).join(", ")}',
            );
          }
        };

    // Room stream update
    ZegoExpressEngine.onRoomStreamUpdate =
        (
          String roomID,
          ZegoUpdateType updateType,
          List<ZegoStream> streamList,
          Map<String, dynamic> extendedData,
        ) {
          if (updateType == ZegoUpdateType.Add) {
            debugPrint(
              '📹 Streams added: ${streamList.map((s) => s.streamID).join(", ")}',
            );
          } else {
            debugPrint(
              '🛑 Streams removed: ${streamList.map((s) => s.streamID).join(", ")}',
            );

            // If all streams removed, notify stream ended
            if (streamList.isNotEmpty) {
              onStreamEnded?.call();
            }
          }
        };
  }

  /// Get ZEGO authentication token from backend
  Future<String> getToken(String userId) async {
    try {
      final jwtToken = HiveUtils.getData('token');
      if (jwtToken == null) {
        throw Exception('JWT token not found');
      }

      final response = await http.get(
        Uri.parse('${AppConfig.apiBaseUrl}/zego/token?user_id=$userId'),
        headers: {'Authorization': 'Bearer $jwtToken'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['data']['token'] as String;
      } else {
        throw Exception('Failed to get ZEGO token: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('❌ Error getting ZEGO token: $e');
      rethrow;
    }
  }

  /// Login to a ZEGO room
  Future<void> loginRoom({
    required String roomId,
    required String userId,
    required String userName,
  }) async {
    try {
      if (!_isEngineCreated) {
        await initEngine();
      }

      debugPrint('🔐 Logging into room: $roomId as $userName ($userId)');

      // Get token from backend
      final token = await getToken(userId);

      // Create user
      final user = ZegoUser(userId, userName);

      // Create room config with token
      final config = ZegoRoomConfig(0, true, token);

      // Login to room
      await ZegoExpressEngine.instance.loginRoom(roomId, user, config: config);

      _currentRoomId = roomId;
      debugPrint('✅ Successfully logged into room: $roomId');
    } catch (e) {
      debugPrint('❌ Failed to login room: $e');
      rethrow;
    }
  }

  /// Logout from current room
  Future<void> logoutRoom() async {
    if (_currentRoomId == null) {
      debugPrint('⚠️ No active room to logout from');
      return;
    }

    try {
      debugPrint('🚪 Logging out from room: $_currentRoomId');
      await ZegoExpressEngine.instance.logoutRoom(_currentRoomId!);
      _currentRoomId = null;
      debugPrint('✅ Successfully logged out from room');
    } catch (e) {
      debugPrint('❌ Failed to logout room: $e');
    }
  }

  /// Start publishing stream (for host)
  Future<void> startPublishingStream(String streamId) async {
    try {
      debugPrint('📤 Starting to publish stream: $streamId');
      await ZegoExpressEngine.instance.startPublishingStream(streamId);
      debugPrint('✅ Started publishing stream successfully');
    } catch (e) {
      debugPrint('❌ Failed to start publishing: $e');
      rethrow;
    }
  }

  /// Stop publishing stream (for host)
  Future<void> stopPublishingStream() async {
    try {
      debugPrint('🛑 Stopping publishing stream');
      await ZegoExpressEngine.instance.stopPublishingStream();
      debugPrint('✅ Stopped publishing stream');
    } catch (e) {
      debugPrint('❌ Failed to stop publishing: $e');
    }
  }

  /// Start playing a remote stream (for audience)
  Future<void> startPlayingStream(String streamId) async {
    try {
      debugPrint('▶️ Starting to play stream: $streamId');
      await ZegoExpressEngine.instance.startPlayingStream(streamId);
      debugPrint('✅ Started playing stream successfully');
    } catch (e) {
      debugPrint('❌ Failed to start playing stream: $e');
      rethrow;
    }
  }

  /// Stop playing a remote stream
  Future<void> stopPlayingStream(String streamId) async {
    try {
      debugPrint('⏹️ Stopping playing stream: $streamId');
      await ZegoExpressEngine.instance.stopPlayingStream(streamId);
      debugPrint('✅ Stopped playing stream');
    } catch (e) {
      debugPrint('❌ Failed to stop playing stream: $e');
    }
  }

  /// Send barrage message (chat message)
  Future<bool> sendBarrageMessage(String message) async {
    if (_currentRoomId == null) {
      debugPrint('⚠️ No active room to send message');
      return false;
    }

    try {
      debugPrint('📨 Sending message: $message');
      await ZegoExpressEngine.instance.sendBarrageMessage(
        _currentRoomId!,
        message,
      );
      debugPrint('✅ Message sent successfully');
      return true;
    } catch (e) {
      debugPrint('❌ Failed to send message: $e');
      return false;
    }
  }

  /// Enable/disable camera
  Future<void> enableCamera(bool enable) async {
    try {
      await ZegoExpressEngine.instance.enableCamera(enable);
      debugPrint('📷 Camera ${enable ? "enabled" : "disabled"}');
    } catch (e) {
      debugPrint('❌ Failed to toggle camera: $e');
    }
  }

  /// Enable/disable microphone
  Future<void> enableMicrophone(bool enable) async {
    try {
      await ZegoExpressEngine.instance.muteMicrophone(!enable);
      debugPrint('🎤 Microphone ${enable ? "enabled" : "disabled"}');
    } catch (e) {
      debugPrint('❌ Failed to toggle microphone: $e');
    }
  }

  /// Switch camera (front/back)
  Future<void> switchCamera() async {
    try {
      await ZegoExpressEngine.instance.useFrontCamera(!await isFrontCamera());
      debugPrint('🔄 Camera switched');
    } catch (e) {
      debugPrint('❌ Failed to switch camera: $e');
    }
  }

  /// Check if using front camera
  Future<bool> isFrontCamera() async {
    try {
      // This is a workaround - ZEGO doesn't provide direct query
      // Default is front camera, so we track state
      return true;
    } catch (e) {
      return true;
    }
  }

  /// Get current room ID
  String? getCurrentRoomId() => _currentRoomId;

  /// Check if engine is created
  bool isEngineCreated() => _isEngineCreated;

  /// Destroy engine and cleanup
  Future<void> destroyEngine() async {
    if (!_isEngineCreated) return;

    try {
      debugPrint('🧹 Destroying ZEGO engine...');

      // Logout from room if still in one
      if (_currentRoomId != null) {
        await logoutRoom();
      }

      // Destroy engine
      await ZegoExpressEngine.destroyEngine();

      _isEngineCreated = false;
      _currentRoomId = null;

      debugPrint('✅ ZEGO engine destroyed');
    } catch (e) {
      debugPrint('❌ Failed to destroy engine: $e');
    }
  }

  /// Cleanup resources
  void dispose() {
    _roomStateSubscription?.cancel();
    _messageSubscription?.cancel();
    onMessageReceived = null;
    onRoomStateChanged = null;
    onRemoteStreamStateUpdate = null;
    onStreamEnded = null;
  }
}

/// Enum for room state
/// Enum for remote stream state
enum ZegoRemoteStreamState { NoPlay, Playing }
