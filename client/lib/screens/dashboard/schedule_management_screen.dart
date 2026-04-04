import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:learning_platform/core/app_theme.dart';
import 'package:learning_platform/core/auth_provider.dart';
import 'package:learning_platform/core/api_service.dart';
import 'package:learning_platform/widgets/edu_widgets.dart';
import 'package:flutter_animate/flutter_animate.dart';

class ScheduleManagementScreen extends StatefulWidget {
  const ScheduleManagementScreen({super.key});

  @override
  State<ScheduleManagementScreen> createState() => _ScheduleManagementScreenState();
}

class _ScheduleManagementScreenState extends State<ScheduleManagementScreen> {
  int _selectedDayIndex = 0; // 0 = today, 1 = tomorrow, etc.
  List<dynamic> _availability = [];
  bool _isLoading = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _fetchSchedule();
  }

  Future<void> _fetchSchedule() async {
    final user = Provider.of<AuthProvider>(context, listen: false).currentUser;
    if (user == null) return;

    try {
      final response = await ApiService().get('/teachers/profile/${user.id}');
      if (mounted) {
        setState(() {
          _availability = response['availability'] ?? [];
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // Returns the selected date (today + offset, future only)
  DateTime get _selectedDate => DateTime.now().add(Duration(days: _selectedDayIndex));

  String get _selectedDateStr {
    final d = _selectedDate;
    return '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final slots = _slotsForDate(_selectedDateStr);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Availability'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.fromLTRB(24, 16, 24, 0),
                  child: Text(
                    'Manage your teaching hours and availability.',
                    style: TextStyle(color: Color(0xFF64748B), fontWeight: FontWeight.w500, fontSize: 15),
                  ),
                ),
                const SizedBox(height: 24),
                _buildCalendarStrip(),
                const SizedBox(height: 32),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Time Slots (${slots.length})',
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Color(0xFF1E293B))),
                      TextButton.icon(
                        onPressed: _showAddSlotDialog,
                        icon: const Icon(Icons.add_rounded, size: 18),
                        label: const Text('Add Slot', style: TextStyle(fontWeight: FontWeight.bold)),
                        style: TextButton.styleFrom(foregroundColor: AppTheme.primaryTeal),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: slots.isEmpty
                      ? _buildEmptySlots()
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 24),
                          itemCount: slots.length,
                          itemBuilder: (context, index) {
                            final slot = slots[index];
                            return _buildSlotCard(slot)
                                .animate(delay: (index * 50).ms)
                                .fadeIn()
                                .slideX(begin: 0.1);
                          },
                        ),
                ),
              ],
            ),
    );
  }

  List<dynamic> _slotsForDate(String dateStr) {
    if (_availability.isEmpty) return [];
    final dayData = _availability.firstWhere((d) => d['date'] == dateStr, orElse: () => null);
    return dayData != null ? (dayData['slots'] ?? []) : [];
  }

  Widget _buildCalendarStrip() {
    // Show today + next 6 days only (no past dates = no stale data issues)
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        children: List.generate(7, (index) {
          final date = DateTime.now().add(Duration(days: index));
          final isSelected = _selectedDayIndex == index;
          final dayNum = date.day;
          final dayName = ['SUN', 'MON', 'TUE', 'WED', 'THU', 'FRI', 'SAT'][date.weekday % 7];
          final isToday = index == 0;

          return GestureDetector(
            onTap: () => setState(() => _selectedDayIndex = index),
            child: Column(
              children: [
                AnimatedContainer(
                  duration: 200.ms,
                  width: 65,
                  height: 85,
                  margin: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: isSelected ? AppTheme.primaryTeal : Colors.transparent,
                    borderRadius: BorderRadius.circular(18),
                    border: isSelected ? null : Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(isToday ? 'TODAY' : dayName,
                          style: TextStyle(
                              color: isSelected ? Colors.white : const Color(0xFF94A3B8),
                              fontWeight: FontWeight.bold,
                              fontSize: 10)),
                      const SizedBox(height: 8),
                      Text('$dayNum',
                          style: TextStyle(
                              color: isSelected ? Colors.white : const Color(0xFF1E293B),
                              fontWeight: FontWeight.w800,
                              fontSize: 18)),
                    ],
                  ),
                ),
                if (isToday)
                  Container(
                      width: 4,
                      height: 4,
                      decoration: const BoxDecoration(
                          color: AppTheme.primaryTeal, shape: BoxShape.circle)),
              ],
            ),
          );
        }),
      ),
    );
  }

  Widget _buildSlotCard(Map<String, dynamic> slot) {
    final isAvailable = slot['available'] ?? true;
    
    return ModernCard(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      radius: 20,
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isAvailable ? const Color(0xFFE2F2EF) : const Color(0xFFF1F5F9), 
              borderRadius: BorderRadius.circular(12)
            ),
            child: Icon(
              isAvailable ? Icons.event_available_rounded : Icons.lock_clock_rounded, 
              color: isAvailable ? AppTheme.primaryTeal : const Color(0xFF94A3B8),
              size: 22,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('${slot['start']} - ${slot['end']}', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
                const SizedBox(height: 2),
                Text(isAvailable ? 'Available for booking' : 'Booked / Unavailable', 
                  style: const TextStyle(color: Color(0xFF64748B), fontWeight: FontWeight.w500, fontSize: 13)),
              ],
            ),
          ),
          const Icon(Icons.access_time_rounded, color: Color(0xFF94A3B8)),
          const SizedBox(width: 8),
          IconButton(
            icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent, size: 20),
            onPressed: () => _deleteSlot(slot),
            tooltip: 'Remove Slot',
          ),
        ],
      ),
    );
  }

  Future<void> _deleteSlot(Map<String, dynamic> slot) async {
    final user = Provider.of<AuthProvider>(context, listen: false).currentUser;
    if (user == null) return;

    try {
      // Only send today + future dates to the server (drop stale past dates)
      final today = DateTime.now();
      final todayStr = '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';

      final List<dynamic> updatedAvailability = _availability
          .where((d) => d['date'] != null && d['date'] >= todayStr)
          .map((d) => {
                'date': d['date'],
                'slots': List.from(d['slots'] ?? []),
              })
          .toList();

      int dayIdx = updatedAvailability.indexWhere((d) => d['date'] == _selectedDateStr);
      if (dayIdx != -1) {
        updatedAvailability[dayIdx]['slots']
            .removeWhere((s) => s['start'] == slot['start'] && s['end'] == slot['end']);
        if ((updatedAvailability[dayIdx]['slots'] as List).isEmpty) {
          updatedAvailability.removeAt(dayIdx);
        }
      }

      await ApiService().post('/teachers/profile', {
        'userId': user.id,
        'availability': updatedAvailability,
      });

      if (mounted) {
        _fetchSchedule();
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Slot removed successfully!')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error removing slot: $e')));
      }
    }
  }

  void _showAddSlotDialog() {
    TimeOfDay? startTime;
    TimeOfDay? endTime;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          title: const Text('Add Time Slot', style: TextStyle(fontWeight: FontWeight.w800)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                title: Text(startTime == null ? 'Select Start Time' : 'Starts: ${startTime!.format(context)}'),
                leading: const Icon(Icons.access_time_rounded, color: AppTheme.primaryTeal),
                onTap: () async {
                  final picked = await showTimePicker(context: context, initialTime: startTime ?? TimeOfDay.now());
                  if (picked != null) {
                    setDialogState(() {
                      startTime = picked;
                      // Don't auto-calculate end time anymore, let user choose
                    });
                  }
                },
              ),
              ListTile(
                title: Text(endTime == null ? 'Select End Time' : 'Ends: ${endTime!.format(context)}'),
                leading: const Icon(Icons.more_time_rounded, color: AppTheme.primaryTeal),
                onTap: () async {
                  final picked = await showTimePicker(context: context, initialTime: endTime ?? startTime ?? TimeOfDay.now());
                  if (picked != null) {
                    setDialogState(() => endTime = picked);
                  }
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context), 
              child: const Text('Cancel', style: TextStyle(color: Color(0xFF64748B), fontWeight: FontWeight.bold))
            ),
            ElevatedButton(
              onPressed: (_isSaving || startTime == null || endTime == null) ? null : () {
                // Validation: End must be after start
                if (endTime!.hour < startTime!.hour || (endTime!.hour == startTime!.hour && endTime!.minute <= startTime!.minute)) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('End time must be after start time'), backgroundColor: Colors.redAccent)
                  );
                  return;
                }
                _saveNewSlot(startTime!, endTime!);
              },
              style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryTeal, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
              child: _isSaving 
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                : const Text('Save Slot', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _saveNewSlot(TimeOfDay start, TimeOfDay end) async {
    final user = Provider.of<AuthProvider>(context, listen: false).currentUser;
    if (user == null) return;

    setState(() => _isSaving = true);

    final newSlot = {
      'start': '${start.hour.toString().padLeft(2, '0')}:${start.minute.toString().padLeft(2, '0')}',
      'end': '${end.hour.toString().padLeft(2, '0')}:${end.minute.toString().padLeft(2, '0')}',
      'available': true,
    };

    try {
      // Only carry forward today + future dates (drop all past/stale dates)
      final today = DateTime.now();
      final todayStr = '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';

      final List<dynamic> updatedAvailability = _availability
          .where((d) => d['date'] != null && d['date'] >= todayStr)
          .map((d) => {
                'date': d['date'],
                'slots': List.from(d['slots'] ?? []),
              })
          .toList();

      int dayIdx = updatedAvailability.indexWhere((d) => d['date'] == _selectedDateStr);

      if (dayIdx != -1) {
        // Check for exact duplicate on this day only
        final existingSlots = updatedAvailability[dayIdx]['slots'] as List;
        final isDuplicate = existingSlots.any((s) => s['start'] == newSlot['start']);
        if (isDuplicate) {
          if (mounted) {
            setState(() => _isSaving = false);
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                  content: Text('This time slot already exists!'),
                  backgroundColor: Colors.orangeAccent),
            );
          }
          return;
        }
        updatedAvailability[dayIdx]['slots'].add(newSlot);
      } else {
        updatedAvailability.add({'date': _selectedDateStr, 'slots': [newSlot]});
      }

      await ApiService().post('/teachers/profile', {
        'userId': user.id,
        'availability': updatedAvailability,
      });

      if (mounted) {
        _fetchSchedule();
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Slot added successfully!'),
              backgroundColor: AppTheme.primaryTeal),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), duration: const Duration(seconds: 5)),
        );
      }
    }
  }

  Widget _buildEmptySlots() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.event_busy_rounded, size: 64, color: const Color(0xFFE2E8F0)),
          const SizedBox(height: 16),
          const Text('No slots for this day', 
            style: TextStyle(color: Color(0xFF94A3B8), fontWeight: FontWeight.w600, fontSize: 16)),
          const SizedBox(height: 8),
          const Text('Click "Add Slot" to set your teaching hours.', 
            style: TextStyle(color: Color(0xFFCBD5E1), fontSize: 13)),
        ],
      ),
    );
  }
}
