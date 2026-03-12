import 'package:flutter/material.dart';
import '../../../models/school_models.dart';
import '../domain/repositories/i_result_repository.dart';

class ResultsNotifier extends ChangeNotifier {
  final IResultRepository _repository;
  List<Result> _state = [];

  ResultsNotifier(this._repository);

  List<Result> get state => _state;

  Future<void> loadResultsForExam(String examId) async {
    _state = await _repository.getResultsForExam(examId);
    notifyListeners();
  }

  Future<void> loadResultsForStudent(String studentId) async {
    _state = await _repository.getResultsForStudent(studentId);
    notifyListeners();
  }

  Future<void> saveResults(List<Result> results) async {
    await _repository.saveResults(results);
    notifyListeners();
  }
}
