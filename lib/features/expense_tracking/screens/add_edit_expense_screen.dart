import 'dart:developer';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../configs/network/data_provider.dart';
import '../../../core/constants/api_path.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/storage_service.dart';
import '../../auth/providers/auth_provider.dart';
import '../models/expense_model.dart';
import '../providers/expense_provider.dart';

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
  late TextEditingController _attachmentUrlController;

  late TransactionType _transactionType;
  DateTime _selectedDate = DateTime.now();
  late String _selectedCategory;
  String _selectedPaymentMethod = 'Cash';

  File? _selectedFile;
  String? _selectedFileName;
  bool _isUploadingFile = false;
  bool _isSubmitting = false;

  final List<String> _incomeCategories = [
    'Tuition Fee Collection',
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
    'Office Supplies',
    'Events',
    'Utilities',
    'Electricity',
    'Electricity Bill',
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

  String _normalizePaymentMethod(String method) {
    final clean = method.trim();
    final lower = clean.toLowerCase().replaceAll('_', ' ');
    if (lower == 'cash') return 'Cash';
    if (lower.contains('bank')) return 'Bank Transfer';
    if (lower.contains('bkash') ||
        lower.contains('mobile') ||
        lower.contains('nagad') ||
        lower.contains('rocket')) {
      return 'bKash / Mobile';
    }
    if (lower.contains('card') || lower.contains('pos')) return 'Card';
    if (lower.contains('cheque') || lower.contains('check')) return 'Cheque';

    for (final pm in _paymentMethods) {
      if (pm.toLowerCase() == lower || pm.toLowerCase() == clean.toLowerCase()) {
        return pm;
      }
    }

    if (!_paymentMethods.contains(clean)) {
      _paymentMethods.add(clean);
    }
    return clean;
  }

  String _normalizeCategory(String category, bool isIncome) {
    final list = isIncome ? _incomeCategories : _expenseCategories;
    final clean = category.trim();
    final lower = clean.toLowerCase();

    for (final cat in list) {
      if (cat.toLowerCase() == lower) {
        return cat;
      }
    }

    if (!list.contains(clean)) {
      list.add(clean);
    }
    return clean;
  }

  @override
  void initState() {
    super.initState();
    final item = widget.expense;
    _transactionType = item?.type ?? widget.initialType;

    _titleController = TextEditingController(text: item?.title ?? '');
    _amountController = TextEditingController(
      text: item != null ? item.amount.toString() : '',
    );
    _descriptionController = TextEditingController(
      text: item?.description ?? '',
    );
    _refNumberController = TextEditingController(
      text: item?.referenceNumber ?? '',
    );
    _attachmentUrlController = TextEditingController(
      text: item?.attachmentUrl ?? '',
    );

    if (item != null) {
      _selectedDate = item.date;
      _selectedCategory = _normalizeCategory(item.category, item.isIncome);
      _selectedPaymentMethod = _normalizePaymentMethod(item.paymentMethod);
    } else {
      _selectedCategory = _transactionType == TransactionType.income
          ? _incomeCategories.first
          : _expenseCategories.first;
      _selectedPaymentMethod = _paymentMethods.first;
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _amountController.dispose();
    _descriptionController.dispose();
    _refNumberController.dispose();
    _attachmentUrlController.dispose();
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

  String _mapPaymentMethodToApi(String method) {
    switch (method.toLowerCase().trim()) {
      case 'cash':
        return 'CASH';
      case 'bank transfer':
      case 'bank_transfer':
        return 'BANK_TRANSFER';
      case 'bkash / mobile':
      case 'bkash':
      case 'mobile':
        return 'BKASH';
      case 'card':
        return 'CARD';
      case 'cheque':
        return 'CHEQUE';
      default:
        return method.toUpperCase().replaceAll(RegExp(r'[^A-Z0-9]'), '_');
    }
  }

  Future<void> _pickAttachment() async {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Select Attachment Source',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              ListTile(
                leading: const Icon(
                  Icons.photo_camera_rounded,
                  color: Color(0xFF10B981),
                ),
                title: const Text('Take Photo / Receipt'),
                onTap: () {
                  Navigator.pop(ctx);
                  _pickImageSource(ImageSource.camera);
                },
              ),
              ListTile(
                leading: const Icon(
                  Icons.photo_library_rounded,
                  color: Color(0xFF6366F1),
                ),
                title: const Text('Choose from Gallery'),
                onTap: () {
                  Navigator.pop(ctx);
                  _pickImageSource(ImageSource.gallery);
                },
              ),
              ListTile(
                leading: const Icon(
                  Icons.picture_as_pdf_rounded,
                  color: Color(0xFFEC4899),
                ),
                title: const Text('Select PDF / Document'),
                onTap: () {
                  Navigator.pop(ctx);
                  _pickDocument();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _pickImageSource(ImageSource source) async {
    try {
      final picker = ImagePicker();
      final picked = await picker.pickImage(source: source, imageQuality: 85);
      if (picked != null) {
        final file = File(picked.path);
        final name = picked.name;
        await _uploadPickedFile(file, name);
      }
    } catch (e) {
      log('Error picking image: $e');
    }
  }

  Future<void> _pickDocument() async {
    try {
      final result = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'png', 'jpg', 'jpeg', 'doc', 'docx'],
      );
      if (result != null && result.files.isNotEmpty && result.files.single.path != null) {
        final file = File(result.files.single.path!);
        final name = result.files.single.name;
        await _uploadPickedFile(file, name);
      }
    } catch (e) {
      log('Error picking document: $e');
    }
  }

  Future<void> _uploadPickedFile(File file, String fileName) async {
    setState(() => _isUploadingFile = true);
    try {
      final token = await StorageService.getToken();
      final formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(
          file.path,
          filename: fileName,
        ),
      });

      final uploadResponse = await DataProvider().performRequest(
        'POST',
        '${APIPath.baseUrl}/general/upload',
        header: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'multipart/form-data',
        },
        data: formData,
      );

      if (uploadResponse != null &&
          (uploadResponse.statusCode == 200 ||
              uploadResponse.statusCode == 201)) {
        final data = uploadResponse.data;
        String? url;
        if (data is Map) {
          url = data['data']?['url'] ?? data['url'];
        }
        if (url != null && url.isNotEmpty) {
          setState(() {
            _attachmentUrlController.text = url!;
            _selectedFile = file;
            _selectedFileName = fileName;
          });
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Attachment uploaded successfully!'),
                backgroundColor: Color(0xFF10B981),
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
        }
      } else {
        throw Exception(
          uploadResponse?.data?['message'] ?? 'Failed to upload attachment',
        );
      }
    } catch (e) {
      log('Upload file error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to upload file: $e'),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isUploadingFile = false);
    }
  }

  Future<void> _saveTransaction() async {
    if (!_formKey.currentState!.validate()) return;

    final isIncome = _transactionType == TransactionType.income;
    final isEditing = widget.expense != null;
    final provider = context.read<ExpenseProvider>();
    final auth = context.read<AuthNotifier>();
    final schoolId = auth.user?.schoolId ?? '';

    setState(() => _isSubmitting = true);

    final amount = double.tryParse(_amountController.text.trim()) ?? 0.0;
    final title = _titleController.text.trim();
    final description = _descriptionController.text.trim();
    final category = _selectedCategory;
    final paymentMethod = _mapPaymentMethodToApi(_selectedPaymentMethod);
    final refNumber = _refNumberController.text.trim().isNotEmpty
        ? _refNumberController.text.trim()
        : null;
    final attachmentUrl = _attachmentUrlController.text.trim().isNotEmpty
        ? _attachmentUrlController.text.trim()
        : null;

    Map<String, dynamic> result;

    if (!isEditing) {
      // Add transaction (Income or Expense) to school wallet using backend API
      result = isIncome
          ? await provider.addMoneyToWalletApi(
              schoolId: schoolId,
              amount: amount,
              category: category,
              title: title,
              description: description,
              paymentMethod: paymentMethod,
              referenceNumber: refNumber,
              transactionDate: _selectedDate,
              attachmentUrl: attachmentUrl,
            )
          : await provider.addExpenseToWalletApi(
              schoolId: schoolId,
              amount: amount,
              category: category,
              title: title,
              description: description,
              paymentMethod: paymentMethod,
              referenceNumber: refNumber,
              transactionDate: _selectedDate,
              attachmentUrl: attachmentUrl,
            );
    } else {
      // Edit / Update transaction (PATCH) via backend API
      result = await provider.updateTransactionApi(
        transactionId: widget.expense!.id,
        schoolId: schoolId,
        amount: amount,
        category: category,
        title: title,
        description: description,
        paymentMethod: paymentMethod,
        referenceNumber: refNumber,
        transactionDate: _selectedDate,
        attachmentUrl: attachmentUrl,
        type: _transactionType,
      );
    }

    if (!mounted) return;
    setState(() => _isSubmitting = false);

    if (result['success'] == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(
                Icons.check_circle_rounded,
                color: Colors.white,
                size: 20,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  isEditing
                      ? 'Transaction updated successfully!'
                      : (isIncome
                          ? 'Amount added to school wallet successfully!'
                          : 'Expense recorded successfully!'),
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
          backgroundColor: isIncome
              ? const Color(0xFF10B981)
              : AppColors.primaryAdmin,
          behavior: SnackBarBehavior.floating,
        ),
      );
      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(
                Icons.error_outline_rounded,
                color: Colors.white,
                size: 20,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  result['message'] ??
                      (isEditing
                          ? 'Failed to update transaction'
                          : (isIncome
                              ? 'Failed to add money to wallet'
                              : 'Failed to record expense')),
                ),
              ),
            ],
          ),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
        ),
      );
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
    final themeColor = isIncome
        ? const Color(0xFF10B981)
        : AppColors.primaryAdmin;

    final categories = isIncome ? _incomeCategories : _expenseCategories;
    _selectedCategory = _normalizeCategory(_selectedCategory, isIncome);
    _selectedPaymentMethod = _normalizePaymentMethod(_selectedPaymentMethod);
    final uniqueCategories = categories.toSet().toList();
    final uniquePaymentMethods = _paymentMethods.toSet().toList();

    return Scaffold(
      appBar: AppBar(
        title: Text(
          isEditing
              ? (isIncome ? 'Edit Income / Fee' : 'Edit Expense')
              : (isIncome
                    ? 'Add Money / Fee Collection'
                    : 'Add School Expense'),
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
                        onTap: isEditing
                            ? null
                            : () => _onTypeChanged(TransactionType.income),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            color: isIncome
                                ? const Color(0xFF10B981)
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: isIncome
                                ? [
                                    BoxShadow(
                                      color: const Color(
                                        0xFF10B981,
                                      ).withOpacity(0.3),
                                      blurRadius: 6,
                                      offset: const Offset(0, 2),
                                    ),
                                  ]
                                : [],
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.add_circle_rounded,
                                size: 18,
                                color: isIncome
                                    ? Colors.white
                                    : Colors.grey[700],
                              ),
                              const SizedBox(width: 8),
                              Text(
                                '+ Add Fee / Income',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: isIncome
                                      ? Colors.white
                                      : Colors.grey[700],
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
                        onTap: isEditing
                            ? null
                            : () => _onTypeChanged(TransactionType.expense),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            color: !isIncome
                                ? AppColors.primaryAdmin
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: !isIncome
                                ? [
                                    BoxShadow(
                                      color: AppColors.primaryAdmin.withOpacity(
                                        0.3,
                                      ),
                                      blurRadius: 6,
                                      offset: const Offset(0, 2),
                                    ),
                                  ]
                                : [],
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.remove_circle_rounded,
                                size: 18,
                                color: !isIncome
                                    ? Colors.white
                                    : Colors.grey[700],
                              ),
                              const SizedBox(width: 8),
                              Text(
                                '- Add Expense',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: !isIncome
                                      ? Colors.white
                                      : Colors.grey[700],
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
                      ? 'e.g. Monthly student tuition fees batch August 2026'
                      : 'e.g. Teacher Salaries or Electric Bill',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  prefixIcon: Icon(
                    isIncome
                        ? Icons.account_balance_wallet_outlined
                        : Icons.receipt_long_outlined,
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
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: themeColor,
                ),
                decoration: InputDecoration(
                  labelText: 'Amount (\$)',
                  hintText: '0.00',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
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
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  prefixIcon: const Icon(Icons.category_outlined),
                ),
                items: uniqueCategories.map((String category) {
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
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        prefixIcon: const Icon(Icons.payment_rounded),
                      ),
                      items: uniquePaymentMethods.map((String method) {
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
                        hintText: 'e.g. DEP-2026-08-001',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
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
                  padding: const EdgeInsets.symmetric(
                    vertical: 16,
                    horizontal: 14,
                  ),
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
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey[600],
                            ),
                          ),
                          Text(
                            DateFormat(
                              'EEEE, MMM dd, yyyy',
                            ).format(_selectedDate),
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                            ),
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
                      ? 'e.g. Collected via offline counter and bank deposits'
                      : 'e.g. Monthly utility bill payment voucher...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  prefixIcon: const Icon(Icons.notes_rounded),
                ),
              ),

              const SizedBox(height: 16),

              // Attachment / Receipt Upload Card
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.grey.withOpacity(0.06),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.grey.withOpacity(0.3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.attach_file_rounded,
                              size: 18,
                              color: themeColor,
                            ),
                            const SizedBox(width: 6),
                            const Text(
                              'Receipt / Document Attachment (Optional)',
                              style: TextStyle(
                                fontSize: 12.5,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                        if (_isUploadingFile)
                          const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    if (_attachmentUrlController.text.isNotEmpty) ...[
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFF10B981).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: const Color(0xFF10B981).withOpacity(0.3),
                          ),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.check_circle_rounded,
                              color: Color(0xFF10B981),
                              size: 18,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                _selectedFileName ??
                                    _attachmentUrlController.text
                                        .split('/')
                                        .last,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF065F46),
                                ),
                              ),
                            ),
                            IconButton(
                              icon: const Icon(
                                Icons.close_rounded,
                                size: 16,
                                color: Colors.red,
                              ),
                              visualDensity: VisualDensity.compact,
                              padding: EdgeInsets.zero,
                              onPressed: () {
                                setState(() {
                                  _selectedFile = null;
                                  _selectedFileName = null;
                                  _attachmentUrlController.clear();
                                });
                              },
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),
                    ],
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed:
                                _isUploadingFile ? null : _pickAttachment,
                            icon: const Icon(
                              Icons.upload_file_rounded,
                              size: 16,
                            ),
                            label: Text(
                              _attachmentUrlController.text.isEmpty
                                  ? 'Upload Receipt / PDF'
                                  : 'Change File',
                              style: const TextStyle(fontSize: 12),
                            ),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: themeColor,
                              side: BorderSide(
                                color: themeColor.withOpacity(0.5),
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                              padding: const EdgeInsets.symmetric(
                                vertical: 10,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 28),

              // Submit Button
              ElevatedButton(
                onPressed: _isSubmitting ? null : _saveTransaction,
                style: ElevatedButton.styleFrom(
                  backgroundColor: themeColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 2,
                  disabledBackgroundColor: themeColor.withOpacity(0.6),
                ),
                child: _isSubmitting
                    ? const SizedBox(
                        height: 22,
                        width: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          color: Colors.white,
                        ),
                      )
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            isIncome
                                ? Icons.account_balance_wallet
                                : Icons.check_circle_outline,
                            color: Colors.white,
                          ),
                          const SizedBox(width: 10),
                          Text(
                            isEditing
                                ? 'Save Changes'
                                : (isIncome
                                      ? 'Add to School Wallet'
                                      : 'Record School Expense'),
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
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
