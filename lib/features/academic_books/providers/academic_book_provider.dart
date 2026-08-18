import 'dart:developer';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:smart_school/core/utils/storage_service.dart';

import '../../../configs/network/data_provider.dart';
import '../../../core/constants/api_path.dart';
import '../models/academic_book.dart';

class AcademicBookNotifier extends ChangeNotifier {
  List<AcademicBook> _books = [];
  bool _isLoading = false;
  bool _isUploading = false;
  String? _error;

  List<AcademicBook> get books => _books;
  bool get isLoading => _isLoading;
  bool get isUploading => _isUploading;
  String? get error => _error;

  // ── Fetch ──────────────────────────────────────────────────────────────────

  Future<void> fetchBooks({String? schoolId, String? classId}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final token = await StorageService.getToken();
      if (token == null) throw Exception('No authentication token found');

      final Map<String, dynamic> query = {};
      if (schoolId != null && schoolId.isNotEmpty) query['schoolId'] = schoolId;
      if (classId != null && classId.isNotEmpty) query['classId'] = classId;

      final response = await DataProvider().performRequest(
        'GET',
        APIPath.academicEbooks,
        query: query.isEmpty ? null : query,
        header: {'Authorization': 'Bearer $token'},
      );

      if (response != null && response.statusCode == 200) {
        final raw = response.data;
        List<dynamic> data = [];
        if (raw is List) {
          data = raw;
        } else if (raw is Map) {
          final inner = raw['data'];
          if (inner is List) {
            data = inner;
          } else if (inner is Map) {
            data = inner['data'] as List<dynamic>? ?? [];
          }
        }
        _books = data.map((e) => AcademicBook.fromJson(e)).toList();
        log('AcademicBookNotifier: fetched ${_books.length} books');

        // If API returns empty (no backend data yet), show dummy data for UI testing
        if (_books.isEmpty) {}
      } else {
        log('AcademicBookNotifier: fetch error ${response?.data}');
        _error = 'Failed to load books. Showing dummy data.';
      }
    } catch (e) {
      log('AcademicBookNotifier: exception $e');
      _error = 'Network error. Showing dummy data.';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ── Upload PDF file ────────────────────────────────────────────────────────

  Future<String?> uploadPdf(File file) async {
    _isUploading = true;
    notifyListeners();

    try {
      final token = await StorageService.getToken();
      if (token == null) throw Exception('No authentication token found');

      final formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(
          file.path,
          filename: file.path.split('/').last,
        ),
      });

      final response = await DataProvider().performRequest(
        'POST',
        '${APIPath.baseUrl}/general/upload',
        header: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'multipart/form-data',
        },
        data: formData,
      );

