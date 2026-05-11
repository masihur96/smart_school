import '../models/school_models.dart' hide Teacher;
import '../models/student_model.dart';
import '../models/teacher_model.dart';
import '../models/user_model.dart';

class DatabaseService {
  // Mock Data
  final List<ClassRoom> classes = [];

  final List<Section> sections = [];

  final List<Subject> subjects = [];

  final List<Student> students = [];

  final List<Teacher> teachers = [];

  final List<Attendance> attendanceRecords = [];

  final List<Homework> homeworkRecords = [];

  final List<Notice> notices = [];

  final List<Exam> exams = [];

  final List<Result> results = [];

  // Helper methods (Mock CRUD)
  Future<List<Student>> getStudentsByClass(
    String classId,
    String sectionId,
  ) async {
    return students
        .where((s) => s.classId == classId && s.sectionId == sectionId)
        .toList();
  }

  Future<void> addHomework(Homework homework) async {
    homeworkRecords.add(homework);
  }

  Future<void> takeAttendance(List<Attendance> records) async {
    attendanceRecords.addAll(records);
  }
}
