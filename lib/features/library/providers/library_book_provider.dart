import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:smart_school/core/utils/storage_service.dart';

import '../../../configs/network/data_provider.dart';
import '../../../core/constants/api_path.dart';
import '../data/models/book.dart';
import '../data/models/issued_book.dart';

class LibraryBookNotifier extends ChangeNotifier {
  List<Book> _books = [];
  bool _isLoading = false;
  String? _error;

  List<IssuedBook> _issuedBooks = [];
  bool _isIssuedLoading = false;
  String? _issuedError;

  List<Book> get books => _books;
  bool get isLoading => _isLoading;
  String? get error => _error;

  List<IssuedBook> get issuedBooks => _issuedBooks;
  bool get isIssuedLoading => _isIssuedLoading;
  String? get issuedError => _issuedError;

  // ── Fetch all books ──────────────────────────────────────────────────────

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


        print(raw);
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

  // ── Fetch issued books ───────────────────────────────────────────────────

  /// Fetches all currently issued books via GET /library/issued-books.
  Future<void> fetchIssuedBooks() async {
    _isIssuedLoading = true;
    _issuedError = null;
    notifyListeners();

    try {
      final token = await StorageService.getToken();
      if (token == null) throw Exception('No authentication token found');

      final response = await DataProvider().performRequest(
        'GET',
        APIPath.libraryIssuedBooks,
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

        _issuedBooks = data
            .whereType<Map<String, dynamic>>()
            .map((e) => IssuedBook.fromJson(e))
            .toList();

        log('LibraryBookNotifier: fetched ${_issuedBooks.length} issued books');
      } else {
        log('LibraryBookNotifier.fetchIssuedBooks: error → ${response?.data}');
        _issuedError = 'Failed to load issued books.';
      }
    } catch (e) {
      log('LibraryBookNotifier.fetchIssuedBooks: exception → $e');
      _issuedError = 'Network error. Please try again.';
    } finally {
      _isIssuedLoading = false;
      notifyListeners();
    }
  }

  // ── Issue a book ─────────────────────────────────────────────────────────

