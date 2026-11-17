import 'package:shared_preferences/shared_preferences.dart';

/// App state that lives on-device only: Pro, settings, daily free
/// delete counter. No account, no server, no analytics.
///
/// Pro model (V1, undecided price -- see docs/v1-plan.md):
/// one-time purchase, no subscription, no trial, no auto-renew.
/// The store purchase itself is wired up in M2; until then a
/// clearly-labelled test preview toggle in Settings lets testers try
/// Pro features. That toggle must be removed before release.
class AppState {
  AppState(this._prefs);

  final SharedPreferences _prefs;

  static Future<AppState> load() async {
    final prefs = await SharedPreferences.getInstance();
    return AppState(prefs);
  }

  // -- Pro ------------------------------------------------------------

  /// Final price is undecided (candidates $19.99 / $29.99-$39.99).
  /// PLACEHOLDER -- set the real store price before release, and do
  /// not ship this constant as the final price without a decision.
  static const double proPriceUsdPlaceholder = 19.99;

  bool get isProEffective => _prefs.getBool('pro_unlocked') == true ||
      _prefs.getBool('pro_preview') == true;

  bool get proPreview => _prefs.getBool('pro_preview') == true;

  Future<void> setProPreview(bool value) =>
      _prefs.setBool('pro_preview', value);

  // -- Similarity -----------------------------------------------------

  /// dHash Hamming threshold. 4 = strict, 16 = loose. Default 10.
  /// Conservative by design: a false positive costs a photo.
  int get similarityThreshold => _prefs.getInt('similarity') ?? 10;

  Future<void> setSimilarityThreshold(int value) =>
      _prefs.setInt('similarity', value.clamp(4, 16));

  // -- Free tier ------------------------------------------------------

  /// Free tier: full scan, exact duplicates, up to 100 deletes a day.
  /// Pro: unlimited. The cap is per calendar day, on-device only.
  static const int freeDailyDeleteLimit = 100;

  int get deletesToday {
    final today = _todayKey();
    if (_prefs.getString('delete_day') != today) return 0;
    return _prefs.getInt('delete_count') ?? 0;
  }

  int get deletesRemainingToday {
    if (isProEffective) return 1 << 30;
    final remaining = freeDailyDeleteLimit - deletesToday;
    return remaining < 0 ? 0 : remaining;
  }

  Future<void> recordDeletes(int count) async {
    final today = _todayKey();
    final priorDay = _prefs.getString('delete_day');
    final prior = priorDay == today ? (_prefs.getInt('delete_count') ?? 0) : 0;
    await _prefs.setString('delete_day', today);
    await _prefs.setInt('delete_count', prior + count);
  }

  String _todayKey() {
    final now = DateTime.now();
    return '${now.year}-${now.month}-${now.day}';
  }

  // -- Scan history ---------------------------------------------------

  int get lastScanCount => _prefs.getInt('last_scan_count') ?? 0;
  int get lastScanFreedBytes => _prefs.getInt('last_scan_freed') ?? 0;

  Future<void> recordScan(int count, int freedBytes) async {
    await _prefs.setInt('last_scan_count', count);
    await _prefs.setInt('last_scan_freed', freedBytes);
  }
}
