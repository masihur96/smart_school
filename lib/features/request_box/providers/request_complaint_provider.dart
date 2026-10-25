import 'dart:developer';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:smart_school/configs/network/data_provider.dart';
import 'package:smart_school/core/constants/api_path.dart';
import 'package:smart_school/core/utils/storage_service.dart';
import '../models/request_complaint_model.dart';

class RequestComplaintProvider extends ChangeNotifier {
  final DataProvider _dataProvider = DataProvider();

  List<RequestComplaintModel> _items = [];
  bool _isLoading = false;
  bool _isLoadingMore = false;
  bool _isSubmitting = false;
  bool _isUpdatingStatus = false;
  bool _isAddingComment = false;
  bool _isLoadingDetail = false;
  bool _isDeleting = false;
  bool _isUploadingAttachment = false;
  String? _errorMessage;

  // Pagination
  int _page = 1;
  final int _limit = 10;
  int _total = 0;
  int _totalPages = 1;

  // Filters
  String _selectedType = 'ALL'; // ALL, REQUEST, COMPLAINT
  String _selectedStatus = 'ALL'; // ALL, PENDING, IN_PROGRESS, RESOLVED, REJECTED
  String _selectedPriority = 'ALL'; // ALL, LOW, MEDIUM, HIGH, URGENT
  String _selectedCategory = 'ALL'; // ALL, ACADEMIC, ATTENDANCE, LEAVE, FACILITY, FEE, DISCIPLINE, BEHAVIOR, EXAM, OTHER
  String _selectedScope = 'ALL'; // ALL, received, sent
  String _searchQuery = '';

  // Potential recipients cache
  List<RequestComplaintUser> _potentialRecipients = [];
  List<RequestComplaintUser> _recipientTeachers = [];
  List<RequestComplaintUser> _recipientStudents = [];
  bool _isLoadingRecipients = false;
  String? _currentRecipientsClassId;

  // Getters
  List<RequestComplaintModel> get items => _items;
  bool get isLoading => _isLoading;
  bool get isLoadingMore => _isLoadingMore;
  bool get isSubmitting => _isSubmitting;
  bool get isUpdatingStatus => _isUpdatingStatus;
  bool get isAddingComment => _isAddingComment;
  bool get isLoadingDetail => _isLoadingDetail;
  bool get isDeleting => _isDeleting;
  bool get isUploadingAttachment => _isUploadingAttachment;
  String? get errorMessage => _errorMessage;
  int get page => _page;
  int get total => _total;
  int get totalPages => _totalPages;
  bool get hasMore => _page < _totalPages;

  String get selectedType => _selectedType;
  String get selectedStatus => _selectedStatus;
  String get selectedPriority => _selectedPriority;
  String get selectedCategory => _selectedCategory;
  String get selectedScope => _selectedScope;
  String get searchQuery => _searchQuery;
  List<RequestComplaintUser> get potentialRecipients => _potentialRecipients;
  List<RequestComplaintUser> get recipientTeachers => _recipientTeachers;
  List<RequestComplaintUser> get recipientStudents => _recipientStudents;
  bool get isLoadingRecipients => _isLoadingRecipients;
  String? get currentRecipientsClassId => _currentRecipientsClassId;

  void setType(String type, {String? schoolId}) {
    if (_selectedType == type) return;
    _selectedType = type;
    notifyListeners();
    fetchRequestComplaints(refresh: true, schoolId: schoolId);
  }

  void setScope(String scope, {String? schoolId}) {
    if (_selectedScope == scope) return;
    _selectedScope = scope;
    notifyListeners();
    fetchRequestComplaints(refresh: true, schoolId: schoolId);
  }

  void setStatus(String status, {String? schoolId}) {
    if (_selectedStatus == status) return;
    _selectedStatus = status;
    notifyListeners();
    fetchRequestComplaints(refresh: true, schoolId: schoolId);
  }

  void setPriority(String priority, {String? schoolId}) {
    if (_selectedPriority == priority) return;
    _selectedPriority = priority;
    notifyListeners();
    fetchRequestComplaints(refresh: true, schoolId: schoolId);
  }

  void setCategory(String category, {String? schoolId}) {
    if (_selectedCategory == category) return;
    _selectedCategory = category;
    notifyListeners();
    fetchRequestComplaints(refresh: true, schoolId: schoolId);
  }

  void setSearchQuery(String query, {String? schoolId}) {
    _searchQuery = query;
    notifyListeners();
    fetchRequestComplaints(refresh: true, schoolId: schoolId);
  }

  void resetFilters({String? schoolId}) {
    _selectedType = 'ALL';
    _selectedStatus = 'ALL';
    _selectedPriority = 'ALL';
    _selectedCategory = 'ALL';
    _selectedScope = 'ALL';
    _searchQuery = '';
    notifyListeners();
    fetchRequestComplaints(refresh: true, schoolId: schoolId);
  }

