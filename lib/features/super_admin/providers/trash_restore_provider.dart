import 'dart:developer';
import 'package:flutter/material.dart';
import '../../../configs/network/data_provider.dart';
import '../../../core/constants/api_path.dart';
import '../../../core/utils/storage_service.dart';

// A lightweight model representing any soft-deleted record
class DeletedRecord {
  final String id;
  final String entity;
  final String displayName;
  final String? subtitle;
  final String? deletedAt;
  final Map<String, dynamic> raw;

  const DeletedRecord({
    required this.id,
    required this.entity,
    required this.displayName,
    this.subtitle,
    this.deletedAt,
    required this.raw,
  });

  factory DeletedRecord.fromJson(Map<String, dynamic> json, String entity) {
    String name = '';
    String? subtitle;

    switch (entity) {
      case 'user':
        name = json['name'] ?? json['username'] ?? json['email'] ?? 'Unknown User';
        subtitle = json['email'] ?? json['role'];
        break;
      case 'school':
        name = json['name'] ?? 'Unknown School';
        subtitle = json['address'] ?? json['schoolId'];
        break;
      case 'class':
        name = json['name'] ?? json['className'] ?? 'Unknown Class';
        subtitle = json['schoolId'];
        break;
      case 'section':
        name = json['name'] ?? json['sectionName'] ?? 'Unknown Section';
        subtitle = json['classId'];
        break;
      case 'subject':
        name = json['name'] ?? json['subjectName'] ?? 'Unknown Subject';
        subtitle = json['classId'];
        break;
      case 'pricing':
        name = json['name'] ?? json['planName'] ?? 'Unknown Plan';
        subtitle = json['price'] != null ? '\$${json['price']}' : null;
        break;
      case 'subscription':
        name = json['schoolId'] ?? json['school']?['name'] ?? 'Unknown Subscription';
        subtitle = json['planId'] ?? json['pricingPlan']?['name'];
        break;
      case 'homework':
        name = json['title'] ?? json['description'] ?? 'Unknown Homework';
        subtitle = json['subject'] ?? json['dueDate'];
        break;
      case 'attendance':
        name = json['studentId'] ?? json['teacherId'] ?? 'Unknown Attendance';
        subtitle = json['date'];
        break;
      default:
        name = json['name'] ?? json['title'] ?? json['id'] ?? entity;
        subtitle = json['id']?.toString();
    }

    return DeletedRecord(
      id: json['id']?.toString() ?? json['_id']?.toString() ?? '',
      entity: entity,
      displayName: name,
      subtitle: subtitle,
      deletedAt: json['deletedAt']?.toString(),
      raw: json,
    );
  }
}

class TrashRestoreNotifier extends ChangeNotifier {
  // Map of entity -> list of deleted records
  final Map<String, List<DeletedRecord>> _deletedData = {};
  final Map<String, bool> _loadingMap = {};
  bool _restoring = false;
  String? _error;

  static const List<String> supportedEntities = [
    'user',
    'school',
    'class',
    'section',
    'subject',
    'pricing',
    'subscription',
    'homework',
    'attendance',
  ];

  List<DeletedRecord> recordsFor(String entity) => _deletedData[entity] ?? [];
  bool isLoadingEntity(String entity) => _loadingMap[entity] ?? false;
  bool get restoring => _restoring;
  String? get error => _error;

  int get totalDeleted => _deletedData.values.fold(0, (s, l) => s + l.length);

  Future<void> fetchAll() async {
    for (final entity in supportedEntities) {
      await fetchEntity(entity);
    }
  }

  Future<void> fetchEntity(String entity) async {
    _loadingMap[entity] = true;
    _error = null;
    notifyListeners();

    try {
      final token = await StorageService.getToken();
      if (token == null) throw Exception('No authentication token found');

      final response = await DataProvider().performRequest(
        'GET',
        APIPath.deletedRecords(entity),
        header: {'Authorization': 'Bearer $token'},
      );

      if (response != null && response.statusCode == 200) {
        final dynamic rawData = response.data;
        final List dataList = rawData is List
            ? rawData
            : (rawData is Map ? (rawData['data'] ?? rawData['records'] ?? []) : []);

        _deletedData[entity] =
            dataList.map((j) => DeletedRecord.fromJson(j as Map<String, dynamic>, entity)).toList();
        log('[Trash] Fetched ${_deletedData[entity]!.length} deleted $entity records');
      } else {
        // Gracefully handle 404 / entity not supported — just show empty
        _deletedData[entity] = [];
        log('[Trash] Non-200 for $entity: ${response?.statusCode}');
      }
    } catch (e) {
      _deletedData[entity] = [];
      log('[Trash] Exception fetching deleted $entity: $e');
    } finally {
      _loadingMap[entity] = false;
      notifyListeners();
    }
  }

  Future<bool> restoreRecord(DeletedRecord record) async {
    _restoring = true;
    _error = null;
    notifyListeners();

    try {
      final token = await StorageService.getToken();
      if (token == null) throw Exception('No authentication token found');

      final response = await DataProvider().performRequest(
        'POST',
        APIPath.restoreRecord,
        header: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        data: {'entity': record.entity, 'id': record.id},
      );

      if (response != null &&
          (response.statusCode == 200 || response.statusCode == 201)) {
        // Remove from local list
        _deletedData[record.entity]?.removeWhere((r) => r.id == record.id);
        log('[Trash] Restored ${record.entity} id=${record.id}');
        return true;
      } else {
        _error = 'Restore failed: ${response?.statusCode}';
        log('[Trash] Restore failed: ${response?.data}');
        return false;
      }
    } catch (e) {
      _error = 'Error restoring record: $e';
      log('[Trash] Exception restoring: $e');
      return false;
    } finally {
      _restoring = false;
      notifyListeners();
    }
  }
}
