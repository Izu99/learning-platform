import 'package:flutter/material.dart';
import '../../../core/api_service.dart';
import '../../../core/app_theme.dart';
import '../../../core/constants.dart';
import '../../../widgets/edu_widgets.dart';
import '../../teacher_profile/teacher_profile_screen.dart';
import '../../../models/teacher_model.dart';
import 'package:flutter_animate/flutter_animate.dart';

class AdminTeacherListScreen extends StatefulWidget {
  const AdminTeacherListScreen({super.key});

  @override
  State<AdminTeacherListScreen> createState() => _AdminTeacherListScreenState();
}

class _AdminTeacherListScreenState extends State<AdminTeacherListScreen> {
  List<dynamic> _teachers = [];
  bool _isLoading = true;
  String? _error;
  String _statusFilter = 'All';

  @override
  void initState() {
    super.initState();
    _fetchTeachers();
  }

  Future<void> _fetchTeachers() async {
    if (!mounted) return;
    setState(() { _isLoading = true; _error = null; });
    try {
      final data = await ApiService().get('/admin/users?role=teacher');
      if (mounted) setState(() { _teachers = (data is List) ? data : []; _isLoading = false; });
    } catch (e) {
      if (mounted) setState(() { _error = e.toString(); _isLoading = false; });
    }
  }

