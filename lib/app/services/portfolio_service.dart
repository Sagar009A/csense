/// Portfolio Service
/// Manages user's trades with P&L calculation via Firebase RTDB
library;

import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'auth_service.dart';

class TradeModel {
  final String id;
  final String symbol;
  final double buyPrice;
  final double quantity;
  final double currentPrice;
  final String type; // 'long' or 'short'
  final int date; // millisecondsSinceEpoch
  final String notes;

  TradeModel({
    required this.id,
    required this.symbol,
    required this.buyPrice,
    required this.quantity,
    required this.currentPrice,
    required this.type,
    required this.date,
    this.notes = '',
  });

  double get pnl {
    if (type == 'short') {
      return (buyPrice - currentPrice) * quantity;
    }
    return (currentPrice - buyPrice) * quantity;
  }

  double get pnlPercent {
    if (buyPrice == 0) return 0;
    if (type == 'short') {
      return ((buyPrice - currentPrice) / buyPrice) * 100;
    }
    return ((currentPrice - buyPrice) / buyPrice) * 100;
  }

  factory TradeModel.fromMap(String id, Map map) {
    return TradeModel(
      id: id,
      symbol: map['symbol']?.toString() ?? '',
      buyPrice: (map['buyPrice'] as num?)?.toDouble() ?? 0.0,
      quantity: (map['quantity'] as num?)?.toDouble() ?? 0.0,
      currentPrice: (map['currentPrice'] as num?)?.toDouble() ?? 0.0,
      type: map['type']?.toString() ?? 'long',
      date: (map['date'] as num?)?.toInt() ?? 0,
      notes: map['notes']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toMap() => {
        'symbol': symbol,
        'buyPrice': buyPrice,
        'quantity': quantity,
        'currentPrice': currentPrice,
        'type': type,
        'date': date,
        'notes': notes,
      };

  TradeModel copyWith({double? currentPrice, String? notes}) {
    return TradeModel(
      id: id,
      symbol: symbol,
      buyPrice: buyPrice,
      quantity: quantity,
      currentPrice: currentPrice ?? this.currentPrice,
      type: type,
      date: date,
      notes: notes ?? this.notes,
    );
  }
}

class PortfolioService extends GetxService {
  static PortfolioService get to => Get.find();

  final DatabaseReference _dbRef = FirebaseDatabase.instance.ref();
  final RxList<TradeModel> trades = <TradeModel>[].obs;
  final RxBool isLoading = false.obs;

  String? get _uid {
    try {
      return Get.isRegistered<AuthService>() ? AuthService.to.currentUser.value?.uid : null;
    } catch (e) {
      return null;
    }
  }

  double get totalPnl => trades.fold(0.0, (sum, t) => sum + t.pnl);
  double get totalInvested => trades.fold(0.0, (sum, t) => sum + (t.buyPrice * t.quantity));

  Future<void> loadTrades() async {
    final uid = _uid;
    if (uid == null) return;
    isLoading.value = true;
    try {
      final snap = await _dbRef.child('users').child(uid).child('portfolio').get();
      final data = snap.value;
      if (data is Map) {
        trades.value = data.entries
            .map((e) => TradeModel.fromMap(e.key.toString(), e.value as Map))
            .toList()
          ..sort((a, b) => b.date.compareTo(a.date));
      } else {
        trades.clear();
      }
    } catch (e) {
      debugPrint('PortfolioService: error loading: $e');
    } finally {
      isLoading.value = false;
    }
  }

  Future<bool> addTrade({
    required String symbol,
    required double buyPrice,
    required double quantity,
    required double currentPrice,
    required String type,
    String notes = '',
  }) async {
    final uid = _uid;
    if (uid == null) return false;
    try {
      final ref = _dbRef.child('users').child(uid).child('portfolio').push();
      final trade = TradeModel(
        id: ref.key!,
        symbol: symbol.toUpperCase(),
        buyPrice: buyPrice,
        quantity: quantity,
        currentPrice: currentPrice,
        type: type,
        date: DateTime.now().millisecondsSinceEpoch,
        notes: notes,
      );
      await ref.set(trade.toMap());
      trades.insert(0, trade);
      return true;
    } catch (e) {
      debugPrint('PortfolioService: error adding trade: $e');
      return false;
    }
  }

  Future<bool> updateCurrentPrice(String tradeId, double newPrice) async {
    final uid = _uid;
    if (uid == null) return false;
    try {
      await _dbRef
          .child('users')
          .child(uid)
          .child('portfolio')
          .child(tradeId)
          .update({'currentPrice': newPrice});
      final idx = trades.indexWhere((t) => t.id == tradeId);
      if (idx != -1) {
        trades[idx] = trades[idx].copyWith(currentPrice: newPrice);
      }
      return true;
    } catch (e) {
      debugPrint('PortfolioService: error updating price: $e');
      return false;
    }
  }

  Future<bool> deleteTrade(String tradeId) async {
    final uid = _uid;
    if (uid == null) return false;
    try {
      await _dbRef.child('users').child(uid).child('portfolio').child(tradeId).remove();
      trades.removeWhere((t) => t.id == tradeId);
      return true;
    } catch (e) {
      debugPrint('PortfolioService: error deleting trade: $e');
      return false;
    }
  }
}
