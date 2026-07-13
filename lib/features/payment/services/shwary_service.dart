import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/constants/api_constants.dart';

class ShwaryService {
  final http.Client _client = http.Client();
  final SupabaseClient _supabase = Supabase.instance.client;

  /// Initie un paiement Mobile Money DRC via l'API directe Shwary
  /// Endpoint réel : POST https://api.shwary.com/api/v1/merchants/payment/DRC
  /// Auth : x-merchant-id + x-merchant-key (pas Authorization: Bearer)
  Future<Map<String, dynamic>> initializeDirectPayment({
    required String userId,
    required String email,
    required double amount,
    required String currency,
    required String reference,
    required String operator,
    required String phoneNumber,
    required String planName,
  }) async {
    // 1. Formater le numéro au format E.164 (+243...)
    String formattedPhone = phoneNumber.trim();
    if (formattedPhone.startsWith('0')) {
      formattedPhone = '+243${formattedPhone.substring(1)}';
    } else if (!formattedPhone.startsWith('+')) {
      formattedPhone = '+243$formattedPhone';
    }

    // 2. Insérer le paiement en attente dans Supabase
    debugPrint('💾 Insertion du paiement pending ($reference)...');
    try {
      await _supabase.from('payments').insert({
        'user_id': userId,
        'amount': amount.toInt(),
        'currency': currency,
        'operator': operator,
        'phone_number': formattedPhone,
        'shwary_reference': reference,
        'status': 'pending',
        'plan_name': planName,
      });
    } catch (e) {
      debugPrint('⚠️ Supabase insert warning: $e');
    }

    // 3. Appeler l'API Shwary réelle — Direct Charge DRC
    debugPrint('📲 Envoi requête Shwary Direct: $formattedPhone → $amount CDF');
    try {
      final url = Uri.parse('${ApiConstants.shwaryBaseUrl}/merchants/payment/DRC');
      final response = await _client.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'x-merchant-id': ApiConstants.shwaryMerchantId,
          'x-merchant-key': ApiConstants.shwaryApiKey,
        },
        body: json.encode({
          'amount': amount.toInt(),
          'clientPhoneNumber': formattedPhone,
          'callbackUrl': ApiConstants.shwaryWebhookUrl,
        }),
      ).timeout(const Duration(seconds: 20));

      debugPrint('📡 Shwary réponse: ${response.statusCode} — ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = json.decode(response.body);
        // Sauvegarder l'ID de transaction Shwary dans Supabase
        final shwaryTxId = data['id']?.toString() ?? reference;
        try {
          await _supabase
              .from('payments')
              .update({'shwary_reference': shwaryTxId})
              .eq('shwary_reference', reference);
        } catch (_) {}
        return {
          'success': true,
          'status': data['status'] ?? 'pending',
          'reference': shwaryTxId,
          'isSandbox': data['isSandbox'] ?? false,
        };
      } else {
        debugPrint('⚠️ Shwary erreur ${response.statusCode}: ${response.body}');
        if (response.statusCode == 401 && kDebugMode) {
          // En mode debug uniquement : simulation si clés API non configurées
          debugPrint('🔄 Clé API invalide (401) - Mode simulation activé (DEBUG seulement).');
          return {
            'success': true,
            'status': 'pending',
            'reference': reference,
            'isSandbox': true,
          };
        }
        return {
          'success': false,
          'error': response.statusCode == 401
              ? 'Configuration du paiement incorrecte. Contactez le support.'
              : 'Erreur API Shwary: ${response.statusCode}',
          'reference': reference,
        };
      }
    } catch (e) {
      debugPrint('❌ Exception Shwary: \$e');
      if (kDebugMode) {
        // Simulation hors-ligne uniquement en debug
        return {
          'success': true,
          'status': 'pending',
          'reference': reference,
          'isSandbox': true,
        };
      }
      return {
        'success': false,
        'error': 'Impossible de contacter le serveur de paiement. Vérifiez votre connexion.',
        'reference': reference,
      };
    }
  }

  /// Vérifie le statut du paiement via Supabase (webhook) ou l'API Shwary
  Future<bool> verifyPaymentStatus(String reference) async {
    try {
      // Si la référence commence par "bp_" → seulement en mode DEBUG (test dev)
      if (reference.startsWith('bp_') && kDebugMode) {
        // Mettre à jour Supabase en succès pour le test local
        try {
          await _supabase
              .from('payments')
              .update({'status': 'success', 'confirmed_at': DateTime.now().toIso8601String()})
              .eq('shwary_reference', reference);
        } catch (_) {}
        return true;
      }

      // D'abord vérifier via Supabase si le webhook a déjà mis à jour le statut
      final row = await _supabase
          .from('payments')
          .select('status')
          .eq('shwary_reference', reference)
          .maybeSingle();

      if (row != null && row['status'] == 'success') {
        return true;
      }

      return false;
    } catch (e) {
      debugPrint('Erreur vérification paiement: $e');
      return false;
    }
  }
}
