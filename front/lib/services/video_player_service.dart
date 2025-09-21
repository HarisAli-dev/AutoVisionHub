import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:video_player/video_player.dart';
import 'package:front/providers/video_player_provider.dart';
import 'package:front/utils/snackbars.dart';

/// Video player service class containing all video player business logic
class VideoPlayerService {
  /// Initialize and play video
  static Future<bool> initializeAndPlay(
    BuildContext context,
    String videoUrl,
  ) async {
    final provider = Provider.of<VideoPlayerProvider>(context, listen: false);

    final success = await provider.initializePlayer(videoUrl);
    if (success) {
      await provider.play();
    } else {
      CustomSnackbars.showErrorSnackbar(
        context,
        'Failed to load video: ${provider.errorMessage ?? 'Unknown error'}',
   
      );
    }

    return success;
  }

  /// Initialize video without playing
  static Future<bool> initialize(BuildContext context, String videoUrl) async {
    final provider = Provider.of<VideoPlayerProvider>(context, listen: false);

    final success = await provider.initializePlayer(videoUrl);
    if (!success) {
      CustomSnackbars.showErrorSnackbar(
        context,
        'Failed to load video: ${provider.errorMessage ?? 'Unknown error'}',
    
      );
    }

    return success;
  }

  /// Play video
  static Future<void> play(BuildContext context) async {
    final provider = Provider.of<VideoPlayerProvider>(context, listen: false);
    await provider.play();
  }

  /// Pause video
  static Future<void> pause(BuildContext context) async {
    final provider = Provider.of<VideoPlayerProvider>(context, listen: false);
    await provider.pause();
  }

  /// Toggle play/pause
  static Future<void> togglePlayPause(BuildContext context) async {
    final provider = Provider.of<VideoPlayerProvider>(context, listen: false);
    await provider.togglePlayPause();
  }

  /// Seek to specific position
  static Future<void> seekTo(BuildContext context, Duration position) async {
    final provider = Provider.of<VideoPlayerProvider>(context, listen: false);
    await provider.seekTo(position);
  }

  /// Seek by percentage (0.0 to 1.0)
  static Future<void> seekToPercentage(
    BuildContext context,
    double percentage,
  ) async {
    final provider = Provider.of<VideoPlayerProvider>(context, listen: false);
    await provider.seekToPercentage(percentage);
  }

  /// Set volume (0.0 to 1.0)
  static Future<void> setVolume(BuildContext context, double volume) async {
    final provider = Provider.of<VideoPlayerProvider>(context, listen: false);
    await provider.setVolume(volume);
  }

  /// Toggle mute
  static Future<void> toggleMute(BuildContext context) async {
    final provider = Provider.of<VideoPlayerProvider>(context, listen: false);
    await provider.toggleMute();
  }

  /// Skip forward
  static Future<void> skipForward(
    BuildContext context, [
    Duration? duration,
  ]) async {
    final provider = Provider.of<VideoPlayerProvider>(context, listen: false);
    await provider.skipForward(duration);
  }

  /// Skip backward
  static Future<void> skipBackward(
    BuildContext context, [
    Duration? duration,
  ]) async {
    final provider = Provider.of<VideoPlayerProvider>(context, listen: false);
    await provider.skipBackward(duration);
  }

  /// Set playback speed
  static Future<void> setPlaybackSpeed(
    BuildContext context,
    double speed,
  ) async {
    final provider = Provider.of<VideoPlayerProvider>(context, listen: false);
    await provider.setPlaybackSpeed(speed);
  }

  /// Restart video
  static Future<void> restart(BuildContext context) async {
    final provider = Provider.of<VideoPlayerProvider>(context, listen: false);
    await provider.restart();
  }

  /// Show video controls
  static void showControls(BuildContext context) {
    final provider = Provider.of<VideoPlayerProvider>(context, listen: false);
    provider.showControls();
  }

  /// Hide video controls
  static void hideControls(BuildContext context) {
    final provider = Provider.of<VideoPlayerProvider>(context, listen: false);
    provider.hideControls();
  }

  /// Toggle video controls
  static void toggleControls(BuildContext context) {
    final provider = Provider.of<VideoPlayerProvider>(context, listen: false);
    provider.toggleControls();
  }

  /// Dispose video player
  static Future<void> dispose(BuildContext context) async {
    final provider = Provider.of<VideoPlayerProvider>(context, listen: false);
    await provider.disposePlayer();
  }

