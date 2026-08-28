import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Resolves profile image filenames against OneeProjectAPI wwwroot.
class MediaUrl {
  MediaUrl._();

  static String? resolve(String? value, {String folder = 'Worker'}) {
    if (value == null) return null;
    final trimmed = value.trim();
    if (trimmed.isEmpty) return null;

    final lower = trimmed.toLowerCase();
    if (lower == 'default.png' || lower.endsWith('/default.png')) {
      return null;
    }

    if (trimmed.startsWith('http://') || trimmed.startsWith('https://')) {
      return trimmed;
    }

    final base = dotenv.env['UPLOAD_BASE_URL']?.trim();
    if (base == null || base.isEmpty) return trimmed;

    final normalized = base.endsWith('/')
        ? base.substring(0, base.length - 1)
        : base;
    return '$normalized/$folder/$trimmed';
  }
}
