import 'dart:developer';

import 'package:flutter/material.dart';

import '../../../configs/network/data_provider.dart';
import '../../../core/constants/api_path.dart';
import '../../../core/utils/storage_service.dart';
import '../models/expense_model.dart';
import '../models/financial_story_model.dart';

enum TransactionFilter { all, income, expense }

class ExpenseProvider with ChangeNotifier {
  final List<Expense> _expenses = [];

  late List<FinancialStory> _stories;

  ExpenseProvider() {
    _refreshStories();
  }

  void _refreshStories() {
    final income = totalIncome;
    final expenses = totalExpenses;
    final balance = walletBalance;
    final incomeList = onlyIncomes;
    final expenseList = onlyExpenses;

    _stories = [
      FinancialStory(
        id: 'story_month',
        title: 'Treasury Pulse',
        subtitle: 'Cashflow Overview',
        icon: Icons.insights_rounded,
        gradientColors: const [Color(0xFF6366F1), Color(0xFF4338CA)],
        slides: [
          StorySlide(
            title: 'Treasury Cashflow',
            highlightValue:
                '${balance >= 0 ? '+' : ''}\$${balance.toStringAsFixed(2)}',
            subtitle: 'Net Balance',
            description: balance >= 0
                ? 'School liquidity remains healthy with total receipts exceeding operational disbursements.'
                : 'Operational disbursements currently exceed logged receipts.',
            bulletPoints: [
              'Total Inflow: \$${income.toStringAsFixed(2)}',
              'Total Outflow: \$${expenses.toStringAsFixed(2)}',
              'Total Transactions: ${_expenses.length}',
            ],
            badge: 'Treasury Health',
            badgeColor: const Color(0xFF6366F1),
            icon: Icons.trending_up_rounded,
            footerNote: 'Synchronized with backend records.',
          ),
        ],
      ),
      FinancialStory(
        id: 'story_fee',
        title: 'Fee Inflow',
        subtitle: 'Collection Pulse',
        icon: Icons.account_balance_wallet_rounded,
        gradientColors: const [Color(0xFF10B981), Color(0xFF047857)],
        slides: [
          StorySlide(
            title: 'Fee & Income Collection',
            highlightValue: '\$${income.toStringAsFixed(2)}',
            subtitle: 'Total receipts collected',
            description: incomeList.isEmpty
                ? 'No income transactions logged yet. Tap "+ Add Money" to add collections.'
                : '${incomeList.length} income deposits logged across all channels.',
            bulletPoints: [
              'Bank Transfers: \$${incomeList.where((e) => e.paymentMethod.toUpperCase().contains('BANK')).fold(0.0, (s, e) => s + e.amount).toStringAsFixed(2)}',
              'Cash Receipts: \$${incomeList.where((e) => e.paymentMethod.toUpperCase().contains('CASH')).fold(0.0, (s, e) => s + e.amount).toStringAsFixed(2)}',
              'Other Channels: \$${incomeList.where((e) => !e.paymentMethod.toUpperCase().contains('BANK') && !e.paymentMethod.toUpperCase().contains('CASH')).fold(0.0, (s, e) => s + e.amount).toStringAsFixed(2)}',
            ],
            badge: 'Fee Inflow',
            badgeColor: const Color(0xFF10B981),
            icon: Icons.payments_rounded,
            footerNote: 'Real-time sync enabled.',
          ),
        ],
      ),
      FinancialStory(
        id: 'story_expenses',
        title: 'Outflows',
        subtitle: 'Disbursements',
        icon: Icons.receipt_long_rounded,
        gradientColors: const [Color(0xFFEF4444), Color(0xFFB91C1C)],
        slides: [
          StorySlide(
            title: 'Campus Expenditures',
            highlightValue: '\$${expenses.toStringAsFixed(2)}',
            subtitle: 'Total expenses recorded',
            description: expenseList.isEmpty
                ? 'No campus expenses logged yet. Tap "- Add Expense" to log bills or payroll.'
                : '${expenseList.length} operational expenditure vouchers recorded.',
            bulletPoints: [
              'Total Outflows: \$${expenses.toStringAsFixed(2)}',
              'Transactions Logged: ${expenseList.length}',
              'Net Operating Reserve: \$${balance.toStringAsFixed(2)}',
            ],
            badge: 'Expenses Done',
            badgeColor: const Color(0xFFEF4444),
            icon: Icons.receipt_long_rounded,
            footerNote: 'Updated from school wallet database.',
          ),
        ],
      ),
    ];
  }

