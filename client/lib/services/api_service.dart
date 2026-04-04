import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import '../models/teacher.dart';

class ApiService {
  static String? _token;
  static const String _baseUrl = 'http://localhost:5000/api';

  static void setToken(String token) {
    _token = token;
  }

  static Future<Map<String, dynamic>?> login(
    String email,
    String password,
  ) async {
    final uri = Uri.parse('$_baseUrl/auth/login');
    final res = await http.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email, 'password': password}),
    );
    if (res.statusCode == 200) {
      final data = jsonDecode(res.body) as Map<String, dynamic>;
      _token = data['token'];
      return data;
    }
    return null;
  }

  static Future<Map<String, dynamic>?> getDashboardMetrics() async {
    final uri = Uri.parse('$_baseUrl/admin/dashboard/metrics');
    final res = await http.get(uri, headers: {'x-auth-token': _token ?? ''});
    if (res.statusCode == 200) {
      return jsonDecode(res.body) as Map<String, dynamic>;
    }
    return null;
  }

  static Future<List<Teacher>> getPendingTeachers() async {
    final uri = Uri.parse('$_baseUrl/admin/teachers');
    final res = await http.get(uri, headers: {'x-auth-token': _token ?? ''});
    if (res.statusCode == 200) {
      final List list = jsonDecode(res.body) as List;
      return list
          .map((e) => Teacher.fromJson(e))
          .where((t) => t.status == 'pending')
          .toList();
    }
    return [];
  }

  static Future<bool> approveTeacher(String id) async {
    final uri = Uri.parse('$_baseUrl/admin/teachers/$id/status');
    final res = await http.put(
      uri,
      headers: {
        'Content-Type': 'application/json',
        'x-auth-token': _token ?? '',
      },
      body: jsonEncode({'status': 'active'}),
    );
    return res.statusCode == 200;
  }
}
