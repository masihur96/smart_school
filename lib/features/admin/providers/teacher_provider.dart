import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:smart_school/models/user_model.dart';
import '../../../models/teacher_model.dart';
import '../../../services/database_service.dart';
import '../../../core/utils/storage_service.dart';
import '../../../configs/network/data_provider.dart';
import '../../../core/constants/api_path.dart';

class TeachersNotifier extends ChangeNotifier {
  final DatabaseService _dbService;
  List<Teacher> _teachers = [];
  bool _isLoading = false;
  int _currentPage = 1;
  bool _hasMore = true;
  bool _isLoadingMore = false;
  int _totalCount = 0;

  TeachersNotifier(this._dbService) {
    _teachers = [..._dbService.teachers];
  }

  List<Teacher> get teachers => _teachers;
  bool get isLoading => _isLoading;
  bool get hasMore => _hasMore;
  bool get isLoadingMore => _isLoadingMore;
  int get totalCount => _totalCount;

  Future<void> fetchTeachers({
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
        'role': 'teacher',
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
        final dynamic rawData = response.data['data'];
        final List<dynamic> data = rawData is List
            ? rawData
            : (rawData is Map ? (rawData['data'] ?? []) : []);
        
        final responseTotal = rawData is Map && rawData['total'] != null 
            ? int.tryParse(rawData['total'].toString()) ?? 0 
            : data.length;
        
        _totalCount = responseTotal;

        if (data.length < 10 || (loadMore && _teachers.length + data.length >= responseTotal)) {
          _hasMore = false;
        }

        if (!loadMore) {
          _dbService.teachers.clear();
        }

        for (var item in data) {
          try {
             _dbService.teachers.add(Teacher.fromJson(item));
          } catch(e) {
             log("Error parsing teacher: $e");
          }
        }
        _teachers = [..._dbService.teachers];
      } else {
        log("Error fetching teachers: ${response?.data}");
        _hasMore = false;
      }
    } catch (e) {
      log("Error fetching teachers: $e");
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

  Future<void> toggleTeacherStatus(String userId) async {
    final index = _dbService.teachers.indexWhere((t) => t.userId == userId);
    if (index != -1) {
      final teacher = _teachers[index];
      final newStatus = !teacher.isActive;

      _isLoading = true;
      notifyListeners();

      try {
        final token = await StorageService.getToken();
        if (token == null) throw Exception('No auth token found');

        final response = await DataProvider().performRequest(
          'PUT',
          '${APIPath.fetchUsers}/$userId',
          data: {'isActive': newStatus},
          header: {'Authorization': 'Bearer $token'},
        );

        if (response != null && response.statusCode == 200) {
          final updatedTeacher = Teacher(
            userId: teacher.userId,
            designation: teacher.designation,
            classId: teacher.classId,
            sectionId: teacher.sectionId,
            isActive: newStatus,
            assignedSubjects: teacher.assignedSubjects,
            user: teacher.user,
          );
          _dbService.teachers[index] = updatedTeacher;
          _teachers = [..._dbService.teachers];
        } else {
          log("Error toggling teacher status: ${response?.data}");
        }
      } catch (e) {
        log("Error toggling teacher status: $e");
      } finally {
        _isLoading = false;
        notifyListeners();
      }
    }
  }

  Future<void> deleteTeacher(String userId) async {
    _isLoading = true;
    notifyListeners();

    try {
      final token = await StorageService.getToken();
      if (token == null) throw Exception('No auth token found');

      final response = await DataProvider().performRequest(
        'DELETE',
        '${APIPath.fetchUsers}/$userId',
        header: {'Authorization': 'Bearer $token'},
      );

      if (response != null && (response.statusCode == 200 || response.statusCode == 204)) {
        _dbService.teachers.removeWhere((t) => t.userId == userId);
        _teachers = [..._dbService.teachers];
      } else {
        log("Error deleting teacher: ${response?.data}");
      }
    } catch (e) {
      log("Error deleting teacher: $e");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> addTeacherToAPI({
    required String name,
    required String email,
    required String password,
    required String schoolId,
    required String phone,
    required String classId,
    required String sectionId,
    required String designation,
    double? lat,
    double? lon,
    double? radius,
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
        "isActive": true,
        if (lat != null) "lat": lat,
        if (lon != null) "lon": lon,
        if (radius != null) "radius": radius,
      };

      final response = await DataProvider().performRequest(
        'POST',
        APIPath.register,
        data: data,
        header: {'Authorization': 'Bearer $token'},
      );

      if (response != null && (response.statusCode == 200 || response.statusCode == 201)) {
        log('Successfully created teacher');
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

  void updateTeacher(Teacher teacher) {
    final index = _dbService.teachers.indexWhere(
      (t) => t.userId == teacher.userId,
    );
    if (index != -1) {
      _dbService.teachers[index] = teacher;
      _teachers = [..._dbService.teachers];
      notifyListeners();
    }
  }

  void removeTeacher(String userId) {
    _dbService.teachers.removeWhere((t) => t.userId == userId);
    _teachers = [..._dbService.teachers];
    notifyListeners();
  }
  Future<void> updateTeacherOnAPI({
    required String userId,
    required String name,
    required String email,
    required String phone,
    required String classId,
    required String sectionId,
    required String designation,
    double? lat,
    double? lon,
    double? radius,
  }) async {
    _isLoading = true;
    notifyListeners();

    try {
      final token = await StorageService.getToken();
      if (token == null) throw Exception('No auth token found');

      final data = {
        "name": name,
        "email": email,
        "phone": phone,
        "classId": classId,
        "sectionId": sectionId,
        "designation": designation,
        if (lat != null) "lat": lat,
        if (lon != null) "lon": lon,
        if (radius != null) "radius": radius,
      };

      final response = await DataProvider().performRequest(
        'PUT',
        '${APIPath.fetchUsers}/$userId',
        data: data,
        header: {'Authorization': 'Bearer $token'},
      );

      if (response != null && response.statusCode == 200) {
        log('Successfully updated teacher');
        final index = _dbService.teachers.indexWhere((t) => t.userId == userId);
        if (index != -1) {
          final oldTeacher = _dbService.teachers[index];
          final updatedTeacher = Teacher(
            userId: userId,
            designation: designation,
            classId: classId,
            sectionId: sectionId,
            isActive: oldTeacher.isActive,
            assignedSubjects: oldTeacher.assignedSubjects,
            lat: lat,
            lon: lon,
            radius: radius,
            user: User(
              id: userId,
              name: name,
              email: email,
              role: UserRole.teacher,
              phone: phone,
              schoolId: oldTeacher.user?.schoolId,
            ),
          );
          _dbService.teachers[index] = updatedTeacher;
          _teachers = [..._dbService.teachers];
        }
      } else {
        log('Error updating teacher: ${response?.data}');
        throw Exception('Failed to update teacher: ${response?.data}');
      }
    } catch (e) {
      log('Error updating teacher: $e');
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
