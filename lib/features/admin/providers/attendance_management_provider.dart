import 'dart:developer';

import 'package:flutter/material.dart';

import '../../../configs/network/data_provider.dart';
import '../../../core/constants/api_path.dart';
import '../../../core/utils/storage_service.dart';
import '../../../models/period_attendance_model.dart';

class AttendanceManagementProvider extends ChangeNotifier {
  bool _isLoading = false;
  String? _error;
  List<PeriodAttendance> _studentAttendance = [];
  List<dynamic> _teacherAttendance = [];

  // Pagination state
  int _total = 0;
  int _page = 1;
  int _limit = 50;
  int _totalPages = 1;

  bool get isLoading => _isLoading;
  String? get error => _error;
  List<PeriodAttendance> get studentAttendance => _studentAttendance;
  List<dynamic> get teacherAttendance => _teacherAttendance;

  int get total => _total;
  int get page => _page;
  int get limit => _limit;
  int get totalPages => _totalPages;

  Future<void> fetchStudentAttendance({
    String? name,
    DateTime? startDate,
    DateTime? endDate,
    String? classId,
    String? sectionId,
    String? subjectId,
    int page = 1,
    int limit = 50,
  }) async {
    _isLoading = true;
    _error = null;
    if (page == 1) {
      _studentAttendance = [];
    }
    notifyListeners();

    try {
      final token = await StorageService.getToken();
      final query = <String, dynamic>{
        'page': page.toString(),
        'limit': limit.toString(),
      };
      if (name != null && name.isNotEmpty) query['studentName'] = name;
      
      if (startDate != null) {
        query['startDate'] = "${startDate.year}-${startDate.month.toString().padLeft(2, '0')}-${startDate.day.toString().padLeft(2, '0')}";
      }
      if (endDate != null) {
        query['endDate'] = "${endDate.year}-${endDate.month.toString().padLeft(2, '0')}-${endDate.day.toString().padLeft(2, '0')}";
      }
      if (classId != null && classId.isNotEmpty) query['classId'] = classId;
      if (sectionId != null && sectionId.isNotEmpty) {
        query['sectionId'] = sectionId;
      }
      if (subjectId != null && subjectId.isNotEmpty) {
        query['subjectId'] = subjectId;
      }

      log("Fetching attendance with query: $query");

      final response = await DataProvider().performRequest(
        'GET',
        APIPath.adminPeriodAttendance,
        query: query,
        header: {'Authorization': 'Bearer $token'},
      );

      if (response != null && response.statusCode == 200) {
        final periodResponse = PeriodAttendanceResponse.fromJson(response.data);
        if (page == 1) {
          _studentAttendance = periodResponse.data.data;
        } else {
          _studentAttendance.addAll(periodResponse.data.data);
        }
        _total = periodResponse.data.total;
        _page = periodResponse.data.page;
        _limit = periodResponse.data.limit;
        _totalPages = periodResponse.data.totalPages;
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

  Future<void> fetchTeacherAttendance({
    String? name,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final token = await StorageService.getToken();
      final query = <String, dynamic>{};
      if (name != null && name.isNotEmpty) query['name'] = name;
      
      if (startDate != null) {
        query['startDate'] = "${startDate.year}-${startDate.month.toString().padLeft(2, '0')}-${startDate.day.toString().padLeft(2, '0')}";
      }
      if (endDate != null) {
        query['endDate'] = "${endDate.year}-${endDate.month.toString().padLeft(2, '0')}-${endDate.day.toString().padLeft(2, '0')}";
      }

      final response = await DataProvider().performRequest(
        'GET',
        APIPath.adminTeacherAttendance,
        query: query,
        header: {'Authorization': 'Bearer $token'},
      );

      if (response != null && response.statusCode == 200) {
        _teacherAttendance = response.data['data'] is List
            ? response.data['data']
            : [];
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

  Future<void> createTeacherAttendance({
    required String teacherId,
    required String date,
    required String status,
    String? startTime,
    String? endTime,
    String? time,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final token = await StorageService.getToken();
      final body = <String, dynamic>{
        "teacherId": teacherId,
        "date": date,
        "status": status,
        if (startTime != null) "startTime": startTime,
        if (endTime != null) "endTime": endTime,
        if (time != null) "time": time,
      };

      log("Creating teacher attendance with body: $body");

      final response = await DataProvider().performRequest(
        'POST',
        APIPath.adminTeacherAttendance,
        data: body,
        header: {'Authorization': 'Bearer $token'},
      );

      if (response != null && (response.statusCode == 200 || response.statusCode == 201)) {
        log("Successfully created teacher attendance");
        // Optionally fetch the latest data after creating
        fetchTeacherAttendance();
      } else {
        _error = "Failed to create teacher attendance";
      }
    } catch (e) {
      _error = e.toString();
      log("Error creating teacher attendance: $e");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
