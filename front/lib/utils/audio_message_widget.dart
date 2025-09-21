import 'package:flutter/material.dart';
import 'package:front/services/unified_audio_service.dart' as AudioService;
import 'package:front/utils/app_colors.dart';
import 'package:provider/provider.dart';
import 'package:front/providers/unified_audio_provider.dart';

class AudioMessageWidget extends StatefulWidget {
  final String messageId;
  final String? audioUrl;
  final int? duration;
  final Color? iconColor;
  final Color? textColor;

  const AudioMessageWidget({
    Key? key,
    required this.messageId,
    this.audioUrl,
    this.duration,
    this.iconColor,
    this.textColor,
  }) : super(key: key);

  @override
  _AudioMessageWidgetState createState() => _AudioMessageWidgetState();
}

class _AudioMessageWidgetState extends State<AudioMessageWidget> {
  bool get isPlaying {
    final audioProvider = Provider.of<AudioProvider>(context);
    return audioProvider.isPlaying &&
        audioProvider.currentlyPlayingId == widget.messageId;
  }

  Duration get currentPosition {
    final audioProvider = Provider.of<AudioProvider>(context);
    if (audioProvider.currentlyPlayingId == widget.messageId) {
      return audioProvider.currentPosition;
    }
    return Duration.zero;
  }

  Duration get totalDuration {
    final audioProvider = Provider.of<AudioProvider>(context);
    if (audioProvider.currentlyPlayingId == widget.messageId) {
      return audioProvider.totalDuration;
    }
    return Duration(seconds: widget.duration ?? 0);
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  Future<void> _togglePlayPause() async {
    if (widget.audioUrl == null) return;

    if (isPlaying) {
      await AudioService.AudioService.pauseAudio(context);
    } else {
      await AudioService.AudioService.playAudio(
        context,
        widget.messageId,
        widget.audioUrl!,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Play/Pause button
          GestureDetector(
            onTap: _togglePlayPause,
            child: Container(
              padding: EdgeInsets.all(8),
              decoration: BoxDecoration(
                color:
                    widget.iconColor?.withOpacity(0.2) ??
                    AppColors.primary.withOpacity(0.2),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Icon(
                isPlaying ? Icons.pause : Icons.play_arrow,
                color: widget.iconColor ?? AppColors.primary,
                size: 20,
              ),
            ),
          ),

          SizedBox(width: 8),

          // Waveform visualization (simplified)
          Expanded(
            child: Container(
              height: 30,
              child: Row(
                children: List.generate(20, (index) {
                  final progress = totalDuration.inMilliseconds > 0
                      ? currentPosition.inMilliseconds /
                            totalDuration.inMilliseconds
                      : 0.0;
                  final isActive = index < (progress * 20);

                  return Expanded(
                    child: Container(
                      margin: EdgeInsets.symmetric(horizontal: 1),
                      height:
                          (index % 3 == 0
                                  ? 20
                                  : index % 2 == 0
                                  ? 15
                                  : 10)
                              .toDouble(),
                      decoration: BoxDecoration(
                        color: isActive
                            ? (widget.iconColor ?? AppColors.primary)
                            : (widget.iconColor ?? AppColors.primary)
                                  .withOpacity(0.3),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  );
                }),
              ),
            ),
          ),

          SizedBox(width: 8),

          // Duration
          Text(
            isPlaying || currentPosition.inSeconds > 0
                ? '${_formatDuration(currentPosition)} / ${_formatDuration(totalDuration)}'
                : _formatDuration(totalDuration),
            style: TextStyle(
              color: widget.textColor ?? Colors.black87,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}
