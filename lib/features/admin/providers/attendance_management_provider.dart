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
    DateTime? date,
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
      final dateStr = date != null
          ? "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}"
          : null;

      final query = <String, dynamic>{
        'page': page.toString(),
        'limit': limit.toString(),
      };
      if (name != null && name.isNotEmpty) query['studentName'] = name;
      if (dateStr != null) query['date'] = dateStr;
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
        APIPath.periodAttendance,
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

  Future<void> fetchTeacherAttendance({String? name, DateTime? date}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final token = await StorageService.getToken();
      final dateStr = date != null
          ? "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}"
          : null;

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
        _teacherAttendance =
            response.data['data'] is List ? response.data['data'] : [];
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
