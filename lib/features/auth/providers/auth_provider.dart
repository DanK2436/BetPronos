import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/auth_service.dart';

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
  final SupabaseClient _supabase = Supabase.instance.client;
  
  AppUser? _user;
  UserProfile? _profile;
  bool _isLoading = false;

  AuthProvider(this._authService) {
    final currentUser = _authService.getCurrentUser();
    if (currentUser != null) {
      _user = _mapAuthUserToAppUser(currentUser);
      _loadProfile();
    }
  }

  AppUser? get user => _user;
  UserProfile? get profile => _profile;
  bool get isLoading => _isLoading;
  bool get isAuthenticated => _user != null;
  bool get isPremium => _user?.isPremium ?? false;
  int get predictionsLeft => _user?.predictionsLeft ?? 0;
  bool get canAccessPredictions => isPremium || predictionsLeft > 0;

  Future<void> login(String email, String password) async {
    _setLoading(true);
    try {
      await _authService.signInWithEmailAndPassword(email: email, password: password);
      final authUser = _authService.getCurrentUser();
      if (authUser == null) throw Exception('Impossible de recuperer l utilisateur.');
      _user = _mapAuthUserToAppUser(authUser);
      await _loadProfile();
    } finally {
      _setLoading(false);
    }
  }

  Future<void> register(String email, String password, String username) async {
    _setLoading(true);
    try {
      await _authService.createUserWithEmailAndPassword(email: email, password: password);
      final authUser = _authService.getCurrentUser();
      if (authUser == null) {
        try {
          await _authService.signInWithEmailAndPassword(email: email, password: password);
          final newUser = _authService.getCurrentUser();
          if (newUser == null) throw Exception('Connexion automatique echouee.');
          _user = _mapAuthUserToAppUser(newUser, username: username);
        } catch (e) {
          throw Exception('Inscription reussie, veuillez vous connecter manuellement.');
        }
      } else {
        _user = _mapAuthUserToAppUser(authUser, username: username);
      }
      await _loadProfile();
    } finally {
      _setLoading(false);
    }
  }

  Future<void> logout() async {
    await _authService.signOut();
    _user = null;
    _profile = null;
    notifyListeners();
  }

  Future<void> makePremium() async {
    if (_user == null) return;
    
    try {
      await _supabase.from('profiles').update({
        'subscription_tier': 'premium'
      }).eq('id', _user!.id);
      
      _user = AppUser(
        id: _user!.id, 
        email: _user!.email, 
        isPremium: true, 
        predictionsLeft: 999
      );
      notifyListeners();
    } catch (e) {
      debugPrint('Error making premium in Supabase: \$e');
    }
  }

  Future<void> usePrediction() async {
    if (_user == null) return;
    if (!isPremium && _user!.predictionsLeft <= 0) return;
    
    try {
      if (!isPremium) {
        final data = await _supabase.from('profiles')
          .select('prediction_count')
          .eq('id', _user!.id)
          .single();
          
        int currentCount = data['prediction_count'] as int? ?? 0;
        
        await _supabase.from('profiles').update({
          'prediction_count': currentCount + 1
        }).eq('id', _user!.id);
      }

      _user = AppUser(
        id: _user!.id,
        email: _user!.email,
        isPremium: _user!.isPremium,
        predictionsLeft: isPremium ? 999 : _user!.predictionsLeft - 1,
      );
      notifyListeners();
    } catch (e) {
      debugPrint('Error using prediction in Supabase: \$e');
    }
  }

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  Future<void> _loadProfile() async {
    if (_user == null) return;
    
    try {
      _profile = UserProfile(userId: _user!.id, displayName: _user!.email.split('@').first);
      
      final data = await _supabase.from('profiles')
          .select('subscription_tier, prediction_count')
          .eq('id', _user!.id)
          .single();
          
      final isPrem = data['subscription_tier'] == 'premium';
      final int predictionCount = data['prediction_count'] as int? ?? 0;
      
      _user = AppUser(
        id: _user!.id,
        email: _user!.email,
        isPremium: isPrem,
        predictionsLeft: isPrem ? 999 : (5 - predictionCount > 0 ? 5 - predictionCount : 0),
      );
      
    } catch (e) {
      debugPrint('Error loading profile from Supabase: \$e');
    }
    
    notifyListeners();
  }

  AppUser _mapAuthUserToAppUser(User authUser, {String? username}) {
    return AppUser(
      id: authUser.id, 
      email: authUser.email ?? 'no-email', 
      isPremium: false, 
      predictionsLeft: 5
    );
  }
}
