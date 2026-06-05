/// Parses standard Laravel paginated API bodies from [response_formatter].
class MobileAppHomeApiHelper {
  static List<Map<String, dynamic>> extractContentDataMaps(dynamic body) {
    if (body is! Map) {
      return const [];
    }
    final map = Map<String, dynamic>.from(body);
    final content = map['content'];
    if (content is Map) {
      final data = content['data'];
      if (data is List) {
        return data
            .whereType<Map>()
            .map((e) => Map<String, dynamic>.from(e))
            .toList();
      }
    }
    // Legacy / mistaken shape (do not rely on this).
    final top = map['data'];
    if (top is List) {
      return top
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .toList();
    }
    return const [];
  }
}
