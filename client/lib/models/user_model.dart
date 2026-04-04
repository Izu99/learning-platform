class User {
  final String id;
  final String name;
  final String email;
  final String role;
  final List<String>? interests;
  final String? level;
  final String? profileImageUrl;
  final String? instagramHandle; // Added field
  final String? registrationDate; // Added field
  final String? phoneNumber; // Added field

  User({
    required this.id, 
    required this.name, 
    required this.email, 
    required this.role,
    this.interests,
    this.level,
    this.profileImageUrl,
    this.instagramHandle, // Added to constructor
    this.registrationDate, // Added to constructor
    this.phoneNumber, // Added to constructor
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: (json['id'] ?? json['_id'] ?? '').toString(),
      name: json['name']?.toString() ?? 'Unknown User',
      email: json['email']?.toString() ?? '',
      role: json['role']?.toString() ?? 'student',
      interests: (json['interests'] as List?)?.map((e) => e.toString()).toList(),
      level: json['level']?.toString(),
      profileImageUrl: json['profileImageUrl']?.toString(),
      instagramHandle: json['instagramHandle']?.toString(), // Added fromJson mapping
      registrationDate: json['registrationDate']?.toString(), // Added fromJson mapping
      phoneNumber: json['phoneNumber']?.toString(), // Added fromJson mapping
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'role': role,
      'interests': interests,
      'level': level,
      'profileImageUrl': profileImageUrl,
      'instagramHandle': instagramHandle, // Added toJson mapping
      'registrationDate': registrationDate, // Added toJson mapping
      'phoneNumber': phoneNumber, // Added toJson mapping
    };
  }
}
