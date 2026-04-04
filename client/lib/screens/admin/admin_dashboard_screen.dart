import 'package:flutter/material.dart';
import '../../core/api_service.dart';
import '../../core/app_theme.dart';
import 'teacher/admin_teacher_list_screen.dart';
import 'student/admin_student_list_screen.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'dart:math' as math;
import '../../widgets/notification_bell.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  Map<String, dynamic>? _metrics;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchMetrics();
  }

  Future<void> _fetchMetrics() async {
    if (!mounted) return;
    setState(() { _isLoading = true; _error = null; });
    try {
      final data = await ApiService().get('/admin/dashboard/metrics');
      if (mounted) setState(() { _metrics = data; _isLoading = false; });
    } catch (e) {
      if (mounted) setState(() { _error = e.toString(); _isLoading = false; });
    }
  }

  int get _totalTeachers => (_metrics?['totalTeachers'] as num?)?.toInt() ?? 0;
  int get _totalStudents => (_metrics?['totalStudents'] as num?)?.toInt() ?? 0;
  int get _pendingTeachers => (_metrics?['pendingTeachers'] as num?)?.toInt() ?? 0;
  int get _totalUsers => _totalTeachers + _totalStudents;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F4F8),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.primaryTeal))
          : _error != null
              ? _buildError()
              : RefreshIndicator(
                  onRefresh: _fetchMetrics,
                  child: CustomScrollView(
                    slivers: [
                      _buildAppBar(),
                      SliverToBoxAdapter(child: _buildBody()),
                    ],
                  ),
                ),
    );
  }

  Widget _buildError() {
    return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      const Icon(Icons.cloud_off_rounded, color: Colors.grey, size: 64),
      const SizedBox(height: 16),
      Text('Could not load dashboard', style: TextStyle(color: Colors.grey.shade600, fontWeight: FontWeight.bold, fontSize: 16)),
      const SizedBox(height: 8),
      Text(_error ?? '', textAlign: TextAlign.center, style: TextStyle(color: Colors.grey.shade400, fontSize: 12)),
      const SizedBox(height: 20),
      ElevatedButton(onPressed: _fetchMetrics, child: const Text('Retry')),
    ]));
  }

  Widget _buildAppBar() {
    return SliverAppBar(
      expandedHeight: 160,
      pinned: true,
      elevation: 0,
      backgroundColor: AppTheme.primaryGreen,
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF0F4C3A), AppTheme.primaryTeal],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                  Row(children: [
                    Container(
                      width: 40, height: 40,
                      decoration: BoxDecoration(color: Colors.white.withOpacity(0.15), borderRadius: BorderRadius.circular(12)),
                      child: const Icon(Icons.shield_rounded, color: Colors.white, size: 20),
                    ),
                    const SizedBox(width: 10),
                    const Text('EmuLearn Admin', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 16)),
                  ]),
                  Row(
                    children: [
                      const NotificationBell(color: Colors.white70),
                      IconButton(
                        icon: const Icon(Icons.refresh_rounded, color: Colors.white70),
                        tooltip: 'Force Refresh',
                        onPressed: _fetchMetrics,
                      ),
                      IconButton(
                        icon: const Icon(Icons.logout_rounded, color: Colors.white70),
                        onPressed: () => Navigator.of(context).pushReplacementNamed('/'),
                      ),
                    ],
                  ),
                ]),
                const SizedBox(height: 8),
                const Text('Admin Console', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 26)),
                Text('Platform overview & management', style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 14)),
              ]),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBody() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // Stat Cards Row
        Row(children: [
          _buildStatCard('Total Teachers', '$_totalTeachers', Icons.people_alt_rounded, const Color(0xFF0D9488), () => _goTeachers()),
          const SizedBox(width: 12),
          _buildStatCard('Total Students', '$_totalStudents', Icons.school_rounded, const Color(0xFF4F46E5), () => _goStudents()),
        ]).animate().fadeIn(delay: 100.ms).slideY(begin: 0.1),
        const SizedBox(height: 12),
        // Pending alert card
        if (_pendingTeachers > 0)
          _buildPendingCard().animate().fadeIn(delay: 150.ms).slideY(begin: 0.1),
        const SizedBox(height: 20),
        // Chart section
        const Text('PLATFORM OVERVIEW', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: Colors.grey, letterSpacing: 1.5)),
        const SizedBox(height: 12),
        _buildChart().animate().fadeIn(delay: 200.ms),
        const SizedBox(height: 20),
        // Quick Actions
        const Text('MANAGE', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: Colors.grey, letterSpacing: 1.5)),
        const SizedBox(height: 12),
        _buildQuickActions().animate().fadeIn(delay: 250.ms),
        const SizedBox(height: 32),
        // Footer
        Center(child: Column(children: [
          Icon(Icons.shield_outlined, size: 24, color: Colors.grey.shade300),
          const SizedBox(height: 6),
          Text('SECURE ADMIN ACCESS', style: TextStyle(color: Colors.grey.shade400, fontWeight: FontWeight.w800, fontSize: 10, letterSpacing: 1.5)),
        ])),
        const SizedBox(height: 20),
      ]),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color, VoidCallback onTap) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(22),
            boxShadow: [BoxShadow(color: color.withOpacity(0.08), blurRadius: 12, offset: const Offset(0, 4))],
            border: Border.all(color: color.withOpacity(0.1)),
          ),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(14)),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(height: 14),
            Text(value, style: TextStyle(fontSize: 32, fontWeight: FontWeight.w900, color: color, letterSpacing: -1)),
            const SizedBox(height: 2),
            Text(title, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppTheme.textSecondary)),
            const SizedBox(height: 8),
            Row(children: [
              Text('View all', style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.bold)),
              const SizedBox(width: 2),
              Icon(Icons.arrow_forward_rounded, size: 12, color: color),
            ]),
          ]),
        ),
      ),
    );
  }

  Widget _buildPendingCard() {
    return GestureDetector(
      onTap: _goTeachers,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: [Colors.orange.shade600, Colors.orange.shade400], begin: Alignment.topLeft, end: Alignment.bottomRight),
          borderRadius: BorderRadius.circular(18),
          boxShadow: [BoxShadow(color: Colors.orange.withOpacity(0.3), blurRadius: 12, offset: const Offset(0, 4))],
        ),
        child: Row(children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(12)),
            child: const Icon(Icons.access_time_rounded, color: Colors.white, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('$_pendingTeachers Pending ${_pendingTeachers == 1 ? 'Teacher' : 'Teachers'}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 16)),
            Text('Tap to review and approve applications', style: TextStyle(color: Colors.white.withOpacity(0.85), fontSize: 12)),
          ])),
          const Icon(Icons.chevron_right_rounded, color: Colors.white),
        ]),
      ),
    );
  }

  Widget _buildChart() {
    final total = _totalUsers == 0 ? 1 : _totalUsers;
    final teacherPct = _totalTeachers / total;
    final studentPct = _totalStudents / total;

    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('User Distribution', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppTheme.textPrimary)),
        Text('$_totalUsers total platform users', style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
        const SizedBox(height: 24),
        // Bar chart
        Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
          _buildBar('Teachers', teacherPct, const Color(0xFF0D9488), '$_totalTeachers'),
          const SizedBox(width: 16),
          _buildBar('Students', studentPct, const Color(0xFF4F46E5), '$_totalStudents'),
        ]),
        const SizedBox(height: 20),
        // Progress bar
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Text('Teacher vs Student Ratio', style: TextStyle(fontSize: 12, color: Colors.grey.shade600, fontWeight: FontWeight.w600)),
            Text('${(teacherPct * 100).toStringAsFixed(0)}% / ${(studentPct * 100).toStringAsFixed(0)}%', style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
          ]),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Row(children: [
              Expanded(flex: (_totalTeachers * 100 / total).round().clamp(1, 99), child: Container(height: 10, color: const Color(0xFF0D9488))),
              Expanded(flex: (_totalStudents * 100 / total).round().clamp(1, 99), child: Container(height: 10, color: const Color(0xFF4F46E5))),
            ]),
          ),
          const SizedBox(height: 12),
          Row(children: [
            _legend('Teachers', const Color(0xFF0D9488)),
            const SizedBox(width: 16),
            _legend('Students', const Color(0xFF4F46E5)),
          ]),
        ]),
      ]),
    );
  }

  Widget _buildBar(String label, double pct, Color color, String count) {
    final maxHeight = 160.0;
    final barH = (maxHeight * pct).clamp(12.0, maxHeight);
    return Expanded(child: Column(mainAxisAlignment: MainAxisAlignment.end, children: [
      Text(count, style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: color)),
      const SizedBox(height: 6),
      AnimatedContainer(
        duration: 600.ms,
        height: barH,
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: [color, color.withOpacity(0.6)], begin: Alignment.topCenter, end: Alignment.bottomCenter),
          borderRadius: BorderRadius.circular(10),
        ),
      ),
      const SizedBox(height: 8),
      Text(label, style: TextStyle(fontSize: 11, color: Colors.grey.shade600, fontWeight: FontWeight.w700)),
    ]));
  }

  Widget _legend(String label, Color color) {
    return Row(children: [
      Container(width: 10, height: 10, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(3))),
      const SizedBox(width: 5),
      Text(label, style: TextStyle(fontSize: 11, color: Colors.grey.shade600, fontWeight: FontWeight.w600)),
    ]);
  }

  Widget _buildQuickActions() {
    return Row(children: [
      _buildActionTile('Teacher Management', 'View & approve teachers', Icons.manage_accounts_rounded, const Color(0xFF0D9488), _goTeachers),
      const SizedBox(width: 12),
      _buildActionTile('Student Management', 'View registered students', Icons.school_rounded, const Color(0xFF4F46E5), _goStudents),
    ]);
  }

  Widget _buildActionTile(String title, String sub, IconData icon, Color color, VoidCallback onTap) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [BoxShadow(color: color.withOpacity(0.3), blurRadius: 12, offset: const Offset(0, 4))],
          ),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Icon(icon, color: Colors.white, size: 26),
            const SizedBox(height: 12),
            Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 14)),
            const SizedBox(height: 2),
            Text(sub, style: TextStyle(color: Colors.white.withOpacity(0.75), fontSize: 11)),
          ]),
        ),
      ),
    );
  }

  void _goTeachers() async {
    await Navigator.pushNamed(context, '/admin/teachers');
    _fetchMetrics(); // Force refresh on return
  }
  
  void _goStudents() async {
    await Navigator.pushNamed(context, '/admin/students');
    _fetchMetrics(); // Force refresh on return
  }
}