  List<Expense> get expenses {
    // Return all sorted by date descending
    final list = [..._expenses];
    list.sort((a, b) => b.date.compareTo(a.date));
    return list;
  }

  List<Expense> get onlyExpenses {
    return expenses.where((e) => e.isExpense).toList();
  }

  List<Expense> get onlyIncomes {
    return expenses.where((e) => e.isIncome).toList();
  }

  List<FinancialStory> get stories => _stories;

  WalletSummary? _summary;
  WalletSummary? get summary => _summary;

  double? _serverBalance;
  double? _serverTotalIncome;
  double? _serverTotalExpense;

  WalletPeriodSummary get allTimeSummary =>
      _summary?.allTime ?? _calculateFallbackAllTime();

  WalletPeriodSummary get currentMonthSummary =>
      _summary?.currentMonth ?? _calculateFallbackCurrentMonth();

  WalletPeriodSummary get currentYearSummary =>
      _summary?.currentYear ?? _calculateFallbackCurrentYear();

  WalletPeriodSummary _calculateFallbackAllTime() {
    final calcIncome = _expenses
        .where((e) => e.isIncome)
        .fold(0.0, (sum, item) => sum + item.amount);
    final calcExpense = _expenses
        .where((e) => e.isExpense)
        .fold(0.0, (sum, item) => sum + item.amount);
    final inc = _serverTotalIncome != null && _serverTotalIncome! > 0
        ? _serverTotalIncome!
        : calcIncome;
    final exp = _serverTotalExpense != null && _serverTotalExpense! > 0
        ? _serverTotalExpense!
        : calcExpense;
    final net = _serverBalance ?? (inc - exp);
    return WalletPeriodSummary(
      totalIncome: inc,
      totalExpense: exp,
      netBalance: net,
    );
  }

  WalletPeriodSummary _calculateFallbackCurrentMonth() {
    final now = DateTime.now();
    final calcIncome = _expenses
        .where(
          (e) =>
              e.isIncome &&
              e.date.year == now.year &&
              e.date.month == now.month,
        )
        .fold(0.0, (sum, item) => sum + item.amount);
    final calcExpense = _expenses
        .where(
          (e) =>
              e.isExpense &&
              e.date.year == now.year &&
              e.date.month == now.month,
        )
        .fold(0.0, (sum, item) => sum + item.amount);
    return WalletPeriodSummary(
      totalIncome: calcIncome,
      totalExpense: calcExpense,
      netBalance: calcIncome - calcExpense,
      month: now.month,
      year: now.year,
    );
  }

  WalletPeriodSummary _calculateFallbackCurrentYear() {
    final now = DateTime.now();
    final calcIncome = _expenses
        .where((e) => e.isIncome && e.date.year == now.year)
        .fold(0.0, (sum, item) => sum + item.amount);
    final calcExpense = _expenses
        .where((e) => e.isExpense && e.date.year == now.year)
        .fold(0.0, (sum, item) => sum + item.amount);
    return WalletPeriodSummary(
      totalIncome: calcIncome,
      totalExpense: calcExpense,
      netBalance: calcIncome - calcExpense,
      year: now.year,
    );
  }

  double get totalIncome => allTimeSummary.totalIncome;

  double get totalExpenses => allTimeSummary.totalExpense;

  double get walletBalance => allTimeSummary.netBalance;

  double get thisMonthIncome => currentMonthSummary.totalIncome;

  double get thisMonthExpenses => currentMonthSummary.totalExpense;

  double get thisMonthNet => currentMonthSummary.netBalance;

  double get thisYearIncome => currentYearSummary.totalIncome;

  double get thisYearExpenses => currentYearSummary.totalExpense;

  double get thisYearNet => currentYearSummary.netBalance;

  double get todayIncome {
    final now = DateTime.now();
    return _expenses
        .where(
          (e) =>
              e.isIncome &&
              e.date.year == now.year &&
              e.date.month == now.month &&
              e.date.day == now.day,
        )
        .fold(0.0, (sum, item) => sum + item.amount);
  }

  double get todayExpenses {
    final now = DateTime.now();
    return _expenses
        .where(
          (e) =>
              e.isExpense &&
              e.date.year == now.year &&
              e.date.month == now.month &&
              e.date.day == now.day,
        )
        .fold(0.0, (sum, item) => sum + item.amount);
  }

