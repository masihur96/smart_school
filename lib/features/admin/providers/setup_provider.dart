import 'package:flutter/material.dart';
import '../../../models/school_models.dart';
import '../../../services/database_service.dart';

class ClassSetupNotifier extends ChangeNotifier {
  final DatabaseService _dbService;
  List<ClassRoom> _classes = [];

  ClassSetupNotifier(this._dbService) {
    _classes = [..._dbService.classes];
  }

  List<ClassRoom> get classes => _classes;

  void addClass(String name) {
    _dbService.classes.add(ClassRoom(id: DateTime.now().toString(), name: name));
    _classes = [..._dbService.classes];
    notifyListeners();
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
    _dbService.sections.add(Section(id: DateTime.now().toString(), classId: classId, name: name));
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
