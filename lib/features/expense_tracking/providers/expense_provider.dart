import 'package:flutter/material.dart';
import '../models/expense_model.dart';
import '../models/financial_story_model.dart';

enum TransactionFilter {
  all,
  income,
  expense,
}

class ExpenseProvider with ChangeNotifier {
  final List<Expense> _expenses = [
    // Income Transactions (Student Fees, Grants, etc.)
    Expense(
      id: 'inc_1',
      title: 'Class 10 Monthly Tuition Fees',
      amount: 32500.0,
      date: DateTime.now().subtract(const Duration(hours: 4)),
      category: 'Tuition Fee',
      description: 'Collected tuition fees for Class 10 (Section A & B).',
      type: TransactionType.income,
      paymentMethod: 'Bank Transfer',
      referenceNumber: 'TXN-FEE-8891',
    ),
    Expense(
      id: 'inc_2',
      title: 'New Admission Fees (Grade 1)',
      amount: 18000.0,
      date: DateTime.now().subtract(const Duration(days: 1)),
      category: 'Admission Fee',
      description: 'Admission fee packages collected for 12 new applicants.',
      type: TransactionType.income,
      paymentMethod: 'bKash / Mobile',
      referenceNumber: 'TXN-ADM-4412',
    ),
    Expense(
      id: 'inc_3',
      title: 'Govt. Education Tech Grant',
      amount: 25000.0,
      date: DateTime.now().subtract(const Duration(days: 4)),
      category: 'Grant',
      description: 'Q3 STEM laboratory infrastructure development grant.',
      type: TransactionType.income,
      paymentMethod: 'Bank Transfer',
      referenceNumber: 'GOV-GRNT-901',
    ),
    Expense(
      id: 'inc_4',
      title: 'Annual Sports Day Registration',
      amount: 6400.0,
      date: DateTime.now().subtract(const Duration(days: 8)),
      category: 'Event Fee',
      description: 'Student registration collection for sports competitions.',
      type: TransactionType.income,
      paymentMethod: 'Cash',
      referenceNumber: 'REC-SPT-102',
    ),
    Expense(
      id: 'inc_5',
      title: 'Cafeteria & Canteen Revenue',
      amount: 4200.0,
      date: DateTime.now().subtract(const Duration(days: 12)),
      category: 'Cafeteria',
      description: 'Monthly cafeteria lease and revenue share deposit.',
      type: TransactionType.income,
      paymentMethod: 'Cash',
      referenceNumber: 'REC-CAF-330',
    ),

    // Expense Transactions
    Expense(
      id: '1',
      title: 'Teacher Salaries',
      amount: 45000.0,
      date: DateTime.now().subtract(const Duration(days: 2)),
      category: 'Salary',
      description: 'Monthly salary for teaching staff.',
      type: TransactionType.expense,
      paymentMethod: 'Bank Transfer',
      referenceNumber: 'PAY-SAL-008',
    ),
    Expense(
      id: '2',
      title: 'Electricity Bill',
      amount: 1200.50,
      date: DateTime.now().subtract(const Duration(days: 5)),
      category: 'Maintenance',
      description: 'Monthly electricity bill for main building & AC units.',
      type: TransactionType.expense,
      paymentMethod: 'bKash / Mobile',
      referenceNumber: 'UTIL-ELEC-412',
    ),
    Expense(
      id: '3',
      title: 'New Whiteboards & Markers',
      amount: 350.0,
      date: DateTime.now().subtract(const Duration(days: 10)),
      category: 'Supplies',
      description: 'Purchased 5 magnetic whiteboards for science classrooms.',
      type: TransactionType.expense,
      paymentMethod: 'Cash',
      referenceNumber: 'SUPP-WB-991',
    ),
    Expense(
      id: '4',
      title: 'Annual Sports Day Organization',
      amount: 2500.0,
      date: DateTime.now().subtract(const Duration(days: 15)),
      category: 'Events',
      description: 'Trophies, guest refreshments, sound system, and track flags.',
      type: TransactionType.expense,
      paymentMethod: 'Cash',
      referenceNumber: 'EVNT-SPT-772',
    ),
    Expense(
      id: '5',
      title: 'Plumbing Repair & Sanitation',
      amount: 150.0,
      date: DateTime.now().subtract(const Duration(days: 20)),
      category: 'Maintenance',
      description: 'Fixed leaking water pipe in chemistry laboratory.',
      type: TransactionType.expense,
      paymentMethod: 'Cash',
      referenceNumber: 'MAINT-PLB-094',
    ),
  ];