  Future<void> fetchRequestComplaints({
    bool refresh = false,
    String? schoolId,
  }) async {
    if (refresh) {
      _page = 1;
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();
    } else {
      if (_isLoadingMore || !hasMore) return;
      _isLoadingMore = true;
      _page++;
      notifyListeners();
    }

    try {
      final token = await StorageService.getToken();
      if (token == null) {
        _errorMessage = 'User not authenticated';
        _isLoading = false;
        _isLoadingMore = false;
        notifyListeners();
        return;
      }

      final Map<String, dynamic> query = {
        'page': _page.toString(),
        'limit': _limit.toString(),
      };

      if (_selectedType != 'ALL') query['type'] = _selectedType;
      if (_selectedStatus != 'ALL') query['status'] = _selectedStatus;
      if (_selectedPriority != 'ALL') query['priority'] = _selectedPriority;
      if (_selectedCategory != 'ALL') query['category'] = _selectedCategory;
      if (_selectedScope != 'ALL') query['scope'] = _selectedScope;
      if (_searchQuery.trim().isNotEmpty) {
        query['search'] = _searchQuery.trim();
      }
      if (schoolId != null && schoolId.isNotEmpty) {
        query['schoolId'] = schoolId;
      }

      final response = await _dataProvider.performRequest(
        'GET',
        APIPath.requestComplaints,
        query: query,
        header: {
          'accept': '*/*',
          'Authorization': 'Bearer $token',
        },
      );

      if (response != null &&
          (response.statusCode == 200 || response.statusCode == 201)) {
        final dynamic raw = response.data;
        List<dynamic> listData = [];

        if (raw is Map && raw['data'] != null) {
          final dataObj = raw['data'];
          if (dataObj is Map) {
            final innerData = dataObj['data'];
            if (innerData is List) {
              listData = innerData;
            }
            _total = int.tryParse(dataObj['total']?.toString() ?? '0') ??
                listData.length;
            _totalPages =
                int.tryParse(dataObj['totalPages']?.toString() ?? '1') ?? 1;
          } else if (dataObj is List) {
            listData = dataObj;
            _total = listData.length;
            _totalPages = 1;
          }
        }

        final parsedList = listData
            .map((item) {
              try {
                return RequestComplaintModel.fromJson(
                    item as Map<String, dynamic>);
              } catch (e) {
                log('Error parsing RequestComplaintModel: $e');
                return null;
              }
            })
            .whereType<RequestComplaintModel>()
            .toList();

        if (refresh) {
          _items = parsedList;
        } else {
          _items.addAll(parsedList);
        }
        _errorMessage = null;
      } else {
        final msg = response?.data is Map
            ? (response?.data['message']?.toString() ?? 'Failed to load data')
            : 'Failed to load requests and complaints';
        _errorMessage = msg;
      }
    } catch (e) {
      log('RequestComplaintProvider fetch error: $e');
      _errorMessage = 'An error occurred: $e';
    } finally {
      _isLoading = false;
      _isLoadingMore = false;
      notifyListeners();
    }
  }