  /// Get current video state
  static bool isInitialized(BuildContext context) {
    final provider = Provider.of<VideoPlayerProvider>(context, listen: false);
    return provider.isInitialized;
  }

  /// Get current playing state
  static bool isPlaying(BuildContext context) {
    final provider = Provider.of<VideoPlayerProvider>(context, listen: false);
    return provider.isPlaying;
  }

  /// Get current buffering state
  static bool isBuffering(BuildContext context) {
    final provider = Provider.of<VideoPlayerProvider>(context, listen: false);
    return provider.isBuffering;
  }

  /// Get current position
  static Duration getCurrentPosition(BuildContext context) {
    final provider = Provider.of<VideoPlayerProvider>(context, listen: false);
    return provider.position;
  }

  /// Get video duration
  static Duration getDuration(BuildContext context) {
    final provider = Provider.of<VideoPlayerProvider>(context, listen: false);
    return provider.duration;
  }

  /// Get progress as percentage
  static double getProgress(BuildContext context) {
    final provider = Provider.of<VideoPlayerProvider>(context, listen: false);
    return provider.progress;
  }

  /// Get formatted position
  static String getFormattedPosition(BuildContext context) {
    final provider = Provider.of<VideoPlayerProvider>(context, listen: false);
    return provider.formattedPosition;
  }

  /// Get formatted duration
  static String getFormattedDuration(BuildContext context) {
    final provider = Provider.of<VideoPlayerProvider>(context, listen: false);
    return provider.formattedDuration;
  }

  /// Get remaining time
  static String getRemainingTime(BuildContext context) {
    final provider = Provider.of<VideoPlayerProvider>(context, listen: false);
    return provider.remainingTime;
  }

  /// Check if video has error
  static bool hasError(BuildContext context) {
    final provider = Provider.of<VideoPlayerProvider>(context, listen: false);
    return provider.hasError;
  }

  /// Get error message
  static String? getErrorMessage(BuildContext context) {
    final provider = Provider.of<VideoPlayerProvider>(context, listen: false);
    return provider.errorMessage;
  }

  /// Check if video has ended
  static bool hasEnded(BuildContext context) {
    final provider = Provider.of<VideoPlayerProvider>(context, listen: false);
    return provider.hasEnded;
  }

  /// Get video aspect ratio
  static double getAspectRatio(BuildContext context) {
    final provider = Provider.of<VideoPlayerProvider>(context, listen: false);
    return provider.aspectRatio;
  }

  /// Get video size
  static Size? getVideoSize(BuildContext context) {
    final provider = Provider.of<VideoPlayerProvider>(context, listen: false);
    return provider.videoSize;
  }

  /// Show video player dialog
  static Future<void> showVideoPlayerDialog(
    BuildContext context, {
    required String videoUrl,
    String? thumbnailUrl,
    bool autoPlay = true,
  }) async {
    await showDialog(
      context: context,
      barrierColor: Colors.black87,
      builder: (dialogContext) => VideoPlayerDialog(
        videoUrl: videoUrl,
        thumbnailUrl: thumbnailUrl,
        autoPlay: autoPlay,
      ),
    );
  }
}

/// Video player dialog widget
class VideoPlayerDialog extends StatefulWidget {
  final String videoUrl;
  final String? thumbnailUrl;
  final bool autoPlay;

  const VideoPlayerDialog({
    super.key,
    required this.videoUrl,
    this.thumbnailUrl,
    this.autoPlay = true,
  });

  @override
  State<VideoPlayerDialog> createState() => _VideoPlayerDialogState();
}

class _VideoPlayerDialogState extends State<VideoPlayerDialog> {
  late VideoPlayerProvider _provider;

  @override
  void initState() {
    super.initState();
    // Get the provider from parent context
    _provider = Provider.of<VideoPlayerProvider>(context, listen: false);
    _initializeVideo();
  }

  Future<void> _initializeVideo() async {
    if (widget.autoPlay) {
      await _provider.initializePlayer(widget.videoUrl);
      if (_provider.isInitialized) {
        await _provider.play();
      }
    } else {
      await _provider.initializePlayer(widget.videoUrl);
    }
  }

  @override
  void dispose() {
    // Dispose the video player when dialog closes
    _provider.disposePlayer();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(16),
      child: Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.8,
          maxWidth: MediaQuery.of(context).size.width * 0.9,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Close button
            Align(
              alignment: Alignment.topRight,
              child: IconButton(
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.close, color: Colors.white, size: 32),
              ),
            ),

