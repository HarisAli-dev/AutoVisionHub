import 'dart:io';
import 'package:flutter/material.dart';
import 'package:front/utils/app_colors.dart';
import 'package:provider/provider.dart';
import 'package:front/providers/unified_audio_provider.dart';
import 'package:front/utils/snackbars.dart';

/// Unified audio service for both recording and playback operations
class AudioService {
  // ==================== RECORDING METHODS ====================

  /// Start recording voice message
  static Future<bool> startRecording(BuildContext context) async {
    final provider = Provider.of<AudioProvider>(context, listen: false);
    final success = await provider.startRecording();

    if (!success) {
      CustomSnackbars.showErrorSnackbar(
        context,
        'Failed to start recording. Please check microphone permission.',
 
      );
    }

    return success;
  }

  /// Stop recording and return file path
  static Future<String?> stopRecording(BuildContext context) async {
    final provider = Provider.of<AudioProvider>(context, listen: false);
    return await provider.stopRecording();
  }

  /// Cancel current recording
  static Future<bool> cancelRecording(BuildContext context) async {
    final provider = Provider.of<AudioProvider>(context, listen: false);
    final success = await provider.cancelRecording();

    if (success) {
      CustomSnackbars.showInfoSnackbar(context, 'Recording canceled', 2.0);
    }

    return success;
  }

  /// Pause current recording
  static Future<bool> pauseRecording(BuildContext context) async {
    final provider = Provider.of<AudioProvider>(context, listen: false);
    return await provider.pauseRecording();
  }

  /// Resume paused recording
  static Future<bool> resumeRecording(BuildContext context) async {
    final provider = Provider.of<AudioProvider>(context, listen: false);
    return await provider.resumeRecording();
  }

  /// Get current recording state
  static bool isRecording(BuildContext context) {
    final provider = Provider.of<AudioProvider>(context, listen: false);
    return provider.isRecording;
  }

  /// Get current recording duration
  static Duration getRecordingDuration(BuildContext context) {
    final provider = Provider.of<AudioProvider>(context, listen: false);
    return provider.recordingDuration;
  }

  /// Get formatted recording duration (mm:ss)
  static String getFormattedRecordingDuration(BuildContext context) {
    final provider = Provider.of<AudioProvider>(context, listen: false);
    return provider.formattedRecordingDuration;
  }

  /// Check if recording is paused
  static bool isRecordingPaused(BuildContext context) {
    final provider = Provider.of<AudioProvider>(context, listen: false);
    return provider.isPaused;
  }

  /// Validate recording file
  static bool isValidRecordingFile(String? filePath) {
    if (filePath == null || filePath.isEmpty) return false;

    final file = File(filePath);
    if (!file.existsSync()) return false;

    // Check file size (should be > 0)
    final fileSize = file.lengthSync();
    return fileSize > 0;
  }

