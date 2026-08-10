import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:smart_school/configs/network/data_provider.dart';
import 'package:smart_school/core/constants/api_path.dart';
import 'package:smart_school/core/utils/storage_service.dart';

class OnlineClassProvider extends ChangeNotifier {
  final DataProvider _dataProvider;

  OnlineClassProvider(this._dataProvider);

  bool _isLoading = false;
  String? _error;

  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<bool> createOnlineClass({
    required String title,
    required String description,
    required String meetLink,
    required String date,
    required String startTime,
    required String endTime,
    String? classId,
    String? sectionId,
    String? subjectId,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final token = await StorageService.getToken();
      if (token == null) throw Exception('No authentication token found');

      final payload = {
        "title": title,
        "description": description,
        "meetLink": meetLink,
        "date": date,
        "startTime": startTime,
        "endTime": endTime,
        if (classId != null) "classId": classId,
        if (sectionId != null) "sectionId": sectionId,
        if (subjectId != null) "subjectId": subjectId,
      };

      log('Create online class payload: $payload');

      final response = await _dataProvider.performRequest(
        'POST',
        APIPath.onlineClasses,
        data: payload,
        header: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
          'accept': '*/*',
        },
      );

      log('Create online class response: ${response?.statusCode} - ${response?.data}');

      if (response == null || response.statusCode == null) {
        throw Exception('No response from server');
      }

      if (response.statusCode! >= 200 && response.statusCode! < 300) {
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        final message = response.data?['message'] ?? 'Failed to create online class';
        throw Exception(message);
      }
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }
}
