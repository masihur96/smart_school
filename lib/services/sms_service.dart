import 'dart:developer';

import 'package:smart_school/configs/network/data_provider.dart';
import 'package:smart_school/core/constants/api_path.dart';
import 'package:smart_school/core/utils/storage_service.dart';
import 'package:smart_school/models/sms_models.dart';

class SmsService {
  final DataProvider _dataProvider;

  // Default sender IDs for the SMS gateway
  static const String defaultNonMaskedSender = "8809639228875";
  static const String defaultMaskedSender = "SchoolCare";

  SmsService({DataProvider? dataProvider})
      : _dataProvider = dataProvider ?? DataProvider();

  Future<Map<String, String>?> _getAuthHeader() async {
    final token = await StorageService.getToken();
    if (token == null || token.isEmpty) return null;
    return {
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
      'accept': '*/*',
    };
  }

  /// 1. Get SMS Quota Status & Balance
  Future<SmsQuotaStatus?> getQuotaStatus() async {
    try {
      final header = await _getAuthHeader();
      if (header == null) {
        log('[SmsService] No auth token available for getQuotaStatus');
        return null;
      }

      final response = await _dataProvider.performRequest(
        'GET',
        APIPath.smsQuotaStatus,
        header: header,
      );

      if (response != null &&
          (response.statusCode == 200 || response.statusCode == 201)) {
        final data = response.data;
        if (data is Map<String, dynamic> && data['data'] != null) {
          return SmsQuotaStatus.fromJson(
            data['data'] as Map<String, dynamic>,
          );
        }
      }
      log('[SmsService] Failed to get quota status: ${response?.data}');
      return null;
    } catch (e, stack) {
      log('[SmsService] Error in getQuotaStatus: $e', stackTrace: stack);
      return null;
    }
  }

  /// 2. Get Available SMS Packages
  Future<List<SmsPackage>> getPackages() async {
    try {
      final header = await _getAuthHeader();
      if (header == null) {
        log('[SmsService] No auth token available for getPackages');
        return [];
      }

      final response = await _dataProvider.performRequest(
        'GET',
        APIPath.smsPackages,
        header: header,
      );

      if (response != null &&
          (response.statusCode == 200 || response.statusCode == 201)) {
        final data = response.data;
        if (data is Map<String, dynamic> && data['data'] is List) {
          return (data['data'] as List<dynamic>)
              .map((e) => SmsPackage.fromJson(e as Map<String, dynamic>))
              .toList();
        }
      }
      log('[SmsService] Failed to get packages: ${response?.data}');
      return [];
    } catch (e, stack) {
      log('[SmsService] Error in getPackages: $e', stackTrace: stack);
      return [];
    }
  }

  /// 3. Buy SMS Package / Top-up Quota
  Future<Map<String, dynamic>> buyPackage({
    required String packageId,
    String paymentMethod = 'WALLET',
    String? transactionId,
    String? notes,
  }) async {
    try {
      final header = await _getAuthHeader();
      if (header == null) {
        return {'success': false, 'message': 'No authentication token found'};
      }

      final Map<String, dynamic> body = {
        'packageId': packageId,
        'paymentMethod': paymentMethod,
        if (transactionId != null && transactionId.isNotEmpty)
          'transactionId': transactionId,
        if (notes != null && notes.isNotEmpty) 'notes': notes,
      };

      final response = await _dataProvider.performRequest(
        'POST',
        APIPath.smsBuyQuota,
        header: header,
        data: body,
      );

      if (response != null &&
          (response.statusCode == 200 || response.statusCode == 201)) {
        final resData = response.data;
        final message = resData is Map && resData['message'] != null
            ? resData['message'].toString()
            : 'Package purchased successfully';
        return {
          'success': true,
          'message': message,
          'data': resData is Map ? resData['data'] : null,
        };
      } else {
        String errorMsg = 'Failed to buy package';
        if (response?.data != null && response!.data is Map) {
          final resMsg = response.data['message'];
          if (resMsg is List) {
            errorMsg = resMsg.join(', ');
          } else if (resMsg is String) {
            errorMsg = resMsg;
          }
        }
        return {'success': false, 'message': errorMsg};
      }
    } catch (e, stack) {
      log('[SmsService] Error in buyPackage: $e', stackTrace: stack);
      return {'success': false, 'message': e.toString()};
    }
  }

