import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart'; // ✅ Import nécessaire pour User
import '../services/auth_service.dart';

// Modèles locaux
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

  // Inscription (propage l'erreur)
  Future<void> register(String email, String password, String username) async {
    _setLoading(true);
    try {
      await _authService.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      final authUser = _authService.getCurrentUser();
      if (authUser == null) {
        throw Exception('Impossible de récupérer l\'utilisateur après inscription. Vérifiez votre email (confirmation requise ?).');
      }
      _user = _mapAuthUserToAppUser(authUser, username: username);
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

  // Utiliser une prédiction
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

  // ✅ Maintenant User est reconnu grâce à l'import supabase_flutter
  AppUser _mapAuthUserToAppUser(User authUser, {String? username}) {
    return AppUser(
      id: authUser.id,
      email: authUser.email ?? 'no-email',
      isPremium: false,
      predictionsLeft: 3,
    );
  }
}