  List<dynamic> get _filtered {
    if (_statusFilter == 'All') return _teachers;
    return _teachers.where((t) => (t['status'] ?? '').toString().toLowerCase() == _statusFilter.toLowerCase()).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F4F8),
      appBar: AppBar(
        title: const Text('Teacher Management', style: TextStyle(fontWeight: FontWeight.w800)),
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: AppTheme.primaryTeal),
            tooltip: 'Force Refresh',
            onPressed: _fetchTeachers,
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
          _buildFilterBar(),
          Expanded(child: _buildContent()),
        ],
      ),
    );
  }

  Widget _buildFilterBar() {
    final counts = {
      'All': _teachers.length,
      'Pending': _teachers.where((t) => (t['status'] ?? '') == 'pending').length,
      'Active': _teachers.where((t) => (t['status'] ?? '') == 'active').length,
    };
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      child: Row(
        children: ['All', 'Pending', 'Active'].map((s) {
          final isSel = _statusFilter == s;
          final color = s == 'Pending' ? Colors.orange : (s == 'Active' ? AppTheme.primaryGreen : AppTheme.primaryTeal);
          return Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _statusFilter = s),
              child: AnimatedContainer(
                duration: 200.ms,
                margin: const EdgeInsets.symmetric(horizontal: 4),
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: isSel ? color : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: isSel ? color : Colors.grey.shade300),
                ),
                child: Column(
                  children: [
                    Text('${counts[s]}', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: isSel ? Colors.white : AppTheme.textPrimary)),
                    Text(s, style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: isSel ? Colors.white.withOpacity(0.9) : Colors.grey.shade500)),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildContent() {
    if (_isLoading) return const Center(child: CircularProgressIndicator());
    if (_error != null) return _buildError();
    if (_filtered.isEmpty) return _buildEmpty();
    return RefreshIndicator(
      onRefresh: _fetchTeachers,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _filtered.length,
        itemBuilder: (ctx, i) => _buildCard(_filtered[i]).animate(delay: (i * 25).ms).fadeIn().slideY(begin: 0.06),
      ),
    );
  }

  Widget _buildError() => Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
    const Icon(Icons.error_outline_rounded, color: Colors.redAccent, size: 48),
    const SizedBox(height: 12),
    Text(_error!, textAlign: TextAlign.center, style: const TextStyle(color: Colors.redAccent)),
    const SizedBox(height: 12),
    ElevatedButton(onPressed: _fetchTeachers, child: const Text('Retry')),
  ]));

  Widget _buildEmpty() => Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
    Icon(Icons.person_search_rounded, size: 64, color: Colors.grey.shade300),
    const SizedBox(height: 12),
    Text('No $_statusFilter teachers', style: TextStyle(color: Colors.grey.shade500, fontWeight: FontWeight.bold, fontSize: 16)),
    TextButton(onPressed: _fetchTeachers, child: const Text('Refresh')),
  ]));

  Widget _buildCard(Map<String, dynamic> t) {
    final status = (t['status'] ?? 'pending').toString().toLowerCase();
    final isActv = status == 'active';
    final statusColor = isActv ? AppTheme.primaryGreen : Colors.orange;
    final name = (t['name'] ?? 'Unknown') as String;
    final imageUrl = t['profileImageUrl'] as String?;

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: InkWell(
        onTap: () => _showTeacherDetail(t),
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Avatar
              Container(
                width: 56, height: 56,
                decoration: BoxDecoration(borderRadius: BorderRadius.circular(16), color: AppTheme.primaryTeal.withOpacity(0.1)),
                clipBehavior: Clip.antiAlias,
                child: imageUrl != null && imageUrl.isNotEmpty
                    ? Image.network('${_baseUrl(imageUrl)}', fit: BoxFit.cover, errorBuilder: (_, __, ___) => _initials(name, AppTheme.primaryTeal))
                    : _initials(name, AppTheme.primaryTeal),
              ),
              const SizedBox(width: 14),
              // Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(name, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: AppTheme.textPrimary), maxLines: 1, overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 2),
                    // Status badge on second row
                    Row(children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(color: statusColor.withOpacity(0.1), borderRadius: BorderRadius.circular(20)),
                        child: Row(mainAxisSize: MainAxisSize.min, children: [
                          Container(width: 5, height: 5, decoration: BoxDecoration(color: statusColor, shape: BoxShape.circle)),
                          const SizedBox(width: 4),
                          Text(status.toUpperCase(), style: TextStyle(color: statusColor, fontSize: 9, fontWeight: FontWeight.w900, letterSpacing: 0.5)),
                        ]),
                      ),
                      if ((t['title'] as String? ?? '').isNotEmpty) ...[
                        const SizedBox(width: 8),
                        Expanded(child: Text(t['title'] as String, style: TextStyle(color: Colors.grey.shade500, fontSize: 12, fontWeight: FontWeight.w500), overflow: TextOverflow.ellipsis)),
                      ],
                    ]),
                    const SizedBox(height: 6),
                    Text(t['email'] ?? '', style: TextStyle(color: Colors.grey.shade500, fontSize: 12, fontWeight: FontWeight.w500), overflow: TextOverflow.ellipsis),
                  ],
                ),
              ),
              // Joined date
              Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                Icon(Icons.chevron_right_rounded, color: Colors.grey.shade300),
                Text(_fmtDate(t['createdAt']), style: TextStyle(color: Colors.grey.shade400, fontSize: 10, fontWeight: FontWeight.bold)),
              ]),
            ],
          ),
        ),
      ),
    );
  }

  String _baseUrl(String url) {
    final base = AppConstants.baseUrl;
    final serverBase = base.replaceAll('/api', '');
    if (url.startsWith('http')) return url;
    return '$serverBase$url';
  }

  Widget _initials(String name, Color color) => Center(child: Text(name.isNotEmpty ? name[0].toUpperCase() : 'T', style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 22)));

  void _showTeacherDetail(Map<String, dynamic> t) async {
    final updated = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => TeacherProfileScreen(
          teacher: Teacher.fromJson(t),
          isAdminView: true,
        ),
      ),
    );

    if (updated == true) {
      _fetchTeachers();
    }
  }

  Widget _statItem(String label, String value) => Column(children: [
    Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: AppTheme.textPrimary)),
    const SizedBox(height: 2),
    Text(label, style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w800, color: Colors.grey, letterSpacing: 0.5)),
  ]);

  Widget _infoRow(IconData icon, String label, String value, {bool isGreen = false}) => Padding(
    padding: const EdgeInsets.only(bottom: 16),
    child: Row(children: [
      Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: const Color(0xFFF8FAFC), borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFFE2E8F0))),
          child: Icon(icon, size: 18, color: isGreen ? AppTheme.primaryGreen : Colors.grey.shade600)),
      const SizedBox(width: 14),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label, style: TextStyle(fontSize: 10, color: Colors.grey.shade500, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
        const SizedBox(height: 2),
        Text(value, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: isGreen ? AppTheme.primaryGreen : AppTheme.textPrimary)),
      ])),
    ]),
  );

  Future<void> _updateStatus(Map<String, dynamic> t, String newStatus) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      final pId = t['profileId'];
      if (pId == null) throw 'Profile ID not found.';
      await ApiService().put('/admin/teachers/$pId/status', {'status': newStatus});
      if (mounted) {
        messenger.showSnackBar(SnackBar(content: Text('Status updated to $newStatus!'), backgroundColor: AppTheme.primaryGreen));
        _fetchTeachers();
      }
    } catch (e) {
      if (mounted) messenger.showSnackBar(SnackBar(content: Text('Failed: $e'), backgroundColor: Colors.redAccent));
    }
  }

  String _fmtDate(dynamic d) {
    if (d == null) return 'N/A';
    try { final dt = DateTime.parse(d.toString()); return '${dt.day}/${dt.month}/${dt.year}'; } catch (_) { return 'N/A'; }
  }
}
