import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../shared/models/match_model.dart';

class MatchCacheService {
  static const String _cacheKeyPrefix = 'matches_';

  String _getKeyForDate(DateTime date) {
    return '$_cacheKeyPrefix${date.toIso8601String().substring(0, 10)}';
  }

  Future<List<MatchModel>> getCachedMatches(DateTime date) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = _getKeyForDate(date);
      final jsonString = prefs.getString(key);
      
      if (jsonString != null) {
        final List<dynamic> jsonList = json.decode(jsonString);
        return jsonList.map((m) => MatchModel.fromJson(m)).toList();
      }
    } catch (e) {
      debugPrint('Error reading match cache: \$e');
    }
    return [];
  }

  Future<void> cacheMatches(DateTime date, List<MatchModel> matches) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = _getKeyForDate(date);
      final jsonString = json.encode(matches.map((m) => m.toJson()).toList());
      
      await prefs.setString(key, jsonString);
      await prefs.setInt('\${key}_timestamp', DateTime.now().millisecondsSinceEpoch);
    } catch (e) {
      debugPrint('Error writing match cache: \$e');
    }
  }

  bool isCacheValid(DateTime date) {
    // For now, since we want to avoid API calls, we just check if it exists.
    // Real validation might check timestamp.
    return true; 
  }

  Future<void> cleanOldCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final keys = prefs.getKeys();
      final now = DateTime.now();
      // Keep yesterday, today, tomorrow
      final limitDate = now.subtract(const Duration(days: 2));
      final limitDateStr = limitDate.toIso8601String().substring(0, 10);

      for (final key in keys) {
        if (key.startsWith(_cacheKeyPrefix)) {
          final dateStr = key.replaceFirst(_cacheKeyPrefix, '').substring(0, 10);
          if (dateStr.compareTo(limitDateStr) <= 0) {
            await prefs.remove(key);
            await prefs.remove('\${key}_timestamp');
          }
        }
      }
    } catch (e) {
      debugPrint('Error cleaning old match cache: \$e');
    }
  }
}
