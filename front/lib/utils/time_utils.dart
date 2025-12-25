import 'package:intl/intl.dart';

/// Utility class for time conversions to Pakistan Standard Time (PKT)
/// Pakistan timezone is UTC+5
class TimeUtils {
  // Pakistan Standard Time offset: UTC+5
  static const Duration pktOffset = Duration(hours: 5);

  /// Converts a DateTime to Pakistan Standard Time (Islamabad, Pakistan)
  /// Returns the DateTime adjusted to PKT timezone
  static DateTime toPKT(DateTime dateTime) {
    // First convert to UTC if not already
    final utcTime = dateTime.isUtc ? dateTime : dateTime.toUtc();
    // Then add Pakistan offset (UTC+5)
    return utcTime.add(pktOffset);
  }

  /// Formats a DateTime to Pakistan time with the given format pattern
  /// 
  /// Example patterns:
  /// - 'MMM dd, yyyy' -> 'Dec 25, 2025'
  /// - 'hh:mm a' -> '02:30 PM'
  /// - 'MMM dd, yyyy HH:mm' -> 'Dec 25, 2025 14:30'
  /// - 'MMM dd, yyyy - hh:mm a' -> 'Dec 25, 2025 - 02:30 PM'
  /// - 'MMMM d, y' -> 'December 25, 2025'
  /// - 'EEEE, MMMM d, yyyy' -> 'Thursday, December 25, 2025'
  static String formatToPKT(DateTime dateTime, String pattern) {
    final pktTime = toPKT(dateTime);
    return DateFormat(pattern).format(pktTime);
  }

  /// Formats time only (e.g., "2:30 PM")
  static String formatTimePKT(DateTime dateTime) {
    final pktTime = toPKT(dateTime);
    return DateFormat.jm().format(pktTime);
  }

  /// Formats date only (e.g., "Dec 25, 2025")
  static String formatDatePKT(DateTime dateTime) {
    final pktTime = toPKT(dateTime);
    return DateFormat('MMM dd, yyyy').format(pktTime);
  }

  /// Formats full date and time (e.g., "Dec 25, 2025 02:30 PM")
  static String formatDateTimePKT(DateTime dateTime) {
    final pktTime = toPKT(dateTime);
    return DateFormat('MMM dd, yyyy hh:mm a').format(pktTime);
  }

  /// Formats date with full month name (e.g., "December 25, 2025")
  static String formatFullDatePKT(DateTime dateTime) {
    final pktTime = toPKT(dateTime);
    return DateFormat('MMMM d, y').format(pktTime);
  }

  /// Formats date with day name (e.g., "Thursday, December 25, 2025")
  static String formatDayDatePKT(DateTime dateTime) {
    final pktTime = toPKT(dateTime);
    return DateFormat('EEEE, MMMM d, yyyy').format(pktTime);
  }

  /// Formats date with day name and time (e.g., "Thursday, December 25, 2025 at 2:30 PM")
  static String formatDayDateTimePKT(DateTime dateTime) {
    final pktTime = toPKT(dateTime);
    return DateFormat('EEEE, MMMM d, yyyy').format(pktTime) +
        ' at ' +
        DateFormat.jm().format(pktTime);
  }

  /// Returns a human-readable relative time string (e.g., "2 hours ago", "Yesterday")
  static String getRelativeTime(DateTime dateTime) {
    final pktTime = toPKT(dateTime);
    final now = toPKT(DateTime.now());
    final difference = now.difference(pktTime);

    if (difference.inSeconds < 60) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      final mins = difference.inMinutes;
      return '$mins ${mins == 1 ? 'minute' : 'minutes'} ago';
    } else if (difference.inHours < 24) {
      final hours = difference.inHours;
      return '$hours ${hours == 1 ? 'hour' : 'hours'} ago';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      final days = difference.inDays;
      return '$days ${days == 1 ? 'day' : 'days'} ago';
    } else {
      return formatDatePKT(dateTime);
    }
  }

  /// Checks if two dates are the same day in PKT
  static bool isSameDay(DateTime date1, DateTime date2) {
    final pktDate1 = toPKT(date1);
    final pktDate2 = toPKT(date2);
    return pktDate1.year == pktDate2.year &&
        pktDate1.month == pktDate2.month &&
        pktDate1.day == pktDate2.day;
  }

  /// Checks if the date is today in PKT
  static bool isToday(DateTime dateTime) {
    return isSameDay(dateTime, DateTime.now());
  }

  /// Checks if the date is yesterday in PKT
  static bool isYesterday(DateTime dateTime) {
    final yesterday = DateTime.now().subtract(const Duration(days: 1));
    return isSameDay(dateTime, yesterday);
  }

  /// Gets a smart date label (Today, Yesterday, or formatted date)
  static String getSmartDateLabel(DateTime dateTime) {
    if (isToday(dateTime)) {
      return 'Today';
    } else if (isYesterday(dateTime)) {
      return 'Yesterday';
    } else {
      return formatDatePKT(dateTime);
    }
  }
}
