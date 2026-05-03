import 'dart:developer';
import 'package:flutter/material.dart';
import '../../../models/user_model.dart';
import '../../../configs/network/data_provider.dart';
import '../../../core/constants/api_path.dart';
import '../../../core/utils/storage_service.dart';

class SchoolManagementNotifier extends ChangeNotifier {
  List<User> _teachers = [];
  List<User> _students = [];
  List<User> _admins = [];
  
  bool _isLoadingTeachers = false;
  bool _isLoadingStudents = false;
  bool _isLoadingAdmins = false;

  List<User> get teachers => _teachers;
  List<User> get students => _students;
  List<User> get admins => _admins;

  bool get isLoadingTeachers => _isLoadingTeachers;
  bool get isLoadingStudents => _isLoadingStudents;
  bool get isLoadingAdmins => _isLoadingAdmins;

  Future<void> fetchSchoolMembers({
    required String schoolId,
    required String role,
  }) async {
    _setLoading(role, true);
    
    try {
      final token = await StorageService.getToken();
      if (token == null) throw Exception('No auth token found');

      final Map<String, dynamic> query = {
        'role': role,
        'schoolId': schoolId,
        'limit': '100', // Fetch more for management view
      };

      final response = await DataProvider().performRequest(
        'GET',
        APIPath.fetchUsers,
        query: query,
        header: {'Authorization': 'Bearer $token'},
      );

      if (response != null && response.statusCode == 200) {
        final dynamic rawData = response.data;
        final List<dynamic> dataList = rawData is List 
            ? rawData 
            : (rawData is Map ? (rawData['data'] is List ? rawData['data'] : (rawData['data']?['data'] ?? [])) : []);

        final List<User> members = dataList.map((json) => User.fromJson(json)).toList();
        
        _setMembers(role, members);
      } else {
        log("Error fetching $role for school $schoolId: ${response?.data}");
      }
    } catch (e) {
      log("Error fetching $role for school $schoolId: $e");
    } finally {
      _setLoading(role, false);
    }
  }

  void _setLoading(String role, bool value) {
    if (role == 'teacher') {
      _isLoadingTeachers = value;
    } else if (role == 'student') {
      _isLoadingStudents = value;
    } else if (role == 'admin') {
      _isLoadingAdmins = value;
    }
    notifyListeners();
  }

  void _setMembers(String role, List<User> members) {
    if (role == 'teacher') {
      _teachers = members;
    } else if (role == 'student') {
      _students = members;
    } else if (role == 'admin') {
      _admins = members;
    }
    notifyListeners();
  }
}
