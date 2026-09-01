import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:smart_school/configs/network/data_provider.dart';
import 'package:smart_school/core/constants/api_path.dart';
import 'package:smart_school/core/utils/storage_service.dart';
import 'package:smart_school/models/online_class_model.dart';

class OnlineClassProvider extends ChangeNotifier {
  final DataProvider _dataProvider;

  OnlineClassProvider(this._dataProvider);

  // ── State ──────────────────────────────────────────────────────────────────

  bool _isLoading = false;
  String? _error;
  List<OnlineClass> _onlineClasses = [];

  bool get isLoading => _isLoading;
  String? get error => _error;
  List<OnlineClass> get onlineClasses => _onlineClasses;

  // ── Helpers ────────────────────────────────────────────────────────────────

  Future<Map<String, String>> _authHeader() async {
    final token = await StorageService.getToken();
    if (token == null || token.isEmpty) {
      throw Exception('Authentication session expired. Please log in again.');
    }
    return {
      'accept': '*/*',
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
    };
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  // ── Fetch ──────────────────────────────────────────────────────────────────

  Future<void> fetchOnlineClasses() async {
    _setLoading(true);
    _error = null;

    try {
      final headers = await _authHeader();
      final response = await _dataProvider.performRequest(
        'GET',
        APIPath.onlineClasses,
        header: headers,
      );

      log('Fetch online classes response: ${response}');
      log('Fetch online classes response: ${response?.statusCode}');

      if (response != null &&
          (response.statusCode == 200 || response.statusCode == 201)) {
        final data = response.data;
        final List<dynamic> listData = data['data'] ?? [];

        _onlineClasses = listData
            .map((json) => OnlineClass.fromJson(json))
            .toList();

        _onlineClasses.sort(
          (a, b) => a.scheduledTime.compareTo(b.scheduledTime),
        );
      } else {
        _error = response?.data?['message']?.toString() ??
            response?.statusMessage ??
            'Failed to fetch online classes';
        log('Fetch online classes error: $_error');
      }
    } catch (e) {
      _error = e.toString();
      log('Fetch online classes exception: $e');
    }

    _setLoading(false);
  }

  // ── Create ─────────────────────────────────────────────────────────────────

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
    List<String>? participantUuids,
  }) async {
    _setLoading(true);
    _error = null;

    try {
      final headers = await _authHeader();
      final payload = {
        'title': title,
        'description': description,
        'meetLink': meetLink,
        'date': date,
        'scheduledTime': date,
        'startTime': startTime,
        'endTime': endTime,
        if (classId != null) 'classId': classId,
        if (sectionId != null) 'sectionId': sectionId,
        if (subjectId != null) 'subjectId': subjectId,
        if (participantUuids != null && participantUuids.isNotEmpty)
          'participantUuids': participantUuids,
      };

      log('Create online class payload: $payload');

      final response = await _dataProvider.performRequest(
        'POST',
        APIPath.onlineClasses,
        data: payload,
        header: headers,
      );

      log('Create online class response: ${response?.statusCode} - ${response?.data}');

      if (response == null || response.statusCode == null) {
        throw Exception('No response from server');
      }

      if (response.statusCode! >= 200 && response.statusCode! < 300) {
        _setLoading(false);
        return true;
      } else {
        throw Exception(
          response.data?['message'] ?? 'Failed to create online class',
        );
      }
    } catch (e) {
      _error = e.toString();
      _setLoading(false);
      return false;
    }
  }

  // ── Update ─────────────────────────────────────────────────────────────────

  Future<bool> updateOnlineClass({
    required String id,
    required String title,
    required String description,
    required String meetLink,
    required String date,
    required String startTime,
    required String endTime,
    String? classId,
    String? sectionId,
    String? subjectId,
    List<String>? participantUuids,
  }) async {
    _setLoading(true);
    _error = null;

    try {
      final headers = await _authHeader();
      final payload = {
        'title': title,
        'description': description,
        'meetLink': meetLink,
        'date': date,
        'scheduledTime': date,
        'startTime': startTime,
        'endTime': endTime,
        if (classId != null) 'classId': classId,
        if (sectionId != null) 'sectionId': sectionId,
        if (subjectId != null) 'subjectId': subjectId,
        if (participantUuids != null && participantUuids.isNotEmpty)
          'participantUuids': participantUuids,
      };

      log('Update online class payload: $payload');

      final response = await _dataProvider.performRequest(
        'PATCH',
        '${APIPath.onlineClasses}/$id',
        data: payload,
        header: headers,
      );

      log('Update online class response: ${response?.statusCode}');

      if (response != null &&
          (response.statusCode == 200 || response.statusCode == 201)) {
        _setLoading(false);
        return true;
      } else {
        throw Exception(
          response?.data?['message'] ?? 'Failed to update online class',
        );
      }
    } catch (e) {
      _error = e.toString();
      _setLoading(false);
      return false;
    }
  }

  // ── Delete ─────────────────────────────────────────────────────────────────

  Future<bool> deleteOnlineClass(String id) async {
    _setLoading(true);
    _error = null;

    try {
      final headers = await _authHeader();
      final response = await _dataProvider.performRequest(
        'DELETE',
        '${APIPath.onlineClasses}/$id',
        header: headers,
      );

      log('Delete online class response: ${response?.statusCode}');

      if (response != null &&
          (response.statusCode == 200 ||
              response.statusCode == 201 ||
              response.statusCode == 204)) {
        _onlineClasses.removeWhere((c) => c.id == id);
        _setLoading(false);
        return true;
      } else {
        throw Exception(
          response?.data?['message'] ?? 'Failed to delete online class',
        );
      }
    } catch (e) {
      _error = e.toString();
      _setLoading(false);
      return false;
    }
  }
}
