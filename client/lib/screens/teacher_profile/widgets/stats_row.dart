import 'package:flutter/material.dart';
import '../../../models/teacher_model.dart';

class StatsRow extends StatelessWidget {
  final Teacher teacher;

  const StatsRow({super.key, required this.teacher});

  @override
  Widget build(BuildContext context) {
    if (teacher.price == null || teacher.price == 0) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatItem('EXPERIENCE', '${teacher.experienceYears} Years'),
          _buildDivider(),
          _buildStatItem('STUDENTS', '${teacher.studentsCount}+'),
          _buildDivider(),
          _buildStatItem('RATE', 'Rs.${teacher.price?.toStringAsFixed(0) ?? '35'}/hr', isPrice: true),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, {bool isPrice = false}) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: Colors.grey[500],
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: isPrice ? const Color(0xFF00695C) : Colors.black87,
          ),
        ),
      ],
    );
  }

  Widget _buildDivider() {
    return Container(
      height: 30,
      width: 1,
      color: Colors.grey[300],
    );
  }
}
