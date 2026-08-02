import 'package:shared_preferences/shared_preferences.dart';

/// Cross-isolate store so a background FCM handler / native wake can hand an
/// offer to the main isolate when the app is brought to the foreground.
class PendingJobOfferStore {
  PendingJobOfferStore._();

  static const _keyJobId = 'onee_pending_job_offer_id';
  static const _keyAt = 'onee_pending_job_offer_at';
  static const _ttl = Duration(minutes: 3);

  static Future<void> save(int jobId) async {
    if (jobId <= 0) return;
    final prefs = await SharedPreferences.getInstance();
    // Strings avoid 32-bit int overflow on Android timestamps.
    await prefs.setString(_keyJobId, '$jobId');
    await prefs.setString(
      _keyAt,
      '${DateTime.now().millisecondsSinceEpoch}',
    );
  }

  static Future<int?> read({bool clear = false}) async {
    final prefs = await SharedPreferences.getInstance();
    final jobRaw = prefs.getString(_keyJobId) ?? prefs.getInt(_keyJobId)?.toString();
    final atRaw = prefs.getString(_keyAt) ?? prefs.getInt(_keyAt)?.toString();
    final jobId = int.tryParse(jobRaw ?? '');
    final atMs = int.tryParse(atRaw ?? '');
    if (jobId == null || jobId <= 0 || atMs == null) {
      if (clear) await clearPending();
      return null;
    }

    final age = DateTime.now().difference(
      DateTime.fromMillisecondsSinceEpoch(atMs),
    );
    if (age > _ttl) {
      await clearPending();
      return null;
    }

    if (clear) await clearPending();
    return jobId;
  }

  static Future<void> clearPending() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyJobId);
    await prefs.remove(_keyAt);
  }

  static Future<void> clearIfJob(int jobId) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_keyJobId) ?? prefs.getInt(_keyJobId)?.toString();
    if (int.tryParse(raw ?? '') == jobId) {
      await clearPending();
    }
  }
}
