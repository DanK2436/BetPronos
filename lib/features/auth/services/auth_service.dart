import 'package:firebase_auth/firebase_auth.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Connecte l'utilisateur avec email et mot de passe.
  /// Retourne les credentials de l'utilisateur connecté.
  /// Lance une [FirebaseAuthException] en cas d'échec (mauvais identifiants, etc.).
  Future<UserCredential> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    // Utilisation des paramètres fournis, plus de valeurs codées en dur !
    return await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
  }

  /// Crée un nouvel utilisateur avec email et mot de passe.
  /// Retourne les credentials du nouvel utilisateur.
  /// Lance une [FirebaseAuthException] en cas d'erreur (email déjà utilisé, mot de passe faible…).
  Future<UserCredential> createUserWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    return await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
  }

  /// Déconnecte l'utilisateur actuel.
  Future<void> signOut() async {
    await _auth.signOut();
  }

  /// Envoie un email de réinitialisation de mot de passe.
  /// Lance une [FirebaseAuthException] si l'adresse email n'existe pas, etc.
  Future<void> sendPasswordResetEmail({required String email}) async {
    await _auth.sendPasswordResetEmail(email: email);
  }

  /// Envoie un email de vérification à l'utilisateur actuellement connecté.
  /// Ne fait rien si aucun utilisateur n'est connecté.
  Future<void> sendEmailVerification() async {
    final user = _auth.currentUser;
    if (user != null && !user.emailVerified) {
      await user.sendEmailVerification();
    }
  }

  /// Retourne l'utilisateur actuellement connecté, ou `null` si personne ne l'est.
  User? getCurrentUser() {
    return _auth.currentUser;
  }

  /// (Optionnel) Écoute les changements d'état d'authentification en temps réel.
  Stream<User?> get authStateChanges => _auth.authStateChanges();
}
