import 'package:supabase_flutter/supabase_flutter.dart';

class AuthService {
  final SupabaseClient _client = Supabase.instance.client;

  /// Connecte un utilisateur avec son email et mot de passe.
  /// Retourne la réponse d'authentification contenant la session et l'utilisateur.
  /// Lance une [AuthException] en cas d'échec.
  Future<AuthResponse> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    return await _client.auth.signInWithPassword(
      email: email,
      password: password,
    );
  }

  /// Crée un nouveau compte utilisateur avec email et mot de passe.
  /// Retourne la réponse d'authentification.
  /// L'utilisateur peut nécessiter une confirmation par email selon la configuration Supabase.
  Future<AuthResponse> createUserWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    return await _client.auth.signUp(
      email: email,
      password: password,
    );
  }

  /// Déconnecte l'utilisateur actuellement connecté.
  Future<void> signOut() async {
    await _client.auth.signOut();
  }

  /// Envoie un email de réinitialisation du mot de passe.
  Future<void> sendPasswordResetEmail({required String email}) async {
    await _client.auth.resetPasswordForEmail(email);
  }

  /// Retourne l'utilisateur actuellement connecté, ou `null` si personne ne l'est.
  User? getCurrentUser() {
    return _client.auth.currentUser;
  }

  /// Écoute les changements d'état de l'authentification (connexion, déconnexion, mise à jour du token...).
  Stream<AuthState> get authStateChanges => _client.auth.onAuthStateChange;
}
