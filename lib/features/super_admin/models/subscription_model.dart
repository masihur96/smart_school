import 'pricing_plan_model.dart';

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
    };
  }
}
