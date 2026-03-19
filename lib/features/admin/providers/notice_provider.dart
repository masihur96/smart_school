import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:smart_school/core/utils/storage_service.dart';

import '../../../configs/network/data_provider.dart';
import '../../../core/constants/api_path.dart';
import '../../../models/school_models.dart';
import '../../../services/database_service.dart';

class NoticesNotifier extends ChangeNotifier {
  final DatabaseService _dbService;
  List<Notice> _notices = [];
  bool _isLoading = false;

  NoticesNotifier(this._dbService) {
    _notices = [..._dbService.notices];
  }

  List<Notice> get notices => _notices;
  bool get isLoading => _isLoading;

  void addNotice(Notice notice) {
    _dbService.notices.add(notice);
    _notices = [..._dbService.notices];
    notifyListeners();
  }

  Future<void> addNoticeToAPI(Notice notice) async {
    _isLoading = true;
    notifyListeners();

    try {
      final token = await StorageService.getToken();
      if (token == null) throw Exception('No auth token found');

      final response = await DataProvider().performRequest(
        'POST',
        APIPath.createNotice,
        data: notice.toJson(),
        header: {'Authorization': 'Bearer $token'},
      );

      if (response != null &&
          (response.statusCode == 200 || response.statusCode == 201)) {
        log('Successfully created notice');
        // Add locally after successful API call
        _dbService.notices.add(notice);
        _notices = [..._dbService.notices];
      } else {
        log('Error creating notice: ${response?.data}');
        throw Exception('Failed to create notice: ${response?.data}');
      }
    } catch (e) {
      log("Error creating notice: $e");
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void removeNotice(String id) {
    _notices = [..._dbService.notices];
    notifyListeners();
  }
}
