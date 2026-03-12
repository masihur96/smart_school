import 'package:flutter/material.dart';
import '../../../models/school_models.dart';
import '../domain/repositories/i_exam_repository.dart';

class ExamsNotifier extends ChangeNotifier {
  final IExamRepository _repository;
  List<Exam> _state = [];

  ExamsNotifier(this._repository) {
    _load();
  }

  List<Exam> get state => _state;

  Future<void> _load() async {
    _state = await _repository.getExams();
    notifyListeners();
  }

  Future<void> addExam(Exam exam) async {
    await _repository.addExam(exam);
    await _load();
  }

  Future<void> updateExam(Exam exam) async {
    await _repository.updateExam(exam);
    await _load();
  }

  Future<void> deleteExam(String id) async {
    await _repository.deleteExam(id);
    await _load();
  }

  Future<void> publishResult(String examId) async {
    await _repository.publishResult(examId);
    await _load();
  }
}
