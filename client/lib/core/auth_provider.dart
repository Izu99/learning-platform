import 'package:flutter/material.dart';
import '../models/user_model.dart';
import 'api_service.dart';

class AuthProvider with ChangeNotifier {
  User? _currentUser;
  String? _token;

  User? get currentUser => _currentUser;
  String? get token => _token;
  bool get isAuthenticated => _token != null;
  bool get isAdmin => _currentUser?.role == 'admin';

  void login(User user, String token) {
    _currentUser = user;
    _token = token;
    ApiService().setToken(token);
    notifyListeners();
  }

  void logout() {
    _currentUser = null;
    _token = null;
    ApiService().setToken(null);
    notifyListeners();
  }

  void updateUserPreferences({List<String>? interests, String? level}) {
    if (_currentUser != null) {
      _currentUser = User(
        id: _currentUser!.id,
        name: _currentUser!.name,
        email: _currentUser!.email,
        role: _currentUser!.role,
        interests: interests ?? _currentUser!.interests,
        level: level ?? _currentUser!.level,
      );
      notifyListeners();
    }
  }
}
