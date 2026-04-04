import 'package:flutter/material.dart';

class TimeSlotGrid extends StatelessWidget {
  final List<String> slots;
  final String? selectedSlot;
  final ValueChanged<String> onSlotSelected;

  const TimeSlotGrid({
    super.key,
    required this.slots,
    required this.selectedSlot,
    required this.onSlotSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: slots.map((slot) {
        final isSelected = slot == selectedSlot;
        return GestureDetector(
          onTap: () => onSlotSelected(slot),
          child: Container(
            width: (MediaQuery.of(context).size.width - 32 - 24) / 3, // 3 columns
            padding: const EdgeInsets.symmetric(vertical: 12),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: isSelected ? const Color(0xFFE0F2F1) : Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSelected ? const Color(0xFF00695C) : Colors.grey[200]!,
                width: isSelected ? 1.5 : 1,
              ),
            ),
            child: Text(
              slot,
              style: TextStyle(
                color: isSelected ? const Color(0xFF00695C) : Colors.black87,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}
