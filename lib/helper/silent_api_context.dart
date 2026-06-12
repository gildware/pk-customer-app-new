/// Suppresses non-auth API error toasts while a background refresh is running.
class SilentApiContext {
  static int _depth = 0;

  static bool get isActive => _depth > 0;

  static Future<T> run<T>(Future<T> Function() action) async {
    _depth++;
    try {
      return await action();
    } finally {
      _depth--;
    }
  }
}