  /// 4. Get SMS Campaign Logs
  Future<SmsCampaignLogsResponse?> getCampaignLogs({
    int page = 1,
    int limit = 20,
  }) async {
    try {
      final header = await _getAuthHeader();
      if (header == null) {
        log('[SmsService] No auth token available for getCampaignLogs');
        return null;
      }

      final response = await _dataProvider.performRequest(
        'GET',
        APIPath.smsLogs(page: page, limit: limit),
        header: header,
      );

      if (response != null &&
          (response.statusCode == 200 || response.statusCode == 201)) {
        final data = response.data;
        if (data is Map<String, dynamic> && data['data'] != null) {
          return SmsCampaignLogsResponse.fromJson(
            data['data'] as Map<String, dynamic>,
          );
        }
      }
      log('[SmsService] Failed to get campaign logs: ${response?.data}');
      return null;
    } catch (e, stack) {
      log('[SmsService] Error in getCampaignLogs: $e', stackTrace: stack);
      return null;
    }
  }

  /// 5. Send Bulk SMS via Backend API
  Future<Map<String, dynamic>> sendSms({
    required List<String> phoneNumbers,
    required String message,
    String? campaignName,
    String? senderId,
    bool isMasked = false,
  }) async {
    if (phoneNumbers.isEmpty || message.trim().isEmpty) {
      return {
        'success': false,
        'message': 'Phone numbers and message are required',
      };
    }

    try {
      final header = await _getAuthHeader();
      if (header == null) {
        return {'success': false, 'message': 'No authentication token found'};
      }

      // Format phone numbers: Ensure they match Bangladeshi format 01XXXXXXXXX
      final formattedNumbers = phoneNumbers.map((raw) {
        var cleaned = raw.trim().replaceAll(RegExp(r'[^0-9]'), '');
        if (cleaned.startsWith('880')) {
          cleaned = cleaned.substring(2);
        } else if (cleaned.startsWith('+880')) {
          cleaned = cleaned.substring(3);
        }
        return cleaned;
      }).where((cleaned) => cleaned.isNotEmpty).toList();

      if (formattedNumbers.isEmpty) {
        return {
          'success': false,
          'message': 'No valid phone numbers to send to',
        };
      }

      final resolvedSenderId = senderId ??
          (isMasked ? defaultMaskedSender : defaultNonMaskedSender);

      final Map<String, dynamic> body = {
        'mobNumbers': formattedNumbers,
        'numbers': formattedNumbers,
        'message': message.trim(),
        'senderId': resolvedSenderId,
        'campaignName': campaignName ?? 'Emergency Broadcast',
        'isMasked': isMasked,
      };

      final response = await _dataProvider.performRequest(
        'POST',
        APIPath.smsSend,
        header: header,
        data: body,
      );

      if (response != null &&
          (response.statusCode == 200 || response.statusCode == 201)) {
        final resData = response.data;
        log('[SmsService] SMS sent successfully: $resData');
        final message = resData is Map && resData['message'] != null
            ? resData['message'].toString()
            : 'SMS submitted successfully';
        return {
          'success': true,
          'message': message,
          'data': resData is Map ? resData['data'] : null,
        };
      } else {
        String errorMsg = 'Failed to send SMS';
        if (response?.data != null && response!.data is Map) {
          final resMsg = response.data['message'];
          if (resMsg is List) {
            errorMsg = resMsg.join(', ');
          } else if (resMsg is String) {
            errorMsg = resMsg;
          }
        }
        log('[SmsService] Failed to send SMS: ${response?.statusCode} - ${response?.data}');
        return {'success': false, 'message': errorMsg};
      }
    } catch (e, stack) {
      log('[SmsService] Error in sendSms: $e', stackTrace: stack);
      return {'success': false, 'message': e.toString()};
    }
  }

  /// Backward-compatible method signature
  Future<bool> sendBulkSms(
    List<String> phoneNumbers,
    String message, {
    bool isMasked = false,
    String? campaignName,
    String? senderId,
  }) async {
    final result = await sendSms(
      phoneNumbers: phoneNumbers,
      message: message,
      isMasked: isMasked,
      campaignName: campaignName,
      senderId: senderId,
    );
    return result['success'] == true;
  }
}