  List<Expense> getFilteredTransactions({
    TransactionFilter filter = TransactionFilter.all,
    String query = '',
  }) {
    var list = expenses;

    if (filter == TransactionFilter.income) {
      list = list.where((e) => e.isIncome).toList();
    } else if (filter == TransactionFilter.expense) {
      list = list.where((e) => e.isExpense).toList();
    }

    if (query.trim().isNotEmpty) {
      final q = query.toLowerCase();
      list = list.where((e) {
        return e.title.toLowerCase().contains(q) ||
            e.category.toLowerCase().contains(q) ||
            e.description.toLowerCase().contains(q) ||
            (e.referenceNumber?.toLowerCase().contains(q) ?? false);
      }).toList();
    }

    return list;
  }

  void _adjustSummaryOnTransactionAdd(Expense transaction) {
    if (_summary == null) return;
    final now = DateTime.now();
    final isCurrentMonth = transaction.date.year ==
            (_summary!.currentMonth.year ?? now.year) &&
        transaction.date.month ==
            (_summary!.currentMonth.month ?? now.month);
    final isCurrentYear =
        transaction.date.year == (_summary!.currentYear.year ?? now.year);

    final amount = transaction.amount;
    final isIncome = transaction.isIncome;

    final newAllTime = _summary!.allTime.copyWith(
      totalIncome: _summary!.allTime.totalIncome + (isIncome ? amount : 0),
      totalExpense: _summary!.allTime.totalExpense + (isIncome ? 0 : amount),
      netBalance: _summary!.allTime.netBalance + (isIncome ? amount : -amount),
    );

    final newCurrentMonth = isCurrentMonth
        ? _summary!.currentMonth.copyWith(
            totalIncome: _summary!.currentMonth.totalIncome +
                (isIncome ? amount : 0),
            totalExpense: _summary!.currentMonth.totalExpense +
                (isIncome ? 0 : amount),
            netBalance: _summary!.currentMonth.netBalance +
                (isIncome ? amount : -amount),
          )
        : _summary!.currentMonth;

    final newCurrentYear = isCurrentYear
        ? _summary!.currentYear.copyWith(
            totalIncome: _summary!.currentYear.totalIncome +
                (isIncome ? amount : 0),
            totalExpense: _summary!.currentYear.totalExpense +
                (isIncome ? 0 : amount),
            netBalance: _summary!.currentYear.netBalance +
                (isIncome ? amount : -amount),
          )
        : _summary!.currentYear;

    _summary = WalletSummary(
      allTime: newAllTime,
      currentMonth: newCurrentMonth,
      currentYear: newCurrentYear,
    );
  }

  void _adjustSummaryOnTransactionDelete(Expense transaction) {
    if (_summary == null) return;
    final now = DateTime.now();
    final isCurrentMonth = transaction.date.year ==
            (_summary!.currentMonth.year ?? now.year) &&
        transaction.date.month ==
            (_summary!.currentMonth.month ?? now.month);
    final isCurrentYear =
        transaction.date.year == (_summary!.currentYear.year ?? now.year);

    final amount = transaction.amount;
    final isIncome = transaction.isIncome;

    final newAllTime = _summary!.allTime.copyWith(
      totalIncome: (_summary!.allTime.totalIncome - (isIncome ? amount : 0))
          .clamp(0, double.infinity),
      totalExpense: (_summary!.allTime.totalExpense - (isIncome ? 0 : amount))
          .clamp(0, double.infinity),
      netBalance: _summary!.allTime.netBalance - (isIncome ? amount : -amount),
    );

    final newCurrentMonth = isCurrentMonth
        ? _summary!.currentMonth.copyWith(
            totalIncome: (_summary!.currentMonth.totalIncome -
                    (isIncome ? amount : 0))
                .clamp(0, double.infinity),
            totalExpense: (_summary!.currentMonth.totalExpense -
                    (isIncome ? 0 : amount))
                .clamp(0, double.infinity),
            netBalance: _summary!.currentMonth.netBalance -
                (isIncome ? amount : -amount),
          )
        : _summary!.currentMonth;

    final newCurrentYear = isCurrentYear
        ? _summary!.currentYear.copyWith(
            totalIncome: (_summary!.currentYear.totalIncome -
                    (isIncome ? amount : 0))
                .clamp(0, double.infinity),
            totalExpense: (_summary!.currentYear.totalExpense -
                    (isIncome ? 0 : amount))
                .clamp(0, double.infinity),
            netBalance: _summary!.currentYear.netBalance -
                (isIncome ? amount : -amount),
          )
        : _summary!.currentYear;

    _summary = WalletSummary(
      allTime: newAllTime,
      currentMonth: newCurrentMonth,
      currentYear: newCurrentYear,
    );
  }

