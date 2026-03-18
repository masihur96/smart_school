import 'dart:developer';
import 'package:flutter/material.dart';
import '../../../models/student_model.dart';
import '../../../services/database_service.dart';
import 'package:smart_school/core/utils/storage_service.dart';
import '../../../configs/network/data_provider.dart';
import '../../../core/constants/api_path.dart';

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

  Future<void> addStudentToAPI({
    required String name,
    required String email,
    required String password,
    required String role,
    required String schoolId,
    required String phone,
    required String classId,
    required String sectionId,
    required String rollNumber,
    required String designation,
  }) async {
    final token = await StorageService.getToken();
    if (token == null) throw Exception('No auth token found');

    final data = {
      "name": name,
      "email": email,
      "password": password,
      "role": role,
      "schoolId": schoolId,
      "phone": phone,
      "classId": classId,
      "sectionId": sectionId,
      "rollNumber": rollNumber,
      "designation": designation,
    };

    final response = await DataProvider().performRequest(
      'POST',
      APIPath.register,
      data: data,
      header: {'Authorization': 'Bearer $token'},
    );

    if (response != null &&
        (response.statusCode == 200 || response.statusCode == 201)) {
      log('Successfully created student');
      // For now we just add it to the local db via basic mock object or wait for fetch.
      // E.g., addStudent(Student(...)) if needed
    } else {
      log('Error creating student: ${response?.data}');
      throw Exception('Failed to create student: ${response?.data}');
    }
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
