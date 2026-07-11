import 'package:flutter/material.dart';

class AppColors {
  // ─── Couleurs principales — Thème Violet/Sombre ───
  static const Color primary = Color(0xFF7C3AED);       // Violet vif
  static const Color primaryLight = Color(0xFF9E95F5);  // Violet clair
  static const Color primaryDark = Color(0xFF5B21B6);   // Violet foncé
  static const Color secondary = Color(0xFF9E95F5);     // Lavande
  static const Color secondaryLight = Color(0xFFC4B5FD);

  // ─── Arrière-plans ───
  static const Color background = Color(0xFF0D0E21);    // Bleu nuit profond
  static const Color surface = Color(0xFF161829);       // Surface légèrement plus claire
  static const Color surfaceElevated = Color(0xFF1E2035); // Surface élevée

  // ─── Texte ───
  static const Color textPrimary = Colors.white;
  static const Color textSecondary = Color(0xFFB0B3C6); // Gris lavande
  static const Color textMuted = Color(0xFF6B6E8A);     // Gris sombre
  static const Color textWhite = Colors.white;

  // ─── États ───
  static const Color success = Color(0xFF22C55E);       // Vert vif
  static const Color error = Color(0xFFEF4444);         // Rouge vif
  static const Color warning = Color(0xFFF59E0B);       // Ambre
  static const Color info = Color(0xFF3B82F6);          // Bleu

  // ─── Agents IA (Noms requis par prediction_screen.dart) ───
  static const Color geminiColor = Color(0xFF4285F4);   // Bleu Google
  static const Color openaiColor = Color(0xFF10B981);   // Vert émeraude
  static const Color mistralColor = Color(0xFFFF7A00);  // Orange Mistral
  static const Color deepseekColor = Color(0xFF6366F1); // Indigo
  static const Color agentGrok = Color(0xFF000000);     // Noir Grok
  static const Color agentPerplexity = Color(0xFF20B2AA);// Turquoise

  // ─── Dégradés ───
  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF7C3AED), Color(0xFF9E95F5)],
  );

  static const LinearGradient backgroundGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFF0D0E21), Color(0xFF111328)],
  );

  static const LinearGradient cardGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF161829), Color(0xFF1E2035)],
  );

  static const LinearGradient heroGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF5B21B6), Color(0xFF7C3AED), Color(0xFF9E95F5)],
  );
}