  Future<bool> createRequestComplaint({
    required String type, // REQUEST or COMPLAINT
    required String title,
    required String description,
    required String category,
    required String priority,
    String? recipientId,
    List<String> attachments = const [],
    String? schoolId,
  }) async {
    _isSubmitting = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final token = await StorageService.getToken();
      if (token == null) {
        _errorMessage = 'User not authenticated';
        _isSubmitting = false;
        notifyListeners();
        return false;
      }

      final Map<String, dynamic> body = {
        'type': type,
        'title': title,
        'description': description,
        'category': category,
        'priority': priority,
        'attachments': attachments,
      };

      if (recipientId != null && recipientId.isNotEmpty) {
        body['recipientId'] = recipientId;
      }
      if (schoolId != null && schoolId.isNotEmpty) {
        body['schoolId'] = schoolId;
      }

      final response = await _dataProvider.performRequest(
        'POST',
        APIPath.requestComplaints,
        data: body,
        header: {
          'accept': '*/*',
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response != null &&
          (response.statusCode == 200 || response.statusCode == 201)) {
        // Successfully created! Refresh list
        await fetchRequestComplaints(refresh: true, schoolId: schoolId);
        _isSubmitting = false;
        notifyListeners();
        return true;
      } else {
        String msg = 'Failed to submit request/complaint';
        if (response?.data is Map) {
          final resMsg = response!.data['message'];
          if (resMsg is List) {
            msg = resMsg.join('\n');
          } else if (resMsg != null) {
            msg = resMsg.toString();
          }
        }
        _errorMessage = msg;
        _isSubmitting = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      log('createRequestComplaint error: $e');
      _errorMessage = 'An error occurred while submitting: $e';
      _isSubmitting = false;
      notifyListeners();
      return false;
    }
  }

  Future<RequestComplaintModel?> updateStatus({
    required String id,
    required String status,
    String? resolutionNote,
  }) async {
    _isUpdatingStatus = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final token = await StorageService.getToken();
      if (token == null) {
        _errorMessage = 'User not authenticated';
        _isUpdatingStatus = false;
        notifyListeners();
        return null;
      }

      final Map<String, dynamic> body = {
        'status': status,
      };
      if (resolutionNote != null && resolutionNote.trim().isNotEmpty) {
        body['resolutionNote'] = resolutionNote.trim();
      }

      final response = await _dataProvider.performRequest(
        'PATCH',
        APIPath.updateRequestComplaintStatus(id),
        data: body,
        header: {
          'accept': '*/*',
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response != null &&
          (response.statusCode == 200 || response.statusCode == 201)) {
        RequestComplaintModel? updatedItem;
        if (response.data is Map && response.data['data'] != null) {
          try {
            updatedItem = RequestComplaintModel.fromJson(
              response.data['data'] as Map<String, dynamic>,
            );
          } catch (e) {
            log('Error parsing updated item: $e');
          }
        }

        // Update in current list if present
        final idx = _items.indexWhere((i) => i.id == id);
        if (idx != -1 && updatedItem != null) {
          _items[idx] = updatedItem;
        }

        _isUpdatingStatus = false;
        notifyListeners();
        return updatedItem;
      } else {
        String msg = 'Failed to update status';
        if (response?.data is Map) {
          final resMsg = response!.data['message'];
          if (resMsg is List) {
            msg = resMsg.join('\n');
          } else if (resMsg != null) {
            msg = resMsg.toString();
          }
        }
        _errorMessage = msg;
        _isUpdatingStatus = false;
        notifyListeners();
        return null;
      }
    } catch (e) {
      log('updateStatus error: $e');
      _errorMessage = 'An error occurred while updating status: $e';
      _isUpdatingStatus = false;
      notifyListeners();
      return null;
    }
  }

  Future<RequestComplaintModel?> fetchRequestComplaintDetail(String id) async {
    _isLoadingDetail = true;
    notifyListeners();

    try {
      final token = await StorageService.getToken();
      if (token == null) {
        _isLoadingDetail = false;
        notifyListeners();
        return null;
      }

      final response = await _dataProvider.performRequest(
        'GET',
        APIPath.requestComplaint(id),
        header: {
          'accept': '*/*',
          'Authorization': 'Bearer $token',
        },
      );

      if (response != null &&
          (response.statusCode == 200 || response.statusCode == 201)) {
        if (response.data is Map && response.data['data'] != null) {
          final item = RequestComplaintModel.fromJson(
            response.data['data'] as Map<String, dynamic>,
          );

          // Update in memory items list
          final idx = _items.indexWhere((i) => i.id == id);
          if (idx != -1) {
            _items[idx] = item;
          }

          _isLoadingDetail = false;
          notifyListeners();
          return item;
        }
      }
    } catch (e) {
      log('fetchRequestComplaintDetail error: $e');
    } finally {
      _isLoadingDetail = false;
      notifyListeners();
    }
    return null;
  }

  Future<bool> addComment({
    required String id,
    required String message,
    List<String> attachments = const [],
  }) async {
    _isAddingComment = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final token = await StorageService.getToken();
      if (token == null) {
        _errorMessage = 'User not authenticated';
        _isAddingComment = false;
        notifyListeners();
        return false;
      }

      final Map<String, dynamic> body = {
        'message': message.trim(),
        'attachments': attachments,
      };

      await _dataProvider.performRequest(
        'POST',
        APIPath.requestComplaintComments(id),
        data: body,
        header: {
          'accept': '*/*',
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      // Re-fetch detail to refresh comments thread with populated author/sender
      await fetchRequestComplaintDetail(id);

      _isAddingComment = false;
      notifyListeners();
      return true;
    } catch (e) {
      log('addComment error: $e');
      // Still attempt to re-fetch in case database insertion succeeded
      await fetchRequestComplaintDetail(id);
      _isAddingComment = false;
      notifyListeners();
      return true;
    }
  }

  Future<bool> deleteRequestComplaint(String id) async {
    _isDeleting = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final token = await StorageService.getToken();
      if (token == null) {
        _errorMessage = 'User not authenticated';
        _isDeleting = false;
        notifyListeners();
        return false;
      }

      final response = await _dataProvider.performRequest(
        'DELETE',
        APIPath.requestComplaint(id),
        header: {
          'accept': '*/*',
          'Authorization': 'Bearer $token',
        },
      );

      if (response != null &&
          (response.statusCode == 200 ||
              response.statusCode == 201 ||
              response.statusCode == 204)) {
        _items.removeWhere((item) => item.id == id);
        _total = (_total - 1).clamp(0, double.infinity).toInt();
        _isDeleting = false;
        notifyListeners();
        return true;
      } else {
        String msg = 'Failed to delete request/complaint';
        if (response?.data is Map) {
          final resMsg = response!.data['message'];
          if (resMsg is List) {
            msg = resMsg.join('\n');
          } else if (resMsg != null) {
            msg = resMsg.toString();
          }
        }
        _errorMessage = msg;
        _isDeleting = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      log('deleteRequestComplaint error: $e');
      _errorMessage = 'An error occurred while deleting: $e';
      _isDeleting = false;
      notifyListeners();
      return false;
    }
  }

  Future<String?> uploadAttachment(File file) async {
    _isUploadingAttachment = true;
    notifyListeners();

    try {
      final token = await StorageService.getToken();
      final fileName = file.path.split('/').last;

      final formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(file.path, filename: fileName),
      });

      final response = await _dataProvider.performRequest(
        'POST',
        '${APIPath.baseUrl}/general/upload',
        data: formData,
        header: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'multipart/form-data',
        },
      );

      if (response != null &&
          (response.statusCode == 200 || response.statusCode == 201)) {
        final url = response.data['data']?['url']?.toString();
        log('Uploaded attachment successfully: $url');
        return url;
      } else {
        log('Failed uploading attachment: ${response?.data}');
        return null;
      }
    } catch (e) {
      log('Error uploading attachment: $e');
      return null;
    } finally {
      _isUploadingAttachment = false;
      notifyListeners();
    }
  }

  Future<void> fetchPotentialRecipients({
    String? classId,
    String? schoolId,
    bool force = false,
  }) async {
    if (!force &&
        _potentialRecipients.isNotEmpty &&
        _currentRecipientsClassId == classId) {
      return;
    }
    _isLoadingRecipients = true;
    _currentRecipientsClassId = classId;
    notifyListeners();

    try {
      final token = await StorageService.getToken();
      if (token == null) {
        _isLoadingRecipients = false;
        notifyListeners();
        return;
      }

      final Map<String, dynamic> query = {};
      if (classId != null && classId.isNotEmpty) {
        query['classId'] = classId;
      }

      final response = await _dataProvider.performRequest(
        'GET',
        APIPath.requestComplaintRecipients(),
        query: query.isNotEmpty ? query : null,
        header: {
          'accept': '*/*',
          'Authorization': 'Bearer $token',
        },
      );

      if (response != null &&
          (response.statusCode == 200 || response.statusCode == 201)) {
        final dynamic raw = response.data;
        List<RequestComplaintUser> teachersList = [];
        List<RequestComplaintUser> studentsList = [];
        List<RequestComplaintUser> otherList = [];

        if (raw is Map && raw['data'] != null) {
          final dataObj = raw['data'];
          if (dataObj is Map) {
            if (dataObj['teachers'] is List) {
              teachersList = (dataObj['teachers'] as List)
                  .map((t) {
                    try {
                      return RequestComplaintUser.fromJson(
                          t as Map<String, dynamic>);
                    } catch (e) {
                      log('Error parsing teacher: $e');
                      return null;
                    }
                  })
                  .whereType<RequestComplaintUser>()
                  .toList();
            }
            if (dataObj['students'] is List) {
              studentsList = (dataObj['students'] as List)
                  .map((s) {
                    try {
                      return RequestComplaintUser.fromJson(
                          s as Map<String, dynamic>);
                    } catch (e) {
                      log('Error parsing student: $e');
                      return null;
                    }
                  })
                  .whereType<RequestComplaintUser>()
                  .toList();
            }
            if (dataObj['admins'] is List) {
              final admins = (dataObj['admins'] as List)
                  .map((a) {
                    try {
                      return RequestComplaintUser.fromJson(
                          a as Map<String, dynamic>);
                    } catch (_) {
                      return null;
                    }
                  })
                  .whereType<RequestComplaintUser>()
                  .toList();
              otherList.addAll(admins);
            }
          } else if (dataObj is List) {
            otherList = dataObj
                .map((u) {
                  try {
                    return RequestComplaintUser.fromJson(
                        u as Map<String, dynamic>);
                  } catch (_) {
                    return null;
                  }
                })
                .whereType<RequestComplaintUser>()
                .toList();
          }
        }

        _recipientTeachers = teachersList;
        _recipientStudents = studentsList;
        _potentialRecipients = [...teachersList, ...studentsList, ...otherList];
      }
    } catch (e) {
      log('fetchPotentialRecipients error: $e');
    } finally {
      _isLoadingRecipients = false;
      notifyListeners();
    }
  }
}
