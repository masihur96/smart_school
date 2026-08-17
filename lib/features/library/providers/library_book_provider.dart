import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:smart_school/core/utils/storage_service.dart';

import '../../../configs/network/data_provider.dart';
import '../../../core/constants/api_path.dart';
import '../data/models/book.dart';

class LibraryBookNotifier extends ChangeNotifier {
  List<Book> _books = [];
  bool _isLoading = false;
  String? _error;

  List<Book> get books => _books;
  bool get isLoading => _isLoading;
  String? get error => _error;

  /// Fetches all books from the API.
  /// Pass [search] and [category] to filter server-side.
  Future<void> fetchBooks({String search = '', String category = ''}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final token = await StorageService.getToken();
      if (token == null) throw Exception('No authentication token found');

      final Map<String, dynamic> query = {};
      if (search.isNotEmpty) query['search'] = search;
      if (category.isNotEmpty && category != 'All') {
        query['category'] = category;
      }

      final response = await DataProvider().performRequest(
        'GET',
        APIPath.libraryBooks,
        query: query.isEmpty ? null : query,
        header: {'Authorization': 'Bearer $token'},
      );

      if (response != null &&
          (response.statusCode == 200 || response.statusCode == 201)) {
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

        _books = data
            .whereType<Map<String, dynamic>>()
            .map((e) => Book.fromJson(e))
            .toList();

        log('LibraryBookNotifier: fetched ${_books.length} books');
      } else {
        log('LibraryBookNotifier: fetch error → ${response?.data}');
        _error = 'Failed to load books.';
      }
    } catch (e) {
      log('LibraryBookNotifier: exception → $e');
      _error = 'Network error. Please try again.';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Issues a book to a student via POST /library/issued-books.
  ///
  /// Throws a [Exception] with a user-readable message on failure.
  Future<void> issueBook({
    required String bookId,
    required String studentId,
    required DateTime dueDate,
  }) async {
    final token = await StorageService.getToken();
    if (token == null) throw Exception('No authentication token found');

    final body = {
      'bookId': bookId,
      'studentId': studentId,
      'dueDate': dueDate.toUtc().toIso8601String(),
    };

    log('LibraryBookNotifier.issueBook: $body');

    final response = await DataProvider().performRequest(
      'POST',
      APIPath.libraryIssuedBooks,
      data: body,
      header: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    if (response != null &&
        (response.statusCode == 200 || response.statusCode == 201)) {
      log('LibraryBookNotifier.issueBook: success → ${response.data}');
    } else {
      final msg = response?.data is Map
          ? (response!.data['message'] ?? 'Failed to issue book.')
          : 'Failed to issue book.';
      log('LibraryBookNotifier.issueBook: error → $msg');
      throw Exception(msg.toString());
    }
  }
}
