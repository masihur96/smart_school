import '../models/school_models.dart' hide Teacher;
import '../models/student_model.dart';
import '../models/teacher_model.dart';
import '../models/user_model.dart';

class DatabaseService {
  // Mock Data
  final List<ClassRoom> classes = [
    ClassRoom(id: 'c1', name: 'Class 9'),
    ClassRoom(id: 'c2', name: 'Class 10'),
    ClassRoom(id: 'uuid-class-001', name: 'Class 10 - Science'),
  ];

  final List<Section> sections = [
    Section(id: 's1', classId: 'c1', name: 'A'),
    Section(id: 's2', classId: 'c1', name: 'B'),
    Section(id: 's3', classId: 'c2', name: 'A'),
    Section(id: 'uuid-section-001', classId: 'uuid-class-001', name: 'A'),
  ];

  final List<Subject> subjects = [
    Subject(id: 'sub1', name: 'Mathematics'),
    Subject(id: 'sub2', name: 'English'),
    Subject(id: 'sub3', name: 'Physics'),
    Subject(id: 'uuid-subject-001', name: 'Mathematics'),
  ];

  final List<Student> students = [
    Student(
      userId: 'student1',
      rollId: '101',
      classId: 'c2',
      sectionId: 's3',
      guardianContact: '01700000000',
      user: User(
        id: 'student1',
        name: 'Masihur Rahman',
        email: 'student@school.com',
        role: UserRole.student,
      ),
    ),
  ];

  final List<Teacher> teachers = [
    Teacher(
      userId: 'teacher1',
      assignedSubjects: [
        AssignedSubject(classId: 'c2', sectionId: 's3', subjectId: 'sub1'),
      ],
      user: User(
        id: 'teacher1',
        name: 'Ms. Sarah',
        email: 'teacher@school.com',
        role: UserRole.teacher,
      ),
    ),
    Teacher(
      userId: 'uuid-teacher-001',
      assignedSubjects: [
        AssignedSubject(
            classId: 'uuid-class-001',
            sectionId: 'uuid-section-001',
            subjectId: 'uuid-subject-001'),
      ],
      user: User(
        id: 'uuid-teacher-001',
        name: 'Mr. David',
        email: 'david@school.com',
        role: UserRole.teacher,
      ),
    ),
  ];

  final List<Attendance> attendanceRecords = _generateMockAttendance();

  static List<Attendance> _generateMockAttendance() {
    final List<Attendance> records = [];
    final now = DateTime.now();

    // Generate data for the last 6 months
    for (int i = 0; i < 6; i++) {
      final monthDate = DateTime(now.year, now.month - i, 1);
      // For each month, simulate 20 school days
      for (int day = 1; day <= 20; day++) {
        final date = DateTime(monthDate.year, monthDate.month, day);
        // Simulate attendance for 'student1'
        // Random presence between 70% and 95%
        final status = (day % 10 != 0)
            ? AttendanceStatus.present
            : AttendanceStatus.absent;
        records.add(
          Attendance(
            id: 'att_${monthDate.month}_$day',
            studentId: 'student1',
            date: date,
            status: status,
            takenBy: 'teacher1',
          ),
        );
      }
    }
    return records;
  }

  final List<Homework> homeworkRecords = [
    Homework(
      id: 'hw1',
      teacherId: 'teacher1',
      classId: 'c2',
      sectionId: 's3',
      subjectId: 'sub1',
      title: 'Algebra Exercise 1.1',
      description: 'Solve problems 1 to 10.',
      dueDate: DateTime.now().add(const Duration(days: 2)),
      createdAt: DateTime.now(), schoolId: '',
    ),
    Homework(
      id: 'hw_seed_1',
      teacherId: 'uuid-teacher-001',
      classId: 'uuid-class-001',
      sectionId: 'uuid-section-001',
      subjectId: 'uuid-subject-001',
      title: 'Mathematics Homework - Algebra',
      description: 'Solve exercises 1 to 10 from Chapter 3.',
      dueDate: DateTime.parse('2026-04-05'),
      createdAt: DateTime.now(), schoolId: '',
    ),
  ];

  final List<Notice> notices = [
    Notice(
      title: 'School Reopening',
      content: 'The school will reopen on March 10th.',
      isImportant: true,
    ),
  ];

  final List<Exam> exams = [
    Exam(
      id: 'exam1',
      name: 'First Term Exam 2024',
      description: 'First term exam for all classes',
      startDate: DateTime.now(),
      endDate: DateTime.now().add(const Duration(days: 7)),
      isPublished: false,
      assignments: [
        ExamAssignment(
          id: 'a1',
          examId: 'exam1',
          classId: 'c2',
          className: 'Class 10',
          subjectId: 'sub1',
          subjectName: 'Mathematics',
          examinerId: 'teacher1',
          examinerName: 'Ms. Sarah',
          date: DateTime.now().add(const Duration(days: 7)),
        )
      ]
    ),
  ];

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
