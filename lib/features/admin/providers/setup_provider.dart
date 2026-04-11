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
          final cls = ClassRoom.fromJson(item);
          if (!cls.isDeleted) {
            _dbService.classes.add(cls);
          }
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

  Future<bool> addClass(
    String name,
    String description,
    String schoolId,
  ) async {
    try {
      final token = await StorageService.getToken();
      if (token == null) return false;

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
        final responseData = response.data['data'] ?? response.data;
        final newId = responseData['_id']?.toString() ?? responseData['id']?.toString() ?? DateTime.now().toString();

        _dbService.classes.add(
          ClassRoom(
            id: newId,
            name: name,
            description: description,
            schoolId: schoolId,
          ),
        );
        _classes = [..._dbService.classes];
        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      log("Error adding class: $e");
      return false;
    }
  }

  Future<bool> updateClass(
    String id,
    String name,
    String description,
    String schoolId,
  ) async {
    try {
      final token = await StorageService.getToken();
      if (token == null) return false;

      print("DDDDD:: $id");
      print("DDDDD:: ${APIPath.updateClass(id)}");

      final response = await DataProvider().performRequest(
        'PUT',
        APIPath.updateClass(id),
        data: {'name': name, 'description': description, 'schoolId': schoolId},
        header: {'Authorization': 'Bearer $token'},
      );

      if (response != null &&
          (response.statusCode == 200 || response.statusCode == 201)) {
        final idx = _dbService.classes.indexWhere((c) => c.id == id);
        if (idx != -1) {
          _dbService.classes[idx] = ClassRoom(
            id: id,
            name: name,
            description: description,
            schoolId: schoolId,
          );
          _classes = [..._dbService.classes];
          notifyListeners();
          return true;
        }
      }
      return false;
    } catch (e) {
      log("Error updating class: $e");
      return false;
    }
  }

  Future<bool> deleteClass(String id) async {
    try {
      final token = await StorageService.getToken();
      if (token == null) return false;

      final response = await DataProvider().performRequest(
        'DELETE',
        APIPath.deleteClass(id),
        header: {'Authorization': 'Bearer $token'},
      );

      if (response != null &&
          (response.statusCode == 200 || response.statusCode == 204)) {
        _dbService.classes.removeWhere((c) => c.id == id);
        _classes = [..._dbService.classes];
        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      log("Error deleting class: $e");
      return false;
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
          final section = Section.fromJson(item);
          if (!section.isDeleted) {
            _dbService.sections.add(section);
          }
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

  Future<bool> addSection(String classId, String name) async {
    try {
      final token = await StorageService.getToken();
      if (token == null) return false;

      final Map<String, dynamic> data = {"name": name, "classId": classId};

      final response = await DataProvider().performRequest(
        'POST',
        APIPath.createSection,
        data: data,
        header: {'Authorization': 'Bearer $token'},
      );

      if (response != null &&
          (response.statusCode == 200 || response.statusCode == 201)) {
        final responseData = response.data['data'] ?? response.data;
        final newId = responseData['_id']?.toString() ?? responseData['id']?.toString() ?? DateTime.now().toString();

        _dbService.sections.add(
          Section(
            id: newId,
            classId: classId,
            name: name,
          ),
        );
        _sections = [..._dbService.sections];
        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      log("Error adding section: $e");
      return false;
    }
  }

  Future<bool> updateSection(String id, String classId, String name) async {
    try {
      final token = await StorageService.getToken();
      if (token == null) return false;

      final response = await DataProvider().performRequest(
        'PUT',
        APIPath.updateSection(id),
        data: {'classId': classId, 'name': name},
        header: {'Authorization': 'Bearer $token'},
      );

      if (response != null &&
          (response.statusCode == 200 || response.statusCode == 201)) {
        final idx = _dbService.sections.indexWhere((s) => s.id == id);
        if (idx != -1) {
          _dbService.sections[idx] = Section(
            id: id,
            classId: classId,
            name: name,
          );
          _sections = [..._dbService.sections];
          notifyListeners();
          return true;
        }
      }
      return false;
    } catch (e) {
      log("Error updating section: $e");
      return false;
    }
  }

  Future<bool> deleteSection(String id) async {
    try {
      final token = await StorageService.getToken();
      if (token == null) return false;

      final response = await DataProvider().performRequest(
        'DELETE',
        APIPath.deleteSection(id),
        header: {'Authorization': 'Bearer $token'},
      );

      if (response != null &&
          (response.statusCode == 200 || response.statusCode == 204)) {
        _dbService.sections.removeWhere((s) => s.id == id);
        _sections = [..._dbService.sections];
        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      log("Error deleting section: $e");
      return false;
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
          final subject = Subject.fromJson(item);
          if (!subject.isDeleted) {
            _dbService.subjects.add(subject);
          }
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

  Future<bool> addSubject(
    String name,
    String code,
    String classId,
    String schoolId,
  ) async {
    try {
      final token = await StorageService.getToken();
      if (token == null) return false;

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
        final responseData = response.data['data'] ?? response.data;
        final newId = responseData['_id']?.toString() ?? responseData['id']?.toString() ?? DateTime.now().toString();

        _dbService.subjects.add(
          Subject(
            id: newId,
            name: name,
            code: code,
            classId: classId,
            schoolId: schoolId,
          ),
        );
        _subjects = [..._dbService.subjects];
        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      log("Error adding subject: $e");
      return false;
    }
  }

  Future<bool> updateSubject(
    String id,
    String name,
    String code,
    String classId,
    String schoolId,
  ) async {
    try {
      final token = await StorageService.getToken();
      if (token == null) return false;

      final response = await DataProvider().performRequest(
        'PUT',
        APIPath.updateSubject(id),
        data: {
          'name': name,
          'code': code,
          'classId': classId,
          'schoolId': schoolId,
        },
        header: {'Authorization': 'Bearer $token'},
      );

      if (response != null &&
          (response.statusCode == 200 || response.statusCode == 201)) {
        final idx = _dbService.subjects.indexWhere((s) => s.id == id);
        if (idx != -1) {
          _dbService.subjects[idx] = Subject(
            id: id,
            name: name,
            code: code,
            classId: classId,
            schoolId: schoolId,
          );
          _subjects = [..._dbService.subjects];
          notifyListeners();
          return true;
        }
      }
      return false;
    } catch (e) {
      log("Error updating subject: $e");
      return false;
    }
  }

  Future<bool> deleteSubject(String id) async {
    try {
      final token = await StorageService.getToken();
      if (token == null) return false;

      final response = await DataProvider().performRequest(
        'DELETE',
        APIPath.deleteSubject(id),
        header: {'Authorization': 'Bearer $token'},
      );

      if (response != null &&
          (response.statusCode == 200 || response.statusCode == 204)) {
        _dbService.subjects.removeWhere((s) => s.id == id);
        _subjects = [..._dbService.subjects];
        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      log("Error deleting subject: $e");
      return false;
    }
  }
}
