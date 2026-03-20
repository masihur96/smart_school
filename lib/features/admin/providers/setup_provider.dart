import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:smart_school/core/utils/storage_service.dart';

import '../../../configs/network/data_provider.dart';
import '../../../core/constants/api_path.dart';
import '../../../models/school_models.dart';
import '../../../services/database_service.dart';

class ClassSetupNotifier extends ChangeNotifier {
  final DatabaseService _dbService;
  List<ClassRoom> _classes = [];
  bool _isLoading = false;

  ClassSetupNotifier(this._dbService) {
    _classes = [..._dbService.classes];
  }

  List<ClassRoom> get classes => _classes;
  bool get isLoading => _isLoading;

  Future<void> fetchClasses(String schoolId) async {
    _isLoading = true;
    notifyListeners();

    try {
      final token = await StorageService.getToken();
      if (token == null) throw Exception('No authentication token found');

      final response = await DataProvider().performRequest(
        'GET',
        APIPath.createClass,
        query: {'schoolId': schoolId},
        header: {'Authorization': 'Bearer $token'},
      );

      if (response != null && response.statusCode == 200) {
        final List<dynamic> data = response.data is List
            ? response.data
            : (response.data['data'] ?? response.data['classes'] ?? []);
        _dbService.classes.clear();
        for (var item in data) {
          _dbService.classes.add(ClassRoom.fromJson(item));
        }
        _classes = [..._dbService.classes];
      } else {
        log("Error fetching classes: ${response?.data}");
      }
    } catch (e) {
      log("Error fetching classes: $e");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> addClass(
    String name,
    String description,
    String schoolId,
  ) async {
    final token = await StorageService.getToken();
    if (token == null) {
      throw Exception('No authentication token found');
    }
    final Map<String, dynamic> data = {
      "name": name,
      "schoolId": schoolId,
      "description": description,
    };

    final response = await DataProvider().performRequest(
      'POST',
      APIPath.createClass,
      data: data,
      header: {'Authorization': 'Bearer $token'},
    );

    if (response != null &&
        (response.statusCode == 200 || response.statusCode == 201)) {
      _dbService.classes.add(
        ClassRoom(
          id: response.data['_id']?.toString() ?? DateTime.now().toString(),
          name: name,
          description: description,
          schoolId: schoolId,
        ),
      );
      _classes = [..._dbService.classes];
      notifyListeners();
    } else {
      log("Error creating class: ${response?.data}");
    }
  }
}

class SectionSetupNotifier extends ChangeNotifier {
  final DatabaseService _dbService;
  List<Section> _sections = [];
  bool _isLoading = false;

  SectionSetupNotifier(this._dbService) {
    _sections = [..._dbService.sections];
  }

  List<Section> get sections => _sections;
  bool get isLoading => _isLoading;

  Future<void> fetchSections() async {
    _isLoading = true;
    notifyListeners();

    try {
      final token = await StorageService.getToken();
      if (token == null) throw Exception('No authentication token found');

      final response = await DataProvider().performRequest(
        'GET',
        APIPath.createSection,
        header: {'Authorization': 'Bearer $token'},
      );

      if (response != null && response.statusCode == 200) {
        final List<dynamic> data = response.data is List
            ? response.data
            : (response.data['data'] ?? response.data['sections'] ?? []);
        _dbService.sections.clear();
        for (var item in data) {
          _dbService.sections.add(Section.fromJson(item));
        }
        _sections = [..._dbService.sections];
      } else {
        log("Error fetching sections: ${response?.data}");
      }
    } catch (e) {
      log("Error fetching sections: $e");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> addSection(String classId, String name) async {
    final token = await StorageService.getToken();
    if (token == null) {
      throw Exception('No authentication token found');
    }

    final Map<String, dynamic> data = {"name": name, "classId": classId};

    print("Section Data :: $data");

    final response = await DataProvider().performRequest(
      'POST',
      APIPath.createSection,
      data: data,
      header: {'Authorization': 'Bearer $token'},
    );

    if (response != null &&
        (response.statusCode == 200 || response.statusCode == 201)) {
      _dbService.sections.add(
        Section(
          id: response.data['_id']?.toString() ?? DateTime.now().toString(),
          classId: classId,
          name: name,
        ),
      );
      _sections = [..._dbService.sections];
      notifyListeners();
    } else {
      log("Error creating section: ${response?.data}");
    }
  }
}

class SubjectSetupNotifier extends ChangeNotifier {
  final DatabaseService _dbService;
  List<Subject> _subjects = [];
  bool _isLoading = false;

  SubjectSetupNotifier(this._dbService) {
    _subjects = [..._dbService.subjects];
  }

  List<Subject> get subjects => _subjects;
  bool get isLoading => _isLoading;

  Future<void> fetchSubjects(String schoolId) async {
    _isLoading = true;
    notifyListeners();

    try {
      final token = await StorageService.getToken();
      if (token == null) throw Exception('No authentication token found');

      final response = await DataProvider().performRequest(
        'GET',
        APIPath.createSubject,
        query: {'schoolId': schoolId},
        header: {'Authorization': 'Bearer $token'},
      );

      if (response != null && response.statusCode == 200) {
        final List<dynamic> data = response.data is List
            ? response.data
            : (response.data['data'] ?? response.data['subjects'] ?? []);
        _dbService.subjects.clear();
        for (var item in data) {
          _dbService.subjects.add(Subject.fromJson(item));
        }
        _subjects = [..._dbService.subjects];
      } else {
        log("Error fetching subjects: ${response?.data}");
      }
    } catch (e) {
      log("Error fetching subjects: $e");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> addSubject(
    String name,
    String code,
    String classId,
    String schoolId,
  ) async {
    final token = await StorageService.getToken();
    if (token == null) {
      throw Exception('No authentication token found');
    }

    final Map<String, dynamic> data = {
      "name": name,
      "code": code,
      "classId": classId,
      "schoolId": schoolId,
    };

    final response = await DataProvider().performRequest(
      'POST',
      APIPath.createSubject,
      data: data,
      header: {'Authorization': 'Bearer $token'},
    );

    if (response != null &&
        (response.statusCode == 200 || response.statusCode == 201)) {
      _dbService.subjects.add(
        Subject(
          id: response.data['_id']?.toString() ?? DateTime.now().toString(),
          name: name,
          code: code,
          classId: classId,
          schoolId: schoolId,
        ),
      );
      _subjects = [..._dbService.subjects];
      notifyListeners();
    } else {
      log("Error creating subject: ${response?.data}");
    }
  }
}
