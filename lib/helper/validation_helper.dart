class ValidationHelper {
  static final RegExp _uuidPattern = RegExp(
    r'^[0-9a-f]{8}-[0-9a-f]{4}-[1-5][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$',
    caseSensitive: false,
  );

  static bool isValidUuid(String? value) {
    if (value == null) return false;
    final trimmed = value.trim();
    if (trimmed.isEmpty || trimmed == 'null') return false;
    return _uuidPattern.hasMatch(trimmed);
  }

  /// User addresses use numeric ids; some APIs also accept UUIDs.
  static bool isValidAddressId(String? value) {
    if (value == null) return false;
    final trimmed = value.trim();
    if (trimmed.isEmpty || trimmed == 'null') return false;
    if (isValidUuid(trimmed)) return true;
    final id = int.tryParse(trimmed);
    return id != null && id > 0;
  }
}
