import 'dart:convert';
import 'package:functions_client/functions_client.dart';

class EmailOtpService {
  final FunctionsClient _functionsClient;

  EmailOtpService(this._functionsClient);

  // Envoi d'un OTP (utilisation de paramètres nommés)
  Future<void> sendOtp({required String email}) async {
    try {
      final response = await _functionsClient.invoke(
        functionName: 'sendOtp',
        body: {'email': email},
      );
      // ✅ Correction : utiliser response.data au lieu de response.body
      final data = response.data as Map<String, dynamic>? ?? {};
      if (data['success'] != true) {
        throw Exception('Erreur lors de l\'envoi de l\'OTP');
      }
    } catch (e) {
      throw Exception('Échec de l\'envoi de l\'OTP: $e');
    }
  }

  // Vérification de l'OTP (méthode unique)
  Future<bool> verifyOtp({required String email, required String code}) async {
    try {
      final response = await _functionsClient.invoke(
        functionName: 'verifyOtp',
        body: {'email': email, 'code': code},
      );
      // ✅ Utilisation de response.data
      final data = response.data as Map<String, dynamic>? ?? {};
      return data['valid'] == true;
    } catch (e) {
      throw Exception('Échec de la vérification OTP: $e');
    }
  }
}
