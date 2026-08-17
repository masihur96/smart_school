enum TransactionType {
  income,
  expense,
}

class Expense {
  final String id;
  final String title;
  final double amount;
  final DateTime date;
  final String category;
  final String description;
  final TransactionType type;
  final String paymentMethod;
  final String? referenceNumber;
  final String? attachmentUrl;

  Expense({
    required this.id,
    required this.title,
    required this.amount,
    required this.date,
    required this.category,
    required this.description,
    this.type = TransactionType.expense,
    this.paymentMethod = 'Cash',
    this.referenceNumber,
    this.attachmentUrl,
  });

  bool get isIncome => type == TransactionType.income;
  bool get isExpense => type == TransactionType.expense;

  Expense copyWith({
    String? id,
    String? title,
    double? amount,
    DateTime? date,
    String? category,
    String? description,
    TransactionType? type,
    String? paymentMethod,
    String? referenceNumber,
    String? attachmentUrl,
  }) {
    return Expense(
      id: id ?? this.id,
      title: title ?? this.title,
      amount: amount ?? this.amount,
      date: date ?? this.date,
      category: category ?? this.category,
      description: description ?? this.description,
      type: type ?? this.type,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      referenceNumber: referenceNumber ?? this.referenceNumber,
      attachmentUrl: attachmentUrl ?? this.attachmentUrl,
    );
  }

  factory Expense.fromJson(Map<String, dynamic> json) {
    final typeStr = (json['type'] ??
            json['transactionType'] ??
            json['walletTransactionType'] ??
            json['typeOfTransaction'] ??
            '')
        .toString()
        .toUpperCase();

    final catStr = (json['category'] ?? '').toString().toUpperCase();
    final titleStr = (json['title'] ?? '').toString().toUpperCase();

    bool isIncome = false;
    if (typeStr.isNotEmpty) {
      if (typeStr == 'INCOME' ||
          typeStr == 'ADD_MONEY' ||
          typeStr == 'DEPOSIT' ||
          typeStr == 'CREDIT' ||
          typeStr == 'INFLOW' ||
          typeStr.contains('INCOME')) {
        isIncome = true;
      } else if (typeStr == 'EXPENSE' ||
          typeStr == 'ADD_EXPENSE' ||
          typeStr == 'DEBIT' ||
          typeStr == 'OUTFLOW' ||
          typeStr.contains('EXPENSE')) {
        isIncome = false;
      }
    } else if (json['isIncome'] != null) {
      isIncome = json['isIncome'] == true;
    } else if (json['isExpense'] != null) {
      isIncome = json['isExpense'] != true;
    } else {
      // Check category and title heuristics
      if (catStr.contains('FEE') ||
          catStr.contains('TUITION') ||
          catStr.contains('ADMISSION') ||
          catStr.contains('GRANT') ||
          catStr.contains('DONATION') ||
          catStr.contains('COLLECTION') ||
          titleStr.contains('FEE') ||
          titleStr.contains('TUITION') ||
          titleStr.contains('DEPOSIT')) {
        isIncome = true;
      } else {
        isIncome = false;
      }
    }

    double parsedAmount = 0.0;
    if (json['amount'] != null) {
      if (json['amount'] is num) {
        parsedAmount = (json['amount'] as num).toDouble();
      } else {
        parsedAmount = double.tryParse(json['amount'].toString()) ?? 0.0;
      }
    }

    DateTime parsedDate = DateTime.now();
    final rawDate = json['transactionDate'] ??
        json['date'] ??
        json['createdAt'] ??
        json['created_at'] ??
        json['timestamp'] ??
        json['time'];
    if (rawDate != null) {
      parsedDate = DateTime.tryParse(rawDate.toString()) ?? DateTime.now();
    }

    return Expense(
      id: json['id']?.toString() ??
          json['_id']?.toString() ??
          json['transactionId']?.toString() ??
          DateTime.now().millisecondsSinceEpoch.toString(),
      title: (json['title'] ??
              json['name'] ??
              json['reason'] ??
              json['description'] ??
              json['category'] ??
              'Transaction')
          .toString(),
      amount: parsedAmount,
      date: parsedDate,
      category: json['category']?.toString() ?? 'General',
      description: (json['description'] ??
              json['note'] ??
              json['remarks'] ??
              json['details'] ??
              '')
          .toString(),
      type: isIncome ? TransactionType.income : TransactionType.expense,
      paymentMethod: (json['paymentMethod'] ??
              json['method'] ??
              json['channel'] ??
              'Cash')
          .toString(),
      referenceNumber: json['referenceNumber']?.toString() ??
          json['refNumber']?.toString() ??
          json['reference']?.toString() ??
          json['trn']?.toString(),
      attachmentUrl: json['attachmentUrl']?.toString() ??
          json['receiptUrl']?.toString() ??
          json['fileUrl']?.toString() ??
          json['attachment']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'amount': amount,
      'transactionDate': date.toUtc().toIso8601String(),
      'category': category,
      'description': description,
      'type': isIncome ? 'income' : 'expense',
      'paymentMethod': paymentMethod,
      'referenceNumber': referenceNumber,
      'attachmentUrl': attachmentUrl,
    };
  }
}

