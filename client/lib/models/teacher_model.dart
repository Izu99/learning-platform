// lib/models/teacher_model.dart

class Teacher {
  final String id;
  final String name;
  final String title;
  final String location;
  final double rating;
  final int studentsCount;
  final int lessonsCount;
  final int hoursCount;
  final int experienceYears;
  final bool isVerified;
  final bool isOnline;
  final String about;
  final List<String> tags;
  final List<String> availability;
  final List<TimeSlot> timeSlots;
  final List<String> sessionTopics;
  final List<Qualification>? qualifications;
  final double? price;
  final String? profileImageUrl;
  final String? status; 
  final String? email; 
  final String? phoneNumber; // Added field
  final String? profileId; // Added for admin operations

  const Teacher({
    required this.id,
    required this.name,
    required this.title,
    required this.location,
    required this.rating,
    required this.studentsCount,
    required this.lessonsCount,
    required this.hoursCount,
    required this.experienceYears,
    required this.isVerified,
    required this.isOnline,
    required this.about,
    required this.tags,
    required this.availability,
    required this.timeSlots,
    required this.sessionTopics,
    this.qualifications,
    this.price,
    this.profileImageUrl,
    this.status,
    this.email, 
    this.phoneNumber, // Added field
    this.profileId, // Added for admin operations
  });

  String get fullName => name; // Added getter for admin screen compatibility

  factory Teacher.fromJson(Map<String, dynamic> json) {
    // Collect all slots across all availability groups
    final List<TimeSlot> flatSlots = [];
    if (json['availability'] is List) {
      for (var dayGroup in json['availability']) {
        if (dayGroup is Map && dayGroup['slots'] is List) {
          final String day = (dayGroup['date'] ?? dayGroup['day'] ?? '').toString();
          for (var slot in dayGroup['slots']) {
            if (slot is Map && slot['start'] != null && slot['end'] != null) {
              // Add the slot as the FULL time range (e.g., 12:30 - 04:30)
              _addFullTimeSlot(flatSlots, day, slot['start'], slot['end'], slot['available'] == true);
            }
          }
        }
      }
    }

    return Teacher(
      id: (json['id'] ?? json['_id'] ?? '').toString(),
      name: json['name']?.toString() ?? 'Unknown User',
      title: json['title']?.toString() ?? json['level']?.toString() ?? 'User',
      location: json['location']?.toString() ?? 'Remote',
      rating: (json['rating'] as num?)?.toDouble() ?? 0.0,
      studentsCount: (json['studentsCount'] as num?)?.toInt() ?? 0,
      lessonsCount: (json['lessonsCount'] as num?)?.toInt() ?? 0,
      hoursCount: (json['hoursCount'] as num?)?.toInt() ?? 0,
      experienceYears: (json['experienceYears'] as num?)?.toInt() ?? 0,
      isVerified: json['isVerified'] == true,
      isOnline: json['isOnline'] == true,
      about: json['about']?.toString() ?? json['bio']?.toString() ?? '',
      tags: (json['tags'] as List?)?.map((e) => e.toString()).toList() ?? 
            (json['interests'] as List?)?.map((e) => e.toString()).toList() ?? [],
      availability: (json['availability'] as List?)?.map((e) => e.toString()).toList() ?? [],
      timeSlots: flatSlots,
      sessionTopics: (json['sessionTopics'] as List?)?.map((e) => e.toString()).toList() ?? [],
      qualifications: (json['qualifications'] as List?)?.map((e) => Qualification.fromJson(e)).toList(),
      price: (json['price'] as num?)?.toDouble(),
      profileImageUrl: json['profileImageUrl']?.toString(),
      status: json['status']?.toString(), 
      email: json['email']?.toString() ?? (json['userId'] is Map ? json['userId']['email']?.toString() : null), 
      phoneNumber: json['phoneNumber']?.toString() ?? (json['userId'] is Map ? json['userId']['phoneNumber']?.toString() : null), // Added fromJson mapping
      profileId: json['profileId']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'title': title,
      'location': location,
      'rating': rating,
      'studentsCount': studentsCount,
      'lessonsCount': lessonsCount,
      'hoursCount': hoursCount,
      'experienceYears': experienceYears,
      'isVerified': isVerified,
      'isOnline': isOnline,
      'about': about,
      'tags': tags,
      'availability': availability,
      'timeSlots': timeSlots.map((e) => e.toJson()).toList(),
      'sessionTopics': sessionTopics,
      'qualifications': qualifications?.map((e) => e.toJson()).toList(),
      'price': price,
      'profileImageUrl': profileImageUrl,
      'status': status,
      'email': email, 
      'phoneNumber': phoneNumber, // Added toJson mapping
      'profileId': profileId,
    };
  }

  static void _addFullTimeSlot(List<TimeSlot> flatSlots, String day, String start, String end, bool available) {
    flatSlots.add(TimeSlot(
      label: '$start - $end', 
      start: start, 
      end: end, 
      available: available, 
      day: day
    ));
  }
}

class Qualification {
  final String title;
  final String institution;

  const Qualification({required this.title, required this.institution});

  factory Qualification.fromJson(Map<String, dynamic> json) {
    return Qualification(
      title: json['title'] ?? '',
      institution: json['institution'] ?? '',
    );
  }

  Map<String, dynamic> toJson() => {'title': title, 'institution': institution};
}

class TimeSlot {
  final String label;
  final String start;
  final String end;
  final bool available;
  final String? day; // Added day mapping

  const TimeSlot({
    required this.label,
    required this.start,
    required this.end,
    required this.available,
    this.day,
  });

  factory TimeSlot.fromJson(Map<String, dynamic> json) {
    return TimeSlot(
      label: json['label']?.toString() ?? '${json['start']} - ${json['end']}',
      start: json['start']?.toString() ?? '',
      end: json['end']?.toString() ?? '',
      available: json['available'] == true,
      day: json['day']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'label': label,
      'start': start,
      'end': end,
      'available': available,
      'day': day,
    };
  }
}
