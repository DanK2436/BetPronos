import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/utils/device_utils.dart';

class AuthService {
  final SupabaseClient _client = Supabase.instance.client;

  User? get currentUser => _client.auth.currentUser;

  Session? get currentSession => _client.auth.currentSession;

  Stream<AuthState> get authStateChanges => _client.auth.onAuthStateChange;

  Future<AuthResponse> signUp({
    required String email,
    required String password,
    required String username,
  }) async {
    try {
      final deviceId = await DeviceUtils.getDeviceId();

      // Check account limits on this device
      final existingAccounts = await _client
          .from('profiles')
          .select('id')
          .eq('device_id', deviceId);

      if (existingAccounts.length >= 2) {
        throw Exception("Limite de 2 comptes par appareil atteinte.");
      }

      final response = await _client.auth.signUp(
        email: email,
        password: password,
        data: {'username': username},
      );
      
      if (response.user != null) {
        await _client.from('profiles').upsert({
          'id': response.user!.id,
          'username': username,
          'avatar_url': 'https://api.dicebear.com/7.x/bottts/svg?seed=$username',
          'subscription_tier': 'free',
          'device_id': deviceId,
          'prediction_count': 0,
          'created_at': DateTime.now().toIso8601String(),
        });
      }
      
      return response;
    } catch (e) {
      rethrow;
    }
  }

  Future<AuthResponse> signIn({
    required String email,
    required String password,
  }) async {
    try {
      return await _client.auth.signInWithPassword(
        email: email,
        password: password,
      );
    } catch (e) {
      rethrow;
    }
  }

  Future<void> signOut() async {
    await _client.auth.signOut();
  }

  Future<Map<String, dynamic>?> getUserProfile(String userId) async {
    try {
      final data = await _client
          .from('profiles')
          .select()
          .eq('id', userId)
          .maybeSingle();
      return data;
    } catch (e) {
      return null;
    }
  }

  Future<void> incrementPredictionCount(String userId) async {
    try {
      final profile = await getUserProfile(userId);
      if (profile != null) {
        final currentCount = profile['prediction_count'] ?? 0;
        await _client.from('profiles').update({
          'prediction_count': currentCount + 1,
        }).eq('id', userId);
      }
    } catch (e) {
      debugPrint('Failed to increment prediction count: $e');
    }
  }

  Future<void> updateUserSubscription(String userId, String tier) async {
    try {
      await _client.from('profiles').update({
        'subscription_tier': tier,
        'prediction_count': 0, // Reset count on subscription
      }).eq('id', userId);
    } catch (e) {
      rethrow;
    }
  }
}
