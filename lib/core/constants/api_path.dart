class APIPath{
  //Base Url for HR Service
  // static const String baseUrl = 'https://smart-school-backend-mmy3.onrender.com';
  static const String baseUrl = 'http://192.168.68.120:3000';
  static String login = "$baseUrl/auth/login";
  static String register = "$baseUrl/users";
  static String profile = "$baseUrl/auth/profile";

}