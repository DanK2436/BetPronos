import 'dart:convert';
import 'package:functions_client/functions_client.dart';

class EmailOtpService {
  final FunctionsClient _functionsClient;

  EmailOtpService(this._functionsClient);

  Future<void> sendOtp({required String email}) async {
    try {
      final response = await _functionsClient.invoke(
        'sendOtp',
        body: {'email': email},
      );
      final data = response.data as Map<String, dynamic>? ?? {};
      if (data['success'] != true) {
        throw Exception('Erreur lors de l\'envoi de l\'OTP');
      }
    } catch (e) {
      throw Exception('Échec de l\'envoi de l\'OTP: $e');
    }
  }

  Future<bool> verifyOtp({required String email, required String code}) async {
    try {
      final response = await _functionsClient.invoke(
        'verifyOtp',
        body: {'email': email, 'code': code},
      );
      final data = response.data as Map<String, dynamic>? ?? {};
      return data['valid'] == true;
    } catch (e) {
      throw Exception('Échec de la vérification OTP: $e');
    }
  }
}
