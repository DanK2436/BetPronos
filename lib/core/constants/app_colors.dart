import 'package:flutter/material.dart';

class AppColors {
  // Couleurs principales (orange/bleu)
  static const Color primary = Color(0xFFFF6B00);      // Orange vif
  static const Color primaryLight = Color(0xFFFF8C42); // Orange clair
  static const Color primaryDark = Color(0xFFCC5500);  // Orange foncé
  
  static const Color secondary = Color(0xFF1A2A3A);    // Bleu foncé
  static const Color secondaryLight = Color(0xFF2C3E50);
  static const Color secondaryDark = Color(0xFF0D1B2A);
  
  // Couleurs d'arrière-plan
  static const Color background = Color(0xFFF5F7FA);
  static const Color surface = Colors.white;
  static const Color surfaceDark = Color(0xFFE8ECF1);
  
  // Couleurs de texte
  static const Color textPrimary = Color(0xFF1A1A1A);
  static const Color textSecondary = Color(0xFF6B7A8A);
  static const Color textLight = Color(0xFF9EADBA);
  static const Color textWhite = Colors.white;
  
  // Couleurs d'état
  static const Color success = Color(0xFF27AE60);
  static const Color error = Color(0xFFE74C3C);
  static const Color warning = Color(0xFFF39C12);
  static const Color info = Color(0xFF3498DB);
  
  // Dégradés
  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [primary, primaryLight],
  );
  
  static const LinearGradient backgroundGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFFF5F7FA), Colors.white],
  );
}
