import '../../../../models/school_models.dart';
import '../../../../services/database_service.dart';
import '../../domain/entities/attendance.dart';
import '../../domain/repositories/i_attendance_repository.dart';

class AttendanceRepositoryImpl implements IAttendanceRepository {
  final DatabaseService _dbService;

  AttendanceRepositoryImpl(this._dbService);

  @override
  Future<List<AttendanceEntity>> getAttendanceForDate(DateTime date) async {
    return _dbService.attendanceRecords
        .where((r) =>
            r.date.year == date.year &&
            r.date.month == date.month &&
            r.date.day == date.day)
        .map((r) => AttendanceEntity(
              id: r.id,
              studentId: r.studentId,
              date: r.date,
              status: r.status,
              takenBy: r.takenBy,
            ))
        .toList();
  }

  @override
  Future<List<AttendanceEntity>> getAllAttendance() async {
    return _dbService.attendanceRecords
        .map((r) => AttendanceEntity(
              id: r.id,
              studentId: r.studentId,
              date: r.date,
              status: r.status,
              takenBy: r.takenBy,
            ))
        .toList();
  }

  @override
  Future<void> saveAttendance(List<AttendanceEntity> records) async {
    for (var entity in records) {
      final record = Attendance(
        id: entity.id,
        studentId: entity.studentId,
        date: entity.date,
        status: entity.status,
        takenBy: entity.takenBy,
      );

      final index = _dbService.attendanceRecords.indexWhere((r) =>
          r.studentId == record.studentId &&
          r.date.year == record.date.year &&
          r.date.month == record.date.month &&
          r.date.day == record.date.day);

      if (index != -1) {
        _dbService.attendanceRecords[index] = record;
      } else {
        _dbService.attendanceRecords.add(record);
      }
    }
  }
}
