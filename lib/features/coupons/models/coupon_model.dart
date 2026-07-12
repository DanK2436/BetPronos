import 'dart:convert';

enum CouponSelectionStatus { pending, won, lost }
enum BetType { score, homeWin, draw, awayWin, btts, over15, over25, oddEven }

class CouponSelection {
  final String matchId;
  final String homeTeamName;
  final String awayTeamName;
  final String leagueName;
  final BetType betType;
  final String selectedValue; 
  final double odds;
  CouponSelectionStatus status;
  DateTime? matchDateTime;

  CouponSelection({
    required this.matchId,
    required this.homeTeamName,
    required this.awayTeamName,
    required this.leagueName,
    required this.betType,
    required this.selectedValue,
    required this.odds,
    this.status = CouponSelectionStatus.pending,
    this.matchDateTime,
  });

  Map<String, dynamic> toJson() {
    return {
      'matchId': matchId,
      'homeTeamName': homeTeamName,
      'awayTeamName': awayTeamName,
      'leagueName': leagueName,
      'betType': betType.name,
      'selectedValue': selectedValue,
      'odds': odds,
      'status': status.name,
      'matchDateTime': matchDateTime?.toIso8601String(),
    };
  }

  factory CouponSelection.fromJson(Map<String, dynamic> json) {
    return CouponSelection(
      matchId: json['matchId'],
      homeTeamName: json['homeTeamName'],
      awayTeamName: json['awayTeamName'],
      leagueName: json['leagueName'],
      betType: BetType.values.firstWhere((e) => e.name == json['betType'], orElse: () => BetType.score),
      selectedValue: json['selectedValue'],
      odds: json['odds']?.toDouble() ?? 1.0,
      status: CouponSelectionStatus.values.firstWhere((e) => e.name == json['status'], orElse: () => CouponSelectionStatus.pending),
      matchDateTime: json['matchDateTime'] != null ? DateTime.tryParse(json['matchDateTime']) : null,
    );
  }
}

class Coupon {
  final String id;
  final List<CouponSelection> selections;
  final DateTime createdAt;
  bool isValidated;

  Coupon({
    required this.id,
    required this.selections,
    required this.createdAt,
    this.isValidated = false,
  });

  double get totalOdds => selections.fold(1.0, (acc, s) => acc * s.odds);
  int get selectionCount => selections.length;
  
  CouponSelectionStatus get overallStatus {
    if (selections.isEmpty) return CouponSelectionStatus.pending;
    if (selections.any((s) => s.status == CouponSelectionStatus.lost)) return CouponSelectionStatus.lost;
    if (selections.every((s) => s.status == CouponSelectionStatus.won)) return CouponSelectionStatus.won;
    return CouponSelectionStatus.pending;
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'selections': selections.map((s) => s.toJson()).toList(),
      'createdAt': createdAt.toIso8601String(),
      'isValidated': isValidated,
    };
  }

  factory Coupon.fromJson(Map<String, dynamic> json) {
    return Coupon(
      id: json['id'],
      selections: (json['selections'] as List).map((s) => CouponSelection.fromJson(s)).toList(),
      createdAt: DateTime.tryParse(json['createdAt']) ?? DateTime.now(),
      isValidated: json['isValidated'] ?? false,
    );
  }
}
