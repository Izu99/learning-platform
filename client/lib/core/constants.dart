import 'dart:io';
import 'package:flutter/foundation.dart';

class AppConstants {
  /// The base URL for the API.
  /// 
  /// In development, you can override this by running:
  /// `flutter run --dart-define=API_URL=http://your-ip:5000/api`
  /// 
  /// By default, it uses localhost for iOS and 10.0.2.2 for Android 
  /// which both point to your laptop's localhost in emulators.
  static String get baseUrl {
    const String? serverIp = String.fromEnvironment('SERVER_IP');
    const String? definedUrl = String.fromEnvironment('API_URL');
    
    String url;
    if (serverIp != null && serverIp.isNotEmpty) {
      url = 'http://$serverIp:5000/api';
    } else if (definedUrl != null && definedUrl.isNotEmpty) {
      url = definedUrl;
    } else if (kDebugMode) {
      // 10.0.2.2 is for emulators. For physical phones, we want the computer IP.
      // Since we don't know it, we default to a common hotspot IP, but suggest using --dart-define.
      if (Platform.isAndroid) {
        // If it's a physical device, 10.0.2.2 won't work.
        // We'll return 10.0.2.2 as a fallback, but users should use SERVER_IP.
        url = 'http://10.0.2.2:5000/api';
      } else {
        url = 'http://localhost:5000/api';
      }
    } else {
      // Production fallback
      url = 'http://192.168.245.1:5000/api'; // Typical gateway IP for Windows Hotspot
    }

    if (kDebugMode) {
      print('🚀 [API] Using Base URL: $url');
    }
    
    // Ensure it always ends with /api
    if (!url.endsWith('/api')) {
      url = url.endsWith('/') ? '${url}api' : '$url/api';
    }
    
    return url;
  }

  /// Builds a full image URL from a relative path.
  static String buildImageUrl(String? path) {
    if (path == null || path.isEmpty) return '';
    if (path.startsWith('http')) return path;
    final serverBase = baseUrl.replaceAll('/api', '');
    return '$serverBase$path';
  }
}
