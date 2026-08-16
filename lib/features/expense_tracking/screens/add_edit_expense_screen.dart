import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/expense_model.dart';
import '../providers/expense_provider.dart';
import '../../../core/theme/app_colors.dart';

class AddEditExpenseScreen extends StatefulWidget {
  final Expense? expense;
  final TransactionType initialType;

  const AddEditExpenseScreen({
    super.key,
    this.expense,
    this.initialType = TransactionType.expense,
  });

  @override
  State<AddEditExpenseScreen> createState() => _AddEditExpenseScreenState();
}

class _AddEditExpenseScreenState extends State<AddEditExpenseScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleController;
  late TextEditingController _amountController;
  late TextEditingController _descriptionController;
  late TextEditingController _refNumberController;

  late TransactionType _transactionType;
  DateTime _selectedDate = DateTime.now();
  late String _selectedCategory;
  String _selectedPaymentMethod = 'Cash';

  final List<String> _incomeCategories = [
    'Tuition Fee',
    'Admission Fee',
    'Exam Fee',
    'Grant',
    'Donation',
    'Event Fee',
    'Cafeteria',
    'Library Fine',
    'Others',
  ];

  final List<String> _expenseCategories = [
    'Salary',
    'Maintenance',
    'Supplies',
    'Events',
    'Utilities',
    'Electricity',
    'Lab Equipment',
    'Transport',
    'Others',
  ];

  final List<String> _paymentMethods = [
    'Cash',
    'Bank Transfer',
    'bKash / Mobile',
    'Card',
    'Cheque',
  ];

  @override
  void initState() {
    super.initState();
    final item = widget.expense;
    _transactionType = item?.type ?? widget.initialType;

    _titleController = TextEditingController(text: item?.title ?? '');
    _amountController =
        TextEditingController(text: item != null ? item.amount.toString() : '');
    _descriptionController = TextEditingController(text: item?.description ?? '');
    _refNumberController =
        TextEditingController(text: item?.referenceNumber ?? '');

    if (item != null) {
      _selectedDate = item.date;
      _selectedCategory = item.category;
      _selectedPaymentMethod = item.paymentMethod;

      final catList = _transactionType == TransactionType.income
          ? _incomeCategories
          : _expenseCategories;
      if (!catList.contains(_selectedCategory)) {
        catList.add(_selectedCategory);
      }
    } else {
      _selectedCategory = _transactionType == TransactionType.income
          ? _incomeCategories.first
          : _expenseCategories.first;
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _amountController.dispose();
    _descriptionController.dispose();
    _refNumberController.dispose();
    super.dispose();
  }

  void _onTypeChanged(TransactionType newType) {
    if (_transactionType == newType) return;
    setState(() {
      _transactionType = newType;
      _selectedCategory = newType == TransactionType.income
          ? _incomeCategories.first
          : _expenseCategories.first;
    });
  }

  void _saveTransaction() {
    if (_formKey.currentState!.validate()) {
      final newExpense = Expense(
        id: widget.expense?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
        title: _titleController.text.trim(),
        amount: double.parse(_amountController.text.trim()),
        date: _selectedDate,
        category: _selectedCategory,
        description: _descriptionController.text.trim(),
        type: _transactionType,
        paymentMethod: _selectedPaymentMethod,
        referenceNumber: _refNumberController.text.trim().isNotEmpty
            ? _refNumberController.text.trim()
            : null,
      );

      final provider = context.read<ExpenseProvider>();
      if (widget.expense == null) {
        if (_transactionType == TransactionType.income) {
          provider.addAmount(newExpense);
        } else {
          provider.addExpense(newExpense);
        }
      } else {
        provider.updateExpense(newExpense);
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _transactionType == TransactionType.income
                ? 'Amount added to school wallet successfully!'
                : 'Expense recorded successfully!',
          ),
          backgroundColor: _transactionType == TransactionType.income
              ? const Color(0xFF10B981)
              : AppColors.primaryAdmin,
          behavior: SnackBarBehavior.floating,
        ),
      );

      Navigator.pop(context);
    }
  }

  Future<void> _pickDate() async {
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );

    if (pickedDate != null && pickedDate != _selectedDate) {
      setState(() {
        _selectedDate = pickedDate;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.expense != null;
    final isIncome = _transactionType == TransactionType.income;
    final themeColor = isIncome ? const Color(0xFF10B981) : AppColors.primaryAdmin;

    final categories = isIncome ? _incomeCategories : _expenseCategories;
    if (!categories.contains(_selectedCategory)) {
      _selectedCategory = categories.first;
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(
          isEditing
              ? (isIncome ? 'Edit Income / Fee' : 'Edit Expense')
              : (isIncome ? 'Add Money / Fee Collection' : 'Add School Expense'),
        ),
        backgroundColor: themeColor,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Segmented Type Selector (if not locked in editing)
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.grey.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: InkWell(
                        borderRadius: BorderRadius.circular(12),
                        onTap: () => _onTypeChanged(TransactionType.income),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            color: isIncome ? const Color(0xFF10B981) : Colors.transparent,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: isIncome
                                ? [
                                    BoxShadow(
                                      color: const Color(0xFF10B981).withOpacity(0.3),
                                      blurRadius: 6,
                                      offset: const Offset(0, 2),
                                    )
                                  ]
                                : [],
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.add_circle_rounded,
                                size: 18,
                                color: isIncome ? Colors.white : Colors.grey[700],
                              ),
                              const SizedBox(width: 8),
                              Text(
                                '+ Add Fee / Income',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: isIncome ? Colors.white : Colors.grey[700],
                                  fontSize: 13.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: InkWell(
                        borderRadius: BorderRadius.circular(12),
                        onTap: () => _onTypeChanged(TransactionType.expense),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            color: !isIncome ? AppColors.primaryAdmin : Colors.transparent,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: !isIncome
                                ? [
                                    BoxShadow(
                                      color: AppColors.primaryAdmin.withOpacity(0.3),
                                      blurRadius: 6,
                                      offset: const Offset(0, 2),
                                    )
                                  ]
                                : [],
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.remove_circle_rounded,
                                size: 18,
                                color: !isIncome ? Colors.white : Colors.grey[700],
                              ),
                              const SizedBox(width: 8),
                              Text(
                                '- Add Expense',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: !isIncome ? Colors.white : Colors.grey[700],
                                  fontSize: 13.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Title Field
              TextFormField(
                controller: _titleController,
                decoration: InputDecoration(
                  labelText: isIncome ? 'Fee / Revenue Title' : 'Expense Title',
                  hintText: isIncome
                      ? 'e.g. Class 10 Tuition Fees or Grant'
                      : 'e.g. Teacher Salaries or Electric Bill',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                  prefixIcon: Icon(
                    isIncome ? Icons.account_balance_wallet_outlined : Icons.receipt_long_outlined,
                  ),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter a title';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 16),

              // Amount Field
              TextFormField(
                controller: _amountController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: themeColor,
                ),
                decoration: InputDecoration(
                  labelText: 'Amount (\$)',
                  hintText: '0.00',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                  prefixIcon: const Icon(Icons.attach_money_rounded),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter an amount';
                  }
                  if (double.tryParse(value) == null) {
                    return 'Please enter a valid number';
                  }
                  if (double.parse(value) <= 0) {
                    return 'Amount must be greater than zero';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 16),

              // Category Dropdown
              DropdownButtonFormField<String>(
                value: _selectedCategory,
                decoration: InputDecoration(
                  labelText: 'Category',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                  prefixIcon: const Icon(Icons.category_outlined),
                ),
                items: categories.map((String category) {
                  return DropdownMenuItem<String>(
                    value: category,
                    child: Text(category),
                  );
                }).toList(),
                onChanged: (String? newValue) {
                  if (newValue != null) {
                    setState(() {
                      _selectedCategory = newValue;
                    });
                  }
                },
              ),

              const SizedBox(height: 16),

              // Payment Method & Reference in Row
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: _selectedPaymentMethod,
                      decoration: InputDecoration(
                        labelText: 'Channel',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                        prefixIcon: const Icon(Icons.payment_rounded),
                      ),
                      items: _paymentMethods.map((String method) {
                        return DropdownMenuItem<String>(
                          value: method,
                          child: Text(
                            method,
                            style: const TextStyle(fontSize: 13),
                          ),
                        );
                      }).toList(),
                      onChanged: (String? newValue) {
                        if (newValue != null) {
                          setState(() {
                            _selectedPaymentMethod = newValue;
                          });
                        }
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _refNumberController,
                      decoration: InputDecoration(
                        labelText: 'Receipt / Ref #',
                        hintText: 'e.g. REC-8891',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                        prefixIcon: const Icon(Icons.tag_rounded),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // Date Picker
              InkWell(
                onTap: _pickDate,
                borderRadius: BorderRadius.circular(14),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 14),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.withOpacity(0.5)),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.calendar_month_rounded, color: themeColor),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Transaction Date',
                            style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                          ),
                          Text(
                            DateFormat('EEEE, MMM dd, yyyy').format(_selectedDate),
                            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Description / Remarks
              TextFormField(
                controller: _descriptionController,
                maxLines: 3,
                decoration: InputDecoration(
                  labelText: 'Remarks / Details (Optional)',
                  hintText: isIncome
                      ? 'e.g. Received from Class 10 students with bank voucher...'
                      : 'e.g. Monthly utility bill payment voucher...',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                  prefixIcon: const Icon(Icons.notes_rounded),
                ),
              ),

              const SizedBox(height: 28),

              // Submit Button
              ElevatedButton(
                onPressed: _saveTransaction,
                style: ElevatedButton.styleFrom(
                  backgroundColor: themeColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 2,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      isIncome ? Icons.account_balance_wallet : Icons.check_circle_outline,
                      color: Colors.white,
                    ),
                    const SizedBox(width: 10),
                    Text(
                      isEditing
                          ? 'Save Changes'
                          : (isIncome ? 'Add to School Wallet' : 'Record School Expense'),
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
