class AuthResponseModel {
  final String id;
  final String name;
  final String email;
  final String role;
  final String? schoolId;
  final String? classId;
  final String? sectionId;
  final String? phone;
  final String? rollNumber;
  final String? designation;
  final bool? isActive;
  final String? createdAt;
  final double? lat;
  final double? lon;
  final double? radius;

  AuthResponseModel({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    this.schoolId,
    this.classId,
    this.sectionId,
    this.phone,
    this.rollNumber,
    this.designation,
    this.isActive,
    this.createdAt,
    this.lat,
    this.lon,
    this.radius,
  });

  factory AuthResponseModel.fromJson(Map<String, dynamic> json) {
    return AuthResponseModel(
      id: json['id'] ?? "",
      name: json['name'] ?? "",
      email: json['email'] ?? "",
      role: json['role'] ?? "",
      schoolId: json['schoolId'],
      classId: json['classId'],
      sectionId: json['sectionId'],
      phone: json['phone'],
      rollNumber: json['rollNumber'],
      designation: json['designation'],
      isActive: json['isActive'],
      createdAt: json['createdAt']?.toString(),
      lat: json['lat'] != null ? double.tryParse(json['lat'].toString()) : null,
      lon: json['lon'] != null ? double.tryParse(json['lon'].toString()) : null,
      radius: json['radius'] != null ? double.tryParse(json['radius'].toString()) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'role': role,
      'schoolId': schoolId,
      'classId': classId,
      'sectionId': sectionId,
      'phone': phone,
      'rollNumber': rollNumber,
      'designation': designation,
      'isActive': isActive,
      'createdAt': createdAt,
      'lat': lat,
      'lon': lon,
      'radius': radius,
    };
  }
}
