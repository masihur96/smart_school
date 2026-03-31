class UserEntity {
  final String id;
  final String name;
  final String email;
  final String role;
  final String? schoolId;
  final String? classId;
  final String? phone;

  UserEntity({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    this.schoolId,
    this.classId,
    this.phone,
  });
}
