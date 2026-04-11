class SuperAdminSchool {
  final String? id;
  final String schoolId;
  final String name;
  final String address;
  final String phone;
  final String email;

  SuperAdminSchool({
    this.id,
    required this.schoolId,
    required this.name,
    required this.address,
    required this.phone,
    required this.email,
  });

  factory SuperAdminSchool.fromJson(Map<String, dynamic> json) {
    return SuperAdminSchool(
      id: json['id'] ?? json['_id'],
      schoolId: json['schoolId'] ?? '',
      name: json['name'] ?? '',
      address: json['address'] ?? '',
      phone: json['phone'] ?? '',
      email: json['email'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'schoolId': schoolId,
      'name': name,
      'address': address,
      'phone': phone,
      'email': email,
    };
  }
}
