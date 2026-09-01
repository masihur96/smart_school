class SuperAdminSchool {
  final String? id;
  final String schoolId;
  final String name;
  final String address;
  final String phone;
  final String email;
  final bool isActive;
  final String? avatar;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final DateTime? deletedAt;

  SuperAdminSchool({
    this.id,
    required this.schoolId,
    required this.name,
    required this.address,
    required this.phone,
    required this.email,
    this.isActive = true,
    this.avatar,
    this.createdAt,
    this.updatedAt,
    this.deletedAt,
  });

  factory SuperAdminSchool.fromJson(Map<String, dynamic> json) {
    return SuperAdminSchool(
      id: json['id'] ?? json['_id'],
      schoolId: json['schoolId'] ?? '',
      name: json['name'] ?? '',
      address: json['address'] ?? '',
      phone: json['phone'] ?? '',
      email: json['email'] ?? '',
      isActive: json['isActive'] ?? true,
      avatar: json['avatar'] as String?,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'])
          : null,
      updatedAt: json['updatedAt'] != null
          ? DateTime.tryParse(json['updatedAt'])
          : null,
      deletedAt: json['deletedAt'] != null
          ? DateTime.tryParse(json['deletedAt'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'schoolId': schoolId,
      'name': name,
      'address': address,
      'phone': phone,
      'email': email,
      'isActive': isActive,
    };
  }

  SuperAdminSchool copyWith({
    String? id,
    String? schoolId,
    String? name,
    String? address,
    String? phone,
    String? email,
    bool? isActive,
    String? avatar,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? deletedAt,
  }) {
    return SuperAdminSchool(
      id: id ?? this.id,
      schoolId: schoolId ?? this.schoolId,
      name: name ?? this.name,
      address: address ?? this.address,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      isActive: isActive ?? this.isActive,
      avatar: avatar ?? this.avatar,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
    );
  }
}