class WalletPeriodSummary {
  final double totalIncome;
  final double totalExpense;
  final double netBalance;
  final int? month;
  final int? year;

  const WalletPeriodSummary({
    this.totalIncome = 0.0,
    this.totalExpense = 0.0,
    this.netBalance = 0.0,
    this.month,
    this.year,
  });

  factory WalletPeriodSummary.fromJson(Map<String, dynamic> json) {
    double parseDouble(dynamic val) {
      if (val == null) return 0.0;
      if (val is num) return val.toDouble();
      return double.tryParse(val.toString()) ?? 0.0;
    }

    final income = parseDouble(
      json['totalIncome'] ??
          json['income'] ??
          json['inflow'] ??
          json['totalInflow'],
    );

    final expense = parseDouble(
      json['totalExpense'] ??
          json['totalExpenses'] ??
          json['expense'] ??
          json['expenses'] ??
          json['outflow'] ??
          json['totalOutflow'],
    );

    final net = json['netBalance'] != null ||
            json['net'] != null ||
            json['balance'] != null
        ? parseDouble(json['netBalance'] ?? json['net'] ?? json['balance'])
        : (income - expense);

    int? parsedMonth;
    if (json['month'] != null) {
      parsedMonth = int.tryParse(json['month'].toString());
    }

    int? parsedYear;
    if (json['year'] != null) {
      parsedYear = int.tryParse(json['year'].toString());
    }

    return WalletPeriodSummary(
      totalIncome: income,
      totalExpense: expense,
      netBalance: net,
      month: parsedMonth,
      year: parsedYear,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'totalIncome': totalIncome,
      'totalExpense': totalExpense,
      'netBalance': netBalance,
      if (month != null) 'month': month,
      if (year != null) 'year': year,
    };
  }

  WalletPeriodSummary copyWith({
    double? totalIncome,
    double? totalExpense,
    double? netBalance,
    int? month,
    int? year,
  }) {
    return WalletPeriodSummary(
      totalIncome: totalIncome ?? this.totalIncome,
      totalExpense: totalExpense ?? this.totalExpense,
      netBalance: netBalance ?? this.netBalance,
      month: month ?? this.month,
      year: year ?? this.year,
    );
  }

  String get monthName {
    if (month == null || month! < 1 || month! > 12) return '';
    const months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];
    return months[month! - 1];
  }

  String get shortMonthName {
    if (month == null || month! < 1 || month! > 12) return '';
    const shortMonths = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return shortMonths[month! - 1];
  }
}

class WalletSummary {
  final WalletPeriodSummary allTime;
  final WalletPeriodSummary currentMonth;
  final WalletPeriodSummary currentYear;

  const WalletSummary({
    this.allTime = const WalletPeriodSummary(),
    this.currentMonth = const WalletPeriodSummary(),
    this.currentYear = const WalletPeriodSummary(),
  });

  factory WalletSummary.fromJson(Map<String, dynamic> json) {
    WalletPeriodSummary parsePeriod(dynamic val) {
      if (val is Map<String, dynamic>) {
        return WalletPeriodSummary.fromJson(val);
      } else if (val is Map) {
        return WalletPeriodSummary.fromJson(Map<String, dynamic>.from(val));
      }
      return const WalletPeriodSummary();
    }

    return WalletSummary(
      allTime: parsePeriod(json['allTime']),
      currentMonth: parsePeriod(json['currentMonth']),
      currentYear: parsePeriod(json['currentYear']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'allTime': allTime.toJson(),
      'currentMonth': currentMonth.toJson(),
      'currentYear': currentYear.toJson(),
    };
  }

  WalletSummary copyWith({
    WalletPeriodSummary? allTime,
    WalletPeriodSummary? currentMonth,
    WalletPeriodSummary? currentYear,
  }) {
    return WalletSummary(
      allTime: allTime ?? this.allTime,
      currentMonth: currentMonth ?? this.currentMonth,
      currentYear: currentYear ?? this.currentYear,
    );
  }
}
