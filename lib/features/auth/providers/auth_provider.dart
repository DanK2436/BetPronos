import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/auth_service.dart';

class AuthProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();
  
  User? _user;
  Map<String, dynamic>? _profile;
  bool _isLoading = false;

  User? get user => _user;
  Map<String, dynamic>? get profile => _profile;
  bool get isLoading => _isLoading;
  bool get isAuthenticated => _user != null;
  bool get isPremium => _profile != null && _profile!['subscription_tier'] == 'premium';

  // Free Trial logic
  bool get isTrialActive {
    if (_profile == null) return false;
    final createdAtStr = _profile!['created_at'];
    if (createdAtStr == null) return false;
    
    final createdAt = DateTime.tryParse(createdAtStr) ?? DateTime.now();
    final difference = DateTime.now().difference(createdAt);
    return difference.inHours < 24; // 1-day free trial limit
  }

  int get predictionsLeft {
    if (_profile == null) return 0;
    if (isPremium) return 99999;
    final count = ((_profile!['prediction_count']) as int?) ?? 0;
    final left = 5 - count;
    return left < 0 ? 0 : left;
  }

  bool get canAccessPredictions {
    return isPremium || (isTrialActive && predictionsLeft > 0);
  }

  AuthProvider() {
    _user = _authService.currentUser;
    if (_user != null) {
      _loadProfile(_user!.id);
    }
    _authService.authStateChanges.listen((data) {
      _user = data.session?.user;
      if (_user != null) {
        _loadProfile(_user!.id);
      } else {
        _profile = null;
      }
      notifyListeners();
    });
  }

  Future<void> _loadProfile(String userId) async {
    _profile = await _authService.getUserProfile(userId);
    notifyListeners();
  }

  Future<bool> login(String email, String password) async {
    _isLoading = true;
    notifyListeners();
    try {
      await _authService.signIn(email: email, password: password);
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  Future<bool> register(String email, String password, String username) async {
    _isLoading = true;
    notifyListeners();
    try {
      await _authService.signUp(email: email, password: password, username: username);
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  Future<void> usePrediction() async {
    if (_user != null && !isPremium) {
      await _authService.incrementPredictionCount(_user!.id);
      await _loadProfile(_user!.id);
    }
  }

  Future<void> logout() async {
    await _authService.signOut();
    _user = null;
    _profile = null;
    notifyListeners();
  }

  Future<void> makePremium() async {
    if (_user != null) {
      await _authService.updateUserSubscription(_user!.id, 'premium');
      await _loadProfile(_user!.id);
    }
  }
}
