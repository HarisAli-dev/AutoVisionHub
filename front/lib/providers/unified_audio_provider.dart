import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:record/record.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

class AudioProvider extends ChangeNotifier {
  // Recording components
  final AudioRecorder _audioRecorder = AudioRecorder();
  bool _isRecording = false;
  bool _isPaused = false;
  String? _recordingPath;
  Duration _recordingDuration = Duration.zero;
  Timer? _recordingTimer;

  // Playback components
  final AudioPlayer _audioPlayer = AudioPlayer();
  String? _currentlyPlayingId;
  bool _isPlaying = false;
  Duration _currentPosition = Duration.zero;
  Duration _totalDuration = Duration.zero;

  // Recording getters
  bool get isRecording => _isRecording;
  bool get isPaused => _isPaused;
  String? get recordingPath => _recordingPath;
  Duration get recordingDuration => _recordingDuration;
  String get formattedRecordingDuration => _formatDuration(_recordingDuration);

  // Playback getters
  String? get currentlyPlayingId => _currentlyPlayingId;
  bool get isPlaying => _isPlaying;
  Duration get currentPosition => _currentPosition;
  Duration get totalDuration => _totalDuration;
  AudioPlayer get audioPlayer => _audioPlayer;

  AudioProvider() {
    _initializePlayer();
  }

  void _initializePlayer() {
    // Listen to player state changes
    _audioPlayer.onPlayerStateChanged.listen((PlayerState state) {
      _isPlaying = state == PlayerState.playing;
      notifyListeners();
    });

    // Listen to position changes
    _audioPlayer.onPositionChanged.listen((Duration position) {
      _currentPosition = position;
      notifyListeners();
    });

    // Listen to duration changes
    _audioPlayer.onDurationChanged.listen((Duration duration) {
      _totalDuration = duration;
      notifyListeners();
    });

    // Listen to completion
    _audioPlayer.onPlayerComplete.listen((event) {
      _currentlyPlayingId = null;
      _isPlaying = false;
      _currentPosition = Duration.zero;
      _totalDuration = Duration.zero;
      notifyListeners();
    });
  }

