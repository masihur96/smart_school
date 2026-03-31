import 'dart:developer';

import 'package:flutter/material.dart';
import '../../../models/school_models.dart';
import '../../../services/database_service.dart';

import '../domain/repositories/i_homework_repository.dart';

class HomeworkNotifier extends ChangeNotifier {
  final DatabaseService _dbService;
  final IHomeworkRepository? _homeworkRepository;
  List<Homework> _homeworkRecords = [];

  HomeworkNotifier(this._dbService, {IHomeworkRepository? homeworkRepository})
      : _homeworkRepository = homeworkRepository {
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

  Future<bool> submitHomework(Homework homework) async {
    if (_homeworkRepository == null) {
      // Fallback to mock if repository is not provided (e.g. in tests)
      addHomework(homework);
      return true;
    }

    try {
      final success = await _homeworkRepository.submitHomework(homework);
      if (success) {
        addHomework(homework);
      }
      return success;
    } catch (e) {
      log('Error submitting homework: $e');
      rethrow;
    }
  }
}
