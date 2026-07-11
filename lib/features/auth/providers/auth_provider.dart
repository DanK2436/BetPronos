// lib/features/auth/providers/auth_provider.dart
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart'; // ✅ nécessaire pour le type User
import '../services/auth_service.dart';

// Modèles locaux (si vous n'avez pas de classes dédiées)
class AppUser {
  final String id;
  final String email;
  final bool isPremium;
  final int predictionsLeft;
  AppUser({
    required this.id,
    required this.email,
    this.isPremium = false,
    this.predictionsLeft = 3,
  });
}

class UserProfile {
  final String userId;
  final String displayName;
  UserProfile({required this.userId, required this.displayName});
}

class AuthProvider extends ChangeNotifier {
  final AuthService _authService;
  AppUser? _user;
  UserProfile? _profile;
  bool _isLoading = false;

  AuthProvider(this._authService) {
    final currentUser = _authService.getCurrentUser();
    debugPrint('AuthProvider: currentUser = $currentUser');
    if (currentUser != null) {
      _user = _mapAuthUserToAppUser(currentUser);
      _loadProfile();
    }
  }

  // Getters
  AppUser? get user => _user;
  UserProfile? get profile => _profile;
  bool get isLoading => _isLoading;
  bool get isAuthenticated => _user != null;
  bool get isPremium => _user?.isPremium ?? false;
  int get predictionsLeft => _user?.predictionsLeft ?? 0;
  bool get canAccessPredictions => (_user?.predictionsLeft ?? 0) > 0;

  // Connexion (propage l'erreur)
  Future<void> login(String email, String password) async {
    _setLoading(true);
    try {
      await _authService.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      final authUser = _authService.getCurrentUser();
      if (authUser == null) {
        throw Exception('Impossible de récupérer l\'utilisateur après connexion.');
      }
      _user = _mapAuthUserToAppUser(authUser);
      await _loadProfile();
    } finally {
      _setLoading(false);
    }
  }

  // Inscription (sans OTP, connexion immédiate)
  Future<void> register(String email, String password, String username) async {
    _setLoading(true);
    try {
      // Étape 1 : inscription via Supabase
      await _authService.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Étape 2 : récupérer l'utilisateur fraîchement créé
      // (si la confirmation d'email est désactivée dans Supabase, il est automatiquement connecté)
      final authUser = _authService.getCurrentUser();
      if (authUser == null) {
        // Si l'utilisateur n'est pas encore connecté (ex: confirmation requise),
        // on tente une connexion automatique avec les identifiants fournis.
        try {
          await _authService.signInWithEmailAndPassword(
            email: email,
            password: password,
          );
          final newUser = _authService.getCurrentUser();
          if (newUser == null) {
            throw Exception(
              'L\'inscription a réussi, mais nous n\'avons pas pu vous connecter automatiquement. '
              'Veuillez vous connecter manuellement.'
            );
          }
          _user = _mapAuthUserToAppUser(newUser, username: username);
        } catch (e) {
          // En cas d'échec de la connexion automatique, on laisse l'utilisateur se connecter lui-même
          throw Exception(
            'Inscription réussie, veuillez vous connecter avec vos identifiants. '
            'Si vous avez reçu un email de confirmation, validez-le d\'abord.'
          );
        }
      } else {
        // L'utilisateur est déjà connecté après l'inscription
        _user = _mapAuthUserToAppUser(authUser, username: username);
      }

      // Chargement du profil (ici, vous pouvez ajouter des appels Firestore)
      await _loadProfile();

    } finally {
      _setLoading(false);
    }
  }

  // Déconnexion
  Future<void> logout() async {
    await _authService.signOut();
    _user = null;
    _profile = null;
    notifyListeners();
  }

  // Premium (simulation)
  Future<void> makePremium() async {
    if (_user == null) return;
    _user = AppUser(
      id: _user!.id,
      email: _user!.email,
      isPremium: true,
      predictionsLeft: 999,
    );
    notifyListeners();
  }

  // Utiliser une prédiction (décrémente le compteur)
  Future<void> usePrediction() async {
    if (_user == null || _user!.predictionsLeft <= 0) return;
    _user = AppUser(
      id: _user!.id,
      email: _user!.email,
      isPremium: _user!.isPremium,
      predictionsLeft: _user!.predictionsLeft - 1,
    );
    notifyListeners();
  }

  // --- Méthodes privées ---

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  Future<void> _loadProfile() async {
    if (_user != null) {
      _profile = UserProfile(
        userId: _user!.id,
        displayName: _user!.email.split('@').first,
      );
    }
    notifyListeners();
  }

  // Map un User Supabase vers notre AppUser local
  AppUser _mapAuthUserToAppUser(User authUser, {String? username}) {
    // Ici, vous pouvez charger des données supplémentaires depuis Firestore
    return AppUser(
      id: authUser.id,
      email: authUser.email ?? 'no-email',
      isPremium: false, // à remplacer par la vraie valeur (ex: depuis Firestore)
      predictionsLeft: 3,
    );
  }
}
