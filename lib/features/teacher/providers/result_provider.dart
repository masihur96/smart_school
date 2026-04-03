import 'dart:developer';
import 'package:flutter/material.dart';
import '../../../models/school_models.dart';
import '../domain/repositories/i_result_repository.dart';

class ResultsNotifier extends ChangeNotifier {
  final IResultRepository _repository;

  // ─── Exam step ────────────────────────────────────────────────────────────
  List<Exam> _exams = [];
  bool _examsLoading = false;
  String? _examsError;

  // ─── Class step ───────────────────────────────────────────────────────────
  List<TeacherAssignmentClass> _classes = [];
  bool _classesLoading = false;

  // ─── Student step ─────────────────────────────────────────────────────────
  List<TeacherAssignmentStudent> _students = [];
  bool _studentsLoading = false;

  // ─── Subject step ─────────────────────────────────────────────────────────
  List<TeacherAssignmentSubject> _subjects = [];
  bool _subjectsLoading = false;

  // ─── Submit state ─────────────────────────────────────────────────────────
  bool _submitting = false;

  // ─── Legacy state ─────────────────────────────────────────────────────────
  List<Result> _legacyResults = [];

  ResultsNotifier(this._repository);

  // ─── Getters ──────────────────────────────────────────────────────────────
  List<Exam> get exams => _exams;
  bool get examsLoading => _examsLoading;
  String? get examsError => _examsError;

  List<TeacherAssignmentClass> get classes => _classes;
  bool get classesLoading => _classesLoading;

  List<TeacherAssignmentStudent> get students => _students;
  bool get studentsLoading => _studentsLoading;

  List<TeacherAssignmentSubject> get subjects => _subjects;
  bool get subjectsLoading => _subjectsLoading;

  bool get submitting => _submitting;

  // Legacy getter
  List<Result> get state => _legacyResults;

  // ─── Actions ──────────────────────────────────────────────────────────────

  Future<void> loadExams() async {
    _examsLoading = true;
    _examsError = null;
    _exams = [];
    _classes = [];
    _students = [];
    _subjects = [];
    notifyListeners();
    try {
      _exams = await _repository.getTeacherExams();
      log('Loaded ${_exams.length} exams');
    } catch (e) {
      _examsError = e.toString();
      log('Error loading exams: $e');
    } finally {
      _examsLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadClasses(String examId) async {
    _classesLoading = true;
    _classes = [];
    _students = [];
    _subjects = [];
    notifyListeners();
    try {
      _classes = await _repository.getExamClasses(examId);
      log('Loaded ${_classes.length} classes for exam $examId');
    } catch (e) {
      log('Error loading classes: $e');
    } finally {
      _classesLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadStudents(String examId, String classId) async {
    _studentsLoading = true;
    _students = [];
    _subjects = [];
    notifyListeners();
    try {
      _students = await _repository.getClassStudents(examId, classId);
      log('Loaded ${_students.length} students for class $classId');
    } catch (e) {
      log('Error loading students: $e');
    } finally {
      _studentsLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadSubjects(
      String examId, String classId, String studentId) async {
    _subjectsLoading = true;
    _subjects = [];
    notifyListeners();
    try {
      _subjects =
          await _repository.getStudentSubjects(examId, classId, studentId);
      log('Loaded ${_subjects.length} subjects for student $studentId');
    } catch (e) {
      log('Error loading subjects: $e');
    } finally {
      _subjectsLoading = false;
      notifyListeners();
    }
  }

  Future<void> submitMarks({
    required String examId,
    required String teacherId,
    required String schoolId,
    required List<Map<String, dynamic>> marks,
  }) async {
    _submitting = true;
    notifyListeners();
    try {
      await _repository.submitMarks(
        examId: examId,
        teacherId: teacherId,
        schoolId: schoolId,
        marks: marks,
      );
      log('Marks submitted successfully');
    } finally {
      _submitting = false;
      notifyListeners();
    }
  }

  // ─── Legacy methods ───────────────────────────────────────────────────────

  Future<void> loadResultsForExam(String examId) async {
    _legacyResults = await _repository.getResultsForExam(examId);
    notifyListeners();
  }

  Future<void> loadResultsForStudent(String studentId) async {
    _legacyResults = await _repository.getResultsForStudent(studentId);
    notifyListeners();
  }

  Future<void> saveResults(List<Result> results) async {
    await _repository.saveResults(results);
    notifyListeners();
  }
}
