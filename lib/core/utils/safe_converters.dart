int safeInt(dynamic val, {required int fallback, int? min, int? max}) {
  int result = fallback;
  if (val != null) {
    if (val is int) {
      result = val;
    } else if (val is double) {
      result = val.toInt();
    } else if (val is String) {
      result = int.tryParse(val) ?? fallback;
    }
  }
  
  if (min != null && result < min) result = min;
  if (max != null && result > max) result = max;
  
  // validate minAge <= maxAge happens outside this or implicitly by setting min/max properly.
  return result;
}

bool safeBool(dynamic val, {bool fallback = false}) {
  if (val == true || val == 1 || val == 'true') return true;
  if (val == false || val == 0 || val == 'false') return false;
  return fallback;
}

List<String> safeStringList(dynamic val) {
  if (val is List) {
    return val
        .where((e) => e != null)
        .map((e) => e.toString().trim())
        .where((s) => s.isNotEmpty)
        .toList();
  }
  return [];
}
