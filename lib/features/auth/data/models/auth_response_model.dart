class AuthResponseModel {
  final String name;
  final String email;
  final String role;

  AuthResponseModel({
    required this.name,
    required this.email,
    required this.role,
  });

  factory AuthResponseModel.fromJson(Map<String, dynamic> json) {
    return AuthResponseModel(
      name: json['name']??"",
      email: json['email']??"",
      role: json['role']??"",
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'email': email,
      'role': role,
    };
  }
}
