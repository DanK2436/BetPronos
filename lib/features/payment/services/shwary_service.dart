import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/constants/api_constants.dart';

class ShwaryService {
  final http.Client _client = http.Client();
  final SupabaseClient _supabase = Supabase.instance.client;

  /// Initie un paiement Mobile Money DRC via l'API REST de MaishaPay
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

    // 2. Associer l'opérateur avec le code de fournisseur MaishaPay
    String providerCode = 'ORANGE';
    final lowerOp = operator.toLowerCase();
    if (lowerOp.contains('orange')) {
      providerCode = 'ORANGE';
    } else if (lowerOp.contains('airtel')) {
      providerCode = 'AITEL'; // Note : 'AITEL' (sans le R) requis par MaishaPay
    } else if (lowerOp.contains('mpesa') || lowerOp.contains('pesa')) {
      providerCode = 'MPESA';
    }

    // 3. Insérer le paiement en attente dans Supabase
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

    // 4. Appeler l'API MaishaPay REST réelle
    debugPrint('📲 Envoi requête MaishaPay REST: $formattedPhone → $amount CDF ($providerCode)');
    try {
      final response = await _client.post(
        Uri.parse(ApiConstants.maishaPayBaseUrl),
        headers: {
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'gatewayMode': 1, // Mode Live (Production)
          'publicApiKey': ApiConstants.maishaPayPublicApiKey,
          'secretApiKey': ApiConstants.maishaPaySecretApiKey,
          'transactionReference': reference,
          'amount': amount.toDouble(),
          'currency': currency,
          'customerFullName': email.split('@').first,
          'walletID': formattedPhone,
          'chanel': 'MOBILEMONEY',
          'provider': providerCode,
        }),
      ).timeout(const Duration(seconds: 20));

      debugPrint('📡 MaishaPay réponse: ${response.statusCode} — ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = json.decode(response.body);
        final original = data['original'] ?? {};
        final resData = original['data'] ?? {};
        final maishaPayTxId = resData['transactionId']?.toString() ?? reference;
        
        final int statusCode = original['status'] ?? response.statusCode;

        if (statusCode == 200 || statusCode == 201 || original['statusCode'] == '202' || resData['statusCode'] == '202') {
          // Succès de l'initiation du paiement
          try {
            await _supabase
                .from('payments')
                .update({'shwary_reference': maishaPayTxId})
                .eq('shwary_reference', reference);
          } catch (_) {}

          return {
            'success': true,
            'status': 'pending',
            'reference': maishaPayTxId,
            'isSandbox': false,
          };
        } else {
          return {
            'success': false,
            'error': original['statusDescription'] ?? 'Échec de l\'initiation du paiement chez MaishaPay.',
            'reference': reference,
          };
        }
      } else {
        debugPrint('⚠️ MaishaPay erreur ${response.statusCode}: ${response.body}');
        return {
          'success': false,
          'error': 'Erreur API MaishaPay: ${response.statusCode} - ${response.body}',
          'reference': reference,
        };
      }
    } catch (e) {
      debugPrint('❌ Exception MaishaPay: $e');
      // Mode simulation hors-ligne pour tests en mode debug
      if (kDebugMode) {
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

  /// Vérifie le statut du paiement via Supabase (webhook)
  Future<bool> verifyPaymentStatus(String reference) async {
    try {
      // Si en mode debug et référence de test, simuler le succès
      if (kDebugMode && reference.startsWith('bp_')) {
        try {
          await _supabase
              .from('payments')
              .update({'status': 'success', 'confirmed_at': DateTime.now().toIso8601String()})
              .eq('shwary_reference', reference);
        } catch (_) {}
        return true;
      }

      // Vérifier via Supabase si le webhook de MaishaPay a mis à jour le statut
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
