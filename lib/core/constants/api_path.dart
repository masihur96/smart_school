class APIPath {
  //Base Url for HR Service
  // static const String baseUrl = 'https://smart-school-backend-mmy3.onrender.com';
  //static const String baseUrl = 'http://192.168.68.120:3000';
  static const String baseUrl = 'http://10.0.2.2:3000';
  static String login = "$baseUrl/auth/login";
  static String register = "$baseUrl/users";
  static String profile = "$baseUrl/auth/profile";
  static String createClass = "$baseUrl/admin/classes";
  static String createSection = "$baseUrl/admin/sections";
  static String createSubject = "$baseUrl/admin/subjects";
  static String fetchUsers = "$baseUrl/admin/users";
  static String changePassword = "$baseUrl/auth/change-password";
  static String createNotice = "$baseUrl/general/notices";
  static String fetchStudent = "$baseUrl/general/students";
  static String updateNotice(String id) => "$baseUrl/general/notices/$id";
  static String deleteNotice(String id) => "$baseUrl/general/notices/$id";
  static String createRoutine = "$baseUrl/general/routine";
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
  static String superAdminDashboard = "$baseUrl/superadmin/dashboard";
  static String superAdminSchools = "$baseUrl/superadmin/schools";
  static String updateSchool(String id) => "$baseUrl/superadmin/schools/$id";
  static String deleteSchool(String id) => "$baseUrl/superadmin/schools/$id";

  static String pricingPlans = "$baseUrl/pricing/plans";
  static String createPricing = "$baseUrl/pricing";
  static String updatePricing(String id) => "$baseUrl/pricing/$id";
  static String deletePricing(String id) => "$baseUrl/pricing/$id";

  static String allSubscriptions = "$baseUrl/subscriptions/all";

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
  static String updateStudentHomeworkDirect(String homeworkId, String studentId) =>
      "$baseUrl/teacher/homework/$homeworkId/students/$studentId";
}
