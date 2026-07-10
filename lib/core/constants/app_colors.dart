import 'package:flutter/material.dart';

class AppColors {
  static const Color background = Color(0xFF0D0E21); // Dark Navy from logo/design
  static const Color surface = Color(0xFF161829);    // Cards/Containers
  static const Color primary = Color(0xFF7C6FE0);    // Violet Accent from logo/design
  static const Color secondary = Color(0xFF9E95F5);  // Lighter violet
  
  static const Color textPrimary = Colors.white;
  static const Color textSecondary = Color(0xFF8E92B2);
  static const Color textMuted = Color(0xFF5A5D7A);

  static const Color success = Color(0xFF00E676);    // Green for positive predictions
  static const Color error = Color(0xFFFF1744);      // Red for wrong predictions
  static const Color warning = Color(0xFFFFB300);    // Amber
  
  // Agent-specific colors for distinction
  static const Color geminiColor = Color(0xFF1A73E8);
  static const Color openaiColor = Color(0xFF10A37F);
  static const Color mistralColor = Color(0xFFFF5E00);
  static const Color deepseekColor = Color(0xFF4D6BFE);

  // Gradient
  static const Gradient primaryGradient = LinearGradient(
    colors: [primary, Color(0xFF5E4EE6)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const Gradient backgroundGradient = LinearGradient(
    colors: [background, Color(0xFF070814)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );
}
