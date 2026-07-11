import 'package:flutter/material.dart';
import 'package:betpronos/features/auth/services/auth_service.dart';

// Modèle utilisateur minimal (remplacez par votre vrai User si existant)
class AppUser {
  final String id;
  final String email;
  final bool isPremium;
  final int predictionsLeft;
  AppUser({required this.id, required this.email, this.isPremium = false, this.predictionsLeft = 3});
}

// Modèle de profil (similaire)
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
    // Récupérer l'utilisateur courant si déjà connecté
    final currentUser = _authService.getCurrentUser();
    if (currentUser != null) {
      _user = _mapAuthUserToAppUser(currentUser);
      _loadProfile();
    }
  }

  // Getters publics
  AppUser? get user => _user;
  UserProfile? get profile => _profile;
  bool get isLoading => _isLoading;
  bool get isAuthenticated => _user != null;
  bool get isPremium => _user?.isPremium ?? false;
  int get predictionsLeft => _user?.predictionsLeft ?? 0;
  bool get canAccessPredictions => _user?.predictionsLeft ?? 0 > 0;

  // Connexion
  Future<bool> login(String email, String password) async {
    _setLoading(true);
    try {
      await _authService.signInWithEmailAndPassword(email: email, password: password);
      final authUser = _authService.getCurrentUser();
      if (authUser != null) {
        _user = _mapAuthUserToAppUser(authUser);
        await _loadProfile();
        _setLoading(false);
        return true;
      }
      return false;
    } catch (e) {
      _setLoading(false);
      return false;
    }
  }

  // Inscription
  Future<bool> register(String email, String password, String username) async {
    _setLoading(true);
    try {
      await _authService.createUserWithEmailAndPassword(email: email, password: password);
      final authUser = _authService.getCurrentUser();
      if (authUser != null) {
        _user = _mapAuthUserToAppUser(authUser, username: username);
        // Vous pouvez enregistrer le username dans Firestore ici
        await _loadProfile();
        _setLoading(false);
        return true;
      }
      return false;
    } catch (e) {
      _setLoading(false);
      return false;
    }
  }

  // Déconnexion
  Future<void> logout() async {
    await _authService.signOut();
    _user = null;
    _profile = null;
    notifyListeners();
  }

  // Devenir premium (simulation)
  Future<void> makePremium() async {
    if (_user == null) return;
    // Appel à votre backend pour mettre à jour l'abonnement
    // await _authService.updateUserSubscription(_user!.id, 'premium');
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
    // Décrémenter le compteur (appel API)
    // await _authService.incrementPredictionCount(_user!.id); // ou décrémenter
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
    // Simulation de chargement de profil
    if (_user != null) {
      _profile = UserProfile(
        userId: _user!.id,
        displayName: _user!.email.split('@').first,
      );
    }
    notifyListeners();
  }

  // Fonction de mapping (à adapter selon votre AuthService)
  AppUser _mapAuthUserToAppUser(dynamic authUser, {String? username}) {
    // Si AuthService retourne un User de Supabase, utilisez ses champs
    // Ici je suppose que authUser a un 'id' et un 'email'
    return AppUser(
      id: authUser.id ?? 'unknown',
      email: authUser.email ?? 'no-email',
      isPremium: false, // à récupérer depuis Firestore
      predictionsLeft: 3, // idem
    );
  }
}
