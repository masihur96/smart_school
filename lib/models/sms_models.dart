class SmsQuotaStatus {
  final String schoolId;
  final String schoolName;
  final int balance;
  final int totalPurchased;
  final int totalAllocated;
  final int totalUsed;
  final bool isEnabled;
  final int lowBalanceThreshold;
  final bool isLowBalance;
  final List<SmsTransaction> recentTransactions;
  final DateTime? updatedAt;

  SmsQuotaStatus({
    required this.schoolId,
    required this.schoolName,
    required this.balance,
    required this.totalPurchased,
    required this.totalAllocated,
    required this.totalUsed,
    required this.isEnabled,
    required this.lowBalanceThreshold,
    required this.isLowBalance,
    required this.recentTransactions,
    this.updatedAt,
  });

  factory SmsQuotaStatus.fromJson(Map<String, dynamic> json) {
    return SmsQuotaStatus(
      schoolId: json['schoolId']?.toString() ?? '',
      schoolName: json['schoolName']?.toString() ?? '',
      balance: json['balance'] is num ? (json['balance'] as num).toInt() : 0,
      totalPurchased: json['totalPurchased'] is num
          ? (json['totalPurchased'] as num).toInt()
          : 0,
      totalAllocated: json['totalAllocated'] is num
          ? (json['totalAllocated'] as num).toInt()
          : 0,
      totalUsed:
          json['totalUsed'] is num ? (json['totalUsed'] as num).toInt() : 0,
      isEnabled: json['isEnabled'] == true,
      lowBalanceThreshold: json['lowBalanceThreshold'] is num
          ? (json['lowBalanceThreshold'] as num).toInt()
          : 50,
      isLowBalance: json['isLowBalance'] == true,
      recentTransactions: (json['recentTransactions'] as List<dynamic>?)
              ?.map((e) => SmsTransaction.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      updatedAt: json['updatedAt'] != null
          ? DateTime.tryParse(json['updatedAt'].toString())
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'schoolId': schoolId,
        'schoolName': schoolName,
        'balance': balance,
        'totalPurchased': totalPurchased,
        'totalAllocated': totalAllocated,
        'totalUsed': totalUsed,
        'isEnabled': isEnabled,
        'lowBalanceThreshold': lowBalanceThreshold,
        'isLowBalance': isLowBalance,
        'recentTransactions':
            recentTransactions.map((e) => e.toJson()).toList(),
        'updatedAt': updatedAt?.toIso8601String(),
      };
}

class SmsTransaction {
  final String id;
  final String schoolId;
  final String type; // USAGE, REFUND, PURCHASE
  final int amount;
  final int previousBalance;
  final int newBalance;
  final String? referenceId;
  final String? description;
  final String? performedById;
  final DateTime? createdAt;

  SmsTransaction({
    required this.id,
    required this.schoolId,
    required this.type,
    required this.amount,
    required this.previousBalance,
    required this.newBalance,
    this.referenceId,
    this.description,
    this.performedById,
    this.createdAt,
  });

  factory SmsTransaction.fromJson(Map<String, dynamic> json) {
    return SmsTransaction(
      id: json['id']?.toString() ?? '',
      schoolId: json['schoolId']?.toString() ?? '',
      type: json['type']?.toString() ?? '',
      amount: json['amount'] is num ? (json['amount'] as num).toInt() : 0,
      previousBalance: json['previousBalance'] is num
          ? (json['previousBalance'] as num).toInt()
          : 0,
      newBalance: json['newBalance'] is num
          ? (json['newBalance'] as num).toInt()
          : 0,
      referenceId: json['referenceId']?.toString(),
      description: json['description']?.toString(),
      performedById: json['performedById']?.toString(),
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString())
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'schoolId': schoolId,
        'type': type,
        'amount': amount,
        'previousBalance': previousBalance,
        'newBalance': newBalance,
        'referenceId': referenceId,
        'description': description,
        'performedById': performedById,
        'createdAt': createdAt?.toIso8601String(),
      };
}

class SmsPackage {
  final String id;
  final String name;
  final int smsCount;
  final double price;
  final double perSmsRate;
  final String? description;
  final bool isActive;
  final bool isPopular;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  SmsPackage({
    required this.id,
    required this.name,
    required this.smsCount,
    required this.price,
    required this.perSmsRate,
    this.description,
    required this.isActive,
    required this.isPopular,
    this.createdAt,
    this.updatedAt,
  });

  factory SmsPackage.fromJson(Map<String, dynamic> json) {
    return SmsPackage(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      smsCount:
          json['smsCount'] is num ? (json['smsCount'] as num).toInt() : 0,
      price: json['price'] is num ? (json['price'] as num).toDouble() : 0.0,
      perSmsRate: json['perSmsRate'] is num
          ? (json['perSmsRate'] as num).toDouble()
          : 0.0,
      description: json['description']?.toString(),
      isActive: json['isActive'] == true,
      isPopular: json['isPopular'] == true,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString())
          : null,
      updatedAt: json['updatedAt'] != null
          ? DateTime.tryParse(json['updatedAt'].toString())
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'smsCount': smsCount,
        'price': price,
        'perSmsRate': perSmsRate,
        'description': description,
        'isActive': isActive,
        'isPopular': isPopular,
        'createdAt': createdAt?.toIso8601String(),
        'updatedAt': updatedAt?.toIso8601String(),
      };
}

class SmsCampaignLog {
  final String id;
  final String schoolId;
  final String? senderId;
  final String? campaignName;
  final String? targetAudience;
  final String? classId;
  final String? sectionId;
  final int recipientCount;
  final int smsParts;
  final int creditsDeducted;
  final List<String> recipients;
  final String message;
  final String status; // PROCESSING, DELIVERED, FAILED, PENDING
  final String? batchId;
  final String? messageId;
  final int? responseCode;
  final String? errorMessage;
  final String? sentById;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  SmsCampaignLog({
    required this.id,
    required this.schoolId,
    this.senderId,
    this.campaignName,
    this.targetAudience,
    this.classId,
    this.sectionId,
    required this.recipientCount,
    required this.smsParts,
    required this.creditsDeducted,
    required this.recipients,
    required this.message,
    required this.status,
    this.batchId,
    this.messageId,
    this.responseCode,
    this.errorMessage,
    this.sentById,
    this.createdAt,
    this.updatedAt,
  });

  factory SmsCampaignLog.fromJson(Map<String, dynamic> json) {
    return SmsCampaignLog(
      id: json['id']?.toString() ?? '',
      schoolId: json['schoolId']?.toString() ?? '',
      senderId: json['senderId']?.toString(),
      campaignName: json['campaignName']?.toString(),
      targetAudience: json['targetAudience']?.toString(),
      classId: json['classId']?.toString(),
      sectionId: json['sectionId']?.toString(),
      recipientCount: json['recipientCount'] is num
          ? (json['recipientCount'] as num).toInt()
          : 0,
      smsParts:
          json['smsParts'] is num ? (json['smsParts'] as num).toInt() : 1,
      creditsDeducted: json['creditsDeducted'] is num
          ? (json['creditsDeducted'] as num).toInt()
          : 0,
      recipients: (json['recipients'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      message: json['message']?.toString() ?? '',
      status: json['status']?.toString().toUpperCase() ?? 'UNKNOWN',
      batchId: json['batchId']?.toString(),
      messageId: json['messageId']?.toString(),
      responseCode: json['responseCode'] is num
          ? (json['responseCode'] as num).toInt()
          : null,
      errorMessage: json['errorMessage']?.toString(),
      sentById: json['sentById']?.toString(),
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString())
          : null,
      updatedAt: json['updatedAt'] != null
          ? DateTime.tryParse(json['updatedAt'].toString())
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'schoolId': schoolId,
        'senderId': senderId,
        'campaignName': campaignName,
        'targetAudience': targetAudience,
        'classId': classId,
        'sectionId': sectionId,
        'recipientCount': recipientCount,
        'smsParts': smsParts,
        'creditsDeducted': creditsDeducted,
        'recipients': recipients,
        'message': message,
        'status': status,
        'batchId': batchId,
        'messageId': messageId,
        'responseCode': responseCode,
        'errorMessage': errorMessage,
        'sentById': sentById,
        'createdAt': createdAt?.toIso8601String(),
        'updatedAt': updatedAt?.toIso8601String(),
      };
}

class SmsCampaignLogsResponse {
  final List<SmsCampaignLog> items;
  final int total;
  final int page;
  final int limit;
  final int totalPages;

  SmsCampaignLogsResponse({
    required this.items,
    required this.total,
    required this.page,
    required this.limit,
    required this.totalPages,
  });

  factory SmsCampaignLogsResponse.fromJson(Map<String, dynamic> json) {
    return SmsCampaignLogsResponse(
      items: (json['items'] as List<dynamic>?)
              ?.map((e) => SmsCampaignLog.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      total: json['total'] is num ? (json['total'] as num).toInt() : 0,
      page: json['page'] is num ? (json['page'] as num).toInt() : 1,
      limit: json['limit'] is num ? (json['limit'] as num).toInt() : 20,
      totalPages:
          json['totalPages'] is num ? (json['totalPages'] as num).toInt() : 1,
    );
  }
}
