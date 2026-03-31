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

  void _removeLocal(String id) {
    _dbService.homeworkRecords.removeWhere((h) => h.id == id);
    _homeworkRecords = [..._dbService.homeworkRecords];
    notifyListeners();
  }

  void _updateLocal(Homework homework) {
    final index = _dbService.homeworkRecords.indexWhere((h) => h.id == homework.id);
    if (index != -1) {
      _dbService.homeworkRecords[index] = homework;
    } else {
      _dbService.homeworkRecords.add(homework);
    }
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

  Future<bool> updateHomework(Homework homework) async {
    if (_homeworkRepository == null) {
      _updateLocal(homework);
      return true;
    }
    try {
      final success = await _homeworkRepository.updateHomework(homework);
      if (success) {
        _updateLocal(homework);
      }
      return success;
    } catch (e) {
      log('Error updating homework: $e');
      rethrow;
    }
  }

  Future<bool> removeHomework(String id) async {
    if (_homeworkRepository == null) {
      _removeLocal(id);
      return true;
    }
    try {
      final success = await _homeworkRepository.deleteHomework(id);
      if (success) {
        _removeLocal(id);
      }
      return success;
    } catch (e) {
      log('Error deleting homework: $e');
      rethrow;
    }
  }
}
