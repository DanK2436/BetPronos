import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import '../models/coupon_model.dart';

class CouponProvider extends ChangeNotifier {
  static const String _couponsKey = 'saved_coupons';
  
  List<Coupon> _coupons = [];
  Coupon? _activeCoupon;

  List<Coupon> get coupons => _coupons;
  Coupon? get activeCoupon => _activeCoupon;

  CouponProvider() {
    _loadCoupons();
  }

  Future<void> _loadCoupons() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? jsonStr = prefs.getString(_couponsKey);
      if (jsonStr != null) {
        final List<dynamic> list = json.decode(jsonStr);
        _coupons = list.map((item) => Coupon.fromJson(item)).toList();
      }
    } catch (e) {
      debugPrint('Error loading coupons: \$e');
    }
    notifyListeners();
  }

  Future<void> _saveCoupons() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String jsonStr = json.encode(_coupons.map((c) => c.toJson()).toList());
      await prefs.setString(_couponsKey, jsonStr);
    } catch (e) {
      debugPrint('Error saving coupons: \$e');
    }
  }

  void addSelection(CouponSelection selection) {
    if (_activeCoupon == null) {
      _activeCoupon = Coupon(
        id: const Uuid().v4(),
        selections: [selection],
        createdAt: DateTime.now(),
      );
    } else {
      if (_activeCoupon!.selections.length >= 10) {
        // Limit reached
        return;
      }
      
      // Check if match already exists
      final existingIndex = _activeCoupon!.selections.indexWhere((s) => s.matchId == selection.matchId);
      if (existingIndex >= 0) {
        // Replace existing selection for this match
        _activeCoupon!.selections[existingIndex] = selection;
      } else {
        _activeCoupon!.selections.add(selection);
      }
    }
    notifyListeners();
  }

  void removeSelection(String matchId) {
    if (_activeCoupon != null) {
      _activeCoupon!.selections.removeWhere((s) => s.matchId == matchId);
      if (_activeCoupon!.selections.isEmpty) {
        _activeCoupon = null;
      }
      notifyListeners();
    }
  }

  void resetCoupon() {
    _activeCoupon = null;
    notifyListeners();
  }

  Future<void> validateCoupon() async {
    if (_activeCoupon != null && _activeCoupon!.selections.isNotEmpty) {
      _activeCoupon!.isValidated = true;
      _coupons.insert(0, _activeCoupon!);
      _activeCoupon = null;
      await _saveCoupons();
      notifyListeners();
    }
  }

  Future<void> updateMatchResult(String matchId, int homeScore, int awayScore) async {
    bool updated = false;
    for (var coupon in _coupons) {
      for (var selection in coupon.selections) {
        if (selection.matchId == matchId && selection.status == CouponSelectionStatus.pending) {
          selection.status = _evaluateSelection(selection, homeScore, awayScore);
          updated = true;
        }
      }
    }
    
    if (updated) {
      await _saveCoupons();
      notifyListeners();
    }
  }

  CouponSelectionStatus _evaluateSelection(CouponSelection selection, int homeScore, int awayScore) {
    switch (selection.betType) {
      case BetType.score:
        final expected = selection.selectedValue.split('-');
        if (expected.length == 2 && int.tryParse(expected[0].trim()) == homeScore && int.tryParse(expected[1].trim()) == awayScore) {
          return CouponSelectionStatus.won;
        }
        return CouponSelectionStatus.lost;
      case BetType.homeWin:
        return homeScore > awayScore ? CouponSelectionStatus.won : CouponSelectionStatus.lost;
      case BetType.draw:
        return homeScore == awayScore ? CouponSelectionStatus.won : CouponSelectionStatus.lost;
      case BetType.awayWin:
        return homeScore < awayScore ? CouponSelectionStatus.won : CouponSelectionStatus.lost;
      case BetType.btts:
        final btts = homeScore > 0 && awayScore > 0;
        final expected = selection.selectedValue.toLowerCase() == 'oui' || selection.selectedValue.toLowerCase() == 'yes';
        return btts == expected ? CouponSelectionStatus.won : CouponSelectionStatus.lost;
      case BetType.over15:
        return (homeScore + awayScore) > 1.5 ? CouponSelectionStatus.won : CouponSelectionStatus.lost;
      case BetType.over25:
        return (homeScore + awayScore) > 2.5 ? CouponSelectionStatus.won : CouponSelectionStatus.lost;
      case BetType.oddEven:
        final isEven = (homeScore + awayScore) % 2 == 0;
        final expectedEven = selection.selectedValue.toLowerCase() == 'pair' || selection.selectedValue.toLowerCase() == 'even';
        return isEven == expectedEven ? CouponSelectionStatus.won : CouponSelectionStatus.lost;
    }
  }
}
