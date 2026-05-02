class APIPath {
  //Base Url for HR Service
  static const String baseUrl =
      'https://smart-school-backend-production.up.railway.app'; // For Railway
  //static const String baseUrl = 'http://192.168.68.120:3000';
  // static const String baseUrl = 'http://10.0.2.2:3000';
  static String login = "$baseUrl/auth/login";
  static String register = "$baseUrl/users";
  static String profile = "$baseUrl/auth/profile";
  static String createSchool = "$baseUrl/admin/schools";
  static String createClass = "$baseUrl/admin/classes";
  static String createSection = "$baseUrl/admin/sections";
  static String createSubject = "$baseUrl/admin/subjects";
  static String fetchUsers = "$baseUrl/admin/users";
  static String changePassword = "$baseUrl/auth/change-password";
  static String createNotice = "$baseUrl/general/notices";
  static String fetchStudent = "$baseUrl/general/students";
  static String updateNotice(String id) => "$baseUrl/general/notices/$id";
  static String deleteNotice(String id) => "$baseUrl/general/notices/$id";
  static String marquee = "$baseUrl/general/marquee";
  static String createRoutine = "$baseUrl/general/routine";
  static String schoolData = "$baseUrl/general/school-data";
  static String createExam = "$baseUrl/admin/exams";
  static String attendanceOverview = "$baseUrl/admin/attendance/overview";
  static String todayClass = "$baseUrl/teacher/todays-classes";
  static String submitAttendance = "$baseUrl/teacher/attendance";
  static String selfAttendance = "$baseUrl/teacher/self-attendance";
  static String adminTeacherAttendance = "$baseUrl/admin/teacher-attendance";
  static String submitHomeWork = "$baseUrl/teacher/homework";
  static String studentAttendance = "$baseUrl/student/attendance";
  static String studentRoutine = "$baseUrl/student/routine";
  static String studentHomework = "$baseUrl/student/homework";
  static String studentResult = "$baseUrl/student/results";
  static String teacherAssignment = "$baseUrl/teacher/assignments";
  static String teacherMarks = "$baseUrl/teacher/marks";
  static String teacherExams = "$baseUrl/teacher/exams";
  static String superAdminDashboard = "$baseUrl/superadmin/dashboard";
  static String superAdminSchools = "$baseUrl/superadmin/schools";
  static String updateSchool(String id) => "$baseUrl/superadmin/schools/$id";
  static String deleteSchool(String id) => "$baseUrl/superadmin/schools/$id";

  static String pricingPlans = "$baseUrl/pricing/plans";
  static String createPricing = "$baseUrl/pricing";
  static String updatePricing(String id) => "$baseUrl/pricing/$id";
  static String deletePricing(String id) => "$baseUrl/pricing/$id";

  static String allSubscriptions = "$baseUrl/subscriptions/all";
  static String schoolSubscription(String schoolId) =>
      "$baseUrl/subscriptions/school/$schoolId";
  static String assignSubscription = "$baseUrl/subscriptions/assign";
  static String updateSubscription(String id) => "$baseUrl/subscriptions/$id";
  static String deleteSubscription(String id) => "$baseUrl/subscriptions/$id";

  static String updateClass(String id) => "$baseUrl/admin/classes/$id";
  static String deleteClass(String id) => "$baseUrl/admin/classes/$id";
  static String updateSection(String id) => "$baseUrl/admin/sections/$id";
  static String deleteSection(String id) => "$baseUrl/admin/sections/$id";
  static String updateSubject(String id) => "$baseUrl/admin/subjects/$id";
  static String deleteSubject(String id) => "$baseUrl/admin/subjects/$id";

  static String homeworkDetails(String id) => "$baseUrl/teacher/homework/$id";
  static String updateStudentHomework(String id) =>
      "$baseUrl/teacher/homework/student-homework/$id";
  static String bulkUpdateHomework(String homeworkId) =>
      "$baseUrl/teacher/homework/$homeworkId/students/bulk";
  static String updateStudentHomeworkDirect(
    String homeworkId,
    String studentId,
  ) => "$baseUrl/teacher/homework/$homeworkId/students/$studentId";

  // Backup & Restore
  static String trash = "$baseUrl/superadmin/trash";
  static String restore(String entity, String id) =>
      "$baseUrl/superadmin/trash/$entity/$id/restore";
  static String deletedRecords(String entity) =>
      "$baseUrl/superadmin/backup/deleted?entity=$entity";
  static String restoreRecord = "$baseUrl/superadmin/backup/restore";

  // Notifications
  static String registerFcmToken = "$baseUrl/notifications/fcm-token";
  static String notifications = "$baseUrl/notifications";
  static String sendTestNotification = "$baseUrl/notifications/send-test";
  static String sendNotification = "$baseUrl/notifications/send";

  // Student Exam Endpoints
  static String studentExams = "$baseUrl/student/exams";
  static String studentExamRoutine(String id) =>
      "$baseUrl/student/exam-routine/$id";
  static String studentExamSyllabus(String id) =>
      "$baseUrl/student/exam-syllabus/$id";
  static String studentExamResults(String id) =>
      "$baseUrl/student/exam-results/$id";
}
