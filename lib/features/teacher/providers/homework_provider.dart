import 'dart:developer';

import 'package:flutter/material.dart';
import '../../../models/school_models.dart';
import '../../../services/database_service.dart';

import '../domain/repositories/i_homework_repository.dart';

class HomeworkNotifier extends ChangeNotifier {
  final DatabaseService _dbService;
  final IHomeworkRepository? _homeworkRepository;
  List<Homework> _homeworkRecords = [];
  bool _isLoading = false;

  HomeworkNotifier(this._dbService, {IHomeworkRepository? homeworkRepository})
      : _homeworkRepository = homeworkRepository {
    _homeworkRecords = [..._dbService.homeworkRecords];
  }

  List<Homework> get homeworkRecords => _homeworkRecords;
  bool get isLoading => _isLoading;

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

  Future<void> fetchHomework({
    String? classId,
    String? sectionId,
    String? subjectId,
  }) async {
    if (_homeworkRepository == null) return;

    _isLoading = true;
    notifyListeners();

    log('fetchHomework: classId=$classId, sectionId=$sectionId, subjectId=$subjectId');
    try {
      final results = await _homeworkRepository.fetchHomework(
        classId: classId,
        sectionId: sectionId,
        subjectId: subjectId,
      );

      log('fetchHomework results count: ${results.length}');
      _homeworkRecords = results;
    } catch (e) {
      log('Error fetching homework from API: $e');
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Homework? _selectedHomework;
  Homework? get selectedHomework => _selectedHomework;

  Future<void> getHomeworkDetails(String id) async {
    if (_homeworkRepository == null) return;

    _isLoading = true;
    notifyListeners();

    try {
      _selectedHomework = await _homeworkRepository.fetchHomeworkDetails(id);
    } catch (e) {
      log('Error fetching homework details: $e');
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> bulkUpdateStudentHomeworkStatus({
    required String homeworkId,
    required String status,
    String? comment,
  }) async {
    if (_homeworkRepository == null) return false;

    _isLoading = true;
    notifyListeners();

    try {
      final success = await _homeworkRepository.bulkUpdateStudentHomeworkStatus(
        homeworkId: homeworkId,
        status: status,
        comment: comment,
      );
      if (success && _selectedHomework != null) {
        await getHomeworkDetails(_selectedHomework!.id);
      }
      return success;
    } catch (e) {
      log('Error bulk updating student homework status: $e');
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> updateStudentHomeworkStatus({
    required String homeworkId,
    required String studentId,
    required String status,
    String? comment,
  }) async {
    if (_homeworkRepository == null) return false;

    _isLoading = true;
    notifyListeners();

    try {
      final success = await _homeworkRepository.updateSpecificStudentHomeworkStatus(
        homeworkId: homeworkId,
        studentId: studentId,
        status: status,
        comment: comment,
      );
      if (success && _selectedHomework != null) {
        await getHomeworkDetails(_selectedHomework!.id);
      }
      return success;
    } catch (e) {
      log('Error updating student homework status: $e');
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
