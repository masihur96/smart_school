class SuperAdminDashboardData {
  final int totalSchools;
  final int totalStudents;
  final int totalTeachers;
  final int activeSubscriptions;

  SuperAdminDashboardData({
    required this.totalSchools,
    required this.totalStudents,
    required this.totalTeachers,
    required this.activeSubscriptions,
  });

  factory SuperAdminDashboardData.fromJson(Map<String, dynamic> json) {
    return SuperAdminDashboardData(
      totalSchools: json['totalSchools'] ?? 0,
      totalStudents: json['totalStudents'] ?? 0,
      totalTeachers: json['totalTeachers'] ?? 0,
      activeSubscriptions: json['activeSubscriptions'] ?? 0,
    );
  }

  factory SuperAdminDashboardData.initial() {
    return SuperAdminDashboardData(
      totalSchools: 0,
      totalStudents: 0,
      totalTeachers: 0,
      activeSubscriptions: 0,
    );
  }
}
