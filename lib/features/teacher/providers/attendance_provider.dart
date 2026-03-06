import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/entities/attendance.dart';
import '../domain/repositories/i_attendance_repository.dart';
import '../data/repositories/attendance_repository_impl.dart';
import '../../admin/providers/student_provider.dart';

final attendanceRepositoryProvider = Provider<IAttendanceRepository>((ref) {
  final dbService = ref.watch(databaseServiceProvider);
  return AttendanceRepositoryImpl(dbService);
});

final attendanceProvider = NotifierProvider<AttendanceNotifier, List<AttendanceEntity>>(() {
  return AttendanceNotifier();
});

class AttendanceNotifier extends Notifier<List<AttendanceEntity>> {
  late final IAttendanceRepository _repository;

  @override
  List<AttendanceEntity> build() {
    _repository = ref.watch(attendanceRepositoryProvider);
    _load(DateTime.now());
    return [];
  }

  Future<void> _load(DateTime date) async {
    state = await _repository.getAttendanceForDate(date);
  }

  Future<void> loadAll() async {
    state = await _repository.getAllAttendance();
  }

  Future<void> saveAttendance(List<AttendanceEntity> records) async {
    await _repository.saveAttendance(records);
    await _load(DateTime.now());
  }

  List<AttendanceEntity> getRecordsForDate(DateTime date) {
    return state.where((r) => 
      r.date.year == date.year && 
      r.date.month == date.month && 
      r.date.day == date.day
    ).toList();
  }
}
