import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/expense_model.dart';
import '../screens/add_edit_expense_screen.dart';

class ExpenseListTile extends StatelessWidget {
  final Expense expense;
  final VoidCallback onDelete;

  const ExpenseListTile({
    super.key,
    required this.expense,
    required this.onDelete,
  });

  IconData _getCategoryIcon(String category, bool isIncome) {
    final cat = category.toLowerCase().trim();
    if (isIncome) {
      if (cat.contains('tuition') || cat.contains('student')) {
        return Icons.school_rounded;
      } else if (cat.contains('admission')) {
        return Icons.how_to_reg_rounded;
      } else if (cat.contains('exam')) {
        return Icons.assignment_turned_in_rounded;
      } else if (cat.contains('grant')) {
        return Icons.account_balance_rounded;
      } else if (cat.contains('donation')) {
        return Icons.volunteer_activism_rounded;
      } else if (cat.contains('cafeteria') ||
          cat.contains('canteen') ||
          cat.contains('food')) {
        return Icons.restaurant_rounded;
      } else if (cat.contains('event') || cat.contains('sports')) {
        return Icons.emoji_events_rounded;
      } else if (cat.contains('library')) {
        return Icons.local_library_rounded;
      }
      return Icons.account_balance_wallet_rounded;
    } else {
      if (cat.contains('salary') ||
          cat.contains('payroll') ||
          cat.contains('staff') ||
          cat.contains('teacher')) {
        return Icons.people_rounded;
      } else if (cat.contains('maintenance') || cat.contains('repair')) {
        return Icons.build_circle_rounded;
      } else if (cat.contains('supplies') || cat.contains('stationary')) {
        return Icons.inventory_2_rounded;
      } else if (cat.contains('event') || cat.contains('sports')) {
        return Icons.celebration_rounded;
      } else if (cat.contains('electric') ||
          cat.contains('power') ||
          cat.contains('utilit') ||
          cat.contains('bill') ||
          cat.contains('water') ||
          cat.contains('gas')) {
        return Icons.bolt_rounded;
      } else if (cat.contains('lab') || cat.contains('science')) {
        return Icons.science_rounded;
      } else if (cat.contains('transport') || cat.contains('bus')) {
        return Icons.directions_bus_rounded;
      }
      return Icons.receipt_long_rounded;
    }
  }

  Color _getTransactionColor(BuildContext context, bool isIncome) {
    if (isIncome) {
      return const Color(0xFF10B981); // Emerald Green
    } else {
      return const Color(0xFFEF4444); // Crimson / Red
    }
  }

  void _showTransactionDetails(BuildContext context) {
    final isIncome = expense.isIncome;
    final primaryColor = _getTransactionColor(context, isIncome);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Drag Handle
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[400],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 18),

              // Title & Close
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Transaction Receipt',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).textTheme.titleLarge?.color,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // Amount Card
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: primaryColor.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: primaryColor.withOpacity(0.3)),
                ),
                child: Column(
                  children: [
                    Text(
                      isIncome ? 'Fee / Deposit Added' : 'Expense Outflow',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: primaryColor,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '${isIncome ? '+' : '-'}\$${expense.amount.toStringAsFixed(2)}',
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.w900,
                        color: primaryColor,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      expense.title,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Details List
              _buildReceiptRow(
                'Category',
                expense.category,
                Icons.category_outlined,
              ),
              _buildReceiptRow(
                'Date & Time',
                DateFormat('MMM dd, yyyy • hh:mm a').format(expense.date),
                Icons.calendar_today_outlined,
              ),
              _buildReceiptRow(
                'Payment Channel',
                expense.paymentMethod,
                Icons.payment_outlined,
              ),
              if (expense.referenceNumber != null &&
                  expense.referenceNumber!.isNotEmpty)
                _buildReceiptRow(
                  'Reference No.',
                  expense.referenceNumber!,
                  Icons.tag_rounded,
                ),
              if (expense.description.isNotEmpty)
                _buildReceiptRow(
                  'Note / Remarks',
                  expense.description,
                  Icons.notes_rounded,
                ),
              if (expense.attachmentUrl != null &&
                  expense.attachmentUrl!.isNotEmpty)
                _buildReceiptRow(
                  'Attachment',
                  'View Attachment / Receipt',
                  Icons.attachment_rounded,
                ),

              const SizedBox(height: 24),

              // Action Buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Navigator.pop(ctx);
                        _showDeleteConfirm(context);
                      },
                      icon: const Icon(Icons.delete_outline, color: Colors.red),
                      label: const Text(
                        'Delete',
                        style: TextStyle(color: Colors.red),
                      ),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Colors.red),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.pop(ctx);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                AddEditExpenseScreen(expense: expense),
                          ),
                        );
                      },
                      icon: const Icon(Icons.edit, color: Colors.white),
                      label: const Text(
                        'Edit Entry',
                        style: TextStyle(color: Colors.white),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF6750A4),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildReceiptRow(String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: Colors.grey[600]),
          const SizedBox(width: 10),
          SizedBox(
            width: 110,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: const TextStyle(
                fontSize: 13.5,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirm(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Transaction'),
        content: Text('Are you sure you want to remove "${expense.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              onDelete();
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isIncome = expense.isIncome;
    final color = _getTransactionColor(context, isIncome);
    final iconData = _getCategoryIcon(expense.category, isIncome);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 6.0),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: color.withOpacity(0.18), width: 1),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => _showTransactionDetails(context),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: [
              // Icon Badge
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(iconData, color: color, size: 24),
              ),
              const SizedBox(width: 14),

              // Title and Meta details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      expense.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        // Category Pill
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 7,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.grey.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            expense.category,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey[700],
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        // Payment method
                        Text(
                          '• ${expense.paymentMethod}',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey[500],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      DateFormat('MMM dd, yyyy').format(expense.date),
                      style: TextStyle(fontSize: 11.5, color: Colors.grey[500]),
                    ),
                  ],
                ),
              ),

              // Trailing Amount & Arrow
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        isIncome
                            ? Icons.arrow_downward_rounded
                            : Icons.arrow_upward_rounded,
                        size: 14,
                        color: color,
                      ),
                      const SizedBox(width: 2),
                      Text(
                        '${isIncome ? '+' : '-'}\$${expense.amount.toStringAsFixed(2)}',
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 15.5,
                          color: color,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      isIncome ? 'Fee Inflow' : 'Expense',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: color,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
