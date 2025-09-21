import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

class VideoPlayerProvider extends ChangeNotifier {
  VideoPlayerController? _controller;
  bool _isInitialized = false;
  bool _isPlaying = false;
  bool _isBuffering = false;
  bool _hasError = false;
  String? _errorMessage;
  Duration _position = Duration.zero;
  Duration _duration = Duration.zero;
  double _volume = 1.0;
  bool _isControlsVisible = true;
  String? _currentVideoUrl;

  // Getters
  VideoPlayerController? get controller => _controller;
  bool get isInitialized => _isInitialized;
  bool get isPlaying => _isPlaying;
  bool get isBuffering => _isBuffering;
  bool get hasError => _hasError;
  String? get errorMessage => _errorMessage;
  Duration get position => _position;
  Duration get duration => _duration;
  double get volume => _volume;
  bool get isControlsVisible => _isControlsVisible;
  String? get currentVideoUrl => _currentVideoUrl;

  // Computed properties
  double get progress => _duration.inMilliseconds > 0
      ? _position.inMilliseconds / _duration.inMilliseconds
      : 0.0;

  String get formattedPosition => _formatDuration(_position);
  String get formattedDuration => _formatDuration(_duration);
  String get remainingTime => _formatDuration(_duration - _position);

  // Format duration to mm:ss
  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, "0");
    String twoDigitMinutes = twoDigits(duration.inMinutes.remainder(60));
    String twoDigitSeconds = twoDigits(duration.inSeconds.remainder(60));
    return "$twoDigitMinutes:$twoDigitSeconds";
  }

  // Initialize video player with URL
  Future<bool> initializePlayer(String videoUrl) async {
    try {
      debugPrint('Initializing video player with URL: $videoUrl');

      // Dispose existing controller if any
      await disposePlayer();

      _currentVideoUrl = videoUrl;
      _hasError = false;
      _errorMessage = null;

      // Create new controller
      _controller = VideoPlayerController.networkUrl(Uri.parse(videoUrl));

      // Add listeners
      _setupListeners();

      // Initialize controller
      await _controller!.initialize();

      _isInitialized = true;
      _duration = _controller!.value.duration;
      _position = _controller!.value.position;

      debugPrint('Video player initialized successfully');
      debugPrint('Video duration: ${_formatDuration(_duration)}');

      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Error initializing video player: $e');
      _hasError = true;
      _errorMessage = e.toString();
      _isInitialized = false;
      notifyListeners();
      return false;
    }
  }

  // Setup controller listeners
  void _setupListeners() {
    if (_controller == null) return;

    _controller!.addListener(() {
      if (_controller == null) return;

      final value = _controller!.value;

      // Update playing state
      if (_isPlaying != value.isPlaying) {
        _isPlaying = value.isPlaying;
        notifyListeners();
      }

      // Update buffering state
      if (_isBuffering != value.isBuffering) {
        _isBuffering = value.isBuffering;
        notifyListeners();
      }

      // Update position
      if (_position != value.position) {
        _position = value.position;
        notifyListeners();
      }

      // Update duration
      if (_duration != value.duration) {
        _duration = value.duration;
        notifyListeners();
      }

      // Check for errors
      if (value.hasError && !_hasError) {
        _hasError = true;
        _errorMessage = value.errorDescription;
        debugPrint('Video player error: ${value.errorDescription}');
        notifyListeners();
      }
    });
  }

  // Play video
  Future<void> play() async {
    if (_controller != null && _isInitialized) {
      await _controller!.play();
      _isPlaying = true;
      notifyListeners();
    }
  }

  // Pause video
  Future<void> pause() async {
    if (_controller != null && _isInitialized) {
      await _controller!.pause();
      _isPlaying = false;
      notifyListeners();
    }
  }

  // Toggle play/pause
  Future<void> togglePlayPause() async {
    if (_isPlaying) {
      await pause();
    } else {
      await play();
    }
  }

  // Seek to position
  Future<void> seekTo(Duration position) async {
    if (_controller != null && _isInitialized) {
      await _controller!.seekTo(position);
      _position = position;
      notifyListeners();
    }
  }

  // Seek by percentage (0.0 to 1.0)
  Future<void> seekToPercentage(double percentage) async {
    if (_duration.inMilliseconds > 0) {
      final position = Duration(
        milliseconds: (_duration.inMilliseconds * percentage).round(),
      );
      await seekTo(position);
    }
  }

  // Set volume (0.0 to 1.0)
  Future<void> setVolume(double volume) async {
    if (_controller != null && _isInitialized) {
      _volume = volume.clamp(0.0, 1.0);
      await _controller!.setVolume(_volume);
      notifyListeners();
    }
  }

  // Mute/unmute
  Future<void> toggleMute() async {
    if (_volume > 0) {
      await setVolume(0.0);
    } else {
      await setVolume(1.0);
    }
  }

  // Show/hide controls
  void showControls() {
    _isControlsVisible = true;
    notifyListeners();
  }

  void hideControls() {
    _isControlsVisible = false;
    notifyListeners();
  }

  void toggleControls() {
    _isControlsVisible = !_isControlsVisible;
    notifyListeners();
  }

  // Skip forward/backward
  Future<void> skipForward([Duration? duration]) async {
    final skipDuration = duration ?? const Duration(seconds: 10);
    final newPosition = _position + skipDuration;
    await seekTo(newPosition > _duration ? _duration : newPosition);
  }

  Future<void> skipBackward([Duration? duration]) async {
    final skipDuration = duration ?? const Duration(seconds: 10);
    final newPosition = _position - skipDuration;
    await seekTo(newPosition < Duration.zero ? Duration.zero : newPosition);
  }

  // Set playback speed
  Future<void> setPlaybackSpeed(double speed) async {
    if (_controller != null && _isInitialized) {
      await _controller!.setPlaybackSpeed(speed);
      notifyListeners();
    }
  }

  // Get video aspect ratio
  double get aspectRatio {
    if (_controller != null && _isInitialized) {
      return _controller!.value.aspectRatio;
    }
    return 16 / 9; // Default aspect ratio
  }

  // Get video size
  Size? get videoSize {
    if (_controller != null && _isInitialized) {
      return _controller!.value.size;
    }
    return null;
  }

  // Check if video has ended
  bool get hasEnded {
    if (_controller != null && _isInitialized) {
      return _position >= _duration && _duration.inMilliseconds > 0;
    }
    return false;
  }

  // Restart video from beginning
  Future<void> restart() async {
    await seekTo(Duration.zero);
    await play();
  }

  // Dispose player
  Future<void> disposePlayer() async {
    if (_controller != null) {
      await _controller!.pause();
      await _controller!.dispose();
      _controller = null;
    }

    _isInitialized = false;
    _isPlaying = false;
    _isBuffering = false;
    _hasError = false;
    _errorMessage = null;
    _position = Duration.zero;
    _duration = Duration.zero;
    _currentVideoUrl = null;

    notifyListeners();
  }

  @override
  void dispose() {
    disposePlayer();
    super.dispose();
  }
}
