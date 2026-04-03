import 'dart:developer';
import 'package:flutter/material.dart';
import '../../../configs/network/data_provider.dart';
import '../../../core/constants/api_path.dart';
import '../../../core/utils/storage_service.dart';
import '../../../models/school_models.dart';

class StudentResultNotifier extends ChangeNotifier {
  List<Result> _results = [];
  bool _isLoading = false;
  String? _error;

  List<Result> get results => _results;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> fetchResults() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final token = await StorageService.getToken();
      if (token == null) throw Exception('No authentication token found');

      final response = await DataProvider().performRequest(
        'GET',
        APIPath.studentResult,
        header: {'Authorization': 'Bearer $token'},
      );

      if (response != null && response.statusCode == 200) {
        final dynamic rawData = response.data;
        final List data = rawData is List
            ? rawData
            : (rawData is Map ? (rawData['data'] ?? []) : []);
        
        _results = data.map((json) => Result.fromJson(json)).toList();
        log('Fetched ${_results.length} student results');
      } else {
        _error = 'Failed to fetch results: ${response?.statusCode}';
        log('Error fetching student results: ${response?.data}');
      }
    } catch (e) {
      _error = 'Error: $e';
      log('Exception fetching student results: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
