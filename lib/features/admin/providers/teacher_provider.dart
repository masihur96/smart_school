import 'package:flutter/material.dart';
import '../../../models/teacher_model.dart';
import '../../../services/database_service.dart';

class TeachersNotifier extends ChangeNotifier {
  final DatabaseService _dbService;
  List<Teacher> _state = [];

  TeachersNotifier(this._dbService) {
    _state = [..._dbService.teachers];
  }

  List<Teacher> get teachers => _state;

  void addTeacher(Teacher teacher) {
    _dbService.teachers.add(teacher);
    _state = [..._dbService.teachers];
    notifyListeners();
  }

  void updateTeacher(Teacher teacher) {
    final index = _dbService.teachers.indexWhere((t) => t.userId == teacher.userId);
    if (index != -1) {
      _dbService.teachers[index] = teacher;
      _state = [..._dbService.teachers];
      notifyListeners();
    }
  }

  void removeTeacher(String userId) {
    _dbService.teachers.removeWhere((t) => t.userId == userId);
    _state = [..._dbService.teachers];
    notifyListeners();
  }
}
