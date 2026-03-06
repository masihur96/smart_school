import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../models/student_model.dart';
import '../../../services/database_service.dart';

final databaseServiceProvider = Provider((ref) => MockDatabaseService());

final studentsProvider = NotifierProvider<StudentsNotifier, List<Student>>(() {
  return StudentsNotifier();
});

class StudentsNotifier extends Notifier<List<Student>> {
  late final MockDatabaseService _dbService;

  @override
  List<Student> build() {
    _dbService = ref.watch(databaseServiceProvider);
    return _dbService.students;
  }

  void addStudent(Student student) {
    _dbService.students.add(student);
    state = [..._dbService.students];
  }

  void updateStudent(Student student) {
    final index = _dbService.students.indexWhere((s) => s.userId == student.userId);
    if (index != -1) {
      _dbService.students[index] = student;
      state = [..._dbService.students];
    }
  }

  void toggleStudentStatus(String userId) {
    final index = _dbService.students.indexWhere((s) => s.userId == userId);
    if (index != -1) {
      final student = _dbService.students[index];
      _dbService.students[index] = Student(
        userId: student.userId,
        rollId: student.rollId,
        classId: student.classId,
        sectionId: student.sectionId,
        guardianContact: student.guardianContact,
        isActive: !student.isActive,
        user: student.user,
      );
      state = [..._dbService.students];
    }
  }
}

final classesProvider = Provider((ref) => ref.watch(databaseServiceProvider).classes);
final sectionsProvider = Provider((ref) => ref.watch(databaseServiceProvider).sections);
final subjectsProvider = Provider((ref) => ref.watch(databaseServiceProvider).subjects);
