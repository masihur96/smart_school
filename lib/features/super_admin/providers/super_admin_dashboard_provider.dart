import 'dart:developer';
import 'package:flutter/material.dart';
import '../../../configs/network/data_provider.dart';
import '../../../core/constants/api_path.dart';
import '../../../core/utils/storage_service.dart';
import '../models/super_admin_dashboard_model.dart';

class SuperAdminDashboardNotifier extends ChangeNotifier {
  SuperAdminDashboardData _dashboardData = SuperAdminDashboardData.initial();
  bool _isLoading = false;
  String? _error;

  SuperAdminDashboardData get dashboardData => _dashboardData;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> fetchDashboardData() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final token = await StorageService.getToken();
      if (token == null) throw Exception('No authentication token found');

      final response = await DataProvider().performRequest(
        'GET',
        APIPath.superAdminDashboard,
        header: {'Authorization': 'Bearer $token'},
      );

      if (response != null && response.statusCode == 200) {
        final Map<String, dynamic> responseBody = response.data;
        if (responseBody['data'] != null) {
          _dashboardData = SuperAdminDashboardData.fromJson(responseBody['data']);
          log('Super Admin Dashboard data fetched successfully');
        }
      } else {
        _error = 'Failed to fetch dashboard data: ${response?.statusCode}';
        log('Error fetching super admin dashboard: ${response?.data}');
      }
    } catch (e) {
      _error = 'Error: $e';
      log('Exception fetching super admin dashboard: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
