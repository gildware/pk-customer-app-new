import 'package:http/http.dart' as http;

class AdvertisementVideoHelper {
  AdvertisementVideoHelper._();

  static bool hasVideoUrl(String? url) {
    final path = url?.trim();
    if (path == null || path.isEmpty || path.toLowerCase() == 'null') {
      return false;
    }
    if (path.contains('placeholder')) {
      return false;
    }
    final uri = Uri.tryParse(path);
    if (uri == null || !uri.hasScheme) {
      return false;
    }
    return uri.scheme == 'http' || uri.scheme == 'https';
  }

  /// Returns true only when the remote file responds and looks like a video.
  static Future<bool> isUrlReachable(String url) async {
    if (!hasVideoUrl(url)) {
      return false;
    }

    final client = http.Client();
    try {
      final uri = Uri.parse(url.trim());
      var response = await client.head(uri).timeout(const Duration(seconds: 6));

      if (response.statusCode == 405 || response.statusCode == 501 || response.statusCode == 403) {
        response = await client
            .get(uri, headers: {'Range': 'bytes=0-1'})
            .timeout(const Duration(seconds: 6));
      }

      if (response.statusCode < 200 || response.statusCode >= 400) {
        return false;
      }

      final type = (response.headers['content-type'] ?? '').toLowerCase();
      if (type.isEmpty) {
        return true;
      }
      return type.startsWith('video/') ||
          type.contains('octet-stream') ||
          type.contains('application/mp4');
    } catch (_) {
      return false;
    } finally {
      client.close();
    }
  }
}
