import 'dart:developer';
import 'package:flutter/material.dart';
import '../../../configs/network/data_provider.dart';
import '../../../core/constants/api_path.dart';
import '../../../core/utils/storage_service.dart';
import '../models/subscription_model.dart';

class SubscriptionNotifier extends ChangeNotifier {
  List<Subscription> _subscriptions = [];
  bool _isLoading = false;
  String? _error;

  List<Subscription> get subscriptions => _subscriptions;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> fetchSubscriptions() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final token = await StorageService.getToken();
      if (token == null) throw Exception('No authentication token found');

      final response = await DataProvider().performRequest(
        'GET',
        APIPath.allSubscriptions,
        header: {'Authorization': 'Bearer $token'},
      );

      if (response != null && response.statusCode == 200) {
        final dynamic rawData = response.data;
        final List dataList = rawData is List
            ? rawData
            : (rawData is Map ? (rawData['data'] ?? []) : []);

        _subscriptions = dataList
            .map((json) => Subscription.fromJson(json))
            .toList();
        log('Fetched ${_subscriptions.length} subscriptions');
      } else {
        _error = 'Failed to fetch subscriptions: ${response?.statusCode}';
        log('Error fetching subscriptions: ${response?.data}');
      }
    } catch (e) {
      _error = 'Error: $e';
      log('Exception fetching subscriptions: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
