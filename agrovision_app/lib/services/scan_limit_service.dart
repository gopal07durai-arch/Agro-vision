import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'auth_service.dart';

/// Manages the 5 scans/month guest limit.
/// Registered users have no limit enforced here.
class ScanLimitService {
  static final ScanLimitService _instance = ScanLimitService._internal();
  factory ScanLimitService() => _instance;
  ScanLimitService._internal();

  static const int guestMonthlyLimit = 5;

  String get _currentMonthKey {
    final now = DateTime.now();
    return 'guest_scans_${now.year}_${now.month}';
  }

  /// Returns how many scans the guest has used this month.
  Future<int> getGuestScanCount() async {
    if (AuthService().isLoggedIn) return 0;
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getInt(_currentMonthKey) ?? 0;
    } catch (e) {
      debugPrint('[ScanLimit] Error getting count: $e');
      return 0;
    }
  }

  /// Returns true if the guest has reached the monthly limit.
  Future<bool> isGuestLimitReached() async {
    if (AuthService().isLoggedIn) return false;
    final count = await getGuestScanCount();
    return count >= guestMonthlyLimit;
  }

  /// Increments the guest scan count. Call AFTER a successful scan.
  Future<void> incrementGuestScan() async {
    if (AuthService().isLoggedIn) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      final current = prefs.getInt(_currentMonthKey) ?? 0;
      await prefs.setInt(_currentMonthKey, current + 1);
      debugPrint('[ScanLimit] Guest scan count now: ${current + 1}/$guestMonthlyLimit');
    } catch (e) {
      debugPrint('[ScanLimit] Error incrementing: $e');
    }
  }

  /// Returns remaining scans for guests (0 if logged in = unlimited).
  Future<int> remainingScans() async {
    if (AuthService().isLoggedIn) return 999;
    final count = await getGuestScanCount();
    final remaining = guestMonthlyLimit - count;
    return remaining < 0 ? 0 : remaining;
  }
}
