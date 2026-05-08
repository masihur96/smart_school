import 'dart:developer';
import 'package:flutter/foundation.dart';
import 'package:smart_school/core/utils/storage_service.dart';
import '../../../../configs/network/data_provider.dart';
import '../../../../core/constants/api_path.dart';
import '../data/models/student_dashboard_model.dart';

class StudentDashboardProvider extends ChangeNotifier {
  StudentDashboardData? _dashboardData;
  StudentDashboardData? get dashboardData => _dashboardData;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _error;
  String? get error => _error;

  Future<void> fetchStudentDashboard() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final token = await StorageService.getToken();
      if (token == null) {
        throw Exception('No auth token found');
      }

      final url = APIPath.studentDashboard;
      log('Fetching student dashboard: $url');

      final response = await DataProvider().performRequest(
        'GET',
        url,
        header: {
          'Authorization': 'Bearer $token',
          'accept': '*/*',
        },
      );

      if (response != null &&
          (response.statusCode == 200 || response.statusCode == 201)) {
        final data = response.data['data'];
        if (data != null) {
          _dashboardData = StudentDashboardData.fromJson(data);
        } else {
          _dashboardData = StudentDashboardData();
        }
      } else {
        throw Exception(
            'Failed to load student dashboard: ${response?.statusCode} - ${response?.data}');
      }
    } catch (e) {
      log('Error fetching student dashboard: $e');
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
