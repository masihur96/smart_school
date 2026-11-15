import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:smart_school/core/theme/app_colors.dart';
import 'package:smart_school/features/admin/providers/sms_provider.dart';
import 'package:smart_school/models/sms_models.dart';

class SmsBuySheet extends StatefulWidget {
  final SmsPackage? initialPackage;

  const SmsBuySheet({super.key, this.initialPackage});

  static Future<bool?> show(BuildContext context, {SmsPackage? package}) {
    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => SmsBuySheet(initialPackage: package),
    );
  }

  @override
  State<SmsBuySheet> createState() => _SmsBuySheetState();
}

class _SmsBuySheetState extends State<SmsBuySheet> {
  SmsPackage? _selectedPackage;
  String _selectedPaymentMethod = 'WALLET';
  final TextEditingController _txnController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();
  bool _isProcessing = false;

  final List<Map<String, dynamic>> _paymentMethods = [
    {
      'value': 'WALLET',
      'label': 'School Wallet',
      'icon': Icons.account_balance_wallet_rounded,
      'color': Colors.teal,
      'subtitle': 'Instant debit from your school balance',
    },
    {
      'value': 'MOBILE_BANKING',
      'label': 'bKash / Nagad',
      'icon': Icons.phone_android_rounded,
      'color': Colors.pink,
      'subtitle': 'Mobile wallet merchant transfer',
    },
    {
      'value': 'BANK_TRANSFER',
      'label': 'Bank Transfer',
      'icon': Icons.account_balance_rounded,
      'color': Colors.blue,
      'subtitle': 'Direct deposit / EFTN',
    },
    {
      'value': 'CASH',
      'label': 'Cash / Manual',
      'icon': Icons.payments_rounded,
      'color': Colors.green,
      'subtitle': 'Direct office counter payment',
    },
  ];

  @override
  void initState() {
    super.initState();
    _selectedPackage = widget.initialPackage;
  }

  @override
  void dispose() {
    _txnController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _handleBuy() async {
    final smsProvider = context.read<SmsProvider>();
    final package = _selectedPackage ??
        (smsProvider.packages.isNotEmpty ? smsProvider.packages.first : null);

    if (package == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select an SMS package to purchase'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    if (_selectedPaymentMethod == 'MOBILE_BANKING' &&
        _txnController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter the Transaction ID for mobile payment'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() => _isProcessing = true);

    final result = await smsProvider.buyPackage(
      packageId: package.id,
      paymentMethod: _selectedPaymentMethod,
      transactionId: _txnController.text.trim().isEmpty
          ? null
          : _txnController.text.trim(),
      notes: _notesController.text.trim().isEmpty
          ? 'Purchased ${package.name}'
          : _notesController.text.trim(),
    );

    setState(() => _isProcessing = false);

    if (!mounted) return;

    if (result['success'] == true) {
      Navigator.pop(context, true);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
          content: Row(
            children: [
              const Icon(Icons.check_circle_rounded, color: Colors.white),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  result['message'] ?? 'SMS package purchased successfully!',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          content: Row(
            children: [
              const Icon(Icons.error_outline_rounded, color: Colors.white),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  result['message'] ?? 'Failed to complete package purchase',
                ),
              ),
            ],
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final smsProvider = context.watch<SmsProvider>();
    final packages = smsProvider.packages;

    if (_selectedPackage == null && packages.isNotEmpty) {
      _selectedPackage = packages.firstWhere(
        (p) => p.isPopular,
        orElse: () => packages.first,
      );
    }

    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      padding: EdgeInsets.fromLTRB(20, 16, 20, 20 + bottomInset),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: isDark ? Colors.grey.shade700 : Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 14),

            // Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.primaryAdmin.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.shopping_bag_rounded,
                    color: AppColors.primaryAdmin,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Buy SMS Credits',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Select a bundle and payment method to recharge',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close_rounded, size: 20),
                ),
              ],
            ),
            const SizedBox(height: 18),

            // Package Selector
            const Text(
              'Select SMS Package',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),

