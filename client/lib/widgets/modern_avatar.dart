import 'package:flutter/material.dart';

class ModernAvatar extends StatelessWidget {
  final String? imageUrl;
  final String fallbackText;
  final double radius;

  const ModernAvatar({
    super.key,
    required this.imageUrl,
    required this.fallbackText,
    this.radius = 24.0,
  });

  @override
  Widget build(BuildContext context) {
    if (imageUrl != null && imageUrl!.isNotEmpty) {
      return CircleAvatar(
        radius: radius,
        backgroundImage: NetworkImage(imageUrl!),
        backgroundColor: Colors.grey[200],
      );
    }
    
    return CircleAvatar(
      radius: radius,
      backgroundColor: const Color(0xFFE2F2EF),
      child: Text(
        fallbackText.isNotEmpty ? fallbackText[0].toUpperCase() : 'U',
        style: TextStyle(
          color: const Color(0xFF00695C), 
          fontWeight: FontWeight.bold,
          fontSize: radius * 0.8,
        ),
      ),
    );
  }
}
