import 'dart:developer';
import 'dart:io';

import 'package:dio/dio.dart';
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
    File? logoFile,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final token = await StorageService.getToken();
      if (token == null) throw Exception('No authentication token found');

      String? logoUrl;
      if (logoFile != null) {
        final uploadFormData = FormData.fromMap({
          'file': await MultipartFile.fromFile(
            logoFile.path,
            filename: logoFile.path.split('/').last,
          ),
        });

        final uploadResponse = await DataProvider().performRequest(
          'POST',
          'https://smart-school-backend-production.up.railway.app/general/upload',
          header: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'multipart/form-data',
          },
          data: uploadFormData,
        );

        if (uploadResponse != null &&
            (uploadResponse.statusCode == 200 || uploadResponse.statusCode == 201)) {
          logoUrl = uploadResponse.data['data']['url'];
        }
      }

      final response = await DataProvider().performRequest(
        'POST',
        APIPath.createSchool,
        data: {
          "schoolId": schoolId,
          "name": name,
          "address": address,
          "phone": phone,
          "email": email,
          if (logoUrl != null) "avatar": logoUrl,
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
