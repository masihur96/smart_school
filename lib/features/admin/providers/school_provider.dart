import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:smart_school/configs/network/data_provider.dart';
import 'package:smart_school/core/constants/api_path.dart';
import 'package:smart_school/core/utils/storage_service.dart';

class AdminSchoolNotifier extends ChangeNotifier {
  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _error;
  String? get error => _error;

  Future<bool> registerSchool({
    required String schoolId,
    required String name,
    required String address,
    required String phone,
    required String email,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final token = await StorageService.getToken();
      if (token == null) throw Exception('No authentication token found');

      final response = await DataProvider().performRequest(
        'POST',
        APIPath.createSchool,
        data: {
          "schoolId": schoolId,
          "name": name,
          "address": address,
          "phone": phone,
          "email": email,
        },
        header: {'Authorization': 'Bearer $token'},
      );

      if (response != null &&
          (response.statusCode == 200 || response.statusCode == 201)) {
        log('School registered successfully');
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _error = response?.data?['message'] ?? 'Failed to register school';
        log('Error registering school: $_error');
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _error = e.toString();
      log('Exception registering school: $_error');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
