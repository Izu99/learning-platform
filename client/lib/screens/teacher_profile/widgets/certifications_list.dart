import 'package:flutter/material.dart';
import '../../../models/teacher_model.dart';

class CertificationsList extends StatelessWidget {
  final List<Qualification> qualifications;

  const CertificationsList({super.key, required this.qualifications});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: qualifications.map((qualification) {
          return Padding(
            padding: const EdgeInsets.only(right: 12.0),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(25),
                border: Border.all(color: Colors.grey[200]!),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withValues(alpha: 0.05),
                    spreadRadius: 1,
                    blurRadius: 5,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  const Icon(Icons.school, color: Color(0xFF455A64), size: 20),
                  const SizedBox(width: 8),
                  Text(
                    qualification.title,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF37474F),
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
