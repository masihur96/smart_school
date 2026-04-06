import 'package:intl/intl.dart';

class MockData {
  static final String today = DateFormat('yyyy-MM-dd').format(DateTime.now());
  
  static final List<Map<String, dynamic>> students = [
    {'id': '1', 'name': 'Ahmed Ali', 'roll': '101'},
    {'id': '2', 'name': 'Fatima Zahra', 'roll': '102'},
    {'id': '3', 'name': 'Zayan Khan', 'roll': '103'},
    {'id': '4', 'name': 'Sara Ahmed', 'roll': '104'},
    {'id': '5', 'name': 'Omar Faruk', 'roll': '105'},
  ];

  static Map<String, List<Map<String, dynamic>>> studentAttendance = {
    today: [
      {'studentId': '1', 'status': 'Present'},
      {'studentId': '2', 'status': 'Absent'},
      {'studentId': '3', 'status': 'Present'},
      {'studentId': '4', 'status': 'Present'},
      {'studentId': '5', 'status': 'Present'},
    ],
    '2026-02-10': [
      {'studentId': '1', 'status': 'Present'},
      {'studentId': '2', 'status': 'Present'},
      {'studentId': '3', 'status': 'Present'},
      {'studentId': '4', 'status': 'Present'},
      {'studentId': '5', 'status': 'Absent'},
    ]
  };

  static List<Map<String, dynamic>> teacherAttendance = [
    {'date': today, 'status': 'Present'},
    {'date': '2026-02-10', 'status': 'Present'},
    {'date': '2026-02-09', 'status': 'Present'},
    {'date': '2026-02-08', 'status': 'Present'},
    {'date': '2026-02-07', 'status': 'Present'},
  ];

  static List<Map<String, dynamic>> coursework = [
    {
      'id': '1',
      'type': 'Homework',
      'title': 'Math Algebra Intro',
      'description': 'Solve exercises 1-10 on page 45.',
      'dueDate': '2026-02-15',
      'createdAt': today,
    },
    {
      'id': '2',
      'type': 'Classwork',
      'title': 'Science Essay',
      'description': 'Write a 200-word essay on Photosynthesis.',
      'dueDate': today,
      'createdAt': today,
    },
     {
      'id': '3',
      'type': 'Homework',
      'title': 'English Grammar',
      'description': 'Complete the tenses worksheet.',
      'dueDate': '2026-02-16',
      'createdAt': today,
    },
  ];

  static Map<String, String> homeworkFeedback = {
    '1': 'Excellent work on the equations.',
    '2': 'Good effort, but need more detail on chloroplasts.',
  };

  static void markTodayPresent() {
    bool alreadyPresent = teacherAttendance.any((r) => r['date'] == today);
    if (!alreadyPresent) {
      teacherAttendance.insert(0, {'date': today, 'status': 'Present'});
    }
  }

  static bool isTodayMarked() {
    return teacherAttendance.any((r) => r['date'] == today);
  }

  // Summary helper methods
  static Map<String, dynamic> getStudentSummary() {
    final todayRecords = studentAttendance[today] ?? [];
    int present = todayRecords.where((r) => r['status'] == 'Present').length;
    int absent = todayRecords.where((r) => r['status'] == 'Absent').length;
    double percentage = (present / students.length) * 100;
    return {
      'present': present,
      'absent': absent,
      'percentage': percentage.toStringAsFixed(1),
      'total': students.length,
    };
  }

  static Map<String, dynamic> getTeacherSummary() {
    int presentCount = teacherAttendance.where((r) => r['status'] == 'Present').length;
    return {
      'todayStatus': 'Present',
      'monthlyAttendance': '$presentCount/22 days',
      'onTimeRate': '98%',
    };
  }
}
