import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:smart_school/core/utils/storage_service.dart';
import '../../../../configs/network/data_provider.dart';
import '../../../../core/constants/api_path.dart';
import '../../../../models/school_models.dart';

class TeacherDashboardProvider extends ChangeNotifier {
  List<RoutineEntry> _todayClasses = [];
  bool _isLoading = false;
  String? _error;

  List<RoutineEntry> get todayClasses => _todayClasses;
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
}
