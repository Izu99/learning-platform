import 'package:flutter/material.dart';

class AvailabilityCalendar extends StatelessWidget {
  final DateTime? selectedDate;
  final ValueChanged<DateTime> onDateSelected;

  const AvailabilityCalendar({
    super.key,
    required this.selectedDate,
    required this.onDateSelected,
  });

  @override
  Widget build(BuildContext context) {
    // Generate dates for the current week starting from today (or based on design)
    // For demo, we assume the week starts around Oct 1st as per image, 
    // but practically we'd generate real dates.
    // Let's generate 7 days starting from a base date.
    
    final baseDate = DateTime.now();
    final dates = List.generate(7, (index) => baseDate.add(Duration(days: index)));

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: dates.map((date) {
        final isSelected = selectedDate != null && 
            date.day == selectedDate!.day && 
            date.month == selectedDate!.month && 
            date.year == selectedDate!.year;

        return GestureDetector(
          onTap: () => onDateSelected(date),
          child: Column(
            children: [
              Text(
                _getWeekday(date.weekday),
                style: TextStyle(
                  color: Colors.grey[400],
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 12),
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: isSelected ? const Color(0xFF00695C) : Colors.transparent, // Dark teal
                  borderRadius: BorderRadius.circular(8),
                ),
                alignment: Alignment.center,
                child: Text(
                  date.day.toString(),
                  style: TextStyle(
                    color: isSelected ? Colors.white : Colors.black87,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  String _getWeekday(int weekday) {
    const days = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
    return days[weekday - 1];
  }
}
