import 'package:flutter/material.dart';
import '../../core/api_service.dart';
import '../../core/app_theme.dart';
import '../../widgets/edu_widgets.dart';
import 'package:flutter_animate/flutter_animate.dart';

class AdminUserListScreen extends StatefulWidget {
  final String? initialRole; // 'student' or 'teacher'

  const AdminUserListScreen({super.key, this.initialRole});

  @override
  State<AdminUserListScreen> createState() => _AdminUserListScreenState();
}

class _AdminUserListScreenState extends State<AdminUserListScreen> {
  List<dynamic> _users = [];
  bool _isLoading = true;
  String? _error;
  String _currentFilter = 'Teacher';
  String _statusFilter = 'All';

  @override
  void initState() {
    super.initState();
    _parseInitialRole();
    _fetchUsers();
  }

  void _parseInitialRole() {
    final role = widget.initialRole;
    if (role != null && role.isNotEmpty) {
      try {
        _currentFilter = role[0].toUpperCase() + role.substring(1).toLowerCase();
      } catch (_) {
        _currentFilter = 'Teacher';
      }
    }
  }

  Future<void> _fetchUsers() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    try {
      final role = _currentFilter.toLowerCase();
      final response = await ApiService().get('/admin/users?role=$role');
      if (mounted) {
        setState(() {
          _users = (response is List) ? response : [];
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  List<dynamic> get _filteredUsers {
    if (_currentFilter == 'Student') return _users;
    if (_statusFilter == 'All') return _users;
    return _users.where((u) => 
      (u['status'] ?? '').toString().toLowerCase() == _statusFilter.toLowerCase()
    ).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text('${_currentFilter} Management', style: const TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: Column(
        children: [
          if (_currentFilter == 'Teacher') _buildStatusFilterBar(),
          Expanded(child: _buildMainContent()),
        ],
      ),
    );
  }

  Widget _buildMainContent() {
    if (_isLoading) return const Center(child: CircularProgressIndicator());
    if (_error != null) return _buildErrorView();
    if (_filteredUsers.isEmpty) return _buildEmptyView();

    return RefreshIndicator(
      onRefresh: _fetchUsers,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _filteredUsers.length,
        itemBuilder: (context, index) {
          final user = _filteredUsers[index];
          return _buildUserCard(user).animate(delay: (index * 20).ms).fadeIn().slideY(begin: 0.05);
        },
      ),
    );
  }

  Widget _buildErrorView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline_rounded, color: Colors.redAccent, size: 48),
            const SizedBox(height: 16),
            Text(_error ?? 'Unknown error', textAlign: TextAlign.center, style: const TextStyle(color: Colors.redAccent)),
            const SizedBox(height: 16),
            ElevatedButton(onPressed: _fetchUsers, child: const Text('Try Again')),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.person_search_rounded, size: 64, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text('No ${_currentFilter.toLowerCase()}s found.', style: TextStyle(color: Colors.grey[500], fontWeight: FontWeight.bold)),
          TextButton(onPressed: _fetchUsers, child: const Text('Refresh List')),
        ],
      ),
    );
  }

  Widget _buildStatusFilterBar() {
    return Container(
      width: double.infinity,
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 16),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: ['All', 'Pending', 'Active'].map((st) {
            final isSelected = _statusFilter == st;
            return GestureDetector(
              onTap: () => setState(() => _statusFilter = st),
              child: Container(
                margin: const EdgeInsets.only(right: 12),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                decoration: BoxDecoration(
                  color: isSelected ? AppTheme.primaryTeal : Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: isSelected ? AppTheme.primaryTeal : Colors.grey.shade300),
                  boxShadow: isSelected ? [BoxShadow(color: AppTheme.primaryTeal.withOpacity(0.2), blurRadius: 8, offset: const Offset(0, 4))] : null,
                ),
                child: Text(st, style: TextStyle(color: isSelected ? Colors.white : Colors.grey.shade600, fontWeight: FontWeight.bold, fontSize: 13)),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildUserCard(Map<String, dynamic> u) {
    final role = (u['role'] ?? 'student').toString().toLowerCase();
    final isT = role == 'teacher';
    final st = (u['status'] ?? 'active').toString().toLowerCase();
    
    return ModernCard(
      margin: const EdgeInsets.only(bottom: 16),
      padding: EdgeInsets.zero,
      radius: 24,
      child: InkWell(
        onTap: () => _showUserDetails(u),
        borderRadius: BorderRadius.circular(24),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                    radius: 28,
                    backgroundColor: (isT ? AppTheme.primaryTeal : Colors.indigo).withOpacity(0.1),
                    child: Text(
                      ((u['name'] ?? 'U') as String).substring(0, 1).toUpperCase(),
                      style: TextStyle(color: isT ? AppTheme.primaryTeal : Colors.indigo, fontWeight: FontWeight.bold, fontSize: 20),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(child: Text(u['name'] ?? 'Unknown', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18, color: AppTheme.textPrimary))),
                            if (isT) _statusBadge(st),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(u['email'] ?? 'No email', style: TextStyle(color: Colors.grey.shade600, fontSize: 13, fontWeight: FontWeight.w500)),
                      ],
                    ),
                  ),
                ],
              ),
              const Divider(height: 32, thickness: 1, color: Color(0xFFF1F5F9)),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.phone_android_rounded, size: 14, color: Colors.grey),
                          const SizedBox(width: 6),
                          Text(u['phoneNumber'] ?? 'No Phone', style: const TextStyle(fontSize: 13, color: Colors.blueGrey, fontWeight: FontWeight.w600)),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text('Role: ${role.toUpperCase()}', style: TextStyle(color: Colors.grey.shade500, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
                    ],
                  ),
                  _buildActionArea(u),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionArea(Map<String, dynamic> u) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text('Joined', style: TextStyle(color: Colors.grey.shade400, fontSize: 10, fontWeight: FontWeight.bold)),
        Text(_formatDate(u['createdAt']), style: TextStyle(color: Colors.grey.shade600, fontSize: 12, fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _statusBadge(String st) {
    final isP = st == 'pending';
    final color = isP ? Colors.orange : AppTheme.primaryGreen;
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(20), border: Border.all(color: color.withOpacity(0.2))),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(width: 6, height: 6, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
          const SizedBox(width: 6),
          Text(st.toUpperCase(), style: TextStyle(color: color, fontWeight: FontWeight.w800, fontSize: 10, letterSpacing: 0.5)),
        ],
      ),
    );
  }

  Future<void> _updateTeacherStatus(Map<String, dynamic> u, String newSt) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      final pId = u['profileId'];
      if (pId == null) throw 'Profile ID not found.';

      await ApiService().put('/admin/teachers/$pId/status', {'status': newSt});
      if (mounted) {
        messenger.showSnackBar(SnackBar(content: Text('Status updated to $newSt!'), backgroundColor: AppTheme.primaryGreen));
        _fetchUsers();
      }
    } catch (e) {
      if (mounted) {
        messenger.showSnackBar(SnackBar(content: Text('Update failed: $e'), backgroundColor: Colors.redAccent));
      }
    }
  }

  void _showUserDetails(Map<String, dynamic> u) {
    final isT = (u['role'] ?? '').toString().toLowerCase() == 'teacher';
    final st = (u['status'] ?? 'active').toString().toLowerCase();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.85,
        decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(32))),
        child: Column(
          children: [
            const SizedBox(height: 12),
            Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2))),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: CircleAvatar(
                        radius: 50,
                        backgroundColor: (isT ? AppTheme.primaryTeal : Colors.indigo).withOpacity(0.1),
                        child: Text(
                          ((u['name'] ?? 'U') as String).substring(0, 1).toUpperCase(),
                          style: TextStyle(color: isT ? AppTheme.primaryTeal : Colors.indigo, fontWeight: FontWeight.bold, fontSize: 36),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Center(
                      child: Column(
                        children: [
                          Text(u['name'] ?? 'Unknown', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: AppTheme.textPrimary)),
                          if (isT) ...[const SizedBox(height: 8), _statusBadge(st)]
                        ],
                      ),
                    ),
                    const SizedBox(height: 48),
                    const Text('REGISTRATION DETAILS', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: Colors.grey, letterSpacing: 1.5)),
                    const SizedBox(height: 20),
                    _detailTile(Icons.alternate_email_rounded, 'Email Address', u['email'] ?? 'Not provided'),
                    _detailTile(Icons.phone_android_rounded, 'Phone Number', u['phoneNumber'] ?? 'Not provided', isPrimary: true),
                    _detailTile(Icons.calendar_month_rounded, 'Account Created', _formatDate(u['createdAt'])),
                    if (isT) ...[
                      const SizedBox(height: 40),
                      const Text('PROFESSIONAL CONTROL', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: Colors.grey, letterSpacing: 1.5)),
                      const SizedBox(height: 20),
                      if (st == 'pending')
                         EduPrimaryButton(label: 'Approve Teacher', color: AppTheme.primaryGreen, onPressed: () { Navigator.pop(context); _updateTeacherStatus(u, 'approved'); })
                      else if (st == 'active')
                        EduPrimaryButton(label: 'Set back to Pending', color: Colors.orange, onPressed: () { Navigator.pop(context); _updateTeacherStatus(u, 'pending'); }),
                    ],
                    const SizedBox(height: 40),
                    TextButton(onPressed: () => Navigator.pop(context), child: const Center(child: Text('Close Profile', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)))),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _detailTile(IconData icon, String label, String value, {bool isPrimary = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: const Color(0xFFF8FAFC), borderRadius: BorderRadius.circular(16), border: Border.all(color: const Color(0xFFF1F5F9))),
            child: Icon(icon, size: 22, color: isPrimary ? AppTheme.primaryGreen : const Color(0xFF64748B)),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: TextStyle(fontSize: 11, color: Colors.grey.shade500, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
                const SizedBox(height: 2),
                Text(value, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: isPrimary ? AppTheme.primaryGreen : const Color(0xFF1E293B))),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(dynamic dateStr) {
    if (dateStr == null) return 'N/A';
    try {
      final date = DateTime.parse(dateStr.toString());
      return '${date.day}/${date.month}/${date.year}';
    } catch (_) {
      return 'N/A';
    }
  }
}
