import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:smart_school/core/utils/storage_service.dart';
import '../../../configs/network/data_provider.dart';
import '../../../core/constants/api_path.dart';
import '../models/admin_dashboard_model.dart';

class AdminDashboardProvider extends ChangeNotifier {
  bool _isLoading = false;
  bool get isLoading => _isLoading;

  AdminDashboardData? _dashboardData;
  AdminDashboardData? get dashboardData => _dashboardData;

  String? _error;
  String? get error => _error;

  Future<void> fetchDashboardData() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final token = await StorageService.getToken();
      if (token == null) throw Exception('No auth token found');

      final response = await DataProvider().performRequest(
        'GET',
        APIPath.adminDashboard,
        header: {'Authorization': 'Bearer $token'},
      );

      if (response != null && response.statusCode == 200) {
        final data = response.data['data'];
        _dashboardData = AdminDashboardData.fromJson(data);
        log('Fetched Admin Dashboard successfully.');
      } else {
        _error = 'Failed to load dashboard data';
        log('Failed to fetch dashboard: ${response?.data}');
      }
    } catch (e) {
      _error = 'Error loading dashboard: $e';
      log('Error fetching admin dashboard: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
