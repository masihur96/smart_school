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
  bool _isLoading = false;
  int _currentPage = 1;
  bool _hasMore = true;
  bool _isLoadingMore = false;

  StudentsNotifier(this._dbService) {
    _students = [..._dbService.students];
  }

  List<Student> get students => _students;
  bool get isLoading => _isLoading;
  bool get hasMore => _hasMore;
  bool get isLoadingMore => _isLoadingMore;

  Future<void> fetchStudents({String? classId, String? sectionId, bool loadMore = false}) async {
    if (loadMore) {
      if (_isLoadingMore || !_hasMore) return;
      _isLoadingMore = true;
      _currentPage++;
    } else {
      _isLoading = true;
      _currentPage = 1;
      _hasMore = true;
    }
    notifyListeners();

    try {
      final token = await StorageService.getToken();
      if (token == null) throw Exception('No auth token found');

      final Map<String, dynamic> query = {
        'role': 'student',
        'page': _currentPage.toString(),
        'limit': '10',
      };
      if (classId != null && classId.isNotEmpty) query['classId'] = classId;
      if (sectionId != null && sectionId.isNotEmpty) query['sectionId'] = sectionId;

      final response = await DataProvider().performRequest(
        'GET',
        APIPath.fetchUsers,
        query: query,
        header: {'Authorization': 'Bearer $token'},
      );

      if (response != null && response.statusCode == 200) {
        final List<dynamic> data = response.data is List
            ? response.data
            : (response.data['data'] ?? response.data['users'] ?? []);
        
        if (data.length < 10) {
          _hasMore = false;
        }

        if (!loadMore) {
          _dbService.students.clear();
        }

        for (var item in data) {
          try {
             _dbService.students.add(Student.fromJson(item));
          } catch(e) {
             log("Error parsing student: $e");
          }
        }
        _students = [..._dbService.students];
      } else {
        log("Error fetching students: ${response?.data}");
        _hasMore = false;
      }
    } catch (e) {
      log("Error fetching students: $e");
      _hasMore = false;
    } finally {
      if (loadMore) {
        _isLoadingMore = false;
      } else {
        _isLoading = false;
      }
      notifyListeners();
    }
  }



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

  Future<void> updateStudentToAPI({
    required String userId,
    required String name,
    required String email,
    String? password, // optional for update
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
      "phone": phone,
      "classId": classId,
      "sectionId": sectionId,
      "rollNumber": rollNumber,
      "designation": designation,
    };
    if (password != null && password.isNotEmpty) {
      data["password"] = password;
    }

    final response = await DataProvider().performRequest(
      'PATCH',
      '${APIPath.register}/$userId',
      data: data,
      header: {'Authorization': 'Bearer $token'},
    );

    if (response != null && response.statusCode == 200) {
      log('Successfully updated student');
    } else {
      log('Error updating student: ${response?.data}');
      throw Exception('Failed to update student: ${response?.data}');
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

  Future<void> toggleStudentStatus(String userId) async {
    final index = _dbService.students.indexWhere((s) => s.userId == userId);
    if (index != -1) {
      final student = _students[index];
      final newStatus = !student.isActive;

      _isLoading = true;
      notifyListeners();

      try {
        final token = await StorageService.getToken();
        if (token == null) throw Exception('No auth token found');

        // We assume PATCH /users/:id to update status
        final response = await DataProvider().performRequest(
          'PATCH',
          '${APIPath.register}/$userId',
          data: {'isActive': newStatus},
          header: {'Authorization': 'Bearer $token'},
        );

        if (response != null && response.statusCode == 200) {
          _dbService.students[index] = Student(
            userId: student.userId,
            rollId: student.rollId,
            classId: student.classId,
            sectionId: student.sectionId,
            guardianContact: student.guardianContact,
            isActive: newStatus,
            user: student.user,
          );
          _students[index] = _dbService.students[index];
        } else {
          log("Error toggling student status: ${response?.data}");
        }
      } catch (e) {
        log("Error toggling student status: $e");
      } finally {
        _isLoading = false;
        notifyListeners();
      }
    }
  }

  Future<void> deleteStudent(String userId) async {
    _isLoading = true;
    notifyListeners();

    try {
      final token = await StorageService.getToken();
      if (token == null) throw Exception('No auth token found');

      final response = await DataProvider().performRequest(
        'DELETE',
        '${APIPath.register}/$userId',
        header: {'Authorization': 'Bearer $token'},
      );

      if (response != null && (response.statusCode == 200 || response.statusCode == 204)) {
        _dbService.students.removeWhere((s) => s.userId == userId);
        _students = [..._dbService.students];
      } else {
        log("Error deleting student: ${response?.data}");
      }
    } catch (e) {
      log("Error deleting student: $e");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
