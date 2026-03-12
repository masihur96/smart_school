import 'dart:async';
import '../models/user_model.dart';

class MockAuthService {
  // Mock users
  final List<User> _mockUsers = [
    User(
      id: 'admin1',
      name: 'Principal John',
      email: 'admin@school.com',
      role: UserRole.admin,
    ),
    User(
      id: 'teacher1',
      name: 'Ms. Sarah',
      email: 'teacher@school.com',
      role: UserRole.teacher,
    ),
    User(
      id: 'student1',
      name: 'Masihur Rahman',
      email: 'student@school.com',
      role: UserRole.student,
    ),
  ];

  Future<User?> login(String email, String password) async {
    // Simulate network delay
    await Future.delayed(const Duration(seconds: 1));

    try {
      return _mockUsers.firstWhere(
        (user) => user.email == email,
      );
    } catch (e) {
      return null;
    }
  }

  Future<User?> register({
    required String name,
    required String email,
    required String password,
    required String role,
    required String schoolId,
    required String phone,
  }) async {
    // Simulate network delay
    await Future.delayed(const Duration(seconds: 1));

    final newUser = User(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: name,
      email: email,
      role: UserRole.values.firstWhere((e) => e.name == role, orElse: () => UserRole.student),
      schoolId: schoolId,
      phone: phone,
    );

    _mockUsers.add(newUser);
    return newUser;
  }

  Future<void> logout() async {
    await Future.delayed(const Duration(milliseconds: 500));
  }
}
