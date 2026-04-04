import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:learning_platform/core/app_theme.dart';
import 'package:learning_platform/core/auth_provider.dart';
import 'package:learning_platform/core/api_service.dart';
import 'package:learning_platform/widgets/edu_widgets.dart';
import 'package:flutter_animate/flutter_animate.dart';

class MyTopicsScreen extends StatefulWidget {
  const MyTopicsScreen({super.key});

  @override
  State<MyTopicsScreen> createState() => _MyTopicsScreenState();
}

class _MyTopicsScreenState extends State<MyTopicsScreen> {
  bool _isUpdating = false;

  Future<void> _updateInterests(List<String> newInterests) async {
    setState(() => _isUpdating = true);
    try {
      final response = await ApiService().post('/auth/preferences', {
        'interests': newInterests,
      });
      if (mounted) {
        final auth = Provider.of<AuthProvider>(context, listen: false);
        auth.updateUserPreferences(interests: newInterests);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Topics updated successfully!')));
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Update failed: $e')));
    } finally {
      if (mounted) setState(() => _isUpdating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<AuthProvider>(context).currentUser;
    final topics = user?.interests ?? [];

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Topics'),
        actions: [
          if (_isUpdating) const Center(child: Padding(padding: EdgeInsets.all(16.0), child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)))),
          IconButton(icon: const Icon(Icons.add_rounded), onPressed: () => _showAddTopicDialog(topics)),
          const SizedBox(width: 8),
        ],
      ),
      body: topics.isEmpty 
        ? _buildEmptyState()
        : ListView.builder(
            padding: const EdgeInsets.all(24),
            itemCount: topics.length,
            itemBuilder: (context, index) {
              return Container(
                margin: const EdgeInsets.only(bottom: 16),
                child: ModernCard(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  radius: 20,
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(color: AppTheme.primaryBlue.withValues(alpha: 0.1), shape: BoxShape.circle),
                        child: const Icon(Icons.auto_stories_rounded, color: AppTheme.primaryBlue, size: 20),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Text(topics[index], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete_outline_rounded, color: AppTheme.accentRed),
                        onPressed: () {
                          final newList = List<String>.from(topics)..removeAt(index);
                          _updateInterests(newList);
                        },
                      ),
                    ],
                  ),
                ),
              ).animate(delay: (index * 50).ms).fadeIn().slideX(begin: 0.1);
            },
          ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
        decoration: const BoxDecoration(color: Colors.white, border: Border(top: BorderSide(color: Color(0xFFE2E8F0)))),
        child: EduPrimaryButton(
          label: 'Add New Topic', 
          onPressed: () => _showAddTopicDialog(topics),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: const [
          Icon(Icons.auto_stories_rounded, size: 64, color: AppTheme.textMuted),
          SizedBox(height: 16),
          Text('No interests added yet.', style: TextStyle(color: AppTheme.textSecondary)),
        ],
      ),
    );
  }

  void _showAddTopicDialog(List<String> currentTopics) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Add Topic'),
        content: TextField(controller: controller, decoration: const InputDecoration(hintText: 'e.g. TOEFL Prep')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          TextButton(onPressed: () {
            if (controller.text.isNotEmpty) {
              final newList = List<String>.from(currentTopics)..add(controller.text);
              _updateInterests(newList);
              Navigator.pop(context);
            }
          }, child: const Text('Add')),
        ],
      ),
    );
  }
}
