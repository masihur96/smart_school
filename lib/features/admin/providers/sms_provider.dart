import 'dart:developer';
import 'package:flutter/foundation.dart';
import 'package:smart_school/models/sms_models.dart';
import 'package:smart_school/services/sms_service.dart';

class SmsProvider extends ChangeNotifier {
  final SmsService _smsService;

  SmsProvider({SmsService? smsService})
      : _smsService = smsService ?? SmsService();

  // Quota Status
  SmsQuotaStatus? _quotaStatus;
  bool _isLoadingQuota = false;

  // Packages
  List<SmsPackage> _packages = [];
  bool _isLoadingPackages = false;

  // Campaign Logs
  List<SmsCampaignLog> _campaignLogs = [];
  bool _isLoadingLogs = false;
  bool _isLoadingMoreLogs = false;
  int _logsPage = 1;
  final int _logsLimit = 20;
  int _logsTotal = 0;
  int _logsTotalPages = 1;

  // Actions
  bool _isBuying = false;
  bool _isSending = false;
  String? _errorMessage;

  // Getters
  SmsQuotaStatus? get quotaStatus => _quotaStatus;
  int get balance => _quotaStatus?.balance ?? 0;
  bool get isLowBalance => _quotaStatus?.isLowBalance ?? false;
  bool get isLoadingQuota => _isLoadingQuota;

  List<SmsPackage> get packages => _packages;
  bool get isLoadingPackages => _isLoadingPackages;

  List<SmsCampaignLog> get campaignLogs => _campaignLogs;
  bool get isLoadingLogs => _isLoadingLogs;
  bool get isLoadingMoreLogs => _isLoadingMoreLogs;
  int get logsPage => _logsPage;
  int get logsTotal => _logsTotal;
  int get logsTotalPages => _logsTotalPages;
  bool get hasMoreLogs => _logsPage < _logsTotalPages;

  bool get isBuying => _isBuying;
  bool get isSending => _isSending;
  String? get errorMessage => _errorMessage;

  /// Fetch SMS Quota & Balance
  Future<void> fetchQuotaStatus() async {
    _isLoadingQuota = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final status = await _smsService.getQuotaStatus();
      if (status != null) {
        _quotaStatus = status;
      }
    } catch (e) {
      log('[SmsProvider] Error fetching quota: $e');
      _errorMessage = e.toString();
    } finally {
      _isLoadingQuota = false;
      notifyListeners();
    }
  }

  /// Fetch Available SMS Packages
  Future<void> fetchPackages() async {
    _isLoadingPackages = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final list = await _smsService.getPackages();
      _packages = list;
    } catch (e) {
      log('[SmsProvider] Error fetching packages: $e');
      _errorMessage = e.toString();
    } finally {
      _isLoadingPackages = false;
      notifyListeners();
    }
  }

  /// Fetch SMS Campaign Logs
  Future<void> fetchCampaignLogs({bool loadMore = false}) async {
    if (loadMore) {
      if (_isLoadingMoreLogs || !hasMoreLogs) return;
      _isLoadingMoreLogs = true;
      notifyListeners();
    } else {
      _isLoadingLogs = true;
      _logsPage = 1;
      _errorMessage = null;
      notifyListeners();
    }

    try {
      final targetPage = loadMore ? _logsPage + 1 : 1;
      final res = await _smsService.getCampaignLogs(
        page: targetPage,
        limit: _logsLimit,
      );

      if (res != null) {
        if (loadMore) {
          _campaignLogs.addAll(res.items);
          _logsPage = res.page;
        } else {
          _campaignLogs = res.items;
          _logsPage = res.page;
        }
        _logsTotal = res.total;
        _logsTotalPages = res.totalPages;
      }
    } catch (e) {
      log('[SmsProvider] Error fetching campaign logs: $e');
      _errorMessage = e.toString();
    } finally {
      _isLoadingLogs = false;
      _isLoadingMoreLogs = false;
      notifyListeners();
    }
  }

  /// Buy a package / Top up Quota
  Future<Map<String, dynamic>> buyPackage({
    required String packageId,
    String paymentMethod = 'WALLET',
    String? transactionId,
    String? notes,
  }) async {
    _isBuying = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final result = await _smsService.buyPackage(
        packageId: packageId,
        paymentMethod: paymentMethod,
        transactionId: transactionId,
        notes: notes,
      );

      if (result['success'] == true) {
        // Refresh Quota status to show the new balance
        await fetchQuotaStatus();
      }

      return result;
    } catch (e) {
      log('[SmsProvider] Error buying package: $e');
      return {'success': false, 'message': e.toString()};
    } finally {
      _isBuying = false;
      notifyListeners();
    }
  }

  /// Send Bulk SMS
  Future<Map<String, dynamic>> sendSms({
    required List<String> phoneNumbers,
    required String message,
    String? campaignName,
    String? senderId,
    bool isMasked = false,
  }) async {
    _isSending = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final result = await _smsService.sendSms(
        phoneNumbers: phoneNumbers,
        message: message,
        campaignName: campaignName,
        senderId: senderId,
        isMasked: isMasked,
      );

      if (result['success'] == true) {
        // Automatically refresh quota & logs
        fetchQuotaStatus();
        fetchCampaignLogs();
      }

      return result;
    } catch (e) {
      log('[SmsProvider] Error sending SMS: $e');
      return {'success': false, 'message': e.toString()};
    } finally {
      _isSending = false;
      notifyListeners();
    }
  }

  /// Initial load for all SMS data
  Future<void> initAll() async {
    await Future.wait([
      fetchQuotaStatus(),
      fetchPackages(),
      fetchCampaignLogs(),
    ]);
  }
}
