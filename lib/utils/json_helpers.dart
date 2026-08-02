class JsonHelpers {
  JsonHelpers._();

  static dynamic _valueForKey(Map<String, dynamic> json, String key) {
    if (json.containsKey(key)) return json[key];
    final lower = key.toLowerCase();
    for (final entry in json.entries) {
      if (entry.key.toLowerCase() == lower) return entry.value;
    }
    return null;
  }

  static String? pickString(Map<String, dynamic> json, List<String> keys) {
    for (final key in keys) {
      final value = _valueForKey(json, key);
      if (value != null && value.toString().isNotEmpty) {
        return value.toString();
      }
    }
    return null;
  }

  static bool? pickBool(Map<String, dynamic> json, List<String> keys) {
    for (final key in keys) {
      final value = _valueForKey(json, key);
      if (value is bool) return value;
      if (value != null) {
        final text = value.toString().toLowerCase();
        if (text == 'true' || text == '1' || text == 'online') return true;
        if (text == 'false' || text == '0' || text == 'offline') return false;
      }
    }
    return null;
  }

  static int? pickInt(Map<String, dynamic> json, List<String> keys) {
    for (final key in keys) {
      final value = _valueForKey(json, key);
      if (value is int) return value;
      if (value is num) return value.toInt();
      if (value != null) return int.tryParse(value.toString());
    }
    return null;
  }

  static double? pickDouble(Map<String, dynamic> json, List<String> keys) {
    for (final key in keys) {
      final value = _valueForKey(json, key);
      if (value is double) return value;
      if (value is num) return value.toDouble();
      if (value != null) return double.tryParse(value.toString());
    }
    return null;
  }

  static DateTime? pickDate(Map<String, dynamic> json, List<String> keys) {
    final raw = pickString(json, keys);
    if (raw == null) return null;
    return DateTime.tryParse(raw);
  }

  static List<T> pickList<T>(
    Map<String, dynamic> json,
    List<String> keys,
    T Function(Map<String, dynamic>) mapItem,
  ) {
    for (final key in keys) {
      final value = _valueForKey(json, key);
      if (value is List) {
        return parseObjectList(value, mapItem);
      }
    }
    return <T>[];
  }

  static List<T> parseObjectList<T>(
    dynamic raw,
    T Function(Map<String, dynamic>) mapItem,
  ) {
    if (raw is! List) return <T>[];
    final items = <T>[];
    for (final item in raw) {
      if (item is Map) {
        items.add(mapItem(Map<String, dynamic>.from(item)));
      }
    }
    return items;
  }
}
