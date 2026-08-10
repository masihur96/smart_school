import 'package:flutter/material.dart';
import '../models/expense_model.dart';

class ExpenseProvider with ChangeNotifier {
  final List<Expense> _expenses = [
    Expense(
      id: '1',
      title: 'Teacher Salaries',
      amount: 45000.0,
      date: DateTime.now().subtract(const Duration(days: 2)),
      category: 'Salary',
      description: 'Monthly salary for teaching staff.',
    ),
    Expense(
      id: '2',
      title: 'Electricity Bill',
      amount: 1200.50,
      date: DateTime.now().subtract(const Duration(days: 5)),
      category: 'Maintenance',
      description: 'Monthly electricity bill for main building.',
    ),
    Expense(
      id: '3',
      title: 'New Whiteboards',
      amount: 350.0,
      date: DateTime.now().subtract(const Duration(days: 10)),
      category: 'Supplies',
      description: 'Purchased 5 new whiteboards for classrooms.',
    ),
    Expense(
      id: '4',
      title: 'Annual Sports Day',
      amount: 2500.0,
      date: DateTime.now().subtract(const Duration(days: 15)),
      category: 'Events',
      description: 'Trophies, snacks, and equipment rental.',
    ),
    Expense(
      id: '5',
      title: 'Plumbing Repair',
      amount: 150.0,
      date: DateTime.now().subtract(const Duration(days: 20)),
      category: 'Maintenance',
      description: 'Fixed leaking pipe in science lab.',
    ),
  ];

  List<Expense> get expenses {
    // Return sorted by date descending
    final list = [..._expenses];
    list.sort((a, b) => b.date.compareTo(a.date));
    return list;
  }

  double get totalExpenses {
    return _expenses.fold(0.0, (sum, item) => sum + item.amount);
  }

  double get thisMonthExpenses {
    final now = DateTime.now();
    return _expenses
        .where((e) => e.date.year == now.year && e.date.month == now.month)
        .fold(0.0, (sum, item) => sum + item.amount);
  }

  void addExpense(Expense expense) {
    _expenses.add(expense);
    notifyListeners();
  }

  void updateExpense(Expense expense) {
    final index = _expenses.indexWhere((e) => e.id == expense.id);
    if (index >= 0) {
      _expenses[index] = expense;
      notifyListeners();
    }
  }

  void deleteExpense(String id) {
    _expenses.removeWhere((e) => e.id == id);
    notifyListeners();
  }
}