  /// Issues a book to a student via POST /library/issued-books.
  ///
  /// Throws an [Exception] with a user-readable message on failure.
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
      // Refresh the issued list so the new entry is visible immediately
      fetchIssuedBooks();
    } else {
      final msg = response?.data is Map
          ? (response!.data['message'] ?? 'Failed to issue book.')
          : 'Failed to issue book.';
      log('LibraryBookNotifier.issueBook: error → $msg');
      throw Exception(msg.toString());
    }
  }

  // ── Return a book ────────────────────────────────────────────────────────

  /// Marks an issued book as returned via PATCH /library/issued-books/{id}/return.
  ///
  /// Throws an [Exception] with a user-readable message on failure.
  Future<void> returnBook(String issuedBookId) async {
    final token = await StorageService.getToken();
    if (token == null) throw Exception('No authentication token found');

    log('LibraryBookNotifier.returnBook: issuedBookId=$issuedBookId');

    final response = await DataProvider().performRequest(
      'PATCH',
      APIPath.libraryReturnBook(issuedBookId),
      header: {
        'Authorization': 'Bearer $token',
        'accept': '*/*',
      },
    );

    if (response != null &&
        (response.statusCode == 200 || response.statusCode == 201)) {
      log('LibraryBookNotifier.returnBook: success → ${response.data}');
      // Refresh both lists so availability & issued count update everywhere
      fetchIssuedBooks();
      fetchBooks();
    } else {
      final msg = response?.data is Map
          ? (response!.data['message'] ?? 'Failed to return book.')
          : 'Failed to return book.';
      log('LibraryBookNotifier.returnBook: error → $msg');
      throw Exception(msg.toString());
    }
  }

  // ── Add a book ───────────────────────────────────────────────────────────

  /// Adds a new book via POST /library/books.
  ///
  /// Throws an [Exception] with a user-readable message on failure.
  Future<Book> addBook(Map<String, dynamic> data) async {
    final token = await StorageService.getToken();
    if (token == null) throw Exception('No authentication token found');

    log('LibraryBookNotifier.addBook: data=$data');

    final response = await DataProvider().performRequest(
      'POST',
      APIPath.libraryBooks,
      data: data,
      header: {
        'Authorization': 'Bearer $token',
        'accept': '*/*',
        'Content-Type': 'application/json',
      },
    );

    if (response != null &&
        (response.statusCode == 200 || response.statusCode == 201)) {
      log('LibraryBookNotifier.addBook: success → ${response.data}');
      Book newBook;
      final raw = response.data;
      if (raw is Map && raw['data'] != null && raw['data'] is Map) {
        newBook = Book.fromJson(raw['data'] as Map<String, dynamic>);
      } else if (raw is Map) {
        newBook = Book.fromJson(raw as Map<String, dynamic>);
      } else {
        newBook = Book.fromJson(data);
      }
      fetchBooks();
      return newBook;
    } else {
      final msg = response?.data is Map
          ? (response!.data['message'] ?? 'Failed to create book.')
          : 'Failed to create book.';
      log('LibraryBookNotifier.addBook: error → $msg');
      throw Exception(msg.toString());
    }
  }

  // ── Update a book ────────────────────────────────────────────────────────

  /// Updates a book via PATCH /library/books/{id}.
  ///
  /// Throws an [Exception] with a user-readable message on failure.
  Future<Book> updateBook(String id, Map<String, dynamic> data) async {
    final token = await StorageService.getToken();
    if (token == null) throw Exception('No authentication token found');

    log('LibraryBookNotifier.updateBook: id=$id, data=$data');

    final response = await DataProvider().performRequest(
      'PATCH',
      APIPath.libraryBook(id),
      data: data,
      header: {
        'Authorization': 'Bearer $token',
        'accept': '*/*',
        'Content-Type': 'application/json',
      },
    );

    if (response != null &&
        (response.statusCode == 200 || response.statusCode == 201)) {
      log('LibraryBookNotifier.updateBook: success → ${response.data}');
      Book updatedBook;
      final raw = response.data;
      if (raw is Map && raw['data'] != null && raw['data'] is Map) {
        updatedBook = Book.fromJson(raw['data'] as Map<String, dynamic>);
      } else if (raw is Map) {
        updatedBook = Book.fromJson(raw as Map<String, dynamic>);
      } else {
        updatedBook = Book.fromJson(data);
      }
      fetchBooks();
      return updatedBook;
    } else {
      final msg = response?.data is Map
          ? (response!.data['message'] ?? 'Failed to update book.')
          : 'Failed to update book.';
      log('LibraryBookNotifier.updateBook: error → $msg');
      throw Exception(msg.toString());
    }
  }

  // ── Delete a book ────────────────────────────────────────────────────────

  /// Deletes a book via DELETE /library/books/{id}.
  ///
  /// Throws an [Exception] with a user-readable message on failure.
  Future<void> deleteBook(String id) async {
    final token = await StorageService.getToken();
    if (token == null) throw Exception('No authentication token found');

    log('LibraryBookNotifier.deleteBook: id=$id');

    final response = await DataProvider().performRequest(
      'DELETE',
      APIPath.libraryBook(id),
      header: {
        'Authorization': 'Bearer $token',
        'accept': '*/*',
      },
    );

    if (response != null &&
        (response.statusCode == 200 || response.statusCode == 204)) {
      log('LibraryBookNotifier.deleteBook: success → ${response.data}');
      fetchBooks();
    } else {
      final msg = response?.data is Map
          ? (response!.data['message'] ?? 'Failed to delete book.')
          : 'Failed to delete book.';
      log('LibraryBookNotifier.deleteBook: error → $msg');
      throw Exception(msg.toString());
    }
  }
}

