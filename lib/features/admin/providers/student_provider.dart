import 'package:flutter/material.dart';
import '../../../models/student_model.dart';
import '../../../services/database_service.dart';

class StudentsNotifier extends ChangeNotifier {
  final DatabaseService _dbService;
  List<Student> _students = [];

  StudentsNotifier(this._dbService) {
    _students = [..._dbService.students];
  }

  List<Student> get students => _students;

  void addStudent(Student student) {
    _dbService.students.add(student);
    _students = [..._dbService.students];
    notifyListeners();
  }

  void updateStudent(Student student) {
    final index = _dbService.students.indexWhere(
      (s) => s.userId == student.userId,
    );
    if (index != -1) {
      _dbService.students[index] = student;
      _students = [..._dbService.students];
      notifyListeners();
    }
  }

  void toggleStudentStatus(String userId) {
    final index = _dbService.students.indexWhere((s) => s.userId == userId);
    if (index != -1) {
      final student = _students[index];
      _dbService.students[index] = Student(
        userId: student.userId,
        rollId: student.rollId,
        classId: student.classId,
        sectionId: student.sectionId,
        guardianContact: student.guardianContact,
        isActive: !student.isActive,
        user: student.user,
      );
      _students[index] = _dbService.students[index];
      notifyListeners();
    }
  }
}
