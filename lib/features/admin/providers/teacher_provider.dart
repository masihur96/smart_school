import 'dart:developer';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:smart_school/models/user_model.dart';

import '../../../configs/network/data_provider.dart';
import '../../../core/constants/api_path.dart';
import '../../../core/utils/storage_service.dart';
import '../../../models/teacher_model.dart';
import '../../../services/database_service.dart';

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
    bool loadMore = false,
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
      if (sectionId != null && sectionId.isNotEmpty)
        query['sectionId'] = sectionId;
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

        if (data.length < 10 ||
            (loadMore && _teachers.length + data.length >= responseTotal)) {
          _hasMore = false;
        }

        if (!loadMore) {
          _dbService.teachers.clear();
        }

        for (var item in data) {
          try {
            final teacher = Teacher.fromJson(item);
            if (!teacher.isDeleted) {
              _dbService.teachers.add(teacher);
            }
          } catch (e) {
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
            embeddedClasses: teacher.embeddedClasses,
            embeddedSections: teacher.embeddedSections,
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

      if (response != null &&
          (response.statusCode == 200 || response.statusCode == 204)) {
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

    required String designation,
    double? lat,
    double? lon,
    double? radius,
    File? imageFile,
  }) async {
    _isLoading = true;
    notifyListeners();

    try {
      final token = await StorageService.getToken();
      if (token == null) throw Exception('No auth token found');

      final Map<String, dynamic> dataMap = {
        "name": name,
        "email": email,
        "password": password,
        "role": "teacher",
        "schoolId": schoolId,
        "phone": phone,
        "designation": designation,
        "isActive": true,
        if (lat != null) "lat": lat,
        if (lon != null) "lon": lon,
        if (radius != null) "radius": radius,
      };

      if (imageFile != null) {
        final uploadFormData = FormData.fromMap({
          'file': await MultipartFile.fromFile(
            imageFile.path,
            filename: imageFile.path.split('/').last,
          ),
        });

        final uploadResponse = await DataProvider().performRequest(
          'POST',
          'https://smart-school-backend-production.up.railway.app/general/upload',
          header: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'multipart/form-data',
          },
          data: uploadFormData,
        );

        if (uploadResponse != null &&
            (uploadResponse.statusCode == 200 ||
                uploadResponse.statusCode == 201)) {
          final url = uploadResponse.data['data']['url'];
          if (url != null) {
            dataMap['image'] = url;
            dataMap['avatar'] = url;
          }
        }
      }

      final response = await DataProvider().performRequest(
        'POST',
        APIPath.register,
        data: dataMap,
        header: {'Authorization': 'Bearer $token'},
      );

      if (response != null &&
          (response.statusCode == 200 || response.statusCode == 201)) {
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
    required String designation,
    double? lat,
    double? lon,
    double? radius,
    File? imageFile,
  }) async {
    _isLoading = true;
    notifyListeners();

    try {
      final token = await StorageService.getToken();
      if (token == null) throw Exception('No auth token found');

      final Map<String, dynamic> dataMap = {
        "name": name,
        "email": email,
        "phone": phone,
        "designation": designation,
        if (lat != null) "lat": lat,
        if (lon != null) "lon": lon,
        if (radius != null) "radius": radius,
      };

      if (imageFile != null) {
        final uploadFormData = FormData.fromMap({
          'file': await MultipartFile.fromFile(
            imageFile.path,
            filename: imageFile.path.split('/').last,
          ),
        });

        final uploadResponse = await DataProvider().performRequest(
          'POST',
          'https://smart-school-backend-production.up.railway.app/general/upload',
          header: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'multipart/form-data',
          },
          data: uploadFormData,
        );

        if (uploadResponse != null &&
            (uploadResponse.statusCode == 200 ||
                uploadResponse.statusCode == 201)) {
          final url = uploadResponse.data['data']['url'];
          if (url != null) {
            dataMap['image'] = url;
            dataMap['avatar'] = url;
          }
        }
      }

      final response = await DataProvider().performRequest(
        'PUT',
        '${APIPath.fetchUsers}/$userId',
        data: dataMap,
        header: {'Authorization': 'Bearer $token'},
      );

      if (response != null && response.statusCode == 200) {
        log('Successfully updated teacher');
        final index = _dbService.teachers.indexWhere((t) => t.userId == userId);
        if (index != -1) {
          final oldTeacher = _dbService.teachers[index];

          // Use the new avatar URL if we uploaded a new image, otherwise keep the old one
          String? updatedAvatar = dataMap['avatar'] ?? oldTeacher.user?.avatar;

          final updatedTeacher = Teacher(
            userId: userId,
            designation: designation,
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
              avatar: updatedAvatar,
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
