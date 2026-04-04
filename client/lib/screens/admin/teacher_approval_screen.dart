import 'package:flutter/material.dart';
import '../../core/api_service.dart';
import '../../core/app_theme.dart';
import '../../models/teacher_model.dart';
import '../../widgets/edu_widgets.dart';

class TeacherApprovalScreen extends StatefulWidget {
  const TeacherApprovalScreen({super.key});

  @override
  State<TeacherApprovalScreen> createState() => _TeacherApprovalScreenState();
}

class _TeacherApprovalScreenState extends State<TeacherApprovalScreen> {
  List<Teacher> _pendingTeachers = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchPendingTeachers();
  }

  Future<void> _fetchPendingTeachers() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final response = await ApiService().get('/admin/teachers');
      
      // Defensively handle response types
      List<dynamic> rawList = [];
      if (response is List) {
        rawList = response;
      } else if (response is Map && response.containsKey('teachers')) {
        rawList = response['teachers'] as List;
      } else if (response is Map && response.containsKey('message')) {
        throw response['message'];
      } else {
        throw 'Unexpected response format: $response';
      }

      _pendingTeachers = rawList
          .map((json) => Teacher.fromJson(json))
          .where((teacher) => teacher.status == 'pending')
          .toList();
    } catch (e) {
      _error = 'Failed to load pending teachers: $e';
      debugPrint('❌ [TeacherApproval] Error: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _updateTeacherStatus(String teacherId, String status) async {
    try {
      await ApiService().put('/admin/teachers/$teacherId/status', {'status': status});
      _fetchPendingTeachers();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Teacher $status successfully!'), backgroundColor: status == 'approved' ? Colors.green : Colors.orange),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to $status teacher: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  void _showTeacherDetails(Teacher teacher) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(teacher.fullName, style: const TextStyle(fontWeight: FontWeight.bold)),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _infoRow('Title', teacher.title),
              _infoRow('Email', teacher.email ?? 'N/A'),
              _infoRow('Experience', '${teacher.experienceYears} Years'),
              _infoRow('Price', 'Rs. ${teacher.price ?? 0}'),
              const SizedBox(height: 16),
              const Text('Bio:', style: TextStyle(fontWeight: FontWeight.bold)),
              Text(teacher.about, style: const TextStyle(color: Colors.grey)),
              const SizedBox(height: 16),
              const Text('Qualifications:', style: TextStyle(fontWeight: FontWeight.bold)),
              if (teacher.qualifications != null && teacher.qualifications!.isNotEmpty)
                ...teacher.qualifications!.map((q) => Text('• ${q.title} at ${q.institution}'))
              else
                const Text('No qualifications listed.'),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close')),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _updateTeacherStatus(teacher.id, 'approved');
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryTeal, foregroundColor: Colors.white),
            child: const Text('Approve Now'),
          ),
        ],
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Text('$label: ', style: const TextStyle(fontWeight: FontWeight.bold)),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('Teacher Applications', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text(_error!, style: const TextStyle(color: Colors.red)))
              : _pendingTeachers.isEmpty
                  ? const Center(child: Text('No pending teachers.', style: TextStyle(color: Colors.grey, fontSize: 16)))
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _pendingTeachers.length,
                      itemBuilder: (context, index) {
                        final teacher = _pendingTeachers[index];
                        return ModernCard(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            children: [
                              CircleAvatar(
                                backgroundColor: AppTheme.primaryTeal.withOpacity(0.1),
                                child: Text(teacher.fullName[0], style: const TextStyle(color: AppTheme.primaryTeal, fontWeight: FontWeight.bold)),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(teacher.fullName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                    Text(teacher.title, style: const TextStyle(color: Colors.grey, fontSize: 13)),
                                  ],
                                ),
                              ),
                              TextButton(
                                onPressed: () => _showTeacherDetails(teacher),
                                child: const Text('Review', style: TextStyle(fontWeight: FontWeight.bold)),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
    );
  }
}
