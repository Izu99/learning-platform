class Teacher {
  final String id;
  final String name;
  final String email;
  final String status;

  Teacher({
    required this.id,
    required this.name,
    required this.email,
    required this.status,
  });

  factory Teacher.fromJson(Map<String, dynamic> json) {
    return Teacher(
      id: json['_id'] ?? json['id'],
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      status: json['status'] ?? 'pending',
    );
  }
}
