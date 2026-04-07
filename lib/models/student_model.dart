import 'user_model.dart';

class Student {
  final String userId;
  final String rollId;
  final String classId;
  final String sectionId;
  final String guardianContact;
  final bool isActive;
  final User? user; // Joined user data

  Student({
    required this.userId,
    required this.rollId,
    required this.classId,
    required this.sectionId,
    required this.guardianContact,
    this.isActive = true,
    this.user,
  });

  factory Student.fromJson(Map<String, dynamic> json) {
    return Student(
      userId: json['userId']?.toString() ?? json['id']?.toString() ?? '',
      rollId: json['rollId']?.toString() ?? json['rollNumber']?.toString() ?? '',
      classId: json['classId']?.toString() ?? '',
      sectionId: json['sectionId']?.toString() ?? '',
      guardianContact: json['guardianContact']?.toString() ?? json['phone']?.toString() ?? '',
      isActive: json['isActive'] ?? true,
      user: json['user'] != null ? User.fromJson(json['user']) : User.fromJson(json),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'rollId': rollId,
      'classId': classId,
      'sectionId': sectionId,
      'guardianContact': guardianContact,
      'isActive': isActive,
      if (user != null) 'user': user!.toJson(),
    };
  }
}
