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
  int _totalCount = 0;

  StudentsNotifier(this._dbService) {
    _students = [..._dbService.students];
  }

  List<Student> get students => _students;
  bool get isLoading => _isLoading;
  bool get hasMore => _hasMore;
  bool get isLoadingMore => _isLoadingMore;
  int get totalCount => _totalCount;

  Future<void> fetchStudents({
    String? classId, 
    String? sectionId, 
    bool? isActive,
    bool loadMore = false
  }) async {
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
      if (isActive != null) query['isActive'] = isActive.toString();

      final response = await DataProvider().performRequest(
        'GET',
        APIPath.fetchUsers,
        query: query,
        header: {'Authorization': 'Bearer $token'},
      );



      if (response != null && response.statusCode == 200) {
        print("Student Query:: ${response.data}");
        // API response structure: { data: { total, page, limit, data: [...] } }
        final inner = response.data is Map ? response.data['data'] : response.data;
        final List<dynamic> data = inner is List
            ? inner
            : (inner is Map ? (inner['data'] as List<dynamic>? ?? []) : []);
        
        print("Extracted Data Length: ${data.length}");

        final responseTotal = (inner is Map && inner['total'] != null)
            ? int.tryParse(inner['total'].toString()) ?? 0
            : data.length;
        
        _totalCount = responseTotal;
        
        if (data.length < 10 || (loadMore && _students.length + data.length >= responseTotal)) {
          _hasMore = false;
        }

        if (!loadMore) {
          _dbService.students.clear();
        }

        for (var item in data) {
          try {
             print("Parsing student item: $item");
             final parsedStudent = Student.fromJson(item);
             print("Parsed Student: classId=${parsedStudent.classId}");
             _dbService.students.add(parsedStudent);
          } catch(e, stacktrace) {
             print("Error parsing student: $e");
             print("Stacktrace: $stacktrace");
          }
        }
        _students = [..._dbService.students];
        print("Total students in notifier: ${_students.length}. Provided classId: $classId");
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
      'PUT',
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

        // Based on the request, update endpoint is /users/:id (APIPath.fetchUsers + /id)
        final response = await DataProvider().performRequest(
          'PUT',
          '${APIPath.fetchUsers}/$userId',
          data: {'isActive': newStatus},
          header: {'Authorization': 'Bearer $token'},
        );

        if (response != null && response.statusCode == 200) {
          final updatedStudent = Student(
            userId: student.userId,
            rollId: student.rollId,
            classId: student.classId,
            sectionId: student.sectionId,
            guardianContact: student.guardianContact,
            isActive: newStatus,
            user: student.user,
          );
          _dbService.students[index] = updatedStudent;
          _students = [..._dbService.students];
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
