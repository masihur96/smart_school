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
        name =
            json['name'] ?? json['username'] ?? json['email'] ?? 'Unknown User';
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
        subtitle = json['pricePerMonth'] != null
            ? '\$${json['pricePerMonth']}/mo'
            : (json['price'] != null ? '\$${json['price']}' : null);
        break;
      case 'subscription':
        name =
            json['school']?['name'] ??
            json['schoolId'] ??
            'Unknown Subscription';
        subtitle = json['pricingPlan']?['name'] ?? json['planId'];
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
  bool _deleting = false;
  String? _error;

  // Selection state for bulk operations
  final Set<String> _selectedIds = {};
  bool _selectionMode = false;

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
  bool get deleting => _deleting;
  String? get error => _error;

  bool _isLoadingAll = false;
  bool get isLoadingAll => _isLoadingAll;

  int get totalDeleted => _deletedData.values.fold(0, (s, l) => s + l.length);

  // ─── Selection helpers ──────────────────────────────────────────────────────
  bool get selectionMode => _selectionMode;
  Set<String> get selectedIds => Set.unmodifiable(_selectedIds);
  int get selectedCount => _selectedIds.length;
  bool isSelected(String id) => _selectedIds.contains(id);

  void enterSelectionMode([String? id]) {
    _selectionMode = true;
    if (id != null && id.isNotEmpty) {
      _selectedIds.add(id);
    }
    notifyListeners();
  }

  void toggleSelection(String id) {
    if (_selectedIds.contains(id)) {
      _selectedIds.remove(id);
    } else {
      _selectedIds.add(id);
    }
    if (_selectedIds.isEmpty) _selectionMode = false;
    notifyListeners();
  }

  void selectAll(String entity) {
    final records = _deletedData[entity] ?? [];
    _selectedIds.addAll(records.map((r) => r.id));
    notifyListeners();
  }

  void selectAllVisible(List<DeletedRecord> records) {
    _selectedIds.addAll(records.map((r) => r.id));
    notifyListeners();
  }

  void clearSelection() {
    _selectedIds.clear();
    _selectionMode = false;
    notifyListeners();
  }

  bool areAllSelected(List<DeletedRecord> records) {
    if (records.isEmpty) return false;
    return records.every((r) => _selectedIds.contains(r.id));
  }

  // ─── Fetch ──────────────────────────────────────────────────────────────────
  Future<void> fetchAll() async {
    await fetchAllFromTrash();
  }

  Future<void> fetchAllFromTrash() async {
    _isLoadingAll = true;
    _error = null;
    notifyListeners();

    try {
      final token = await StorageService.getToken();
      if (token == null) throw Exception('No authentication token found');

      final response = await DataProvider().performRequest(
        'GET',
        APIPath.trash,
        header: {'Authorization': 'Bearer $token'},
      );

      if (response != null && response.statusCode == 200) {
        final dynamic body = response.data;
        final dynamic nestedData = (body is Map) ? body['data'] : null;

        // Clear old data
        _deletedData.clear();

        if (nestedData is Map<String, dynamic>) {
          nestedData.forEach((key, value) {
            if (key == 'summary') return; // Skip summary object

            String entityKey = key;

            // Map backend keys to internal supported entities
            if (key == 'pricingPlans') {
              entityKey = 'pricing';
            } else if (key == 'subscriptions') {
              entityKey = 'subscription';
            } else if (key == 'users') {
              entityKey = 'user';
            } else if (key == 'schools') {
              entityKey = 'school';
            } else if (key == 'classes') {
              entityKey = 'class';
            } else if (key == 'sections') {
              entityKey = 'section';
            } else if (key == 'subjects') {
              entityKey = 'subject';
            }

            // Fallback plural check (e.g. homeworks -> homework)
            if (!supportedEntities.contains(entityKey) && key.endsWith('s')) {
              final singular = key.substring(0, key.length - 1);
              if (supportedEntities.contains(singular)) {
                entityKey = singular;
              }
            }

            if (value is List && supportedEntities.contains(entityKey)) {
              _deletedData[entityKey] = value
                  .map(
                    (j) => DeletedRecord.fromJson(
                      j as Map<String, dynamic>,
                      entityKey,
                    ),
                  )
                  .toList();
            }
          });
          log(
            '[Trash] Fetched consolidated data: $totalDeleted records across ${_deletedData.length} categories',
          );
        }
      } else {
        _error = 'Failed to fetch trash: ${response?.statusCode}';
        log('[Trash] consolidated fetch failed: ${response?.statusCode}');
      }
    } catch (e) {
      _error = 'Error fetching trash: $e';
      log('[Trash] Exception in fetchAllFromTrash: $e');
    } finally {
      _isLoadingAll = false;
      notifyListeners();
    }
  }

  Future<void> fetchEntity(String entity) async {
    // Keep this for individual refreshes if needed, but usually redundant now
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
            : (rawData is Map
                  ? (rawData['data'] ?? rawData['records'] ?? [])
                  : []);

        _deletedData[entity] = dataList
            .map(
              (j) => DeletedRecord.fromJson(j as Map<String, dynamic>, entity),
            )
            .toList();
        log(
          '[Trash] Fetched ${_deletedData[entity]!.length} deleted $entity records',
        );
      } else {
        _deletedData[entity] = [];
      }
    } catch (e) {
      _deletedData[entity] = [];
    } finally {
      _loadingMap[entity] = false;
      notifyListeners();
    }
  }

  // ─── Restore ────────────────────────────────────────────────────────────────
  Future<bool> restoreRecord(DeletedRecord record) async {
    _restoring = true;
    _error = null;
    notifyListeners();

    try {
      final token = await StorageService.getToken();
      if (token == null) throw Exception('No authentication token found');

      final response = await DataProvider().performRequest(
        'PATCH',
        APIPath.restore(record.entity, record.id),
        header: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response != null &&
          (response.statusCode == 200 || response.statusCode == 201)) {
        _deletedData[record.entity]?.removeWhere((r) => r.id == record.id);
        _selectedIds.remove(record.id);
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

  // ─── Permanent Delete (single) ──────────────────────────────────────────────
  Future<bool> permanentDelete(DeletedRecord record) async {
    _deleting = true;
    _error = null;
    notifyListeners();

    try {
      final token = await StorageService.getToken();
      if (token == null) throw Exception('No authentication token found');

      final response = await DataProvider().performRequest(
        'DELETE',
        APIPath.permanentDelete(record.entity, record.id),
        header: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response != null &&
          (response.statusCode == 200 ||
              response.statusCode == 204 ||
              response.statusCode == 201)) {
        _deletedData[record.entity]?.removeWhere((r) => r.id == record.id);
        _selectedIds.remove(record.id);
        log('[Trash] Permanently deleted ${record.entity} id=${record.id}');
        return true;
      } else {
        _error = 'Delete failed: ${response?.statusCode}';
        log('[Trash] Permanent delete failed: ${response?.data}');
        return false;
      }
    } catch (e) {
      _error = 'Error deleting record: $e';
      log('[Trash] Exception permanently deleting: $e');
      return false;
    } finally {
      _deleting = false;
      notifyListeners();
    }
  }

  // ─── Permanent Delete (bulk) ────────────────────────────────────────────────
  Future<({int succeeded, int failed})> permanentDeleteBulk(
    String entity,
    List<String> ids,
  ) async {
    _deleting = true;
    _error = null;
    notifyListeners();

    int succeeded = 0;
    int failed = 0;

    try {
      final token = await StorageService.getToken();
      if (token == null) throw Exception('No authentication token found');

      final response = await DataProvider().performRequest(
        'DELETE',
        APIPath.permanentDeleteBulk(entity),
        header: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        data: {'ids': ids},
      );

      if (response != null &&
          (response.statusCode == 200 ||
              response.statusCode == 204 ||
              response.statusCode == 201)) {
        // Remove all selected IDs locally
        _deletedData[entity]?.removeWhere((r) => ids.contains(r.id));
        _selectedIds.removeAll(ids);
        succeeded = ids.length;
        log('[Trash] Bulk deleted $succeeded ${entity} records');
      } else {
        // Fallback: delete one by one
        log(
          '[Trash] Bulk endpoint failed (${response?.statusCode}), falling back to sequential deletes',
        );
        for (final id in ids) {
          try {
            final res = await DataProvider().performRequest(
              'DELETE',
              APIPath.permanentDelete(entity, id),
              header: {
                'Authorization': 'Bearer $token',
                'Content-Type': 'application/json',
              },
            );
            if (res != null &&
                (res.statusCode == 200 ||
                    res.statusCode == 204 ||
                    res.statusCode == 201)) {
              _deletedData[entity]?.removeWhere((r) => r.id == id);
              _selectedIds.remove(id);
              succeeded++;
            } else {
              failed++;
            }
          } catch (_) {
            failed++;
          }
        }
        if (failed > 0) {
          _error = '$failed record(s) could not be deleted.';
        }
      }
    } catch (e) {
      _error = 'Error during bulk delete: $e';
      log('[Trash] Exception in permanentDeleteBulk: $e');
    } finally {
      if (_selectedIds.isEmpty) _selectionMode = false;
      _deleting = false;
      notifyListeners();
    }

    return (succeeded: succeeded, failed: failed);
  }

  // ─── Restore bulk (selected) ────────────────────────────────────────────────
  Future<({int succeeded, int failed})> restoreSelected(
    String entity,
    List<String> ids,
  ) async {
    _restoring = true;
    _error = null;
    notifyListeners();

    int succeeded = 0;
    int failed = 0;

    try {
      final token = await StorageService.getToken();
      if (token == null) throw Exception('No authentication token found');

      for (final id in ids) {
        try {
          final res = await DataProvider().performRequest(
            'PATCH',
            APIPath.restore(entity, id),
            header: {
              'Authorization': 'Bearer $token',
              'Content-Type': 'application/json',
            },
          );
          if (res != null && (res.statusCode == 200 || res.statusCode == 201)) {
            _deletedData[entity]?.removeWhere((r) => r.id == id);
            _selectedIds.remove(id);
            succeeded++;
          } else {
            failed++;
          }
        } catch (_) {
          failed++;
        }
      }
    } catch (e) {
      _error = 'Error during bulk restore: $e';
    } finally {
      if (_selectedIds.isEmpty) _selectionMode = false;
      _restoring = false;
      notifyListeners();
    }

    return (succeeded: succeeded, failed: failed);
  }
}
