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

  // ─── Fetch from API ───────────────────────────────────────────────────────
  Future<void> fetchNoticesFromAPI(String schoolId) async {
    _isLoading = true;
    notifyListeners();

    try {
      final token = await StorageService.getToken();
      if (token == null) throw Exception('No auth token found');

      final response = await DataProvider().performRequest(
        'GET',
        '${APIPath.createNotice}?schoolId=$schoolId',
        header: {'Authorization': 'Bearer $token'},
      );

      if (response != null &&
          (response.statusCode == 200 || response.statusCode == 201)) {
        final data = response.data;
        List<dynamic> raw = [];

        if (data is List) {
          raw = data;
        } else if (data is Map && data['data'] is List) {
          raw = data['data'];
        } else if (data is Map && data['notices'] is List) {
          raw = data['notices'];
        }

        final fetched = raw
            .map((e) => Notice.fromJson(e as Map<String, dynamic>))
            .toList();

        _dbService.notices
          ..clear()
          ..addAll(fetched);
        _notices = [...fetched];
        log('Fetched ${fetched.length} notices from API');
      } else {
        log('Failed to fetch notices: ${response?.data}');
      }
    } catch (e) {
      log('Error fetching notices: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ─── Create ───────────────────────────────────────────────────────────────
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
        // Capture server-returned id
        Notice saved = notice;
        final body = response.data;
        if (body is Map) {
          final serverId =
              (body['id'] ?? body['_id'])?.toString();
          if (serverId != null) saved = notice.copyWith(id: serverId);
        }
        _dbService.notices.add(saved);
        _notices = [..._dbService.notices];
      } else {
        throw Exception('Failed to create notice: ${response?.data}');
      }
    } catch (e) {
      log('Error creating notice: $e');
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ─── Update ───────────────────────────────────────────────────────────────
  Future<void> updateNoticeOnAPI(Notice updated) async {
    if (updated.id == null) throw Exception('Notice id is required to update');
    _isLoading = true;
    notifyListeners();

    try {
      final token = await StorageService.getToken();
      if (token == null) throw Exception('No auth token found');

      final response = await DataProvider().performRequest(
        'PUT',
        '${APIPath.createNotice}/${updated.id}',
        data: updated.toJson(),
        header: {'Authorization': 'Bearer $token'},
      );

      if (response != null &&
          (response.statusCode == 200 || response.statusCode == 201)) {
        log('Successfully updated notice ${updated.id}');
        final idx =
            _dbService.notices.indexWhere((n) => n.id == updated.id);
        if (idx != -1) {
          _dbService.notices[idx] = updated;
        }
        _notices = [..._dbService.notices];
      } else {
        throw Exception('Failed to update notice: ${response?.data}');
      }
    } catch (e) {
      log('Error updating notice: $e');
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ─── Delete ───────────────────────────────────────────────────────────────
  Future<void> deleteNoticeOnAPI(String id) async {
    _isLoading = true;
    notifyListeners();

    try {
      final token = await StorageService.getToken();
      if (token == null) throw Exception('No auth token found');

      log('Deleting notice: ${APIPath.createNotice}/$id');

      final response = await DataProvider().performRequest(
        'DELETE',
        '${APIPath.createNotice}/$id',
        header: {'Authorization': 'Bearer $token'},
      );

      if (response != null &&
          (response.statusCode == 200 || response.statusCode == 204)) {
        log('Successfully deleted notice $id');
        _dbService.notices.removeWhere((n) => n.id == id);
        _notices = [..._dbService.notices];
      } else {
        throw Exception('Failed to delete notice: ${response?.data}');
      }
    } catch (e) {
      log('Error deleting notice: $e');
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void removeNotice(String id) {
    _dbService.notices.removeWhere((n) => n.id == id);
    _notices = [..._dbService.notices];
    notifyListeners();
  }
}
