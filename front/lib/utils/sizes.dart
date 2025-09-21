import 'package:flutter/material.dart';

class AppSizes {
  // Screen dimensions
  static double getScreenWidth(BuildContext context) {
    return MediaQuery.of(context).size.width;
  }

  static double getScreenHeight(BuildContext context) {
    return MediaQuery.of(context).size.height;
  }

  // Padding and margins
  static double containerPadding(BuildContext context) {
    return getScreenWidth(context) * 0.04;
  }

  static double smallPadding(BuildContext context) {
    return getScreenWidth(context) * 0.02;
  }

  static double mediumPadding(BuildContext context) {
    return getScreenWidth(context) * 0.04;
  }

  static double largePadding(BuildContext context) {
    return getScreenWidth(context) * 0.06;
  }

  static double bottomNavBarElevation(BuildContext context) {
    return getScreenHeight(context) * 0.02;
  }

  static double getSizeBoxHeight(BuildContext context) {
    return getScreenHeight(context) * 0.02;
  }

  static double smallSpacing(BuildContext context) {
    return getScreenHeight(context) * 0.01;
  }

  static double mediumSpacing(BuildContext context) {
    return getScreenHeight(context) * 0.02;
  }

  static double largeSpacing(BuildContext context) {
    return getScreenHeight(context) * 0.04;
  }

  // Font sizes
  static double titleFontSize(BuildContext context) {
    return getScreenWidth(context) * 0.06;
  }

  static double inputFontSize(BuildContext context) {
    return getScreenWidth(context) * 0.04;
  }

  static double subtitleFontSize(BuildContext context) {
    return getScreenWidth(context) * 0.045;
  }

  static double bodyFontSize(BuildContext context) {
    return getScreenWidth(context) * 0.035;
  }

  static double smallFontSize(BuildContext context) {
    return getScreenWidth(context) * 0.03;
  }

  static double largeFontSize(BuildContext context) {
    return getScreenWidth(context) * 0.05;
  }

  static double headerFontSize(BuildContext context) {
    return getScreenWidth(context) * 0.07;
  }

  static double captionFontSize(BuildContext context) {
    return getScreenWidth(context) * 0.025;
  }

  // Icon sizes
  static double smallIconSize(BuildContext context) {
    return getScreenWidth(context) * 0.04;
  }

  static double mediumIconSize(BuildContext context) {
    return getScreenWidth(context) * 0.05;
  }

  static double largeIconSize(BuildContext context) {
    return getScreenWidth(context) * 0.06;
  }

  static double extraLargeIconSize(BuildContext context) {
    return getScreenWidth(context) * 0.08;
  }

  // Button dimensions
  static double buttonHeight(BuildContext context) {
    return getScreenHeight(context) * 0.06;
  }

  static double smallButtonHeight(BuildContext context) {
    return getScreenHeight(context) * 0.04;
  }

  static double buttonPadding(BuildContext context) {
    return getScreenWidth(context) * 0.04;
  }

  // Card and container dimensions
  static double cardElevation(BuildContext context) {
    return getScreenWidth(context) * 0.01;
  }

  static double cardBorderRadius(BuildContext context) {
    return getScreenWidth(context) * 0.03;
  }

  static double imageHeight(BuildContext context) {
    return getScreenHeight(context) * 0.25;
  }

  static double smallImageHeight(BuildContext context) {
    return getScreenHeight(context) * 0.15;
  }

  static double avatarRadius(BuildContext context) {
    return getScreenWidth(context) * 0.06;
  }

  static double smallAvatarRadius(BuildContext context) {
    return getScreenWidth(context) * 0.04;
  }

  // Input field dimensions
  static double inputFieldHeight(BuildContext context) {
    return getScreenHeight(context) * 0.07;
  }

  static double inputBorderRadius(BuildContext context) {
    return getScreenWidth(context) * 0.02;
  }
}
