import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:front/model/chats/message_model.dart';
import 'package:front/model/groups/group_message_model.dart';
import 'package:front/model/groups/poll_model.dart';
import 'package:front/services/unified_audio_service.dart';
import 'package:front/services/video_player_service.dart';
import 'package:front/utils/app_colors.dart';
import 'package:front/utils/snackbars.dart';
import 'package:front/utils/hive_utils.dart';
import 'package:front/utils/time_utils.dart';
import 'package:intl/intl.dart';
import 'package:open_file/open_file.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

class ChatComponents {
  static // Download file from url to downloads folder without showing progress
  Future<bool>
  downloadFile(String url, String fileName) async {
    try {
      // Request storage permission
      var status = await Permission.storage.request();
      debugPrint('Storage permission status: $status');
      if (!status.isGranted) {
        debugPrint('Storage permission denied');
        return false;
      }

      // Get download directory path
      Directory? directory;
      if (Platform.isAndroid) {
        directory = Directory('/storage/emulated/0/Download');
      } else {
        directory = await getApplicationDocumentsDirectory();
      }

      // Create file path with a unique timestamp to prevent overwriting
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final safeName = fileName.replaceAll(RegExp(r'[^\w\s.-]'), '_');
      final filePath = '${directory.path}/${timestamp}_$safeName';

      // Initialize Dio
      final dio = Dio();

      // Download file without showing progress updates
      await dio.download(url, filePath);

      // Open the file
      await OpenFile.open(filePath);
      return true;
    } catch (e) {
      debugPrint('Error downloading file: $e');
      return false;
    }
  }

  // Widget to display video message with play button overlay for both chat and group chat
  static ClipRRect videoMessageWidget(
    BuildContext context, {
    GroupMessage? groupMessage,
    Message? chatMessage,
  }) {
    late final dynamic message;
    if (groupMessage != null) {
      message = groupMessage;
    } else if (chatMessage != null) {
      message = chatMessage;
    } else {
      throw ArgumentError(
        'Either groupMessage or chatMessage must be provided.',
      );
    }
    return ClipRRect(
      borderRadius: BorderRadius.circular(8.0),
      child: Stack(
        alignment: Alignment.center,
        children: [
          if (message.thumbnailUrl != null)
            CachedNetworkImage(
              imageUrl: message.thumbnailUrl!,
              width: double.infinity,
              fit: BoxFit.cover,
              errorWidget: (context, url, error) =>
                  Container(height: 150, width: 200, color: Colors.grey[300]),
            )
          else
            Container(height: 150, width: 200, color: Colors.grey[800]),
          CircleAvatar(
            backgroundColor: Colors.black54,
            radius: 24,
            child: IconButton(
              icon: Icon(
                Icons.play_arrow,
                color: AppColors.foregroundColor,
                size: 32,
              ),
              onPressed: () {
                if (message.mediaUrl != null) {
                  _playVideo(message, context);
                } else {
                  debugPrint('No media URL available for video playback.');
                }
              },
            ),
          ),
        ],
      ),
    );
  }

  static Future<void> _playVideo(dynamic message, BuildContext context) async {
    if (message.mediaUrl != null) {
      await VideoPlayerService.showVideoPlayerDialog(
        context,
        videoUrl: message.mediaUrl!,
        thumbnailUrl: message.thumbnailUrl,
        autoPlay: true,
      );
    }
  }

