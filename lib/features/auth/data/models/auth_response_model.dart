class AuthResponseModel {
  final String id;
  final String name;
  final String email;
  final String role;
  final String? schoolId;
  final String? phone;

  AuthResponseModel({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    this.schoolId,
    this.phone,
  });

  factory AuthResponseModel.fromJson(Map<String, dynamic> json) {
    return AuthResponseModel(
      id: json['id'] ?? "",
      name: json['name'] ?? "",
      email: json['email'] ?? "",
      role: json['role'] ?? "",
      schoolId: json['schoolId'],
      phone: json['phone'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'role': role,
      'schoolId': schoolId,
      'phone': phone,
    };
  }
}
