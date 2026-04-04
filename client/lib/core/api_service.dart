import 'dart:convert';
import 'package:http/http.dart' as http;
import 'constants.dart';

class ApiService {
  static ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal();

  static set instance(ApiService instance) => _instance = instance;

  String? _token;
  
  void setToken(String? token) {
    _token = token;
  }

  // Common headers
  Map<String, String> _headers() {
    final Map<String, String> headers = {
      'Content-Type': 'application/json',
    };
    if (_token != null) {
      // Adding both common auth headers just in case
      headers['x-auth-token'] = _token!;
      headers['Authorization'] = 'Bearer $_token';
    }
    return headers;
  }

  String get _baseUrl => AppConstants.baseUrl;

  Future<dynamic> post(String endpoint, Map<String, dynamic> data) async {
    final response = await http.post(
      Uri.parse('$_baseUrl$endpoint'),
      headers: _headers(),
      body: jsonEncode(data),
    );
    
    final decoded = jsonDecode(response.body);
    if (response.statusCode >= 400) {
      throw decoded['message'] ?? 'Error ${response.statusCode}: ${response.reasonPhrase}';
    }
    return decoded;
  }

  Future<dynamic> get(String endpoint) async {
    final response = await http.get(
      Uri.parse('$_baseUrl$endpoint'),
      headers: _headers(),
    );
    
    final decoded = jsonDecode(response.body);
    if (response.statusCode >= 400) {
      throw decoded['message'] ?? 'Error ${response.statusCode}: ${response.reasonPhrase}';
    }
    return decoded;
  }

  Future<Map<String, dynamic>> put(String endpoint, Map<String, dynamic> body) async {
    final response = await http.put(
      Uri.parse('$_baseUrl$endpoint'),
      headers: _headers(),
      body: jsonEncode(body),
    );
    
    final decoded = jsonDecode(response.body);
    if (response.statusCode >= 400) {
      throw decoded['message'] ?? 'Update failed';
    }
    return decoded;
  }

  Future<Map<String, dynamic>> patch(String endpoint, Map<String, dynamic> body) async {
    final response = await http.patch(
      Uri.parse('$_baseUrl$endpoint'),
      headers: _headers(),
      body: jsonEncode(body),
    );
    
    final decoded = jsonDecode(response.body);
    if (response.statusCode >= 400) {
      throw Exception(decoded['message'] ?? 'Patch failed');
    }
    return decoded;
  }

  Future<Map<String, dynamic>> delete(String endpoint) async {
    final response = await http.delete(
      Uri.parse('$_baseUrl$endpoint'),
      headers: _headers(),
    );
    
    final decoded = jsonDecode(response.body);
    if (response.statusCode >= 400) {
      throw decoded['message'] ?? 'Delete failed';
    }
    return decoded;
  }

  /// Handles profile image uploads via multipart request
  Future<Map<String, dynamic>> uploadImage(String endpoint, String filePath) async {
    final uri = Uri.parse('$_baseUrl$endpoint');
    final request = http.MultipartRequest('POST', uri);
    
    // Add auth headers manually for multipart
    if (_token != null) {
      request.headers['x-auth-token'] = _token!;
      request.headers['Authorization'] = 'Bearer $_token';
    }

    request.files.add(await http.MultipartFile.fromPath('image', filePath));

    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);
    final decoded = jsonDecode(response.body);

    if (response.statusCode >= 400) {
      throw Exception(decoded['message'] ?? 'Upload failed');
    }
    return decoded;
  }

  // Instance methods for testability/DI
  Future<dynamic> fetchDashboardMetrics() => get('/admin/dashboard/metrics');
  Future<dynamic> getData(String endpoint) => get(endpoint);
  Future<dynamic> postData(String endpoint, Map<String, dynamic> data) => post(endpoint, data);

  Future<List<dynamic>> fetchTeacherSlots(String teacherId, String date) async {
    final response = await get('/teachers/slots/$teacherId?date=$date');
    if (response is List) return response;
    return [];
  }
}
