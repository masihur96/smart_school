import 'dart:developer';
import 'package:flutter/material.dart';
import '../../../configs/network/data_provider.dart';
import '../../../core/constants/api_path.dart';
import '../../../core/utils/storage_service.dart';
import '../models/pricing_plan_model.dart';

class PricingNotifier extends ChangeNotifier {
  List<PricingPlan> _plans = [];
  bool _isLoading = false;
  String? _error;

  List<PricingPlan> get plans => _plans;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> fetchPricingPlans() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final token = await StorageService.getToken();
      if (token == null) throw Exception('No authentication token found');

      final response = await DataProvider().performRequest(
        'GET',
        APIPath.pricingPlans,
        header: {'Authorization': 'Bearer $token'},
      );

      if (response != null && response.statusCode == 200) {
        final dynamic rawData = response.data;
        final List dataList = rawData is List
            ? rawData
            : (rawData is Map ? (rawData['data'] ?? []) : []);

        _plans = dataList
            .map((json) => PricingPlan.fromJson(json))
            .toList();
        log('Fetched ${_plans.length} pricing plans');
      } else {
        _error = 'Failed to fetch plans: ${response?.statusCode}';
        log('Error fetching pricing plans: ${response?.data}');
      }
    } catch (e) {
      _error = 'Error: $e';
      log('Exception fetching pricing plans: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> createPricingPlan(PricingPlan plan) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final token = await StorageService.getToken();
      if (token == null) throw Exception('No authentication token found');

      final response = await DataProvider().performRequest(
        'POST',
        APIPath.createPricing,
        header: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        data: plan.toJson(),
      );

      if (response != null &&
          (response.statusCode == 201 || response.statusCode == 200)) {
        log('Pricing plan created successfully');
        await fetchPricingPlans(); // Refresh list
        return true;
      } else {
        _error = 'Failed to create plan: ${response?.statusCode}';
        log('Error creating pricing plan: ${response?.data}');
        return false;
      }
    } catch (e) {
      _error = 'Error: $e';
      log('Exception creating pricing plan: $e');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
