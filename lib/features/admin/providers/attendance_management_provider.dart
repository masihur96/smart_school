import 'dart:developer';
import 'package:flutter/material.dart';
import '../../../configs/network/data_provider.dart';
import '../../../core/constants/api_path.dart';
import '../../../core/utils/storage_service.dart';

class AttendanceManagementProvider extends ChangeNotifier {
  bool _isLoading = false;
  String? _error;
  List<dynamic> _studentAttendance = [];
  List<dynamic> _teacherAttendance = [];

  bool get isLoading => _isLoading;
  String? get error => _error;
  List<dynamic> get studentAttendance => _studentAttendance;
  List<dynamic> get teacherAttendance => _teacherAttendance;

  Future<void> fetchStudentAttendance({String? name, DateTime? date}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final token = await StorageService.getToken();
      final dateStr = date != null ? "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}" : null;

      final query = <String, dynamic>{};
      if (name != null && name.isNotEmpty) query['name'] = name;
      if (dateStr != null) query['date'] = dateStr;

      final response = await DataProvider().performRequest(
        'GET',
        APIPath.attendanceOverview, // Using overview endpoint for student attendance report
        query: query,
        header: {'Authorization': 'Bearer $token'},
      );

      if (response != null && response.statusCode == 200) {
        // The API structure for admin attendance overview might vary, assuming a 'data' array
        _studentAttendance = response.data['data'] is List ? response.data['data'] : [];
      } else {
        _error = "Failed to fetch student attendance";
      }
    } catch (e) {
      _error = e.toString();
      log("Error fetching student attendance: $e");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchTeacherAttendance({String? name, DateTime? date}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final token = await StorageService.getToken();
      final dateStr = date != null ? "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}" : null;

      final query = <String, dynamic>{};
      if (name != null && name.isNotEmpty) query['name'] = name;
      if (dateStr != null) query['date'] = dateStr;

      final response = await DataProvider().performRequest(
        'GET',
        APIPath.adminTeacherAttendance,
        query: query,
        header: {'Authorization': 'Bearer $token'},
      );

      if (response != null && response.statusCode == 200) {
        _teacherAttendance = response.data['data'] is List ? response.data['data'] : [];
      } else {
        _error = "Failed to fetch teacher attendance";
      }
    } catch (e) {
      _error = e.toString();
      log("Error fetching teacher attendance: $e");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
