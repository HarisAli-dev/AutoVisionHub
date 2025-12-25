// theme_provider.dart

import 'package:flutter/material.dart';

class AppColors {
  static const Color primary = Color(0xFFFF9800);
  static const Color buttonColor = primary;
  static Color? secondary = const Color(0xFFFFE0B2);

  static const Color lightBackground = Color(0xFFFFF7F1);
  static const Color darkBackground = Color(0xFF111317);
  static const Color lightSurface = Colors.white;
  static const Color darkSurface = Color(0xFF1C1F24);
  static const Color lightForeground = Color(0xFF1F1F1F);
  static const Color darkForeground = Color(0xFFE5E7EB);
  static const Color lightShade = Color(0xFF6B7280);
  static final Color darkShade = Colors.grey.shade500;
  static const Color darkAppBar = Color(0xFF1C1F24);

  static Color backgroundColor = lightBackground;
  static Color surfaceColor = lightSurface;
  static Color foregroundColor = lightForeground;
  static Color shadeColor = lightShade;
  static Color appBarColor = primary;
  static Color successColor = const Color(0xFF4CAF50);
  static Color errorColor = const Color(0xFFFF5252);
  static Color titleColor = Colors.black87;

  static const Color gridLineColor = Colors.grey;
  static const Color seatEmptyColor = Color(0xFF4CAF50);
  static const Color seatBookedColor = Color(0xFFFFB300);
  static const Color seatReservedColor = Color(0xFFEF5350);

  static Color messageReceiverColor = Colors.purple;
  static Color? disabledInputFillColor = Colors.black12;

  static void applyTheme(bool isDark) {
    if (isDark) {
      backgroundColor = darkBackground;
      surfaceColor = darkSurface;
      foregroundColor = darkForeground;
      shadeColor = darkShade;
      appBarColor = primary;
      titleColor = Colors.white;
      messageReceiverColor = Colors.purpleAccent;
      disabledInputFillColor = Colors.white12;
    } else {
      backgroundColor = lightBackground;
      surfaceColor = lightSurface;
      foregroundColor = lightForeground;
      shadeColor = lightShade;
      appBarColor = primary;
      titleColor = Colors.black87;
      messageReceiverColor = Colors.purple;
      disabledInputFillColor = Colors.black12;
    }
  }

  static Color getBackgroundColor(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    applyTheme(isDark);
    return backgroundColor;
  }
}
