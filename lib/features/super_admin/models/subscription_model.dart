import 'pricing_plan_model.dart';

class SubscriptionSchoolInfo {
  final String id;
  final String schoolId;
  final String name;
  final String address;
  final String phone;
  final String email;
  final bool? isActive;

  SubscriptionSchoolInfo({
    required this.id,
    required this.schoolId,
    required this.name,
    required this.address,
    required this.phone,
    required this.email,
    this.isActive,
  });

  factory SubscriptionSchoolInfo.fromJson(Map<String, dynamic> json) {
    return SubscriptionSchoolInfo(
      id: json['id'] ?? '',
      schoolId: json['schoolId'] ?? '',
      name: json['name'] ?? '',
      address: json['address'] ?? '',
      phone: json['phone'] ?? '',
      email: json['email'] ?? '',
      isActive: json['isActive'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'schoolId': schoolId,
      'name': name,
      'address': address,
      'phone': phone,
      'email': email,
      'isActive': isActive,
    };
  }
}

class Subscription {
  final String id;
  final String schoolId;
  final String startDate;
  final String endDate;
  final bool isActive;
  final int lastStudentCount;
  final String createdAt;
  final String updatedAt;
  final PricingPlan? pricingPlan;
  final SubscriptionSchoolInfo? school;

  Subscription({
    required this.id,
    required this.schoolId,
    required this.startDate,
    required this.endDate,
    required this.isActive,
    required this.lastStudentCount,
    required this.createdAt,
    required this.updatedAt,
    this.pricingPlan,
    this.school,
  });

  factory Subscription.fromJson(Map<String, dynamic> json) {
    return Subscription(
      id: json['id'] ?? '',
      schoolId: json['schoolId'] ?? '',
      startDate: json['startDate'] ?? '',
      endDate: json['endDate'] ?? '',
      isActive: json['isActive'] ?? false,
      lastStudentCount: json['lastStudentCount'] ?? 0,
      createdAt: json['createdAt'] ?? '',
      updatedAt: json['updatedAt'] ?? '',
      pricingPlan: json['pricingPlan'] != null
          ? PricingPlan.fromJson(json['pricingPlan'])
          : null,
      school: json['school'] != null
          ? SubscriptionSchoolInfo.fromJson(json['school'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'schoolId': schoolId,
      'startDate': startDate,
      'endDate': endDate,
      'isActive': isActive,
      'lastStudentCount': lastStudentCount,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
      'pricingPlan': pricingPlan?.toJson(),
      'school': school?.toJson(),
    };
  }
}
