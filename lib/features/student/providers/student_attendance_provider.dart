import 'dart:developer';
import 'package:flutter/material.dart';
import '../../../configs/network/data_provider.dart';
import '../../../core/constants/api_path.dart';
import '../../../core/utils/storage_service.dart';
import '../../../models/school_models.dart';

class StudentAttendanceNotifier extends ChangeNotifier {
  List<Attendance> _attendanceRecords = [];
  bool _isLoading = false;
  String? _error;

  List<Attendance> get attendanceRecords => _attendanceRecords;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> fetchAttendance() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final token = await StorageService.getToken();
      if (token == null) throw Exception('No authentication token found');

      final response = await DataProvider().performRequest(
        'GET',
        APIPath.studentAttendance,
        header: {'Authorization': 'Bearer $token'},
      );

      if (response != null && response.statusCode == 200) {
        final dynamic rawData = response.data;
        final List data = rawData is List
            ? rawData
            : (rawData is Map ? (rawData['data'] ?? []) : []);
        
        _attendanceRecords = data.map((json) => Attendance.fromJson(json)).toList();
        log('Fetched ${_attendanceRecords.length} student attendance records');
      } else {
        _error = 'Failed to fetch attendance: ${response?.statusCode}';
        log('Error fetching student attendance: ${response?.data}');
      }
    } catch (e) {
      _error = 'Error: $e';
      log('Exception fetching student attendance: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
