import 'pricing_plan_model.dart';

class SubscriptionSchoolInfo {
  final String id;
  final String schoolId;
  final String name;
  final String address;
  final String phone;
  final String email;
  final bool? isActive;
  final String? avatar;
  final String? createdAt;
  final String? updatedAt;
  final String? deletedAt;

  SubscriptionSchoolInfo({
    required this.id,
    required this.schoolId,
    required this.name,
    required this.address,
    required this.phone,
    required this.email,
    this.isActive,
    this.avatar,
    this.createdAt,
    this.updatedAt,
    this.deletedAt,
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
      avatar: json['avatar'],
      createdAt: json['createdAt'],
      updatedAt: json['updatedAt'],
      deletedAt: json['deletedAt'],
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
      'avatar': avatar,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
      'deletedAt': deletedAt,
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
  final String? paymentMethod;
  final String? transactionId;
  final String? amount;
  final String createdAt;
  final String updatedAt;
  final String? deletedAt;
  final PricingPlan? pricingPlan;
  final SubscriptionSchoolInfo? school;
  final String? status;
  final int? daysRemaining;
  final bool? isExpired;

  Subscription({
    required this.id,
    required this.schoolId,
    required this.startDate,
    required this.endDate,
    required this.isActive,
    required this.lastStudentCount,
    this.paymentMethod,
    this.transactionId,
    this.amount,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
    this.pricingPlan,
    this.school,
    this.status,
    this.daysRemaining,
    this.isExpired,
  });

  factory Subscription.fromJson(Map<String, dynamic> json) {
    return Subscription(
      id: json['id'] ?? '',
      schoolId: json['schoolId'] ?? '',
      startDate: json['startDate'] ?? '',
      endDate: json['endDate'] ?? '',
      isActive: json['isActive'] ?? false,
      lastStudentCount: json['lastStudentCount'] ?? 0,
      paymentMethod: json['paymentMethod'],
      transactionId: json['transactionId'],
      amount: json['amount']?.toString(),
      createdAt: json['createdAt'] ?? '',
      updatedAt: json['updatedAt'] ?? '',
      deletedAt: json['deletedAt'],
      pricingPlan: json['pricingPlan'] != null && json['pricingPlan'] is Map
          ? PricingPlan.fromJson(Map<String, dynamic>.from(json['pricingPlan']))
          : null,
      school: json['school'] != null && json['school'] is Map
          ? SubscriptionSchoolInfo.fromJson(Map<String, dynamic>.from(json['school']))
          : null,
      status: json['status'],
      daysRemaining: json['daysRemaining'],
      isExpired: json['isExpired'],
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
      'paymentMethod': paymentMethod,
      'transactionId': transactionId,
      'amount': amount,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
      'deletedAt': deletedAt,
      'pricingPlan': pricingPlan?.toJson(),
      'school': school?.toJson(),
      'status': status,
      'daysRemaining': daysRemaining,
      'isExpired': isExpired,
    };
  }
}

class SubscriptionSummary {
  final int totalSubscriptions;
  final bool hasActiveSubscription;
  final num totalAmountPaid;

  SubscriptionSummary({
    required this.totalSubscriptions,
    required this.hasActiveSubscription,
    required this.totalAmountPaid,
  });

  factory SubscriptionSummary.fromJson(Map<String, dynamic> json) {
    return SubscriptionSummary(
      totalSubscriptions: json['totalSubscriptions'] ?? 0,
      hasActiveSubscription: json['hasActiveSubscription'] ?? false,
      totalAmountPaid: json['totalAmountPaid'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'totalSubscriptions': totalSubscriptions,
      'hasActiveSubscription': hasActiveSubscription,
      'totalAmountPaid': totalAmountPaid,
    };
  }
}

class SubscriptionHistoryData {
  final String schoolId;
  final SubscriptionSchoolInfo? school;
  final int total;
  final int page;
  final int limit;
  final int totalPages;
  final Subscription? activeSubscription;
  final SubscriptionSummary? summary;
  final List<Subscription> subscriptions;

  SubscriptionHistoryData({
    required this.schoolId,
    this.school,
    required this.total,
    required this.page,
    required this.limit,
    required this.totalPages,
    this.activeSubscription,
    this.summary,
    required this.subscriptions,
  });

  factory SubscriptionHistoryData.fromJson(Map<String, dynamic> json) {
    final rawList = json['subscriptions'] ?? json['data'];
    final List<Subscription> items = [];
    if (rawList is List) {
      for (final item in rawList) {
        if (item is Map<String, dynamic>) {
          items.add(Subscription.fromJson(item));
        } else if (item is Map) {
          items.add(Subscription.fromJson(Map<String, dynamic>.from(item)));
        }
      }
    }

    return SubscriptionHistoryData(
      schoolId: json['schoolId'] ?? '',
      school: json['school'] != null && json['school'] is Map
          ? SubscriptionSchoolInfo.fromJson(
              Map<String, dynamic>.from(json['school']),
            )
          : null,
      total: json['total'] ?? 0,
      page: json['page'] ?? 1,
      limit: json['limit'] ?? 20,
      totalPages: json['totalPages'] ?? 1,
      activeSubscription: json['activeSubscription'] != null &&
              json['activeSubscription'] is Map
          ? Subscription.fromJson(
              Map<String, dynamic>.from(json['activeSubscription']),
            )
          : null,
      summary: json['summary'] != null && json['summary'] is Map
          ? SubscriptionSummary.fromJson(
              Map<String, dynamic>.from(json['summary']),
            )
          : null,
      subscriptions: items,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'schoolId': schoolId,
      'school': school?.toJson(),
      'total': total,
      'page': page,
      'limit': limit,
      'totalPages': totalPages,
      'activeSubscription': activeSubscription?.toJson(),
      'summary': summary?.toJson(),
      'subscriptions': subscriptions.map((s) => s.toJson()).toList(),
    };
  }
}
