import 'package:flutter/material.dart';
import '../../../core/api_service.dart';
import '../../../core/app_theme.dart';
import '../../../core/constants.dart';
import '../../teacher_profile/teacher_profile_screen.dart';
import '../../../models/teacher_model.dart';
import 'package:flutter_animate/flutter_animate.dart';

class AdminStudentListScreen extends StatefulWidget {
  const AdminStudentListScreen({super.key});

  @override
  State<AdminStudentListScreen> createState() => _AdminStudentListScreenState();
}

class _AdminStudentListScreenState extends State<AdminStudentListScreen> {
  List<dynamic> _students = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchStudents();
  }

  Future<void> _fetchStudents() async {
    if (!mounted) return;
    setState(() { _isLoading = true; _error = null; });
    try {
      final data = await ApiService().get('/admin/users?role=student');
      if (mounted) setState(() { _students = (data is List) ? data : []; _isLoading = false; });
    } catch (e) {
      if (mounted) setState(() { _error = e.toString(); _isLoading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F4F8),
      appBar: AppBar(
        title: const Text('Student Management', style: TextStyle(fontWeight: FontWeight.w800)),
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: AppTheme.primaryTeal),
            tooltip: 'Force Refresh',
            onPressed: _fetchStudents,
          ),
          const SizedBox(width: 8),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: const Color(0xFFE2E8F0)),
        ),
      ),
      body: Column(
        children: [
          _buildHeader(),
          Expanded(child: _buildContent()),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      child: Row(children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(color: const Color(0xFF4F46E5).withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
          child: const Icon(Icons.school_rounded, color: Color(0xFF4F46E5), size: 20),
        ),
        const SizedBox(width: 12),
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('${_students.length} Students', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: AppTheme.textPrimary)),
          Text('Total registered students', style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
        ]),
      ]),
    );
  }

  Widget _buildContent() {
    if (_isLoading) return const Center(child: CircularProgressIndicator());
    if (_error != null) return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      const Icon(Icons.error_outline_rounded, color: Colors.redAccent, size: 48),
      const SizedBox(height: 12),
      Text(_error!, textAlign: TextAlign.center, style: const TextStyle(color: Colors.redAccent)),
      const SizedBox(height: 12),
      ElevatedButton(onPressed: _fetchStudents, child: const Text('Retry')),
    ]));
    if (_students.isEmpty) return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      Icon(Icons.person_search_rounded, size: 64, color: Colors.grey.shade300),
      const SizedBox(height: 12),
      Text('No students registered yet', style: TextStyle(color: Colors.grey.shade500, fontWeight: FontWeight.bold, fontSize: 16)),
    ]));

    return RefreshIndicator(
      onRefresh: _fetchStudents,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _students.length,
        itemBuilder: (ctx, i) => _buildCard(_students[i]).animate(delay: (i * 25).ms).fadeIn().slideY(begin: 0.06),
      ),
    );
  }

  Widget _buildCard(Map<String, dynamic> s) {
    final name = (s['name'] ?? 'Unknown') as String;
    final imageUrl = s['profileImageUrl'] as String?;
    final level = (s['level'] as String? ?? '');
    final interests = (s['interests'] as List<dynamic>? ?? []).map((e) => e.toString()).toList();

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: InkWell(
        onTap: () => _showStudentDetail(s),
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(children: [
            // Avatar
            Container(
              width: 56, height: 56,
              decoration: BoxDecoration(borderRadius: BorderRadius.circular(16), color: const Color(0xFF4F46E5).withOpacity(0.1)),
              clipBehavior: Clip.antiAlias,
              child: imageUrl != null && imageUrl.isNotEmpty
                  ? Image.network(_buildUrl(imageUrl), fit: BoxFit.cover, errorBuilder: (_, __, ___) => _initials(name))
                  : _initials(name),
            ),
            const SizedBox(width: 14),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              // Row 1: Name
              Text(name, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: AppTheme.textPrimary), maxLines: 1, overflow: TextOverflow.ellipsis),
              const SizedBox(height: 3),
              // Row 2: Level badge
              if (level.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(color: const Color(0xFF4F46E5).withOpacity(0.1), borderRadius: BorderRadius.circular(20)),
                  child: Text(level, style: const TextStyle(color: Color(0xFF4F46E5), fontSize: 10, fontWeight: FontWeight.w800)),
                )
              else
                Text('Student', style: TextStyle(color: Colors.grey.shade400, fontSize: 11, fontWeight: FontWeight.w600)),
              const SizedBox(height: 5),
              // Row 3: Email
              Text(s['email'] ?? '', style: TextStyle(color: Colors.grey.shade500, fontSize: 12), overflow: TextOverflow.ellipsis),
            ])),
            Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
              const Icon(Icons.chevron_right_rounded, color: Color(0xFFCBD5E1)),
              Text(_fmtDate(s['createdAt']), style: TextStyle(color: Colors.grey.shade400, fontSize: 10, fontWeight: FontWeight.bold)),
            ]),
          ]),
        ),
      ),
    );
  }

  void _showStudentDetail(Map<String, dynamic> s) async {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => TeacherProfileScreen(
          teacher: Teacher.fromJson(s),
          isAdminView: true,
        ),
      ),
    );
  }

  Widget _initials(String name) => Center(child: Text(name.isNotEmpty ? name[0].toUpperCase() : 'S', style: const TextStyle(color: Color(0xFF4F46E5), fontWeight: FontWeight.bold, fontSize: 22)));

  Widget _infoRow(IconData icon, String label, String value, {bool isHighlight = false}) => Padding(
    padding: const EdgeInsets.only(bottom: 16),
    child: Row(children: [
      Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: const Color(0xFFF8FAFC), borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFFE2E8F0))),
          child: Icon(icon, size: 18, color: isHighlight ? const Color(0xFF4F46E5) : Colors.grey.shade600)),
      const SizedBox(width: 14),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label, style: TextStyle(fontSize: 10, color: Colors.grey.shade500, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
        const SizedBox(height: 2),
        Text(value, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: isHighlight ? const Color(0xFF4F46E5) : AppTheme.textPrimary)),
      ])),
    ]),
  );

  String _buildUrl(String url) {
    if (url.startsWith('http')) return url;
    return '${AppConstants.baseUrl.replaceAll('/api', '')}$url';
  }

  String _fmtDate(dynamic d) {
    if (d == null) return 'N/A';
    try { final dt = DateTime.parse(d.toString()); return '${dt.day}/${dt.month}/${dt.year}'; } catch (_) { return 'N/A'; }
  }
}
