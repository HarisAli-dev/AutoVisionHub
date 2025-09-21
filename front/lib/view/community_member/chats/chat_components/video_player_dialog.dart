import 'package:flutter/material.dart';
import 'package:front/services/video_player_service.dart';

/// Video player helper class for showing video player dialogs
class VideoPlayerHelper {
  /// Show video player dialog
  static Future<void> showVideoPlayer(
    BuildContext context, {
    required String videoUrl,
    String? thumbnailUrl,
    bool autoPlay = true,
  }) async {
    await VideoPlayerService.showVideoPlayerDialog(
      context,
      videoUrl: videoUrl,
      thumbnailUrl: thumbnailUrl,
      autoPlay: autoPlay,
    );
  }
}
