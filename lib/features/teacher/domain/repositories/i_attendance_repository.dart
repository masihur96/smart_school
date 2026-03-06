import '../entities/attendance.dart';

abstract class IAttendanceRepository {
  Future<List<AttendanceEntity>> getAttendanceForDate(DateTime date);
  Future<List<AttendanceEntity>> getAllAttendance();
  Future<void> saveAttendance(List<AttendanceEntity> records);
}
