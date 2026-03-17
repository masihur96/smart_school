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

  ClassSetupNotifier(this._dbService) {
    _classes = [..._dbService.classes];
  }

  List<ClassRoom> get classes => _classes;

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

  SectionSetupNotifier(this._dbService) {
    _sections = [..._dbService.sections];
  }

  List<Section> get sections => _sections;

  void addSection(String classId, String name) {
    _dbService.sections.add(
      Section(id: DateTime.now().toString(), classId: classId, name: name),
    );
    _sections = [..._dbService.sections];
    notifyListeners();
  }
}

class SubjectSetupNotifier extends ChangeNotifier {
  final DatabaseService _dbService;
  List<Subject> _subjects = [];

  SubjectSetupNotifier(this._dbService) {
    _subjects = [..._dbService.subjects];
  }

  List<Subject> get subjects => _subjects;

  void addSubject(String name) {
    _dbService.subjects.add(Subject(id: DateTime.now().toString(), name: name));
    _subjects = [..._dbService.subjects];
    notifyListeners();
  }
}