            // Video player content
            Flexible(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  color: Colors.black,
                  child: Consumer<VideoPlayerProvider>(
                    builder: (context, provider, child) {
                      return provider.isInitialized
                          ? VideoPlayerWidget()
                          : VideoPlayerLoading(
                              thumbnailUrl: widget.thumbnailUrl,
                            );
                    },
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Video player widget
class VideoPlayerWidget extends StatelessWidget {
  const VideoPlayerWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<VideoPlayerProvider>(
      builder: (context, provider, child) {
        if (provider.hasError) {
          return VideoPlayerError(errorMessage: provider.errorMessage);
        }

        if (!provider.isInitialized) {
          return const VideoPlayerLoading();
        }

        return AspectRatio(
          aspectRatio: provider.aspectRatio,
          child: Stack(
            children: [
              // Video display
              VideoPlayer(provider.controller!),

              // Loading indicator
              if (provider.isBuffering)
                const Center(
                  child: CircularProgressIndicator(color: Colors.white),
                ),

              // Controls overlay
              if (provider.isControlsVisible) VideoPlayerControls(),

              // Tap to toggle controls
              GestureDetector(
                onTap: () {
                  final provider = Provider.of<VideoPlayerProvider>(
                    context,
                    listen: false,
                  );
                  provider.toggleControls();
                },
                child: Container(
                  width: double.infinity,
                  height: double.infinity,
                  color: Colors.transparent,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

/// Video player controls
class VideoPlayerControls extends StatelessWidget {
  const VideoPlayerControls({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<VideoPlayerProvider>(
      builder: (context, provider, child) {
        return Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.black.withOpacity(0.3),
                Colors.transparent,
                Colors.transparent,
                Colors.black.withOpacity(0.7),
              ],
            ),
          ),
          child: Column(
            children: [
              const Spacer(),

              // Bottom controls
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    // Progress bar
                    Row(
                      children: [
                        Text(
                          provider.formattedPosition,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: SliderTheme(
                            data: SliderTheme.of(context).copyWith(
                              trackHeight: 2,
                              thumbShape: const RoundSliderThumbShape(
                                enabledThumbRadius: 6,
                              ),
                              overlayShape: const RoundSliderOverlayShape(
                                overlayRadius: 12,
                              ),
                            ),
                            child: Slider(
                              value: provider.progress,
                              onChanged: (value) {
                                provider.seekToPercentage(value);
                              },
                              activeColor: Colors.white,
                              inactiveColor: Colors.white.withOpacity(0.3),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          provider.formattedDuration,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),

                    // Play controls
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        IconButton(
                          onPressed: () => provider.skipBackward(),
                          icon: const Icon(
                            Icons.replay_10,
                            color: Colors.white,
                            size: 32,
                          ),
                        ),
                        const SizedBox(width: 20),
                        GestureDetector(
                          onTap: () => provider.togglePlayPause(),
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: const BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              provider.isPlaying
                                  ? Icons.pause
                                  : Icons.play_arrow,
                              color: Colors.black,
                              size: 32,
                            ),
                          ),
                        ),
                        const SizedBox(width: 20),
                        IconButton(
                          onPressed: () => provider.skipForward(),
                          icon: const Icon(
                            Icons.forward_10,
                            color: Colors.white,
                            size: 32,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

/// Video player loading widget
class VideoPlayerLoading extends StatelessWidget {
  final String? thumbnailUrl;

  const VideoPlayerLoading({super.key, this.thumbnailUrl});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 300,
      color: Colors.black,
      child: Stack(
        children: [
          if (thumbnailUrl != null)
            Image.network(
              thumbnailUrl!,
              width: double.infinity,
              height: double.infinity,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => Container(),
            ),
          const Center(child: CircularProgressIndicator(color: Colors.white)),
        ],
      ),
    );
  }
}

/// Video player error widget
class VideoPlayerError extends StatelessWidget {
  final String? errorMessage;

  const VideoPlayerError({super.key, this.errorMessage});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 300,
      color: Colors.black,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, color: Colors.white, size: 64),
          const SizedBox(height: 16),
          const Text(
            'Failed to load video',
            style: TextStyle(color: Colors.white, fontSize: 16),
          ),
          if (errorMessage != null) ...[
            const SizedBox(height: 8),
            Text(
              errorMessage!,
              style: const TextStyle(color: Colors.white70, fontSize: 12),
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
    );
  }
}