  late List<FinancialStory> _stories;

  ExpenseProvider() {
    _initStories();
  }

  void _initStories() {
    _stories = [
      FinancialStory(
        id: 'story_fee',
        title: 'Fee Stories',
        subtitle: 'Collection Pulse',
        icon: Icons.account_balance_wallet_rounded,
        gradientColors: const [Color(0xFF10B981), Color(0xFF047857)],
        slides: [
          StorySlide(
            title: 'Tuition Fee Collection',
            highlightValue: '\$32,500.00',
            subtitle: 'Collected this month',
            description: '92% of Class 9 & 10 tuition fees have been settled successfully through online portals & treasury counter.',
            bulletPoints: [
              'Online Bank/Mobile: \$26,100 (80%)',
              'Counter Cash: \$6,400 (20%)',
              'Outstanding pending dues: \$2,800',
            ],
            badge: 'Fee Inflow',
            badgeColor: const Color(0xFF10B981),
            icon: Icons.payments_rounded,
            footerNote: 'Auto-reminder SMS sent to remaining 14 students.',
          ),
          StorySlide(
            title: 'Admission Package Receipts',
            highlightValue: '\$18,000.00',
            subtitle: 'New enrollments intake',
            description: 'Fresh admission fees logged for Grade 1 and transfer candidates for the upcoming academic session.',
            bulletPoints: [
              '12 Full admission packages cleared',
              'Orientation kit & uniforms included',
              'Next batch interviews on Monday',
            ],
            badge: 'Admissions',
            badgeColor: const Color(0xFF059669),
            icon: Icons.how_to_reg_rounded,
            footerNote: 'Target 95% met for Grade 1 admissions.',
          ),
        ],
      ),
      FinancialStory(
        id: 'story_month',
        title: 'Monthly Pulse',
        subtitle: 'Cashflow Overview',
        icon: Icons.insights_rounded,
        gradientColors: const [Color(0xFF6366F1), Color(0xFF4338CA)],
        slides: [
          StorySlide(
            title: 'Treasury Cashflow',
            highlightValue: '+\$36,899.50',
            subtitle: 'Net Balance Growth',
            description: 'School liquidity remains strong with total receipts exceeding operational disbursements by 42%.',
            bulletPoints: [
              'Total Inflow: \$86,100.00',
              'Total Outflow: \$49,200.50',
              'Surplus reserve allocated to STEM lab upgrade',
            ],
            badge: 'Financial Health',
            badgeColor: const Color(0xFF6366F1),
            icon: Icons.trending_up_rounded,
            footerNote: 'Financial audit status: In full compliance.',
          ),
        ],
      ),
      FinancialStory(
        id: 'story_salaries',
        title: 'Staff Payroll',
        subtitle: 'Disbursement',
        icon: Icons.people_alt_rounded,
        gradientColors: const [Color(0xFFF59E0B), Color(0xFFD97706)],
        slides: [
          StorySlide(
            title: 'Teacher & Staff Payroll',
            highlightValue: '\$45,000.00',
            subtitle: 'Disbursed on 1st of month',
            description: 'Salaries disbursed to 24 full-time teaching faculty and 8 support & administrative staff members.',
            bulletPoints: [
              'Direct Bank Deposit: 100% completed',
              'Provident fund deductions registered',
              'Bonus evaluation scheduled for Q4',
            ],
            badge: 'Payroll Done',
            badgeColor: const Color(0xFFF59E0B),
            icon: Icons.badge_rounded,
            footerNote: 'Tax certificates generated for all personnel.',
          ),
        ],
      ),
      FinancialStory(
        id: 'story_utilities',
        title: 'Campus Bills',
        subtitle: 'Utilities & Power',
        icon: Icons.bolt_rounded,
        gradientColors: const [Color(0xFFEC4899), Color(0xFFBE185D)],
        slides: [
          StorySlide(
            title: 'Utilities & Energy',
            highlightValue: '\$1,200.50',
            subtitle: 'Monthly electricity & water',
            description: 'Electricity expenses dropped 8% this month following the installation of solar inverter panels in the library.',
            bulletPoints: [
              'Main Building: \$780.00',
              'Science & Computer Lab: \$320.50',
              'Campus Water & Gas: \$100.00',
            ],
            badge: 'Utility Outflow',
            badgeColor: const Color(0xFFEC4899),
            icon: Icons.lightbulb_rounded,
            footerNote: 'Next maintenance review due on 25th.',
          ),
        ],
      ),
      FinancialStory(
        id: 'story_reserve',
        title: 'Reserve Fund',
        subtitle: 'Safety Treasury',
        icon: Icons.shield_rounded,
        gradientColors: const [Color(0xFF8B5CF6), Color(0xFF6D28D9)],
        slides: [
          StorySlide(
            title: 'Emergency & Dev Reserve',
            highlightValue: '\$25,000.00',
            subtitle: 'Government tech grant',
            description: 'Dedicated fund secured for robotics kits, interactive smartboards, and library digital terminals.',
            bulletPoints: [
              'Robotics kit procurement: In progress',
              'High-speed fiber installation: Approved',
              'Unused contingency: \$18,500 held',
            ],
            badge: 'Grant Reserve',
            badgeColor: const Color(0xFF8B5CF6),
            icon: Icons.savings_rounded,
            footerNote: 'Quarterly grant utilization report ready.',
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

  double get totalIncome {
    return _expenses
        .where((e) => e.isIncome)
        .fold(0.0, (sum, item) => sum + item.amount);
  }

  double get totalExpenses {
    return _expenses
        .where((e) => e.isExpense)
        .fold(0.0, (sum, item) => sum + item.amount);
  }

  double get walletBalance {
    return totalIncome - totalExpenses;
  }

  double get thisMonthIncome {
    final now = DateTime.now();
    return _expenses
        .where((e) =>
            e.isIncome &&
            e.date.year == now.year &&
            e.date.month == now.month)
        .fold(0.0, (sum, item) => sum + item.amount);
  }

  double get thisMonthExpenses {
    final now = DateTime.now();
    return _expenses
        .where((e) =>
            e.isExpense &&
            e.date.year == now.year &&
            e.date.month == now.month)
        .fold(0.0, (sum, item) => sum + item.amount);
  }

  double get thisMonthNet => thisMonthIncome - thisMonthExpenses;

  double get todayIncome {
    final now = DateTime.now();
    return _expenses
        .where((e) =>
            e.isIncome &&
            e.date.year == now.year &&
            e.date.month == now.month &&
            e.date.day == now.day)
        .fold(0.0, (sum, item) => sum + item.amount);
  }

  double get todayExpenses {
    final now = DateTime.now();
    return _expenses
        .where((e) =>
            e.isExpense &&
            e.date.year == now.year &&
            e.date.month == now.month &&
            e.date.day == now.day)
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

  void addExpense(Expense expense) {
    _expenses.add(expense);
    _checkAndRefreshStoryHighlights();
    notifyListeners();
  }

  void addAmount(Expense income) {
    _expenses.add(income);
    _checkAndRefreshStoryHighlights();
    notifyListeners();
  }

  void updateExpense(Expense expense) {
    final index = _expenses.indexWhere((e) => e.id == expense.id);
    if (index >= 0) {
      _expenses[index] = expense;
      _checkAndRefreshStoryHighlights();
      notifyListeners();
    }
  }

  void deleteExpense(String id) {
    _expenses.removeWhere((e) => e.id == id);
    _checkAndRefreshStoryHighlights();
    notifyListeners();
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

  void _checkAndRefreshStoryHighlights() {
    // Dynamic recalculation for the main stories if needed
  }
}