  /// Delete recording file
  static Future<bool> deleteRecordingFile(String filePath) async {
    try {
      final file = File(filePath);
      if (file.existsSync()) {
        await file.delete();
        debugPrint('Recording file deleted: $filePath');
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('Error deleting recording file: $e');
      return false;
    }
  }

  // ==================== PLAYBACK METHODS ====================

  /// Play audio message
  static Future<bool> playAudio(
    BuildContext context,
    String messageId,
    String audioUrl,
  ) async {
    final provider = Provider.of<AudioProvider>(context, listen: false);
    final success = await provider.playAudio(messageId, audioUrl);

    if (!success) {
      CustomSnackbars.showErrorSnackbar(
        context,
        'Failed to play audio message',

      );
    }

    return success;
  }

  /// Pause current audio
  static Future<bool> pauseAudio(BuildContext context) async {
    final provider = Provider.of<AudioProvider>(context, listen: false);
    return await provider.pauseAudio();
  }

  /// Resume current audio
  static Future<bool> resumeAudio(BuildContext context) async {
    final provider = Provider.of<AudioProvider>(context, listen: false);
    return await provider.resumeAudio();
  }

  /// Stop current audio
  static Future<bool> stopAudio(BuildContext context) async {
    final provider = Provider.of<AudioProvider>(context, listen: false);
    return await provider.stopAudio();
  }

  /// Toggle play/pause for audio message
  static Future<bool> toggleAudioPlayback(
    BuildContext context,
    String messageId,
    String audioUrl,
  ) async {
    final provider = Provider.of<AudioProvider>(context, listen: false);
    final success = await provider.togglePlayback(messageId, audioUrl);

    if (!success) {
      CustomSnackbars.showErrorSnackbar(
        context,
        'Error playing audio message',
      );
    }

    return success;
  }

  /// Check if a specific message is currently playing
  static bool isMessagePlaying(BuildContext context, String messageId) {
    final provider = Provider.of<AudioProvider>(context, listen: false);
    return provider.isMessagePlaying(messageId);
  }

  /// Get current audio position
  static Duration getCurrentPosition(BuildContext context) {
    final provider = Provider.of<AudioProvider>(context, listen: false);
    return provider.currentPosition;
  }

  /// Get total audio duration
  static Duration getTotalDuration(BuildContext context) {
    final provider = Provider.of<AudioProvider>(context, listen: false);
    return provider.totalDuration;
  }

  /// Get playback progress (0.0 to 1.0)
  static double getProgress(BuildContext context) {
    final provider = Provider.of<AudioProvider>(context, listen: false);
    return provider.progress;
  }

  /// Seek to position
  static Future<bool> seekTo(BuildContext context, Duration position) async {
    final provider = Provider.of<AudioProvider>(context, listen: false);
    return await provider.seekTo(position);
  }

  /// Get formatted duration string
  static String formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, "0");
    String twoDigitMinutes = twoDigits(duration.inMinutes.remainder(60));
    String twoDigitSeconds = twoDigits(duration.inSeconds.remainder(60));
    return "$twoDigitMinutes:$twoDigitSeconds";
  }

  /// Format message duration from seconds
  static String formatMessageDuration(int? durationInSeconds) {
    if (durationInSeconds == null) return '0:00';

    final duration = Duration(seconds: durationInSeconds);
    return formatDuration(duration);
  }
}

/// Unified audio message widget for displaying voice messages
class AudioMessageWidget extends StatelessWidget {
  final String messageId;
  final String? audioUrl;
  final int? duration;
  final Color? iconColor;
  final Color? textColor;

