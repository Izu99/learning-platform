class Booking {
  final String id;
  final String studentId;
  final String teacherId;
  final String? teacherName; // Populated from backend
  final String topic;
  final String scheduledTime;
  final String? suggestedTime;
  final String status;
  final String? notes;
  final String? meetingLink;
  final String? meetingPassword;
  final String? teacherProfileImageUrl;
  final String? studentName;
  final String? studentProfileImageUrl;
  final List<String>? studentInterests; // Added for teacher view
  final String? studentLevel; // Added for teacher view
  final String? rescheduledBy; // 'teacher' or 'student'

  Booking({
    required this.id,
    required this.studentId,
    required this.teacherId,
    this.teacherName,
    required this.topic,
    required this.scheduledTime,
    this.suggestedTime,
    required this.status,
    this.notes,
    this.meetingLink,
    this.meetingPassword,
    this.teacherProfileImageUrl,
    this.studentName,
    this.studentProfileImageUrl,
    this.studentInterests,
    this.studentLevel,
    this.rescheduledBy,
  });

  factory Booking.fromJson(Map<String, dynamic> json) {
    // Handle populated teacher data
    final teacherData = json['teacherId'];
    String? teacherName;
    String? teacherImageUrl;
    if (teacherData is Map<String, dynamic>) {
      teacherName = teacherData['name'];
      teacherImageUrl = teacherData['profileImageUrl'];
    }

    final studentData = json['studentId'];
    String? studentName;
    String? studentImageUrl;
    List<String>? studentInterests;
    String? studentLevel;
    if (studentData is Map<String, dynamic>) {
      studentName = studentData['name'];
      studentImageUrl = studentData['profileImageUrl'];
      studentInterests = json['studentId']['interests'] != null ? List<String>.from(json['studentId']['interests']) : null;
      studentLevel = json['studentId']['level'];
    }

    return Booking(
      id: (json['_id'] ?? json['id']).toString(),
      studentId: (studentData is Map ? (studentData['_id'] ?? studentData['id']) : studentData).toString(),
      teacherId: (teacherData is Map ? (teacherData['_id'] ?? teacherData['id']) : teacherData).toString(),
      teacherName: teacherName,
      topic: json['topic'] ?? 'N/A',
      scheduledTime: json['scheduledTime'] ?? 'N/A',
      suggestedTime: json['suggestedTime'],
      status: json['status'] ?? 'Unknown',
      notes: json['notes'],
      meetingLink: json['meetingLink'],
      meetingPassword: json['meetingPassword'],
      teacherProfileImageUrl: teacherImageUrl,
      studentName: studentName,
      studentProfileImageUrl: studentImageUrl,
      studentInterests: studentInterests,
      studentLevel: studentLevel,
      rescheduledBy: json['rescheduledBy'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'studentId': studentId,
      'teacherId': teacherId,
      'teacherName': teacherName,
      'topic': topic,
      'scheduledTime': scheduledTime,
      'suggestedTime': suggestedTime,
      'status': status,
      'notes': notes,
      'meetingLink': meetingLink,
      'meetingPassword': meetingPassword,
      'teacherProfileImageUrl': teacherProfileImageUrl,
      'studentName': studentName,
      'studentProfileImageUrl': studentProfileImageUrl,
      'studentInterests': studentInterests,
      'studentLevel': studentLevel,
      'rescheduledBy': rescheduledBy,
    };
  }
}
