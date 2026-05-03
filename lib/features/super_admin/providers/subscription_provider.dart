import 'dart:developer';

import 'package:flutter/material.dart';

import '../../../configs/network/data_provider.dart';
import '../../../core/constants/api_path.dart';
import '../../../core/utils/storage_service.dart';
import '../../../services/notification_service.dart';
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

  Future<bool> updateSubscriptionStatus(String id, bool isActive) async {
    _isLoading = true;
    notifyListeners();

    try {
      final token = await StorageService.getToken();
      if (token == null) throw Exception('No authentication token found');

      final response = await DataProvider().performRequest(
        'PATCH',
        APIPath.updateSubscription(id),
        header: {'Authorization': 'Bearer $token'},
        data: {'isActive': isActive},
      );

      if (response != null && response.statusCode == 200) {
        log('Subscription updated successfully');

        // Trigger notification to super admins and school
        NotificationService().triggerNotification(
          title: 'Subscription Update',
          body: 'Subscription status has been changed to ${isActive ? "Active" : "Inactive"}.',
          topic: 'subscription',
          data: {'type': 'subscription_update', 'id': id, 'isActive': isActive},
        );

        await fetchSubscriptions(); // Refresh the list from the server
        return true;
      } else {
        _error = 'Failed to update subscription: ${response?.statusCode}';
        log('Error updating subscription: ${response?.data}');
        return false;
      }
    } catch (e) {
      _error = 'Error updating subscription: $e';
      log('Exception updating subscription: $e');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> deleteSubscription(String id) async {
    _isLoading = true;
    notifyListeners();

    try {
      final token = await StorageService.getToken();
      if (token == null) throw Exception('No authentication token found');

      final response = await DataProvider().performRequest(
        'DELETE',
        APIPath.deleteSubscription(id),
        header: {'Authorization': 'Bearer $token'},
      );

      if (response != null && response.statusCode == 200) {
        _subscriptions.removeWhere((s) => s.id == id);
        return true;
      } else if (response != null && response.statusCode == 204) {
        // Also handle 204 No Content
        _subscriptions.removeWhere((s) => s.id == id);
        return true;
      } else {
        _error = 'Failed to delete subscription: ${response?.statusCode}';
        log('Error deleting subscription: ${response?.data}');
        return false;
      }
    } catch (e) {
      _error = 'Error deleting subscription: $e';
      log('Exception deleting subscription: $e');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
