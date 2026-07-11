import 'dart:convert';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../../../core/constants/api_constants.dart';

/// Service OTP via WhatsApp Cloud API (Meta)
/// Numéro d'envoi configuré : +243852793324
class WhatsAppOtpService {
  // Stockage temporaire du code OTP (en mémoire seulement)
  String? _currentOtp;
  String? _targetPhone;
  DateTime? _otpExpiry;

  /// Génère un code OTP à 6 chiffres
  String _generateOtp() {
    final random = Random.secure();
    return (100000 + random.nextInt(900000)).toString();
  }

  /// Formate le numéro de téléphone en E.164 (ex: 0812345678 → 243812345678)
  String _formatPhone(String phone) {
    String cleaned = phone.replaceAll(RegExp(r'[\s\-\+\(\)]'), '');
    if (cleaned.startsWith('0')) {
      cleaned = '243${cleaned.substring(1)}';
    } else if (!cleaned.startsWith('243')) {
      cleaned = '243$cleaned';
    }
    return cleaned;
  }

  /// Envoie un OTP WhatsApp au numéro spécifié
  Future<bool> sendOtp(String phoneNumber) async {
    try {
      final otp = _generateOtp();
      final formattedPhone = _formatPhone(phoneNumber);

      final url = Uri.parse(
        '${ApiConstants.whatsappBaseUrl}/${ApiConstants.whatsappApiVersion}'
        '/${ApiConstants.whatsappPhoneNumberId}/messages',
      );

      final body = jsonEncode({
        "messaging_product": "whatsapp",
        "to": formattedPhone,
        "type": "template",
        "template": {
          "name": "betpronos_otp", // Nom du template à créer dans Meta for Developers
          "language": {"code": "fr"},
          "components": [
            {
              "type": "body",
              "parameters": [
                {"type": "text", "text": otp},
                {"type": "text", "text": "10"}, // minutes de validité
              ]
            }
          ]
        }
      });

      // Fallback : si le template n'est pas disponible, envoyer un message texte libre
      final bodyText = jsonEncode({
        "messaging_product": "whatsapp",
        "to": formattedPhone,
        "type": "text",
        "text": {
          "body": "🔐 betPronos - Votre code de vérification est : *$otp*\n\nCe code expire dans 10 minutes. Ne le partagez jamais."
        }
      });

      final response = await http.post(
        url,
        headers: {
          'Authorization': 'Bearer ${ApiConstants.whatsappAccessToken}',
          'Content-Type': 'application/json',
        },
        body: bodyText, // Utilise le texte libre en attendant l'approbation du template
      );

      debugPrint('WhatsApp OTP response: ${response.statusCode} ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        _currentOtp = otp;
        _targetPhone = formattedPhone;
        _otpExpiry = DateTime.now().add(const Duration(minutes: 10));
        return true;
      } else {
        debugPrint('WhatsApp OTP failed: ${response.body}');
        return false;
      }
    } catch (e) {
      debugPrint('WhatsApp OTP error: $e');
      return false;
    }
  }

  /// Vérifie si l'OTP saisi par l'utilisateur est correct
  bool verifyOtp(String inputOtp) {
    if (_currentOtp == null || _otpExpiry == null) return false;
    if (DateTime.now().isAfter(_otpExpiry!)) {
      _currentOtp = null; // OTP expiré
      return false;
    }
    final isValid = inputOtp.trim() == _currentOtp;
    if (isValid) _currentOtp = null; // Invalidate après usage
    return isValid;
  }

  /// Vérifie si un OTP est en cours de validité
  bool get hasActiveOtp =>
      _currentOtp != null &&
      _otpExpiry != null &&
      DateTime.now().isBefore(_otpExpiry!);

  /// Retourne le numéro cible formaté (pour affichage masqué)
  String get maskedPhone {
    if (_targetPhone == null) return '';
    final p = _targetPhone!;
    if (p.length < 6) return p;
    return '${p.substring(0, 5)}****${p.substring(p.length - 2)}';
  }
}
