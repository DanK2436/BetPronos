import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:convert';

class EmailOtpService {
  final SupabaseClient _client = Supabase.instance.client;

  /// Appelle une Edge Function Supabase nommée "send-otp"
  /// qui envoie l'email OTP côté serveur (les secrets restent privés).
  Future<void> sendOtp({required String email}) async {
    final response = await _client.functions.invoke(
      'send-otp',
      body: jsonEncode({'email': email}),
    );
    if (response.status != 200) {
      throw Exception('Erreur lors de l\'envoi du code OTP');
    }
  }

  /// Vérifie l'OTP en appelant une seconde Edge Function "verify-otp".
  Future<bool> verifyOtp({
    required String email,
    required String code,
  }) async {
    final response = await _client.functions.invoke(
      'verify-otp',
      body: jsonEncode({'email': email, 'code': code}),
    );
    if (response.status == 200) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      return data['valid'] == true;
    }
    return false;
  }
}
