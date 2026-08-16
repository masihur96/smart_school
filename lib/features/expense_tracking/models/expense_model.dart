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
            json['typeOfTransaction'] ??
            '')
        .toString()
        .toUpperCase();

    final isIncome = typeStr == 'INCOME' ||
        typeStr == 'ADD_MONEY' ||
        typeStr == 'DEPOSIT' ||
        typeStr == 'CREDIT' ||
        json['isIncome'] == true;

    return Expense(
      id: json['id']?.toString() ?? json['_id']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      amount: (json['amount'] as num?)?.toDouble() ?? 0.0,
      date: json['transactionDate'] != null
          ? DateTime.tryParse(json['transactionDate'].toString()) ??
              DateTime.now()
          : (json['date'] != null
              ? DateTime.tryParse(json['date'].toString()) ?? DateTime.now()
              : (json['createdAt'] != null
                  ? DateTime.tryParse(json['createdAt'].toString()) ??
                      DateTime.now()
                  : DateTime.now())),
      category: json['category']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      type: isIncome ? TransactionType.income : TransactionType.expense,
      paymentMethod: json['paymentMethod']?.toString() ?? 'Cash',
      referenceNumber: json['referenceNumber']?.toString(),
      attachmentUrl: json['attachmentUrl']?.toString(),
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
