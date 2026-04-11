import 'dart:developer';

import 'package:flutter/material.dart';

import '../../../configs/network/data_provider.dart';
import '../../../core/constants/api_path.dart';
import '../../../core/utils/storage_service.dart';
import '../models/school_model.dart';

class SuperAdminSchoolNotifier extends ChangeNotifier {
  List<SuperAdminSchool> _schools = [];
  bool _isLoading = false;
  String? _error;

  List<SuperAdminSchool> get schools => _schools;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> fetchSchools() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final token = await StorageService.getToken();
      if (token == null) throw Exception('No authentication token found');

      final response = await DataProvider().performRequest(
        'GET',
        APIPath.superAdminSchools,
        header: {'Authorization': 'Bearer $token'},
      );

      if (response != null && response.statusCode == 200) {
        final dynamic rawData = response.data;
        final List dataList = rawData is List
            ? rawData
            : (rawData is Map ? (rawData['data'] ?? []) : []);

        _schools = dataList
            .map((json) => SuperAdminSchool.fromJson(json))
            .toList();
        log('Fetched ${_schools.length} schools for super admin');
      } else {
        _error = 'Failed to fetch schools: ${response?.statusCode}';
        log('Error fetching super admin schools: ${response?.data}');
      }
    } catch (e) {
      _error = 'Error: $e';
      log('Exception fetching super admin schools: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> createSchool(SuperAdminSchool school) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final token = await StorageService.getToken();
      if (token == null) throw Exception('No authentication token found');

      final response = await DataProvider().performRequest(
        'POST',
        APIPath.superAdminSchools,
        header: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        data: school.toJson(),
      );

      if (response != null &&
          (response.statusCode == 201 || response.statusCode == 200)) {
        log('School created successfully');
        await fetchSchools(); // Refresh list
        return true;
      } else {
        _error = 'Failed to create school: ${response?.statusCode}';
        log('Error creating school: ${response?.data}');
        return false;
      }
    } catch (e) {
      _error = 'Error: $e';
      log('Exception creating school: $e');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
