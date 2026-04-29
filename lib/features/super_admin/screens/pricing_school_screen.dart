import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:smart_school/core/theme/app_colors.dart';

import '../models/pricing_plan_model.dart';
import '../providers/pricing_notifier.dart';

class PricingSchoolScreen extends StatefulWidget {
  const PricingSchoolScreen({super.key});

  @override
  State<PricingSchoolScreen> createState() => _PricingSchoolScreenState();
}

class _PricingSchoolScreenState extends State<PricingSchoolScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<PricingNotifier>().fetchPricingPlans();
    });
  }

  void _showAddPricingPlanSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const AddPricingPlanBottomSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          _buildSliverAppBar(),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Available Plans',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  Consumer<PricingNotifier>(
                    builder: (context, notifier, _) {
                      return Text(
                        '${notifier.plans.length} Plans',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
          _buildPricingList(),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddPricingPlanSheet,
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.add_card_rounded, color: Colors.white),
        label: const Text(
          'Create Plan',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.5,
          ),
        ),
        elevation: 4,
      ),
    );
  }

  Widget _buildSliverAppBar() {
    return SliverAppBar(
      expandedHeight: 180,
      pinned: true,
      elevation: 0,
      backgroundColor: AppColors.primaryDark,
      flexibleSpace: FlexibleSpaceBar(
        centerTitle: true,
        title: const Text(
          'Pricing Management',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
            fontSize: 16,
          ),
        ),
        background: Stack(
          fit: StackFit.expand,
          children: [
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppColors.primaryDark, Color(0xFF673AB7)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
            ),
            Positioned(
              right: -20,
              top: -20,
              child: Icon(
                Icons.payments_rounded,
                size: 150,
                color: Colors.white.withOpacity(0.1),
              ),
            ),
          ],
        ),
      ),
      iconTheme: const IconThemeData(color: Colors.white),
    );
  }

  Widget _buildPricingList() {
    return Consumer<PricingNotifier>(
      builder: (context, notifier, child) {
        if (notifier.isLoading && notifier.plans.isEmpty) {
          return const SliverFillRemaining(
            child: Center(child: CircularProgressIndicator()),
          );
        }

        if (notifier.error != null && notifier.plans.isEmpty) {
          return SliverFillRemaining(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 48, color: Colors.red),
                  const SizedBox(height: 16),
                  Text(notifier.error!),
                  ElevatedButton(
                    onPressed: () => notifier.fetchPricingPlans(),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            ),
          );
        }

        if (notifier.plans.isEmpty) {
          return SliverFillRemaining(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.inventory_2_outlined,
                    size: 80,
                    color: Colors.grey.withOpacity(0.3),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No pricing plans found',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey.shade600,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        return SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate((context, index) {
              final plan = notifier.plans[index];
              return PricingPlanCard(plan: plan);
            }, childCount: notifier.plans.length),
          ),
        );
      },
    );
  }
}

class PricingPlanCard extends StatelessWidget {
  final PricingPlan plan;

  const PricingPlanCard({super.key, required this.plan});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            plan.name,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            plan.description,
                            style: TextStyle(fontSize: 13),
                          ),
                        ],
                      ),
                    ),
                    if (plan.isCustom)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text(
                          'CUSTOM',
                          style: TextStyle(
                            color: Colors.orange,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    PopupMenuButton<String>(
                      icon: const Icon(Icons.more_horiz_rounded),
                      onSelected: (value) {
                        if (value == 'edit') {
                          showModalBottomSheet(
                            context: context,
                            isScrollControlled: true,
                            backgroundColor: Colors.transparent,
                            builder: (context) =>
                                AddPricingPlanBottomSheet(plan: plan),
                          );
                        } else if (value == 'delete') {
                          _showDeleteConfirmation(context);
                        }
                      },
                      itemBuilder: (context) => [
                        const PopupMenuItem(
                          value: 'edit',
                          child: Row(
                            children: [
                              Icon(Icons.edit_outlined, size: 20),
                              SizedBox(width: 8),
                              Text('Edit Plan'),
                            ],
                          ),
                        ),
                        const PopupMenuItem(
                          value: 'delete',
                          child: Row(
                            children: [
                              Icon(
                                Icons.delete_outline_rounded,
                                size: 20,
                                color: Colors.red,
                              ),
                              SizedBox(width: 8),
                              Text(
                                'Delete Plan',
                                style: TextStyle(color: Colors.red),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    _buildPricingDetail(
                      context,
                      Icons.people_alt_rounded,
                      'Students',
                      '${plan.minStudents} - ${plan.maxStudents}',
                    ),
                    const SizedBox(width: 16),
                    _buildPricingDetail(
                      context,
                      Icons.calendar_month_rounded,
                      'Monthly',
                      '\$${plan.pricePerMonth}',
                    ),
                    const SizedBox(width: 16),
                    _buildPricingDetail(
                      context,
                      Icons.person_outline_rounded,
                      'Per Student',
                      '\$${plan.pricePerStudent}',
                    ),
                  ],
                ),
              ],
            ),
          ),
          Divider(),
          Row(
            children: [
              const Icon(Icons.info_outline_rounded, size: 16),
              const SizedBox(width: 8),
              Text(
                'Created: ${plan.createdAt?.split('T')[0] ?? 'N/A'}',
                style: const TextStyle(),
              ),
              const Spacer(),
              TextButton(onPressed: () {}, child: const Text('View Details')),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPricingDetail(
    BuildContext context,
    IconData icon,
    String label,
    String value,
  ) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 14),
              const SizedBox(width: 4),
              Text(label, style: const TextStyle(fontSize: 11)),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Pricing Plan?'),
        content: Text(
          'Are you sure you want to delete "${plan.name}"? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('CANCEL'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              final success = await context
                  .read<PricingNotifier>()
                  .deletePricingPlan(plan.id!);
              if (success && context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('"${plan.name}" deleted')),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('DELETE'),
          ),
        ],
      ),
    );
  }
}

