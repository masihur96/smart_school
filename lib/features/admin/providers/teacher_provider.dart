import 'dart:developer';
import 'package:flutter/material.dart';
import '../../../models/teacher_model.dart';
import '../../../services/database_service.dart';
import '../../../core/utils/storage_service.dart';
import '../../../configs/network/data_provider.dart';
import '../../../core/constants/api_path.dart';

class TeachersNotifier extends ChangeNotifier {
  final DatabaseService _dbService;
  List<Teacher> _state = [];
  bool _isLoading = false;

  TeachersNotifier(this._dbService) {
    _state = [..._dbService.teachers];
  }

  List<Teacher> get teachers => _state;
  bool get isLoading => _isLoading;

  Future<void> addTeacherToAPI({
    required String name,
    required String email,
    required String password,
    required String schoolId,
    required String phone,
    required String classId,
    required String sectionId,
    required String designation,
  }) async {
    _isLoading = true;
    notifyListeners();

    try {
      final token = await StorageService.getToken();
      if (token == null) throw Exception('No auth token found');

      final data = {
        "name": name,
        "email": email,
        "password": password,
        "role": "teacher",
        "schoolId": schoolId,
        "phone": phone,
        "classId": classId,
        "sectionId": sectionId,
        "designation": designation,
        "isActive": true
      };

      final response = await DataProvider().performRequest(
        'POST',
        APIPath.register,
        data: data,
        header: {'Authorization': 'Bearer $token'},
      );

      if (response != null && (response.statusCode == 200 || response.statusCode == 201)) {
        log('Successfully created teacher');
        // Ideally we should add the teacher to the local state here or refresh the list
      } else {
        log('Error creating teacher: ${response?.data}');
        throw Exception('Failed to create teacher: ${response?.data}');
      }
    } catch (e) {
      log('Error creating teacher: $e');
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void addTeacher(Teacher teacher) {
    _dbService.teachers.add(teacher);
    _state = [..._dbService.teachers];
    notifyListeners();
  }

  void updateTeacher(Teacher teacher) {
    final index = _dbService.teachers.indexWhere(
      (t) => t.userId == teacher.userId,
    );
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
