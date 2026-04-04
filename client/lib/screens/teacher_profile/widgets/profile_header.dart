import 'package:flutter/material.dart';
import '../../../models/teacher_model.dart';
import '../../../core/constants.dart';

class ProfileHeader extends StatelessWidget {
  final Teacher teacher;
  final bool isAdminView;

  const ProfileHeader({super.key, required this.teacher, this.isAdminView = false});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Stack(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  width: 80,
                  height: 80,
                  color: Colors.grey[200], // Placeholder color
                  child: teacher.profileImageUrl != null && teacher.profileImageUrl!.isNotEmpty
                      ? Image.network(
                          AppConstants.buildImageUrl(teacher.profileImageUrl),
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) => const Icon(Icons.person, size: 40, color: Colors.grey),
                        )
                      : Center(
                          child: Text(
                            teacher.name.isNotEmpty ? teacher.name[0].toUpperCase() : 'T',
                            style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.grey[600]),
                          ),
                        ),
                ),
              ),
              if (teacher.isOnline)
                Positioned(
                  bottom: 4,
                  right: 4,
                  child: Container(
                    width: 14,
                    height: 14,
                    decoration: BoxDecoration(
                      color: const Color(0xFF00C853), // Online green
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  teacher.name,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                if (isAdminView && teacher.phoneNumber != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Row(
                      children: [
                        const Icon(Icons.phone_android_rounded, size: 14, color: Color(0xFF009688)),
                        const SizedBox(width: 4),
                        Text(
                          teacher.phoneNumber!,
                          style: const TextStyle(
                            color: Color(0xFF009688),
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                const SizedBox(height: 4),
                Text(
                  teacher.title,
                  style: TextStyle(
                    color: const Color(0xFF009688), // Teal color
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                if (teacher.price != null && teacher.price! > 0)
                  Wrap(
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      const Icon(Icons.star_rounded, color: Colors.amber, size: 18),
                      const SizedBox(width: 4),
                      Text(
                        teacher.rating.toString(),
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '(${teacher.lessonsCount} lessons)', // Using lessonsCount as a proxy or if reviewCount is added to model use that
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