  // Format duration to mm:ss
  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, "0");
    String twoDigitMinutes = twoDigits(duration.inMinutes.remainder(60));
    String twoDigitSeconds = twoDigits(duration.inSeconds.remainder(60));
    return "$twoDigitMinutes:$twoDigitSeconds";
  }

  // ==================== RECORDING METHODS ====================

  // Check microphone permission
  Future<bool> _checkMicrophonePermission() async {
    final status = await Permission.microphone.request();
    return status.isGranted;
  }

  // Start recording
  Future<bool> startRecording() async {
    try {
      // Check permission
      if (!await _checkMicrophonePermission()) {
        debugPrint('Microphone permission denied');
        return false;
      }

      // Generate unique file path
      final tempDir = await getTemporaryDirectory();
      _recordingPath =
          '${tempDir.path}/voice_message_${DateTime.now().millisecondsSinceEpoch}.aac';

      // Start recording
      await _audioRecorder.start(
        const RecordConfig(
          encoder: AudioEncoder.aacLc,
          bitRate: 128000,
          sampleRate: 44100,
        ),
        path: _recordingPath!,
      );

      _isRecording = true;
      _isPaused = false;
      _recordingDuration = Duration.zero;

      // Start timer
      _startRecordingTimer();

      notifyListeners();
      debugPrint('Recording started: $_recordingPath');
      return true;
    } catch (e) {
      debugPrint('Error starting recording: $e');
      return false;
    }
  }

  // Stop recording
  Future<String?> stopRecording() async {
    try {
      if (!_isRecording) return null;

      final path = await _audioRecorder.stop();
      _stopRecordingTimer();

      _isRecording = false;
      _isPaused = false;

      notifyListeners();
      debugPrint('Recording stopped: $path');
      return path;
    } catch (e) {
      debugPrint('Error stopping recording: $e');
      return null;
    }
  }

  // Pause recording
  Future<bool> pauseRecording() async {
    try {
      if (!_isRecording || _isPaused) return false;

      await _audioRecorder.pause();
      _isPaused = true;
      _recordingTimer?.cancel();

      notifyListeners();
      debugPrint('Recording paused');
      return true;
    } catch (e) {
      debugPrint('Error pausing recording: $e');
      return false;
    }
  }

  // Resume recording
  Future<bool> resumeRecording() async {
    try {
      if (!_isRecording || !_isPaused) return false;

      await _audioRecorder.resume();
      _isPaused = false;
      _startRecordingTimer();

      notifyListeners();
      debugPrint('Recording resumed');
      return true;
    } catch (e) {
      debugPrint('Error resuming recording: $e');
      return false;
    }
  }

  // Cancel recording
  Future<bool> cancelRecording() async {
    try {
      if (!_isRecording) return false;

      await _audioRecorder.stop();
      _stopRecordingTimer();

      _isRecording = false;
      _isPaused = false;
      _recordingDuration = Duration.zero;

      // Delete the recording file if it exists
      if (_recordingPath != null && File(_recordingPath!).existsSync()) {
        try {
          await File(_recordingPath!).delete();
          debugPrint('Recording file deleted: $_recordingPath');
        } catch (e) {
          debugPrint('Error deleting recording file: $e');
        }
      }

      _recordingPath = null;
      notifyListeners();
      debugPrint('Recording canceled');
      return true;
    } catch (e) {
      debugPrint('Error canceling recording: $e');
      return false;
    }
  }

  // Start timer for duration tracking
  void _startRecordingTimer() {
    _recordingTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _recordingDuration += const Duration(seconds: 1);
      notifyListeners();
    });
  }

  // Stop timer
  void _stopRecordingTimer() {
    _recordingTimer?.cancel();
    _recordingTimer = null;
  }

  // ==================== PLAYBACK METHODS ====================

  // Check if a specific message is currently playing
  bool isMessagePlaying(String messageId) {
    return _currentlyPlayingId == messageId && _isPlaying;
  }

  // Play audio from URL
  Future<bool> playAudio(String messageId, String audioUrl) async {
    try {
      // Stop current audio if playing
      if (_currentlyPlayingId != null) {
        await stopAudio();
      }

      await _audioPlayer.play(UrlSource(audioUrl));
      _currentlyPlayingId = messageId;
      _isPlaying = true;
      notifyListeners();

      debugPrint('Started playing audio for message: $messageId');
      return true;
    } catch (e) {
      debugPrint('Error playing audio: $e');
      return false;
    }
  }

  // Pause current audio
  Future<bool> pauseAudio() async {
    try {
      await _audioPlayer.pause();
      _isPlaying = false;
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Error pausing audio: $e');
      return false;
    }
  }

  // Resume current audio
  Future<bool> resumeAudio() async {
    try {
      await _audioPlayer.resume();
      _isPlaying = true;
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Error resuming audio: $e');
      return false;
    }
  }

  // Stop current audio
  Future<bool> stopAudio() async {
    try {
      await _audioPlayer.stop();
      _currentlyPlayingId = null;
      _isPlaying = false;
      _currentPosition = Duration.zero;
      _totalDuration = Duration.zero;
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Error stopping audio: $e');
      return false;
    }
  }

  // Seek to position
  Future<bool> seekTo(Duration position) async {
    try {
      await _audioPlayer.seek(position);
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Error seeking audio: $e');
      return false;
    }
  }

  // Toggle play/pause for a specific message
  Future<bool> togglePlayback(String messageId, String audioUrl) async {
    if (_currentlyPlayingId == messageId) {
      // Same message - toggle play/pause
      if (_isPlaying) {
        return await pauseAudio();
      } else {
        return await resumeAudio();
      }
    } else {
      // Different message - play new audio
      return await playAudio(messageId, audioUrl);
    }
  }

  // Get formatted duration string
  String formatDuration(Duration duration) {
    return _formatDuration(duration);
  }

  // Get progress percentage (0.0 to 1.0)
  double get progress {
    if (_totalDuration.inMilliseconds == 0) return 0.0;
    return _currentPosition.inMilliseconds / _totalDuration.inMilliseconds;
  }

  @override
  void dispose() {
    _recordingTimer?.cancel();
    if (_isRecording) {
      cancelRecording();
    }
    _audioRecorder.dispose();
    _audioPlayer.dispose();
    super.dispose();
  }
}
