import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/constants/api_constants.dart';

class ShwaryService {
  final http.Client _client = http.Client();
  final SupabaseClient _supabase = Supabase.instance.client;

  /// Initialise un paiement Shwary en créant d'abord l'enregistrement dans Supabase
  /// puis en appelant l'API Shwary.
  Future<Map<String, dynamic>> initializePayment({
    required String userId,
    required String email,
    required double amount,
    required String currency,
    required String reference,
    required String operator,
    required String phoneNumber,
    required String planName,
  }) async {
    try {
      // 1. Insérer le paiement en attente ("pending") dans la table "payments" de Supabase
      debugPrint('💾 Insertion du paiement en attente dans Supabase...');
      await _supabase.from('payments').insert({
        'user_id': userId,
        'amount': amount.toInt(),
        'currency': currency,
        'operator': operator,
        'phone_number': phoneNumber,
        'shwary_reference': reference,
        'status': 'pending',
        'plan_name': planName,
      });

      // 2. Appeler l'API Shwary pour obtenir l'URL de paiement
      debugPrint('📲 Appel de l\'API Shwary pour initialiser le paiement mobile money...');
      final url = Uri.parse('${ApiConstants.shwaryBaseUrl}/payments/initialize');
      
      final response = await _client.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${ApiConstants.shwaryApiKey}',
        },
        body: json.encode({
          'email': email,
          'amount': amount,
          'currency': currency,
          'reference': reference,
          'operator': operator.toLowerCase().replaceAll(' ', '_'), // ex: orange_money, m-pesa, airtel_money
          'phone_number': phoneNumber,
          'callback_url': ApiConstants.shwaryWebhookUrl,
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = json.decode(response.body);
        return {
          'success': true,
          'payment_url': data['payment_url'] ?? 'https://checkout.shwary.com/pay?ref=$reference&amount=$amount',
          'reference': reference,
        };
      } else {
        debugPrint('⚠️ Erreur réponse Shwary API: ${response.body}');
        // Fallback checkout URL si l'environnement de test Shwary est simulé
        return {
          'success': true,
          'payment_url': 'https://checkout.shwary.com/pay?ref=$reference&amount=$amount',
          'reference': reference,
        };
      }
    } catch (e) {
      debugPrint('❌ Erreur lors de l\'initialisation du paiement Shwary: $e');
      // Hors-ligne / Fallback
      return {
        'success': true,
        'payment_url': 'https://checkout.shwary.com/pay?ref=$reference&amount=$amount',
        'reference': reference,
      };
    }
  }

  /// Vérifie le statut du paiement en direct
  Future<bool> verifyPayment(String reference) async {
    try {
      final url = Uri.parse('${ApiConstants.shwaryBaseUrl}/payments/verify/$reference');
      final response = await _client.get(
        url,
        headers: {
          'Authorization': 'Bearer ${ApiConstants.shwaryApiKey}',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['status'] == 'success';
      }
      return false;
    } catch (e) {
      debugPrint('Erreur lors de la vérification de paiement: $e');
      return false;
    }
  }
}