  void addExpense(Expense expense) {
    _expenses.add(expense);
    _adjustSummaryOnTransactionAdd(expense);
    _checkAndRefreshStoryHighlights();
    notifyListeners();
  }

  void addAmount(Expense income) {
    _expenses.add(income);
    _adjustSummaryOnTransactionAdd(income);
    _checkAndRefreshStoryHighlights();
    notifyListeners();
  }

  void updateExpense(Expense expense) {
    final index = _expenses.indexWhere((e) => e.id == expense.id);
    if (index >= 0) {
      final old = _expenses[index];
      _expenses[index] = expense;
      _adjustSummaryOnTransactionDelete(old);
      _adjustSummaryOnTransactionAdd(expense);
      _checkAndRefreshStoryHighlights();
      notifyListeners();
    }
  }

  void deleteExpense(String id) {
    final index = _expenses.indexWhere((e) => e.id == id);
    if (index >= 0) {
      final old = _expenses[index];
      _expenses.removeAt(index);
      _adjustSummaryOnTransactionDelete(old);
      _checkAndRefreshStoryHighlights();
      notifyListeners();
    }
  }

  Future<Map<String, dynamic>> deleteTransactionApi({
    required String transactionId,
    required String schoolId,
  }) async {
    try {
      final token = await StorageService.getToken();
      if (token == null || token.isEmpty) {
        return {
          'success': false,
          'message': 'Authentication session expired. Please log in again.',
        };
      }

      final url =
          '${APIPath.baseUrl}/wallet/transactions/$transactionId?schoolId=$schoolId';
      log('Deleting transaction with URL: $url');

      final response = await DataProvider().performRequest(
        'DELETE',
        url,
        header: {'accept': '*/*', 'Authorization': 'Bearer $token'},
      );

      if (response != null &&
          (response.statusCode == 200 ||
              response.statusCode == 204 ||
              response.statusCode == 201)) {
        deleteExpense(transactionId);
        return {'success': true, 'data': response.data};
      } else {
        String errorMessage = 'Failed to delete transaction.';
        if (response?.data is Map && response?.data['message'] != null) {
          errorMessage = response!.data['message'].toString();
        } else if (response?.statusMessage != null) {
          errorMessage = response!.statusMessage!;
        }
        return {'success': false, 'message': errorMessage};
      }
    } catch (e) {
      log('Error deleting transaction: $e');
      return {'success': false, 'message': e.toString()};
    }
  }

