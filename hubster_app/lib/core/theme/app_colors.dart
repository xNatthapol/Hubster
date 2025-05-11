import 'package:flutter/material.dart';

class AppColors {
  static const Color primary = Color(0xFF4F46E5);
  static const Color primaryLight = Color(0xFF7067F0);
  static const Color primaryDark = Color(0xFF3932B4);

  static const Color secondary = Colors.pinkAccent;
  static const Color background = Colors.white;
  static const Color surface = Colors.white;
  static const Color error = Colors.redAccent;

  static const Color onPrimary = Colors.white;
  static const Color onSecondary = Colors.white;
  static const Color onBackground = Color(0xFF121212);
  static const Color onSurface = Color(0xFF121212);
  static const Color onError = Colors.white;

  static const Color textPrimary = Color(0xFF1F2937);
  static const Color textSecondary = Color(0xFF6B7280);
  static const Color textHint = Color(0xFF9CA3AF);
  static const Color iconColor = Color(0xFF4B5563);

  // Specific for AppBar
  static const Color appBarBackground = Colors.white;
  static const Color appBarForeground = Color(0xFF4F46E5);

  // Specific for BottomNav (can use AppColors.primary too)
  static const Color bottomNavSelected = Color(0xFF4F46E5);
  static const Color bottomNavUnselected = Colors.grey;
}
