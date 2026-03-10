import 'package:smart_school/models/school_models.dart';


class AttendanceEntity {
  final String id;
  final String studentId;
  final DateTime date;
  final AttendanceStatus status;
  final String takenBy; // teacher id

  AttendanceEntity({
    required this.id,
    required this.studentId,
    required this.date,
    required this.status,
    required this.takenBy,
  });

  // Entities should not have toJson/fromJson ideally if we strictly separate layers,
  // but for simplicity in this transition, we might keep them or use data models.
}
