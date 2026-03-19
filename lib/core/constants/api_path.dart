class APIPath {
  //Base Url for HR Service
  // static const String baseUrl = 'https://smart-school-backend-mmy3.onrender.com';
  // static const String baseUrl = 'http://192.168.68.120:3000';
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
}
