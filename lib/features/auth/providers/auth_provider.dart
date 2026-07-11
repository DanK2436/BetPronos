import 'package:flutter/material.dart';
import 'package:betpronos/features/auth/services/auth_service.dart';
import 'package:betpronos/features/auth/models/user_profile.dart'; // Assurez-vous que le modèle existe

class AuthProvider extends ChangeNotifier {
  final AuthService _authService;
  User? _user;
  UserProfile? _profile;

  AuthProvider(this._authService) {
    _user = _authService.getCurrentUser(); // ✅ Utilisation correcte
  }

  User? get user => _user;
  UserProfile? get profile => _profile;

  // Charge le profil utilisateur (méthode à implémenter dans AuthService si nécessaire)
  Future<void> loadUserProfile(String userId) async {
    try {
      // Si la méthode getUserProfile n'existe pas encore, on peut commenter ou simuler
      // _profile = await _authService.getUserProfile(userId);
      // Pour l'instant, on garde un placeholder
      _profile = null; // ou récupérer depuis Firestore directement
      notifyListeners();
    } catch (e) {
      debugPrint('Erreur lors du chargement du profil: $e');
    }
  }

  // Connexion - utilise la méthode correcte
  Future<void> signIn({required String email, required String password}) async {
    try {
      await _authService.signInWithEmailAndPassword(email: email, password: password);
      _user = _authService.getCurrentUser();
      notifyListeners();
    } catch (e) {
      debugPrint('Erreur de connexion: $e');
      rethrow;
    }
  }

  // Inscription - utilise la méthode correcte
  Future<void> signUp({required String email, required String password, required String username}) async {
    try {
      await _authService.createUserWithEmailAndPassword(email: email, password: password);
      _user = _authService.getCurrentUser();
      // Si vous voulez stocker le username, faites-le dans une collection séparée
      notifyListeners();
    } catch (e) {
      debugPrint('Erreur d\'inscription: $e');
      rethrow;
    }
  }

  // Déconnexion
  Future<void> signOut() async {
    try {
      await _authService.signOut();
      _user = null;
      _profile = null;
      notifyListeners();
    } catch (e) {
      debugPrint('Erreur de déconnexion: $e');
      rethrow;
    }
  }

  // Incrémenter le compteur de pronostics (méthode à ajouter si nécessaire)
  Future<void> incrementPredictionCount(String userId) async {
    // Si la méthode n'existe pas, on peut ignorer ou implémenter plus tard
    // await _authService.incrementPredictionCount(userId);
    // Pour l'instant, on ne fait rien
  }

  // Mise à jour de l'abonnement (à ajouter si nécessaire)
  Future<void> updateUserSubscription(String userId, String plan) async {
    // await _authService.updateUserSubscription(userId, plan);
    // Pour l'instant, on ne fait rien
  }
}
