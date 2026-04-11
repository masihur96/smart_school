import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:smart_school/core/utils/storage_service.dart';
import '../../../../configs/network/data_provider.dart';
import '../../../../core/constants/api_path.dart';
import '../../../../models/school_models.dart';

class TeacherAttendanceProvider extends ChangeNotifier {
  List<TeacherSelfAttendance> _attendanceList = [];
  bool _isLoading = false;
  String? _error;

  List<TeacherSelfAttendance> get attendanceList => _attendanceList;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> fetchTeacherAttendance({
    String? teacherId,
    required String schoolId,
    String? date,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final token = await StorageService.getToken();
      if (token == null) throw Exception('No auth token found');

      final Map<String, dynamic> query = {
        'schoolId': schoolId,
      };
      if (teacherId != null && teacherId.isNotEmpty) {
        query['teacherId'] = teacherId;
      }
      if (date != null && date.isNotEmpty) {
        query['date'] = date;
      }

      log('Fetching teacher attendance with query: $query');

      final response = await DataProvider().performRequest(
        'GET',
        APIPath.adminTeacherAttendance,
        query: query,
        header: {'Authorization': 'Bearer $token'},
      );

      if (response != null && (response.statusCode == 200 || response.statusCode == 201)) {
        final List<dynamic> data = response.data['data'] ?? [];
        _attendanceList = data.map((json) => TeacherSelfAttendance.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load attendance: ${response?.statusCode} - ${response?.data}');
      }
    } catch (e) {
      log('Error fetching teacher attendance: $e');
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
