class PricingPlan {
  final String? id;
  final String name;
  final int maxStudents;
  final int minStudents;
  final String pricePerMonth;
  final String pricePerStudent;
  final String description;
  final bool isCustom;
  final String? createdAt;
  final String? updatedAt;

  PricingPlan({
    this.id,
    required this.name,
    required this.maxStudents,
    required this.minStudents,
    required this.pricePerMonth,
    required this.pricePerStudent,
    required this.description,
    this.isCustom = false,
    this.createdAt,
    this.updatedAt,
  });

  factory PricingPlan.fromJson(Map<String, dynamic> json) {
    return PricingPlan(
      id: json['id'],
      name: json['name'] ?? '',
      maxStudents: json['maxStudents'] ?? 0,
      minStudents: json['minStudents'] ?? 0,
      pricePerMonth: json['pricePerMonth']?.toString() ?? '0',
      pricePerStudent: json['pricePerStudent']?.toString() ?? '0',
      description: json['description'] ?? '',
      isCustom: json['isCustom'] ?? false,
      createdAt: json['createdAt'],
      updatedAt: json['updatedAt'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'name': name,
      'maxStudents': maxStudents,
      'minStudents': minStudents,
      'pricePerMonth': pricePerMonth,
      'pricePerStudent': pricePerStudent,
      'description': description,
      'isCustom': isCustom,
    };
  }

  PricingPlan copyWith({
    String? id,
    String? name,
    int? maxStudents,
    int? minStudents,
    String? pricePerMonth,
    String? pricePerStudent,
    String? description,
    bool? isCustom,
    String? createdAt,
    String? updatedAt,
  }) {
    return PricingPlan(
      id: id ?? this.id,
      name: name ?? this.name,
      maxStudents: maxStudents ?? this.maxStudents,
      minStudents: minStudents ?? this.minStudents,
      pricePerMonth: pricePerMonth ?? this.pricePerMonth,
      pricePerStudent: pricePerStudent ?? this.pricePerStudent,
      description: description ?? this.description,
      isCustom: isCustom ?? this.isCustom,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
