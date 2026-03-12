import 'package:flutter/material.dart';
import '../domain/entities/attendance.dart';
import '../domain/repositories/i_attendance_repository.dart';

class AttendanceNotifier extends ChangeNotifier {
  final IAttendanceRepository _repository;
  List<AttendanceEntity> _state = [];

  AttendanceNotifier(this._repository) {
    _load(DateTime.now());
  }

  List<AttendanceEntity> get state => _state;

  Future<void> _load(DateTime date) async {
    _state = await _repository.getAttendanceForDate(date);
    notifyListeners();
  }

  Future<void> loadAll() async {
    _state = await _repository.getAllAttendance();
    notifyListeners();
  }

  Future<void> saveAttendance(List<AttendanceEntity> records) async {
    await _repository.saveAttendance(records);
    if (records.isNotEmpty) {
      await _load(records.first.date);
    }
  }

  List<AttendanceEntity> getRecordsForDate(DateTime date) {
    return _state.where((r) => 
      r.date.year == date.year && 
      r.date.month == date.month && 
      r.date.day == date.day
    ).toList();
  }
}
