/// Analytics Service
/// Logs each AI analysis to Firebase Realtime Database for admin reporting.
///
/// Firebase node structure:
///   /analysis_stats/{YYYY-MM-DD} : number   ← daily count
///
/// Old data (> 90 days) is auto-deleted on every write to keep storage lean.
library;

import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';

class AnalyticsService extends GetxService {
  static AnalyticsService get to => Get.find();

  static const _node = 'analysis_stats';

  /// Increment today's analysis count by 1 and purge entries older than 90 days.
  Future<void> logAnalysis() async {
    try {
      final todayKey = _todayKey();
      final ref = FirebaseDatabase.instance.ref('$_node/$todayKey');

      // Atomic increment using transaction
      await ref.runTransaction((currentValue) {
        final current = (currentValue as int?) ?? 0;
        return Transaction.success(current + 1);
      });

      debugPrint('AnalyticsService: logged analysis for $todayKey');

      // Cleanup old data asynchronously (don't block the caller)
      _purgeOldEntries();
    } catch (e) {
      // Never crash the app due to analytics failure
      debugPrint('AnalyticsService: logAnalysis error – $e');
    }
  }

  /// Delete entries older than 90 days to stay within 3-month window.
  Future<void> _purgeOldEntries() async {
    try {
      final cutoff = DateTime.now().subtract(const Duration(days: 90));
      final cutoffKey = _dateKey(cutoff);

      final snapshot =
          await FirebaseDatabase.instance.ref(_node).get();
      if (!snapshot.exists || snapshot.value == null) return;

      final map = Map<String, dynamic>.from(snapshot.value as Map);

      // Collect keys that are strictly before the cutoff date string
      final toDelete = map.keys
          .where((k) => k.compareTo(cutoffKey) < 0)
          .toList();

      if (toDelete.isEmpty) return;

      // Batch delete using a single PATCH (null = delete in Firebase)
      final updates = <String, dynamic>{};
      for (final k in toDelete) {
        updates['$_node/$k'] = null;
      }
      await FirebaseDatabase.instance.ref().update(updates);

      debugPrint(
          'AnalyticsService: purged ${toDelete.length} old entries (before $cutoffKey)');
    } catch (e) {
      debugPrint('AnalyticsService: purge error – $e');
    }
  }

  // ── Helpers ──────────────────────────────────────────────────────────────
  String _todayKey() => _dateKey(DateTime.now().toUtc());

  String _dateKey(DateTime dt) {
    final y = dt.year.toString().padLeft(4, '0');
    final m = dt.month.toString().padLeft(2, '0');
    final d = dt.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }
}
