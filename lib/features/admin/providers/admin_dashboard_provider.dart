import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:smart_school/core/utils/storage_service.dart';

import '../../../configs/network/data_provider.dart';
import '../../../core/constants/api_path.dart';
import '../models/admin_dashboard_model.dart';

class AdminDashboardProvider extends ChangeNotifier {
  bool _isLoading = false;
  bool get isLoading => _isLoading;

  bool _isMonthlyLoading = false;
  bool get isMonthlyLoading => _isMonthlyLoading;

  MonthlyAttendanceOverview? _monthlyAttendanceOverview;
  MonthlyAttendanceOverview? get monthlyAttendanceOverview =>
      _monthlyAttendanceOverview;

  AdminDashboardData? _dashboardData;
  AdminDashboardData? get dashboardData => _dashboardData;

  int _selectedYear = DateTime.now().year;
  int get selectedYear => _selectedYear;

  String? _error;
  String? get error => _error;

  Future<void> fetchDashboardData({int? year}) async {
    _isLoading = true;
    _error = null;
    if (year != null) {
      _selectedYear = year;
    }
    notifyListeners();

    try {
      final token = await StorageService.getToken();
      if (token == null) throw Exception('No auth token found');

      final targetYear = _selectedYear;

      // Run both core calls in parallel
      final results = await Future.wait([
        DataProvider().performRequest(
          'GET',
          APIPath.adminDashboard,
          header: {'Authorization': 'Bearer $token'},
        ),
        DataProvider().performRequest(
          'GET',
          '${APIPath.baseUrl}/admin/attendance/monthly-overview?year=$targetYear',
          header: {'Authorization': 'Bearer $token'},
        ),
      ]);

      final response = results[0];
      final monthlyResponse = results[1];

      if (response != null && response.statusCode == 200) {
        final data = response.data['data'];
        _dashboardData = AdminDashboardData.fromJson(data);
        log('Fetched Admin Dashboard successfully.');
      } else {
        _error = 'Failed to load dashboard data';
        log('Failed to fetch dashboard: ${response?.data}');
      }

      if (monthlyResponse != null &&
          (monthlyResponse.statusCode == 200 ||
              monthlyResponse.statusCode == 201)) {
        final raw = monthlyResponse.data;
        dynamic monthlyData = raw;
        if (raw is Map && raw.containsKey('data')) {
          monthlyData = raw['data'];
        }
        _monthlyAttendanceOverview =
            MonthlyAttendanceOverview.fromJson(monthlyData);
        log('Fetched Admin Monthly Overview successfully for year $targetYear: ${_monthlyAttendanceOverview?.data.length} months found');
      } else {
        log('Failed to fetch monthly overview: ${monthlyResponse?.data}');
      }
    } catch (e) {
      _error = 'Error loading dashboard: $e';
      log('Error fetching admin dashboard: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> changeYear(int year) async {
    if (_selectedYear == year && _monthlyAttendanceOverview != null) return;
    _selectedYear = year;
    _isMonthlyLoading = true;
    notifyListeners();

    try {
      final token = await StorageService.getToken();
      if (token == null) throw Exception('No auth token found');

      final response = await DataProvider().performRequest(
        'GET',
        '${APIPath.baseUrl}/admin/attendance/monthly-overview?year=$year',
        header: {'Authorization': 'Bearer $token'},
      );

      if (response != null &&
          (response.statusCode == 200 || response.statusCode == 201)) {
        final raw = response.data;
        dynamic monthlyData = raw;
        if (raw is Map && raw.containsKey('data')) {
          monthlyData = raw['data'];
        }
        _monthlyAttendanceOverview =
            MonthlyAttendanceOverview.fromJson(monthlyData);
        log('Fetched Monthly Overview for year $year: ${_monthlyAttendanceOverview?.data.length} months');
      } else {
        log('Failed to fetch monthly overview for year $year: ${response?.data}');
      }
    } catch (e) {
      log('Error fetching monthly overview for year $year: $e');
    } finally {
      _isMonthlyLoading = false;
      notifyListeners();
    }
  }
}