  const AudioMessageWidget({
    super.key,
    required this.messageId,
    required this.audioUrl,
    this.duration,
    this.iconColor,
    this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    if (audioUrl == null) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.error, color: iconColor ?? Colors.red),
          const SizedBox(width: 8),
          Text(
            'Audio not available',
            style: TextStyle(color: textColor ?? Colors.black),
          ),
        ],
      );
    }

    return Consumer<AudioProvider>(
      builder: (context, audioProvider, child) {
        final isPlaying = audioProvider.isMessagePlaying(messageId);
        final isCurrentMessage = audioProvider.currentlyPlayingId == messageId;

        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            GestureDetector(
              onTap: () {
                AudioService.toggleAudioPlayback(context, messageId, audioUrl!);
              },
              child: Icon(
                isPlaying ? Icons.pause : Icons.play_arrow,
                color: iconColor ?? Colors.black,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Duration or progress
                  if (isCurrentMessage &&
                      audioProvider.totalDuration.inSeconds > 0)
                    Text(
                      '${AudioService.formatDuration(audioProvider.currentPosition)} / ${AudioService.formatDuration(audioProvider.totalDuration)}',
                      style: TextStyle(
                        color: textColor ?? Colors.black,
                        fontSize: 12,
                      ),
                    )
                  else
                    Text(
                      AudioService.formatMessageDuration(duration),
                      style: TextStyle(color: AppColors.foregroundColor),
                    ),

                  // Progress bar for current playing message
                  if (isCurrentMessage &&
                      audioProvider.totalDuration.inSeconds > 0)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: LinearProgressIndicator(
                        value: audioProvider.progress,
                        backgroundColor: Colors.grey[300],
                        valueColor: AlwaysStoppedAnimation<Color>(
                          iconColor ?? AppColors.primary,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}

/// Unified audio recorder widget with recording controls and UI
class AudioRecorderWidget extends StatelessWidget {
  final Function(String recordingPath) onRecordingComplete;
  final VoidCallback? onCancel;

  const AudioRecorderWidget({
    super.key,
    required this.onRecordingComplete,
    this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<AudioProvider>(
      builder: (context, audioProvider, child) {
        if (!audioProvider.isRecording) {
          // Start recording button
          return IconButton(
            icon: Icon(Icons.mic, color: AppColors.primary),
            onPressed: () async {
              await AudioService.startRecording(context);
            },
          );
        }

        // Recording controls
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
          decoration: BoxDecoration(
            color: Colors.red.withOpacity(0.1),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Recording indicator
              Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: Colors.red,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),

              // Duration display
              Text(
                audioProvider.formattedRecordingDuration,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
              const SizedBox(width: 8),

              // Pause/Resume button
              IconButton(
                icon: Icon(
                  audioProvider.isPaused ? Icons.play_arrow : Icons.pause,
                  size: 20,
                ),
                onPressed: () async {
                  if (audioProvider.isPaused) {
                    await AudioService.resumeRecording(context);
                  } else {
                    await AudioService.pauseRecording(context);
                  }
                },
              ),

              // Cancel button
              IconButton(
                icon: const Icon(Icons.delete, size: 20, color: Colors.red),
                onPressed: () async {
                  await AudioService.cancelRecording(context);
                  onCancel?.call();
                },
              ),

              // Send button
              IconButton(
                color: AppColors.foregroundColor,
                icon: const Icon(
                  Icons.send,
                  size: 20,
                  color: AppColors.primary,
                ),
                onPressed: () async {
                  final path = await AudioService.stopRecording(context);
                  if (path != null && AudioService.isValidRecordingFile(path)) {
                    onRecordingComplete(path);
                  }
                },
              ),
            ],
          ),
        );
      },
    );
  }
}

/// Audio recorder input widget for message input field
class AudioRecorderInput extends StatelessWidget {
  final Function(String recordingPath) onRecordingComplete;
  final VoidCallback? onStartRecording;
  final VoidCallback? onCancelRecording;

  const AudioRecorderInput({
    super.key,
    required this.onRecordingComplete,
    this.onStartRecording,
    this.onCancelRecording,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<AudioProvider>(
      builder: (context, audioProvider, child) {
        if (!audioProvider.isRecording) {
          // Mic button when not recording
          return IconButton(
            icon: Icon(Icons.mic, color: AppColors.primary),
            onPressed: () async {
              await AudioService.startRecording(context);
              onStartRecording?.call();
            },
          );
        }

        // Recording state - show stop/cancel controls
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Recording indicator with duration
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 6,
                    height: 6,
                    decoration: const BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    audioProvider.formattedRecordingDuration,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.red,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),

            // Cancel button
            GestureDetector(
              onTap: () async {
                await AudioService.cancelRecording(context);
                onCancelRecording?.call();
              },
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.shadeColor,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.close,
                  weight: 40,
                  color: AppColors.primary,
                  size: 20,
                ),
              ),
            ),
            const SizedBox(width: 8),

            // Send button
            GestureDetector(
              onTap: () async {
                final path = await AudioService.stopRecording(context);
                if (path != null && AudioService.isValidRecordingFile(path)) {
                  onRecordingComplete(path);
                }
              },
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.shadeColor,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.send,
                  color: AppColors.primary,
                  size: 20,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