      if (response != null &&
          (response.statusCode == 200 || response.statusCode == 201)) {
        final url = response.data['data']?['url'] as String?;
        log('AcademicBookNotifier: PDF uploaded → $url');
        return url;
      } else {
        log('AcademicBookNotifier: PDF upload failed ${response?.data}');
        return null;
      }
    } catch (e) {
      log('AcademicBookNotifier: upload exception $e');
      return null;
    } finally {
      _isUploading = false;
      notifyListeners();
    }
  }

  // ── Upload image file (cover) ──────────────────────────────────────────────

  Future<String?> uploadImage(File file) async {
    _isUploading = true;
    notifyListeners();

    try {
      final token = await StorageService.getToken();
      if (token == null) throw Exception('No authentication token found');

      final formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(
          file.path,
          filename: file.path.split('/').last,
        ),
      });

      final response = await DataProvider().performRequest(
        'POST',
        '${APIPath.baseUrl}/general/upload',
        header: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'multipart/form-data',
        },
        data: formData,
      );

      if (response != null &&
          (response.statusCode == 200 || response.statusCode == 201)) {
        final url = response.data['data']?['url'] as String?;
        log('AcademicBookNotifier: image uploaded → $url');
        return url;
      } else {
        log('AcademicBookNotifier: image upload failed ${response?.data}');
        return null;
      }
    } catch (e) {
      log('AcademicBookNotifier: image upload exception $e');
      return null;
    } finally {
      _isUploading = false;
      notifyListeners();
    }
  }

  // ── Add book (POST /academic-ebooks) ──────────────────────────────────────

  Future<bool> addBook({
    required String title,
    required String author,
    required String classId,
    required String subject,
    required String pdfUrl,
    String coverImageUrl = '',
    String description = '',
    int totalPages = 0,
    int publishedYear = 0,
    bool isActive = true,
    // Legacy / local-state helpers
    String className = '',
    String subjectId = '',
    String subjectName = '',
    String schoolId = '',
    String uploadedBy = '',
  }) async {
    try {
      final token = await StorageService.getToken();
      if (token == null) return false;

      final body = <String, dynamic>{
        'title': title,
        'author': author,
        'classId': classId,
        'subject': subject,
        'pdfUrl': pdfUrl,
        'isActive': isActive,
      };
      if (coverImageUrl.isNotEmpty) body['coverImageUrl'] = coverImageUrl;
      if (description.isNotEmpty) body['description'] = description;
      if (totalPages > 0) body['totalPages'] = totalPages;
      if (publishedYear > 0) body['publishedYear'] = publishedYear;

      final response = await DataProvider().performRequest(
        'POST',
        APIPath.academicEbooks,
        data: body,
        header: {'Authorization': 'Bearer $token'},
      );

      if (response != null &&
          (response.statusCode == 200 || response.statusCode == 201)) {
        // Try to parse returned object; fallback to local optimistic add
        final raw = response.data['data'] ?? response.data;
        AcademicBook book;
        try {
          book = AcademicBook.fromJson(
            raw is Map<String, dynamic>
                ? raw
                : {
                    'id': DateTime.now().millisecondsSinceEpoch.toString(),
                    'title': title,
                    'author': author,
                    'classId': classId,
                    'subject': subject,
                    'pdfUrl': pdfUrl,
                    'coverImageUrl': coverImageUrl,
                    'description': description,
                    'totalPages': totalPages,
                    'publishedYear': publishedYear,
                    'isActive': isActive,
                    'schoolId': schoolId,
                    'uploadedBy': uploadedBy,
                    'createdAt': DateTime.now().toIso8601String(),
                  },
          );
        } catch (_) {
          book = AcademicBook(
            id: DateTime.now().millisecondsSinceEpoch.toString(),
            title: title,
            author: author,
            classId: classId,
            className: className,
            subject: subject,
            subjectId: subjectId,
            subjectName: subjectName,
            pdfUrl: pdfUrl,
            coverImageUrl: coverImageUrl,
            description: description,
            totalPages: totalPages,
            publishedYear: publishedYear,
            isActive: isActive,
            schoolId: schoolId,
            uploadedBy: uploadedBy,
            createdAt: DateTime.now(),
          );
        }
        _books = [book, ..._books];
        notifyListeners();
        return true;
      }

      log('AcademicBookNotifier: addBook failed ${response?.data}');
      return false;
    } catch (e) {
      log('AcademicBookNotifier: addBook exception $e');
      return false;
    }
  }

  // ── Update book (PUT /academic-ebooks/:id) ────────────────────────────────

  Future<bool> updateBook({
    required String id,
    required String title,
    required String author,
    required String classId,
    required String subject,
    required String pdfUrl,
    String coverImageUrl = '',
    String description = '',
    int totalPages = 0,
    int publishedYear = 0,
    bool isActive = true,
    // Legacy / local-state helpers
    String className = '',
    String subjectId = '',
    String subjectName = '',
  }) async {
    try {
      final token = await StorageService.getToken();
      if (token == null) return false;

      final body = <String, dynamic>{
        'title': title,
        'author': author,
        'classId': classId,
        'subject': subject,
        'pdfUrl': pdfUrl,
        'isActive': isActive,
      };
      if (coverImageUrl.isNotEmpty) body['coverImageUrl'] = coverImageUrl;
      if (description.isNotEmpty) body['description'] = description;
      if (totalPages > 0) body['totalPages'] = totalPages;
      if (publishedYear > 0) body['publishedYear'] = publishedYear;

      final response = await DataProvider().performRequest(
        'PUT',
        APIPath.academicEbook(id),
        data: body,
        header: {'Authorization': 'Bearer $token'},
      );

      if (response != null &&
          (response.statusCode == 200 || response.statusCode == 201)) {
        final idx = _books.indexWhere((b) => b.id == id);
        if (idx != -1) {
          _books[idx] = _books[idx].copyWith(
            title: title,
            author: author,
            classId: classId,
            className: className,
            subject: subject,
            subjectId: subjectId,
            subjectName: subjectName,
            pdfUrl: pdfUrl,
            coverImageUrl: coverImageUrl,
            description: description,
            totalPages: totalPages,
            publishedYear: publishedYear,
            isActive: isActive,
            updatedAt: DateTime.now(),
          );
          notifyListeners();
        }
        return true;
      }
      return false;
    } catch (e) {
      log('AcademicBookNotifier: updateBook exception $e');
      return false;
    }
  }

  // ── Delete book ────────────────────────────────────────────────────────────

  Future<bool> deleteBook(String id) async {
    try {
      final token = await StorageService.getToken();
      if (token == null) return false;

      final response = await DataProvider().performRequest(
        'DELETE',
        APIPath.academicEbook(id),
        header: {'Authorization': 'Bearer $token'},
      );

      if (response != null &&
          (response.statusCode == 200 || response.statusCode == 204)) {
        _books.removeWhere((b) => b.id == id);
        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      log('AcademicBookNotifier: deleteBook exception $e');
      return false;
    }
  }

  // ── Local optimistic add (for demo/local-state mode) ──────────────────────

  void addBookLocally({
    required String title,
    required String author,
    required String classId,
    required String subject,
    required String pdfUrl,
    String coverImageUrl = '',
    String description = '',
    int totalPages = 0,
    int publishedYear = 0,
    bool isActive = true,
    String className = '',
    String subjectId = '',
    String subjectName = '',
    String schoolId = '',
    String uploadedBy = '',
  }) {
    _books = [
      AcademicBook(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        title: title,
        author: author,
        classId: classId,
        className: className,
        subject: subject,
        subjectId: subjectId,
        subjectName: subjectName,
        pdfUrl: pdfUrl,
        coverImageUrl: coverImageUrl,
        description: description,
        totalPages: totalPages,
        publishedYear: publishedYear,
        isActive: isActive,
        schoolId: schoolId,
        uploadedBy: uploadedBy,
        createdAt: DateTime.now(),
      ),
      ..._books,
    ];
    notifyListeners();
  }

  void updateBookLocally({
    required String id,
    required String title,
    required String author,
    required String classId,
    required String subject,
    required String pdfUrl,
    String coverImageUrl = '',
    String description = '',
    int totalPages = 0,
    int publishedYear = 0,
    bool isActive = true,
    String className = '',
    String subjectId = '',
    String subjectName = '',
  }) {
    final idx = _books.indexWhere((b) => b.id == id);
    if (idx != -1) {
      _books[idx] = _books[idx].copyWith(
        title: title,
        author: author,
        classId: classId,
        className: className,
        subject: subject,
        subjectId: subjectId,
        subjectName: subjectName,
        pdfUrl: pdfUrl,
        coverImageUrl: coverImageUrl,
        description: description,
        totalPages: totalPages,
        publishedYear: publishedYear,
        isActive: isActive,
        updatedAt: DateTime.now(),
      );
      notifyListeners();
    }
  }

  void deleteBookLocally(String id) {
    _books.removeWhere((b) => b.id == id);
    notifyListeners();
  }
}
