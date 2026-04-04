import 'package:flutter/material.dart';
import '../models/notification_model.dart';
import 'api_service.dart';

class NotificationProvider extends ChangeNotifier {
  List<AppNotification> _notifications = [];
  bool _isLoading = false;
  int _unreadCount = 0;

  List<AppNotification> get notifications => _notifications;
  bool get isLoading => _isLoading;
  int get unreadCount => _unreadCount;

  final ApiService _apiService = ApiService();

  Future<void> fetchNotifications() async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await _apiService.get('/notifications');
      if (response is List) {
        _notifications = response.map((json) => AppNotification.fromJson(json)).toList();
        _unreadCount = _notifications.where((n) => !n.isRead).length;
      }
    } catch (e) {
      debugPrint('Error fetching notifications: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> markAsRead(String id) async {
    try {
      await _apiService.patch('/notifications/$id/read', {});
      final index = _notifications.indexWhere((n) => n.id == id);
      if (index != -1) {
        _notifications[index] = AppNotification(
          id: _notifications[index].id,
          recipient: _notifications[index].recipient,
          sender: _notifications[index].sender,
          title: _notifications[index].title,
          message: _notifications[index].message,
          type: _notifications[index].type,
          relatedId: _notifications[index].relatedId,
          isRead: true,
          createdAt: _notifications[index].createdAt,
        );
        _unreadCount = _notifications.where((n) => !n.isRead).length;
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error marking notification as read: $e');
    }
  }

  Future<void> markAllAsRead() async {
    try {
      await _apiService.patch('/notifications/read-all', {});
      for (int i = 0; i < _notifications.length; i++) {
        _notifications[i] = AppNotification(
          id: _notifications[i].id,
          recipient: _notifications[i].recipient,
          sender: _notifications[i].sender,
          title: _notifications[i].title,
          message: _notifications[i].message,
          type: _notifications[i].type,
          relatedId: _notifications[i].relatedId,
          isRead: true,
          createdAt: _notifications[i].createdAt,
        );
      }
      _unreadCount = 0;
      notifyListeners();
    } catch (e) {
      debugPrint('Error marking all notifications as read: $e');
    }
  }
}
