import 'package:flutter/material.dart';
import '../../../models/school_models.dart';
import '../../../services/database_service.dart';

class HomeworkNotifier extends ChangeNotifier {
  final DatabaseService _dbService;
  List<Homework> _homeworkRecords = [];

  HomeworkNotifier(this._dbService) {
    _homeworkRecords = [..._dbService.homeworkRecords];
  }

  List<Homework> get homeworkRecords => _homeworkRecords;

  void addHomework(Homework homework) {
    _dbService.homeworkRecords.add(homework);
    _homeworkRecords = [..._dbService.homeworkRecords];
    notifyListeners();
  }

  void removeHomework(String id) {
    _dbService.homeworkRecords.removeWhere((h) => h.id == id);
    _homeworkRecords = [..._dbService.homeworkRecords];
    notifyListeners();
  }

  List<Homework> getHomeworkForTeacher(String teacherId) {
    return _homeworkRecords.where((h) => h.teacherId == teacherId).toList();
  }

  List<Homework> getHomeworkForStudent(String classId, String sectionId) {
    return _homeworkRecords
        .where((h) => h.classId == classId && h.sectionId == sectionId)
        .toList();
  }
}
