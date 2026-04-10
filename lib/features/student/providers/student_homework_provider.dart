import 'dart:developer';
import 'package:flutter/material.dart';
import '../../../configs/network/data_provider.dart';
import '../../../core/constants/api_path.dart';
import '../../../core/utils/storage_service.dart';
import '../../../models/school_models.dart';

class StudentHomeworkNotifier extends ChangeNotifier {
  List<StudentHomework> _homeworkList = [];
  bool _isLoading = false;
  String? _error;

  List<StudentHomework> get homeworkList => _homeworkList;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> fetchHomework(String classId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final token = await StorageService.getToken();
      if (token == null) throw Exception('No authentication token found');

      final response = await DataProvider().performRequest(
        'GET',
        APIPath.studentHomework,
        query: {'classId': classId},
        header: {'Authorization': 'Bearer $token'},
      );

      if (response != null && response.statusCode == 200) {
        final dynamic rawData = response.data;
        final List data = rawData is List
            ? rawData
            : (rawData is Map ? (rawData['data'] ?? []) : []);
        
        _homeworkList = data.map((json) => StudentHomework.fromJson(json)).toList();
        // Sort by due date (most recent/closest first)
        _homeworkList.sort((a, b) {
          final dateA = a.homework?.dueDate ?? DateTime.now();
          final dateB = b.homework?.dueDate ?? DateTime.now();
          return dateA.compareTo(dateB);
        });
        log('Fetched ${_homeworkList.length} student homework entries for class $classId');
      } else {
        _error = 'Failed to fetch homework: ${response?.statusCode}';
        log('Error fetching student homework: ${response?.data}');
      }
    } catch (e) {
      _error = 'Error: $e';
      log('Exception fetching student homework: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
