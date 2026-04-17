import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:smart_school/core/utils/storage_service.dart';
import '../../../../configs/network/data_provider.dart';
import '../../../../core/constants/api_path.dart';
import '../../../../models/school_models.dart';

class MarqueeProvider extends ChangeNotifier {
  bool _isLoading = false;
  String? _error;
  
  Marquee? _teacherMarquee;
  Marquee? _studentMarquee;

  bool get isLoading => _isLoading;
  String? get error => _error;
  Marquee? get teacherMarquee => _teacherMarquee;
  Marquee? get studentMarquee => _studentMarquee;

  Future<void> fetchMarquee(String type) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final token = await StorageService.getToken();
      if (token == null) throw Exception('No auth token found');

      final url = '${APIPath.marquee}?type=$type';
      log('Fetching $type marquee: $url');

      final response = await DataProvider().performRequest(
        'GET',
        url,
        header: {'Authorization': 'Bearer $token'},
      );

      if (response != null && (response.statusCode == 200 || response.statusCode == 201)) {
        final dynamic data = response.data['data'];
        
        if (data != null) {
          final marquee = Marquee.fromJson(data);
          if (type == 'TEACHER') {
            _teacherMarquee = marquee;
          } else if (type == 'STUDENT') {
            _studentMarquee = marquee;
          }
        } else {
          if (type == 'TEACHER') {
            _teacherMarquee = null;
          } else if (type == 'STUDENT') {
            _studentMarquee = null;
          }
        }
      } else {
        throw Exception('Failed to load marquee: ${response?.statusCode} - ${response?.data}');
      }
    } catch (e) {
      log('Error fetching marquee: $e');
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> addOrUpdateMarquee(String text, String type, String schoolId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final token = await StorageService.getToken();
      if (token == null) throw Exception('No auth token found');

      final data = {
        'text': text,
        'type': type,
        'schoolId': schoolId,
      };

      final response = await DataProvider().performRequest(
        'POST',
        APIPath.marquee,
        data: data,
        header: {'Authorization': 'Bearer $token'},
      );

      if (response != null && (response.statusCode == 200 || response.statusCode == 201)) {
        log('Successfully saved $type marquee');
        // Refresh local state if adding for the current school
        return true;
      } else {
        throw Exception(response?.data?['message'] ?? 'Failed to add marquee');
      }
    } catch (e) {
      log('Error creating/updating marquee: $e');
      _error = e.toString();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
