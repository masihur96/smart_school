import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:smart_school/core/utils/storage_service.dart';
import '../../../../configs/network/data_provider.dart';
import '../../../../core/constants/api_path.dart';
import '../../../../models/school_models.dart';

class TeacherDashboardProvider extends ChangeNotifier {
  List<RoutineEntry> _todayClasses = [];
  List<Exam> _exams = [];
  bool _isLoading = false;
  String? _error;

  List<RoutineEntry> get todayClasses => _todayClasses;
  List<Exam> get exams => _exams;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> fetchTodayClasses(String date) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final token = await StorageService.getToken();
      if (token == null) throw Exception('No auth token found');

      final url = '${APIPath.todayClass}?date=$date';
      log('Fetching today classes: $url');

      final response = await DataProvider().performRequest(
        'GET',
        url,
        header: {'Authorization': 'Bearer $token'},
      );

      if (response != null && (response.statusCode == 200 || response.statusCode == 201)) {
        final List<dynamic> data = response.data['data'] ?? [];
        _todayClasses = data.map((json) => RoutineEntry.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load classes: ${response?.statusCode} - ${response?.data}');
      }
    } catch (e) {
      log('Error fetching today classes: $e');
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchExams() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final token = await StorageService.getToken();
      if (token == null) throw Exception('No auth token found');

      final url = APIPath.teacherExams;
      log('Fetching teacher exams: $url');

      final response = await DataProvider().performRequest(
        'GET',
        url,
        header: {'Authorization': 'Bearer $token'},
      );

      if (response != null &&
          (response.statusCode == 200 || response.statusCode == 201)) {
        final List<dynamic> data = response.data['data'] ?? [];
        _exams = data.map((json) => Exam.fromJson(json)).toList();
      } else {
        throw Exception(
            'Failed to load exams: ${response?.statusCode} - ${response?.data}');
      }
    } catch (e) {
      log('Error fetching teacher exams: $e');
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  TeacherSelfAttendance? _todayAttendance;
  TeacherSelfAttendance? get todayAttendance => _todayAttendance;

  Future<void> fetchTodayAttendance(String date) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final token = await StorageService.getToken();
      if (token == null) throw Exception('No auth token found');

      final url = '${APIPath.selfAttendance}?date=$date';
      log('Fetching today attendance: $url');

      final response = await DataProvider().performRequest(
        'GET',
        url,
        header: {'Authorization': 'Bearer $token'},
      );

      if (response != null &&
          (response.statusCode == 200 || response.statusCode == 201)) {
        final List<dynamic> data = response.data['data'] ?? [];
        if (data.isNotEmpty) {
          _todayAttendance = TeacherSelfAttendance.fromJson(data.first);
        } else {
          _todayAttendance = null;
        }
      } else {
        throw Exception(
            'Failed to load attendance: ${response?.statusCode} - ${response?.data}');
      }
    } catch (e) {
      log('Error fetching today attendance: $e');
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> submitSelfAttendance(double lat, double lon) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final token = await StorageService.getToken();
      if (token == null) throw Exception('No auth token found');

      final response = await DataProvider().performRequest(
        'POST',
        APIPath.selfAttendance,
        data: {'lat': lat, 'lon': lon},
        header: {'Authorization': 'Bearer $token'},
      );

      if (response == null ||
          (response.statusCode != 200 && response.statusCode != 201)) {
        throw Exception(
            response?.data?['message'] ?? 'Failed to submit attendance');
      }

      // Refresh attendance after successful submission
      final now = DateTime.now();
      final dateStr = DateFormat('yyyy-MM-dd').format(now);
      await fetchTodayAttendance(dateStr);
    } catch (e) {
      log('Error submitting self attendance: $e');
      _error = e.toString();
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
