
class AppConstants { 
  /// VPS production API — nginx at 82.25.180.20 proxies /learning/ → backend:5005
  static const String _vpsBaseUrl = 'http://82.25.180.20/learning/api';

  /// The base URL for the API.
  ///
  /// Release build  → VPS:   http://82.25.180.20/learning/api
  /// Debug build    → local: http://localhost:5000/api
  ///
  /// Override at build time:
  ///   --dart-define=API_URL=http://192.168.x.x:5000/api
  ///   --dart-define=SERVER_IP=192.168.x.x
  static String get baseUrl {
    const String serverIp = String.fromEnvironment('SERVER_IP');
    const String definedUrl = String.fromEnvironment('API_URL');

    // Override at build time:
    //   --dart-define=API_URL=http://192.168.x.x:5000/api
    //   --dart-define=SERVER_IP=192.168.x.x  (local dev, uses localhost:5000)
    if (serverIp.isNotEmpty) return 'http://$serverIp:5000/api';
    if (definedUrl.isNotEmpty) return definedUrl;

    return _vpsBaseUrl;
  }

  /// Builds a full image URL from a relative path (e.g. /uploads/photo.jpg).
  static String buildImageUrl(String? path) {
    if (path == null || path.isEmpty) return '';
    if (path.startsWith('http')) return path;
    final serverBase = baseUrl.replaceAll('/api', '');
    return '$serverBase$path';
  }
}