            if (packages.isEmpty)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isDark ? Colors.grey.shade900 : Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Center(
                  child: Text('Loading packages...'),
                ),
              )
            else
              SizedBox(
                height: 94,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: packages.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 10),
                  itemBuilder: (context, idx) {
                    final pkg = packages[idx];
                    final isSelected = _selectedPackage?.id == pkg.id;

                    return InkWell(
                      onTap: () => setState(() => _selectedPackage = pkg),
                      borderRadius: BorderRadius.circular(14),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        width: 140,
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? AppColors.primaryAdmin.withValues(alpha: 0.08)
                              : (isDark
                                  ? Colors.grey.shade900
                                  : Colors.grey.shade50),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: isSelected
                                ? AppColors.primaryAdmin
                                : (isDark
                                    ? Colors.grey.shade800
                                    : Colors.grey.shade200),
                            width: isSelected ? 2 : 1,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    pkg.name,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12.5,
                                      color: isSelected
                                          ? AppColors.primaryAdmin
                                          : null,
                                    ),
                                  ),
                                ),
                                if (pkg.isPopular)
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 4,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.amber.shade700,
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: const Text(
                                      'HOT',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 9,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${pkg.smsCount} SMS',
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              '৳${pkg.price.toStringAsFixed(0)} (৳${pkg.perSmsRate}/sms)',
                              style: TextStyle(
                                fontSize: 10.5,
                                color: isDark
                                    ? Colors.grey.shade400
                                    : Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),

            const SizedBox(height: 18),

            // Payment Method Selector
            const Text(
              'Payment Method',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),

            ..._paymentMethods.map((method) {
              final isSelected = _selectedPaymentMethod == method['value'];
              return Padding(
                padding: const EdgeInsets.only(bottom: 8.0),
                child: InkWell(
                  onTap: () => setState(
                    () => _selectedPaymentMethod = method['value'],
                  ),
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? (method['color'] as Color).withValues(alpha: 0.08)
                          : (isDark
                              ? Colors.grey.shade900
                              : Colors.grey.shade50),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected
                            ? (method['color'] as Color)
                            : (isDark
                                ? Colors.grey.shade800
                                : Colors.grey.shade200),
                        width: isSelected ? 1.5 : 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          method['icon'] as IconData,
                          color: method['color'] as Color,
                          size: 22,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                method['label'] as String,
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                  color: isSelected
                                      ? (method['color'] as Color)
                                      : null,
                                ),
                              ),
                              Text(
                                method['subtitle'] as String,
                                style: TextStyle(
                                  fontSize: 11,
                                  color: isDark
                                      ? Colors.grey.shade400
                                      : Colors.grey.shade600,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (isSelected)
                          Icon(
                            Icons.check_circle_rounded,
                            color: method['color'] as Color,
                            size: 22,
                          )
                        else
                          Icon(
                            Icons.radio_button_unchecked_rounded,
                            color: isDark
                                ? Colors.grey.shade600
                                : Colors.grey.shade400,
                            size: 22,
                          ),
                      ],
                    ),
                  ),
                ),
              );
            }),

            // Additional fields for Mobile Banking / Bank
            if (_selectedPaymentMethod == 'MOBILE_BANKING' ||
                _selectedPaymentMethod == 'BANK_TRANSFER') ...[
              const SizedBox(height: 6),
              TextField(
                controller: _txnController,
                decoration: InputDecoration(
                  labelText: 'Transaction ID / Reference',
                  hintText: 'e.g. BKASH-TXN-98472910',
                  isDense: true,
                  filled: true,
                  fillColor: isDark
                      ? Colors.grey.shade900
                      : Colors.grey.shade100,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide.none,
                  ),
                  prefixIcon: const Icon(Icons.receipt_rounded, size: 20),
                ),
              ),
            ],

            const SizedBox(height: 10),

            // Notes
            TextField(
              controller: _notesController,
              decoration: InputDecoration(
                labelText: 'Notes (Optional)',
                hintText: 'e.g. Paid via bKash Merchant',
                isDense: true,
                filled: true,
                fillColor:
                    isDark ? Colors.grey.shade900 : Colors.grey.shade100,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide.none,
                ),
                prefixIcon: const Icon(Icons.notes_rounded, size: 20),
              ),
            ),

            const SizedBox(height: 20),

            // Confirm Button
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton.icon(
                onPressed: _isProcessing ? null : _handleBuy,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryAdmin,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
                icon: _isProcessing
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.check_circle_rounded, size: 20),
                label: Text(
                  _isProcessing
                      ? 'Processing Purchase...'
                      : _selectedPackage != null
                          ? 'Pay ৳${_selectedPackage!.price.toStringAsFixed(0)} for ${_selectedPackage!.smsCount} SMS'
                          : 'Confirm & Recharge',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
