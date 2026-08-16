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