  Future<Map<String, dynamic>> updateTransactionApi({
    required String transactionId,
    required String schoolId,
    double? amount,
    required String category,
    required String title,
    required String description,
    required String paymentMethod,
    String? referenceNumber,
    required DateTime transactionDate,
    String? attachmentUrl,
    TransactionType? type,
  }) async {
    _isActionLoading = true;
    notifyListeners();

    try {
      final token = await StorageService.getToken();
      if (token == null || token.isEmpty) {
        _isActionLoading = false;
        notifyListeners();
        return {
          'success': false,
          'message': 'Authentication session expired. Please log in again.',
        };
      }

      final payload = {
        if (amount != null) 'amount': amount,
        'category': category,
        'title': title,
        'description': description,
        'paymentMethod': paymentMethod,
        if (referenceNumber != null && referenceNumber.isNotEmpty)
          'referenceNumber': referenceNumber,
        'transactionDate': transactionDate.toUtc().toIso8601String(),
        if (attachmentUrl != null && attachmentUrl.isNotEmpty)
          'attachmentUrl': attachmentUrl,
      };

      final url =
          '${APIPath.baseUrl}/wallet/transactions/$transactionId?schoolId=$schoolId';
      log('Sending PATCH transaction request: $url with payload: $payload');

      final response = await DataProvider().performRequest(
        'PATCH',
        url,
        data: payload,
        header: {
          'accept': '*/*',
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      _isActionLoading = false;

      if (response != null &&
          (response.statusCode == 200 ||
              response.statusCode == 201 ||
              response.statusCode == 204)) {
        final existingIndex = _expenses.indexWhere(
          (e) => e.id == transactionId,
        );
        final existingExpense = existingIndex >= 0
            ? _expenses[existingIndex]
            : null;

        final updatedExpense = Expense(
          id: transactionId,
          title: title,
          amount: amount ?? existingExpense?.amount ?? 0.0,
          date: transactionDate,
          category: category,
          description: description,
          type: type ?? existingExpense?.type ?? TransactionType.expense,
          paymentMethod: paymentMethod,
          referenceNumber: referenceNumber,
          attachmentUrl: attachmentUrl,
        );

        updateExpense(updatedExpense);
        return {'success': true, 'data': response.data};
      } else {
        String errorMessage = 'Failed to update transaction.';
        if (response?.data is Map && response?.data['message'] != null) {
          errorMessage = response!.data['message'].toString();
        } else if (response?.statusMessage != null) {
          errorMessage = response!.statusMessage!;
        }
        notifyListeners();
        return {'success': false, 'message': errorMessage};
      }
    } catch (e) {
      log('Error updating transaction: $e');
      _isActionLoading = false;
      notifyListeners();
      return {'success': false, 'message': e.toString()};
    }
  }

  void markStoryAsViewed(String storyId) {
    final index = _stories.indexWhere((s) => s.id == storyId);
    if (index >= 0 && !_stories[index].isViewed) {
      _stories[index].isViewed = true;
      notifyListeners();
    }
  }

  void addCustomStory(FinancialStory story) {
    _stories.insert(0, story);
    notifyListeners();
  }

  bool _isLoading = false;
  bool get isLoading => _isLoading;
  String? _error;
  String? get error => _error;

  bool _isActionLoading = false;
  bool get isActionLoading => _isActionLoading;

  List<Map<String, dynamic>> _extractTransactionsList(dynamic raw) {
    if (raw == null) return [];

    if (raw is List) {
      final list = <Map<String, dynamic>>[];
      for (var item in raw) {
        if (item is Map) {
          final map = Map<String, dynamic>.from(item);
          if (map['transactions'] is List) {
            list.addAll(_extractTransactionsList(map['transactions']));
          } else if (map['recentTransactions'] is List) {
            list.addAll(_extractTransactionsList(map['recentTransactions']));
          } else {
            list.add(map);
          }
        }
      }
      return list;
    }

    if (raw is Map) {
      final map = Map<String, dynamic>.from(raw);

      for (final key in [
        'recentTransactions',
        'recent_transactions',
        'transactions',
        'walletTransactions',
        'wallet_transactions',
        'history',
        'transactionHistory',
        'items',
        'records',
        'data',
        'results',
        'rows',
        'docs',
        'list',
      ]) {
        if (map[key] is List) {
          return _extractTransactionsList(map[key]);
        }
      }

      if (map['expenses'] is List || map['incomes'] is List) {
        final list = <Map<String, dynamic>>[];
        if (map['incomes'] is List) {
          list.addAll(_extractTransactionsList(map['incomes']));
        }
        if (map['expenses'] is List) {
          list.addAll(_extractTransactionsList(map['expenses']));
        }
        return list;
      }

      for (final key in ['data', 'wallet', 'result', 'response', 'payload']) {
        if (map[key] is Map) {
          final extracted = _extractTransactionsList(map[key]);
          if (extracted.isNotEmpty) return extracted;
        } else if (map[key] is List) {
          return _extractTransactionsList(map[key]);
        }
      }
    }

    return [];
  }

  void _extractServerMetrics(dynamic raw) {
    if (raw == null) return;
    if (raw is Map) {
      final map = Map<String, dynamic>.from(raw);

      // 1. Check for summary object
      if (map['summary'] is Map) {
        try {
          _summary = WalletSummary.fromJson(
            Map<String, dynamic>.from(map['summary']),
          );
          _serverTotalIncome = _summary!.allTime.totalIncome;
          _serverTotalExpense = _summary!.allTime.totalExpense;
          _serverBalance = _summary!.allTime.netBalance;
          log('Parsed summary from response: ${_summary?.toJson()}');
        } catch (e) {
          log('Error parsing summary object: $e');
        }
      } else if (map['allTime'] is Map ||
          map['currentMonth'] is Map ||
          map['currentYear'] is Map) {
        try {
          _summary = WalletSummary.fromJson(map);
          _serverTotalIncome = _summary!.allTime.totalIncome;
          _serverTotalExpense = _summary!.allTime.totalExpense;
          _serverBalance = _summary!.allTime.netBalance;
          log('Parsed summary direct map: ${_summary?.toJson()}');
        } catch (e) {
          log('Error parsing summary direct map: $e');
        }
      }

      // Check nested objects if summary was not found at root level
      if (_summary == null) {
        if (map['data'] is Map) _extractServerMetrics(map['data']);
        if (_summary == null && map['wallet'] is Map) {
          _extractServerMetrics(map['wallet']);
        }
        if (_summary == null && map['result'] is Map) {
          _extractServerMetrics(map['result']);
        }
        if (_summary == null && map['response'] is Map) {
          _extractServerMetrics(map['response']);
        }
      }

      final b = map['balance'] ??
          map['walletBalance'] ??
          map['currentBalance'] ??
          map['netBalance'] ??
          map['net'];
      if (b != null) {
        _serverBalance = b is num
            ? b.toDouble()
            : double.tryParse(b.toString());
      }

      final ti = map['totalIncome'] ??
          map['inflow'] ??
          map['totalInflow'] ??
          map['income'];
      if (ti != null) {
        _serverTotalIncome = ti is num
            ? ti.toDouble()
            : double.tryParse(ti.toString());
      }

      final te = map['totalExpense'] ??
          map['totalExpenses'] ??
          map['outflow'] ??
          map['totalOutflow'] ??
          map['expense'] ??
          map['expenses'];
      if (te != null) {
        _serverTotalExpense = te is num
            ? te.toDouble()
            : double.tryParse(te.toString());
      }
    } else if (raw is List && raw.isNotEmpty && raw.first is Map) {
      _extractServerMetrics(raw.first);
    }
  }

  Future<void> fetchTransactions({String? schoolId}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final token = await StorageService.getToken();
      if (token == null || token.isEmpty) {
        _isLoading = false;
        _error = 'Authentication token not found';
        notifyListeners();
        return;
      }

      final String url = (schoolId != null && schoolId.isNotEmpty)
          ? '${APIPath.baseUrl}/wallet?schoolId=$schoolId'
          : '${APIPath.baseUrl}/wallet';

      log('Fetching wallet transactions from: $url');

      final response = await DataProvider().performRequest(
        'GET',
        url,
        header: {'accept': '*/*', 'Authorization': 'Bearer $token'},
      );

      _isLoading = false;

      if (response != null &&
          (response.statusCode == 200 || response.statusCode == 201)) {
        final raw = response.data;
        log('Wallet raw response received: $raw');

        _extractServerMetrics(raw);
        final listData = _extractTransactionsList(raw);

        final fetched = <Expense>[];
        for (var item in listData) {
          try {
            fetched.add(Expense.fromJson(item));
          } catch (itemError) {
            log('Error parsing transaction item: $item, error: $itemError');
          }
        }

        _expenses.clear();
        _expenses.addAll(fetched);
        log(
          'Successfully parsed ${_expenses.length} transactions from wallet API',
        );

        _checkAndRefreshStoryHighlights();
        notifyListeners();
      } else {
        _error = response?.data is Map && response?.data['message'] != null
            ? response!.data['message'].toString()
            : (response?.statusMessage ?? 'Failed to fetch transactions');
        log('Error fetching wallet transactions: $_error');
        notifyListeners();
      }
    } catch (e) {
      log('Exception fetching wallet transactions: $e');
      _isLoading = false;
      _error = e.toString();
      notifyListeners();
    }
  }

  Future<Map<String, dynamic>> addMoneyToWalletApi({
    required String schoolId,
    required double amount,
    required String category,
    required String title,
    required String description,
    required String paymentMethod,
    String? referenceNumber,
    required DateTime transactionDate,
    String? attachmentUrl,
  }) async {
    _isActionLoading = true;
    notifyListeners();

    try {
      final token = await StorageService.getToken();
      if (token == null || token.isEmpty) {
        _isActionLoading = false;
        notifyListeners();
        return {
          'success': false,
          'message': 'Authentication session expired. Please log in again.',
        };
      }

      final payload = {
        'amount': amount,
        'category': category,
        'title': title,
        'description': description,
        'paymentMethod': paymentMethod,
        if (referenceNumber != null && referenceNumber.isNotEmpty)
          'referenceNumber': referenceNumber,
        'transactionDate': transactionDate.toUtc().toIso8601String(),
        if (attachmentUrl != null && attachmentUrl.isNotEmpty)
          'attachmentUrl': attachmentUrl,
      };

      log(
        'Sending add-money request for school: $schoolId with payload: $payload',
      );

      final url = '${APIPath.baseUrl}/wallet/add-money?schoolId=$schoolId';
      final response = await DataProvider().performRequest(
        'POST',
        url,
        data: payload,
        header: {
          'accept': '*/*',
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      _isActionLoading = false;

      if (response != null &&
          (response.statusCode == 200 || response.statusCode == 201)) {
        String newId = DateTime.now().millisecondsSinceEpoch.toString();
        if (response.data is Map) {
          final dataMap = response.data['data'] ?? response.data;
          if (dataMap is Map && dataMap['id'] != null) {
            newId = dataMap['id'].toString();
          }
        }

        final newExpense = Expense(
          id: newId,
          title: title,
          amount: amount,
          date: transactionDate,
          category: category,
          description: description,
          type: TransactionType.income,
          paymentMethod: paymentMethod,
          referenceNumber: referenceNumber,
          attachmentUrl: attachmentUrl,
        );

        addAmount(newExpense);
        return {'success': true, 'data': response.data};
      } else {
        String errorMessage = 'Failed to add money to wallet.';
        if (response?.data is Map && response?.data['message'] != null) {
          errorMessage = response!.data['message'].toString();
        } else if (response?.statusMessage != null) {
          errorMessage = response!.statusMessage!;
        }
        notifyListeners();
        return {'success': false, 'message': errorMessage};
      }
    } catch (e) {
      log('Error adding money to wallet: $e');
      _isActionLoading = false;
      notifyListeners();
      return {'success': false, 'message': e.toString()};
    }
  }

  Future<Map<String, dynamic>> addExpenseToWalletApi({
    required String schoolId,
    required double amount,
    required String category,
    required String title,
    required String description,
    required String paymentMethod,
    String? referenceNumber,
    required DateTime transactionDate,
    String? attachmentUrl,
  }) async {
    _isActionLoading = true;
    notifyListeners();

    try {
      final token = await StorageService.getToken();
      if (token == null || token.isEmpty) {
        _isActionLoading = false;
        notifyListeners();
        return {
          'success': false,
          'message': 'Authentication session expired. Please log in again.',
        };
      }

      final payload = {
        'amount': amount,
        'category': category,
        'title': title,
        'description': description,
        'paymentMethod': paymentMethod,
        if (referenceNumber != null && referenceNumber.isNotEmpty)
          'referenceNumber': referenceNumber,
        'transactionDate': transactionDate.toUtc().toIso8601String(),
        if (attachmentUrl != null && attachmentUrl.isNotEmpty)
          'attachmentUrl': attachmentUrl,
      };

      log(
        'Sending add-expense request for school: $schoolId with payload: $payload',
      );

      final url = '${APIPath.baseUrl}/wallet/add-expense?schoolId=$schoolId';
      final response = await DataProvider().performRequest(
        'POST',
        url,
        data: payload,
        header: {
          'accept': '*/*',
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      _isActionLoading = false;

      if (response != null &&
          (response.statusCode == 200 || response.statusCode == 201)) {
        String newId = DateTime.now().millisecondsSinceEpoch.toString();
        if (response.data is Map) {
          final dataMap = response.data['data'] ?? response.data;
          if (dataMap is Map && dataMap['id'] != null) {
            newId = dataMap['id'].toString();
          }
        }

        final newExpense = Expense(
          id: newId,
          title: title,
          amount: amount,
          date: transactionDate,
          category: category,
          description: description,
          type: TransactionType.expense,
          paymentMethod: paymentMethod,
          referenceNumber: referenceNumber,
          attachmentUrl: attachmentUrl,
        );

        addExpense(newExpense);
        return {'success': true, 'data': response.data};
      } else {
        String errorMessage = 'Failed to record expense.';
        if (response?.data is Map && response?.data['message'] != null) {
          errorMessage = response!.data['message'].toString();
        } else if (response?.statusMessage != null) {
          errorMessage = response!.statusMessage!;
        }
        notifyListeners();
        return {'success': false, 'message': errorMessage};
      }
    } catch (e) {
      log('Error adding expense to wallet: $e');
      _isActionLoading = false;
      notifyListeners();
      return {'success': false, 'message': e.toString()};
    }
  }

  void _checkAndRefreshStoryHighlights() {
    _refreshStories();
  }
}