  // Build message content
  static Widget buildMessageContent(
    bool isMe,
    BuildContext context,
    bool isGroup, {
    Message? chatMessage,
    GroupMessage? groupMessage,
    Poll? poll, // Add poll parameter
    Function(String pollId, String option)? onVote, // Add vote callback
  }) {
    late final dynamic message;
    if (groupMessage != null) {
      message = groupMessage;
    } else if (chatMessage != null) {
      message = chatMessage;
    } else {
      throw ArgumentError(
        'Either groupMessage or chatMessage must be provided.',
      );
    }
    switch (message.type) {
      case MessageType.text || GroupMessageType.text:
        return Text(
          message.content ?? '',
          style: TextStyle(
            color: isMe ? AppColors.foregroundColor : Colors.black,
          ),
        );
      case MessageType.image || GroupMessageType.image:
        return GestureDetector(
          onTap: () {
            // Show full image
            if (message.mediaUrl != null) {
              _showFullImage(message.mediaUrl!, context);
            }
          },
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8.0),
            child: CachedNetworkImage(
              imageUrl: message.mediaUrl ?? 'https://placeholder.com/400',
              //for video thumbnail use message.thumbnailUrl
              placeholder: (context, url) => Container(
                width: 200,
                height: 200,
                color: Colors.grey[300],
                child: const Center(child: CircularProgressIndicator()),
              ),
              errorWidget: (context, url, error) => Container(
                width: 200,
                height: 200,
                color: Colors.grey[300],
                child: const Icon(Icons.broken_image, size: 50),
              ),
            ),
          ),
        );
      case MessageType.video || GroupMessageType.video:
        return ChatComponents.videoMessageWidget(context, chatMessage: message);
      case MessageType.voice || GroupMessageType.voice:
        return AudioMessageWidget(
          messageId: message.id,
          audioUrl: message.mediaUrl,
          duration: message.duration,
          iconColor: AppColors.foregroundColor,
          textColor: AppColors.foregroundColor,
        );
      case MessageType.file || GroupMessageType.file:
        final fileName = message.content ?? 'File';
        return InkWell(
          onTap: () async {
            if (message.mediaUrl != null) {
              if (await ChatComponents.downloadFile(
                message.mediaUrl!,
                fileName,
              )) {
                CustomSnackbars.showSuccessSnackbar(context, 'Downloaded', 1.0);
              }
            } else {
              CustomSnackbars.showErrorSnackbar(
                context,
                'File URL not available',
            
              );
            }
          },
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.insert_drive_file, color: AppColors.foregroundColor),
              SizedBox(width: 8),
              Flexible(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      fileName,
                      style: TextStyle(color: AppColors.foregroundColor),
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      'Tap to download',
                      style: TextStyle(
                        color: isMe
                            ? AppColors.foregroundColor.withOpacity(0.7)
                            : Colors.black54,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.download, size: 16, color: AppColors.foregroundColor),
            ],
          ),
        );
      case MessageType.call || GroupMessageType.call:
        return Row(
          children: [
            Icon(
              Icons.call,
              color: isMe ? AppColors.foregroundColor : Colors.black,
            ),
            SizedBox(width: 8),
            Text(
              'Call',
              style: TextStyle(
                color: isMe ? AppColors.foregroundColor : Colors.black,
              ),
            ),
          ],
        );

      case GroupMessageType.poll:
        return _buildPollWidget(message, isMe, context, poll, onVote);
      default:
        return Text("Unsupported message type");
    }
  }

  static Widget _buildPollWidget(
    GroupMessage message,
    bool isMe,
    BuildContext context,
    Poll? pollData,
    Function(String pollId, String option)? onVote,
  ) {
    // Use provided poll data - no fallback to static poll needed
    if (pollData == null) {
      return Container(
        padding: const EdgeInsets.all(8.0),
        decoration: BoxDecoration(
          color: isMe ? AppColors.primary : Colors.grey[200],
          borderRadius: BorderRadius.circular(8.0),
        ),
        child: Row(
          children: [
            SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(
                  isMe ? AppColors.foregroundColor : AppColors.primary,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              'Loading poll...',
              style: TextStyle(
                color: isMe ? AppColors.foregroundColor : Colors.black,
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(12.0),
      decoration: BoxDecoration(
        color: isMe ? AppColors.primary : Colors.grey[200],
        borderRadius: BorderRadius.circular(8.0),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            pollData.question,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: isMe ? AppColors.foregroundColor : Colors.black,
            ),
          ),
          const SizedBox(height: 12.0),
          ...pollData.options.map((option) {
            final voteCount =
                pollData.votes?.where((vote) => vote.option == option).length ??
                0;
            final totalVotes = pollData.votes?.length ?? 0;
            final percentage = totalVotes > 0
                ? (voteCount / totalVotes * 100).round()
                : 0;

            // Check if current user has voted for this option
            final currentUserId = HiveUtils.getData('userId') ?? '';
            final hasVoted =
                pollData.votes?.any(
                  (vote) =>
                      vote.userId == currentUserId && vote.option == option,
                ) ??
                false;

            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 4.0),
              child: InkWell(
                onTap: onVote != null
                    ? () => onVote(message.pollId!, option)
                    : null,
                borderRadius: BorderRadius.circular(8.0),
                child: Container(
                  padding: const EdgeInsets.all(12.0),
                  decoration: BoxDecoration(
                    color: hasVoted
                        ? (isMe
                              ? AppColors.foregroundColor.withOpacity(0.3)
                              : Colors.blue.withOpacity(0.3))
                        : (isMe
                              ? AppColors.foregroundColor.withOpacity(0.1)
                              : Colors.grey[100]),
                    borderRadius: BorderRadius.circular(8.0),
                    border: hasVoted
                        ? Border.all(
                            color: isMe
                                ? AppColors.foregroundColor
                                : Colors.blue,
                            width: 2,
                          )
                        : null,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              option,
                              style: TextStyle(
                                fontWeight: hasVoted
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                                color: isMe
                                    ? AppColors.foregroundColor
                                    : Colors.black,
                              ),
                            ),
                            if (totalVotes > 0) ...[
                              const SizedBox(height: 4),
                              LinearProgressIndicator(
                                value: percentage / 100,
                                backgroundColor: Colors.grey[300],
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  isMe
                                      ? AppColors.foregroundColor
                                      : AppColors.primary,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: isMe
                              ? AppColors.foregroundColor
                              : AppColors.primary,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '$voteCount${totalVotes > 0 ? ' ($percentage%)' : ''}',
                          style: TextStyle(
                            color: isMe
                                ? AppColors.primary
                                : AppColors.foregroundColor,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }).toList(),
          if (pollData.votes?.isNotEmpty == true) ...[
            const SizedBox(height: 8),
            Text(
              'Total votes: ${pollData.votes!.length}',
              style: TextStyle(
                fontSize: 12,
                color: isMe
                    ? AppColors.foregroundColor.withOpacity(0.7)
                    : Colors.black54,
              ),
            ),
          ],
        ],
      ),
    );
  }

  static void _showFullImage(String imageUrl, BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Stack(
          children: [
            Center(child: Image.network(imageUrl, fit: BoxFit.contain)),
            Positioned(
              top: 40,
              right: 20,
              child: IconButton(
                onPressed: () => Navigator.pop(context),
                icon: Icon(Icons.close, color: Colors.white, size: 30),
              ),
            ),
          ],
        ),
      ),
    );
  }

  //date header functions
  static Widget buildDateHeader(DateTime date) {
    final localDate = date.toLocal();
    final today = DateTime.now();
    final yesterday = DateTime.now().subtract(const Duration(days: 1));
    String dateText;

    if (isSameDay(localDate, today)) {
      dateText = 'Today';
    } else if (isSameDay(localDate, yesterday)) {
      dateText = 'Yesterday';
    } else {
      dateText = TimeUtils.formatFullDatePKT(date);
    }

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 16.0),
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          decoration: BoxDecoration(
            color: Colors.grey[300],
            borderRadius: BorderRadius.circular(16.0),
          ),
          child: Text(
            dateText,
            style: const TextStyle(
              fontSize: 12.0,
              fontWeight: FontWeight.w600,
              color: Colors.black54,
            ),
          ),
        ),
      ),
    );
  }

  static bool isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }
}
