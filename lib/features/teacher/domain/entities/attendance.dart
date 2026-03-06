class AttendanceEntity {
  final String id;
  final String studentId;
  final DateTime date;
  final bool isPresent;
  final String takenBy; // teacher id

  AttendanceEntity({
    required this.id,
    required this.studentId,
    required this.date,
    required this.isPresent,
    required this.takenBy,
  });

  // Entities should not have toJson/fromJson ideally if we strictly separate layers,
  // but for simplicity in this transition, we might keep them or use data models.
}
