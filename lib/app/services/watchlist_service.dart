/// Watchlist Service
/// Manages user's saved stocks/forex pairs in Firebase RTDB
library;

import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'auth_service.dart';

class WatchlistItem {
  final String id;
  final String symbol;
  final String name;
  final String notes;
  final int addedAt;

  WatchlistItem({
    required this.id,
    required this.symbol,
    required this.name,
    this.notes = '',
    required this.addedAt,
  });

  factory WatchlistItem.fromMap(String id, Map map) {
    return WatchlistItem(
      id: id,
      symbol: map['symbol']?.toString() ?? '',
      name: map['name']?.toString() ?? '',
      notes: map['notes']?.toString() ?? '',
      addedAt: (map['addedAt'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toMap() => {
        'symbol': symbol,
        'name': name,
        'notes': notes,
        'addedAt': addedAt,
      };
}

class WatchlistService extends GetxService {
  static WatchlistService get to => Get.find();

  final DatabaseReference _dbRef = FirebaseDatabase.instance.ref();
  final RxList<WatchlistItem> items = <WatchlistItem>[].obs;
  final RxBool isLoading = false.obs;

  String? get _uid {
    try {
      return Get.isRegistered<AuthService>() ? AuthService.to.currentUser.value?.uid : null;
    } catch (e) {
      return null;
    }
  }

  Future<void> loadWatchlist() async {
    final uid = _uid;
    if (uid == null) return;
    isLoading.value = true;
    try {
      final snap = await _dbRef.child('users').child(uid).child('watchlist').get();
      final data = snap.value;
      if (data is Map) {
        items.value = data.entries
            .map((e) => WatchlistItem.fromMap(e.key.toString(), e.value as Map))
            .toList()
          ..sort((a, b) => b.addedAt.compareTo(a.addedAt));
      } else {
        items.clear();
      }
    } catch (e) {
      debugPrint('WatchlistService: error loading: $e');
    } finally {
      isLoading.value = false;
    }
  }

  Future<bool> addItem({required String symbol, required String name, String notes = ''}) async {
    final uid = _uid;
    if (uid == null) return false;
    try {
      final ref = _dbRef.child('users').child(uid).child('watchlist').push();
      final item = WatchlistItem(
        id: ref.key!,
        symbol: symbol.toUpperCase(),
        name: name,
        notes: notes,
        addedAt: DateTime.now().millisecondsSinceEpoch,
      );
      await ref.set(item.toMap());
      items.insert(0, item);
      return true;
    } catch (e) {
      debugPrint('WatchlistService: error adding: $e');
      return false;
    }
  }

  Future<bool> removeItem(String itemId) async {
    final uid = _uid;
    if (uid == null) return false;
    try {
      await _dbRef.child('users').child(uid).child('watchlist').child(itemId).remove();
      items.removeWhere((i) => i.id == itemId);
      return true;
    } catch (e) {
      debugPrint('WatchlistService: error removing: $e');
      return false;
    }
  }

  bool isInWatchlist(String symbol) {
    return items.any((i) => i.symbol == symbol.toUpperCase());
  }
}
