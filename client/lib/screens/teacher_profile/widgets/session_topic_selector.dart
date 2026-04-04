import 'package:flutter/material.dart';

class SessionTopicSelector extends StatelessWidget {
  final List<String> topics;
  final String? selectedTopic;
  final ValueChanged<String> onTopicSelected;

  const SessionTopicSelector({
    super.key,
    required this.topics,
    required this.selectedTopic,
    required this.onTopicSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: topics.map((topic) {
        final isSelected = topic == selectedTopic;
        return GestureDetector(
          onTap: () => onTopicSelected(topic),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: isSelected ? const Color(0xFF00695C) : Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSelected ? Colors.transparent : Colors.grey[200]!,
              ),
            ),
            child: Text(
              topic,
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.black87,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                fontSize: 14,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}
