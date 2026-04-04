// lib/models/session_model.dart

enum SessionStatus { pending, accepted, rejected }

class SessionRequest {
  final String id;
  final String studentName;
  final String studentRole;
  final String dateTime;
  final String duration;
  final SessionStatus status;
  final String topic;
  final String avatarInitials;
  final int avatarColorIndex;

  const SessionRequest({
    required this.id,
    required this.studentName,
    required this.studentRole,
    required this.dateTime,
    required this.duration,
    required this.status,
    required this.topic,
    required this.avatarInitials,
    required this.avatarColorIndex,
  });

  factory SessionRequest.fromJson(Map<String, dynamic> json) {
    return SessionRequest(
      id: json['id'] ?? json['_id'],
      studentName: json['studentName'],
      studentRole: json['studentRole'],
      dateTime: json['dateTime'],
      duration: json['duration'],
      status: SessionStatus.values.byName(json['status'] ?? 'pending'),
      topic: json['topic'],
      avatarInitials: json['avatarInitials'] ?? '',
      avatarColorIndex: json['avatarColorIndex'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'studentName': studentName,
      'studentRole': studentRole,
      'dateTime': dateTime,
      'duration': duration,
      'status': status.name,
      'topic': topic,
      'avatarInitials': avatarInitials,
      'avatarColorIndex': avatarColorIndex,
    };
  }
}
