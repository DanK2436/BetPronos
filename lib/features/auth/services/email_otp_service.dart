import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Service OTP par email via Supabase Auth
/// L'email de l'expéditeur se configure dans :
/// Supabase Dashboard → Authentication → Emails → SMTP Settings
/// Adresse d'envoi : dankande3@gmail.com
class EmailOtpService {
  final SupabaseClient _client = Supabase.instance.client;

  /// Envoie un OTP 6 chiffres à l'email spécifié (appel Supabase natif)
  Future<void> sendOtp(String email) async {
    await _client.auth.signInWithOtp(
      email: email,
      shouldCreateUser: false, // L'user est créé via signUp, pas ici
    );
  }

  /// Vérifie l'OTP entré par l'utilisateur (type signup = confirmation d'inscription)
  Future<bool> verifySignupOtp(String email, String token) async {
    try {
      final response = await _client.auth.verifyOTP(
        email: email,
        token: token,
        type: OtpType.signup,
      );
      return response.session != null || response.user != null;
    } catch (e) {
      debugPrint('OTP verification error: $e');
      return false;
    }
  }

  /// Vérifie l'OTP pour une connexion par magic link/OTP
  Future<bool> verifyEmailOtp(String email, String token) async {
    try {
      final response = await _client.auth.verifyOTP(
        email: email,
        token: token,
        type: OtpType.email,
      );
      return response.session != null || response.user != null;
    } catch (e) {
      debugPrint('OTP email verification error: $e');
      return false;
    }
  }
}