class AddPricingPlanBottomSheet extends StatefulWidget {
  final PricingPlan? plan;
  const AddPricingPlanBottomSheet({super.key, this.plan});

  @override
  State<AddPricingPlanBottomSheet> createState() =>
      _AddPricingPlanBottomSheetState();
}

class _AddPricingPlanBottomSheetState extends State<AddPricingPlanBottomSheet> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _descController;
  late TextEditingController _minStudentsController;
  late TextEditingController _maxStudentsController;
  late TextEditingController _priceMonthController;
  late TextEditingController _priceStudentController;
  bool _isCustom = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.plan?.name);
    _descController = TextEditingController(text: widget.plan?.description);
    _minStudentsController = TextEditingController(
      text: widget.plan?.minStudents.toString() ?? '0',
    );
    _maxStudentsController = TextEditingController(
      text: widget.plan?.maxStudents.toString() ?? '',
    );
    _priceMonthController = TextEditingController(
      text: widget.plan?.pricePerMonth ?? '',
    );
    _priceStudentController = TextEditingController(
      text: widget.plan?.pricePerStudent ?? '',
    );
    _isCustom = widget.plan?.isCustom ?? false;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descController.dispose();
    _minStudentsController.dispose();
    _maxStudentsController.dispose();
    _priceMonthController.dispose();
    _priceStudentController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_formKey.currentState!.validate()) {
      final notifier = context.read<PricingNotifier>();
      final isEditing = widget.plan != null;

      final planData = PricingPlan(
        id: widget.plan?.id,
        name: _nameController.text,
        description: _descController.text,
        minStudents: int.parse(_minStudentsController.text),
        maxStudents: int.parse(_maxStudentsController.text),
        pricePerMonth: _priceMonthController.text,
        pricePerStudent: _priceStudentController.text,
        isCustom: _isCustom,
      );

      bool success;
      if (isEditing) {
        success = await notifier.updatePricingPlan(widget.plan!.id!, planData);
      } else {
        success = await notifier.createPricingPlan(planData);
      }

      if (success && mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              isEditing
                  ? 'Pricing plan updated successfully!'
                  : 'Pricing plan created successfully!',
            ),
            backgroundColor: Colors.green,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final padding = MediaQuery.of(context).viewInsets.bottom;
    final isEditing = widget.plan != null;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Form(
          key: _formKey,
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
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  isEditing ? 'Update Pricing Plan' : 'Create New Plan',
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  isEditing
                      ? 'Modify the pricing structure below'
                      : 'Define a new pricing structure for institutions',
                  style: TextStyle(fontSize: 14),
                ),
                const SizedBox(height: 24),
                _buildTextField(
                  'Plan Name',
                  _nameController,
                  Icons.badge_outlined,
                ),
                const SizedBox(height: 16),
                _buildTextField(
                  'Description',
                  _descController,
                  Icons.description_outlined,
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _buildTextField(
                        'Min Students',
                        _minStudentsController,
                        Icons.group_remove_outlined,
                        keyboardType: TextInputType.number,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildTextField(
                        'Max Students',
                        _maxStudentsController,
                        Icons.group_add_outlined,
                        keyboardType: TextInputType.number,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _buildTextField(
                        'Price/Month',
                        _priceMonthController,
                        Icons.money_outlined,
                        keyboardType: TextInputType.number,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildTextField(
                        'Price/Student',
                        _priceStudentController,
                        Icons.person_pin_circle_outlined,
                        keyboardType: TextInputType.number,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.backgroundLight,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Custom Plan',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      Switch.adaptive(
                        value: _isCustom,
                        activeColor: AppColors.primary,
                        onChanged: (val) => setState(() => _isCustom = val),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),
                Consumer<PricingNotifier>(
                  builder: (context, notifier, child) {
                    return ElevatedButton(
                      onPressed: notifier.isLoading ? null : _submit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        minimumSize: const Size(double.infinity, 56),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 0,
                      ),
                      child: notifier.isLoading
                          ? const CircularProgressIndicator(color: Colors.white)
                          : Text(
                              isEditing
                                  ? 'UPDATE PRICING PLAN'
                                  : 'CREATE PRICING PLAN',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1,
                              ),
                            ),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(
    String label,
    TextEditingController controller,
    IconData icon, {
    TextInputType? keyboardType,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.primary, width: 2),
        ),
        filled: true,
      ),
      validator: (value) => value == null || value.isEmpty ? 'Required' : null,
    );
  }
}
