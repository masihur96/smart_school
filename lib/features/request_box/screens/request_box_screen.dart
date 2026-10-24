import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:smart_school/core/theme/app_colors.dart';
import 'package:smart_school/features/auth/providers/auth_provider.dart';
import '../models/request_complaint_model.dart';
import '../providers/request_complaint_provider.dart';
import 'create_request_complaint_screen.dart';
import 'request_detail_screen.dart';

class RequestBoxScreen extends StatefulWidget {
  const RequestBoxScreen({super.key});

  @override
  State<RequestBoxScreen> createState() => _RequestBoxScreenState();
}

class _RequestBoxScreenState extends State<RequestBoxScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  final List<String> _categories = [
    'ALL',
    'ACADEMIC',
    'ATTENDANCE',
    'LEAVE',
    'FACILITY',
    'FEE',
    'DISCIPLINE',
    'BEHAVIOR',
    'EXAM',
    'OTHER',
  ];

  final List<String> _statuses = [
    'ALL',
    'PENDING',
    'IN_PROGRESS',
    'RESOLVED',
    'REJECTED',
  ];

  final List<String> _priorities = [
    'ALL',
    'LOW',
    'MEDIUM',
    'HIGH',
    'URGENT',
  ];

  final List<String> _scopes = [
    'ALL',
    'received',
    'sent',
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);

    _tabController.addListener(() {
      if (_tabController.indexIsChanging) return;
      final schoolId = context.read<AuthNotifier>().user?.schoolId ?? '';
      final provider = context.read<RequestComplaintProvider>();
      switch (_tabController.index) {
        case 0:
          provider.setType('ALL', schoolId: schoolId);
          break;
        case 1:
          provider.setType('REQUEST', schoolId: schoolId);
          break;
        case 2:
          provider.setType('COMPLAINT', schoolId: schoolId);
          break;
      }
    });

    _scrollController.addListener(_onScroll);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final schoolId = context.read<AuthNotifier>().user?.schoolId ?? '';
      context
          .read<RequestComplaintProvider>()
          .fetchRequestComplaints(refresh: true, schoolId: schoolId);
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      final schoolId = context.read<AuthNotifier>().user?.schoolId ?? '';
      context
          .read<RequestComplaintProvider>()
          .fetchRequestComplaints(schoolId: schoolId);
    }
  }

  void _openFilterBottomSheet() {
    final schoolId = context.read<AuthNotifier>().user?.schoolId ?? '';
    final provider = context.read<RequestComplaintProvider>();

    String tempStatus = provider.selectedStatus;
    String tempPriority = provider.selectedPriority;
    String tempCategory = provider.selectedCategory;
    String tempScope = provider.selectedScope;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: const EdgeInsets.all(20),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade400,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Filter Requests & Complaints',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        TextButton(
                          onPressed: () {
                            setModalState(() {
                              tempStatus = 'ALL';
                              tempPriority = 'ALL';
                              tempCategory = 'ALL';
                              tempScope = 'ALL';
                            });
                          },
                          child: const Text('Reset'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Scope filter
                    const Text(
                      'Scope',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      children: _scopes.map((s) {
                        final isSel = tempScope == s;
                        return ChoiceChip(
                          label: Text(s.toUpperCase()),
                          selected: isSel,
                          onSelected: (val) {
                            if (val) setModalState(() => tempScope = s);
                          },
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 16),

                    // Status filter
                    const Text(
                      'Status',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _statuses.map((s) {
                        final isSel = tempStatus == s;
                        return ChoiceChip(
                          label: Text(s),
                          selected: isSel,
                          onSelected: (val) {
                            if (val) setModalState(() => tempStatus = s);
                          },
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 16),

                    // Priority filter
                    const Text(
                      'Priority',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      children: _priorities.map((p) {
                        final isSel = tempPriority == p;
                        return ChoiceChip(
                          label: Text(p),
                          selected: isSel,
                          onSelected: (val) {
                            if (val) setModalState(() => tempPriority = p);
                          },
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 16),

                    // Category filter
                    const Text(
                      'Category',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _categories.map((c) {
                        final isSel = tempCategory == c;
                        return ChoiceChip(
                          label: Text(c),
                          selected: isSel,
                          onSelected: (val) {
                            if (val) setModalState(() => tempCategory = c);
                          },
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 24),

                    // Apply Button
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        onPressed: () {
                          provider.setStatus(tempStatus, schoolId: schoolId);
                          provider.setPriority(tempPriority,
                              schoolId: schoolId);
                          provider.setCategory(tempCategory,
                              schoolId: schoolId);
                          provider.setScope(tempScope, schoolId: schoolId);
                          Navigator.pop(ctx);
                        },
                        child: const Text(
                          'Apply Filters',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final provider = context.watch<RequestComplaintProvider>();
    final schoolId = context.read<AuthNotifier>().user?.schoolId ?? '';

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Request Box',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        elevation: 0,
        actions: [
          IconButton(
            icon: Stack(
              children: [
                const Icon(Icons.filter_list),
                if (provider.selectedStatus != 'ALL' ||
                    provider.selectedPriority != 'ALL' ||
                    provider.selectedCategory != 'ALL' ||
                    provider.selectedScope != 'ALL')
                  Positioned(
                    right: 0,
                    top: 0,
                    child: Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: Colors.redAccent,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
              ],
            ),
            tooltip: 'Filter',
            onPressed: _openFilterBottomSheet,
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
            onPressed: () {
              provider.fetchRequestComplaints(
                refresh: true,
                schoolId: schoolId,
              );
            },
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: isDark ? Colors.white : AppColors.primary,
          unselectedLabelColor: Colors.grey,
          indicatorColor: AppColors.primary,
          indicatorWeight: 3,
          tabs: const [
            Tab(text: 'All'),
            Tab(text: 'Requests'),
            Tab(text: 'Complaints'),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text(
          'Create Request / Complaint',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        onPressed: () async {
          final res = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => CreateRequestComplaintScreen(
                initialType: _tabController.index == 2
                    ? 'COMPLAINT'
                    : 'REQUEST',
              ),
            ),
          );
          if (res == true && mounted) {
            provider.fetchRequestComplaints(
              refresh: true,
              schoolId: schoolId,
            );
          }
        },
      ),
      body: Column(
        children: [
          // Search & Active Filter Bar
          _buildSearchBar(theme, isDark, schoolId, provider),

          // Active Filters chips if any
          _buildActiveFiltersChips(provider, schoolId),

          // List Body
          Expanded(
            child: RefreshIndicator(
              onRefresh: () async {
                await provider.fetchRequestComplaints(
                  refresh: true,
                  schoolId: schoolId,
                );
              },
              child: _buildBody(theme, isDark, provider, schoolId),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar(
    ThemeData theme,
    bool isDark,
    String schoolId,
    RequestComplaintProvider provider,
  ) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: 'Search requests and complaints...',
          prefixIcon: const Icon(Icons.search, size: 20),
          suffixIcon: _searchController.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear, size: 18),
                  onPressed: () {
                    _searchController.clear();
                    provider.setSearchQuery('', schoolId: schoolId);
                  },
                )
              : null,
          filled: true,
          fillColor: isDark ? const Color(0xFF1E232E) : Colors.grey.shade100,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
        ),
        onSubmitted: (val) {
          provider.setSearchQuery(val.trim(), schoolId: schoolId);
        },
      ),
    );
  }

  Widget _buildActiveFiltersChips(
    RequestComplaintProvider provider,
    String schoolId,
  ) {
    final hasFilters = provider.selectedStatus != 'ALL' ||
        provider.selectedPriority != 'ALL' ||
        provider.selectedCategory != 'ALL' ||
        provider.selectedScope != 'ALL';

    if (!hasFilters) return const SizedBox.shrink();

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Row(
        children: [
          if (provider.selectedScope != 'ALL')
            _buildFilterChip(
              'Scope: ${provider.selectedScope.toUpperCase()}',
              () => provider.setScope('ALL', schoolId: schoolId),
            ),
          if (provider.selectedStatus != 'ALL')
            _buildFilterChip(
              'Status: ${provider.selectedStatus}',
              () => provider.setStatus('ALL', schoolId: schoolId),
            ),
          if (provider.selectedPriority != 'ALL')
            _buildFilterChip(
              'Priority: ${provider.selectedPriority}',
              () => provider.setPriority('ALL', schoolId: schoolId),
            ),
          if (provider.selectedCategory != 'ALL')
            _buildFilterChip(
              'Category: ${provider.selectedCategory}',
              () => provider.setCategory('ALL', schoolId: schoolId),
            ),
          ActionChip(
            label: const Text('Clear All', style: TextStyle(fontSize: 11)),
            onPressed: () => provider.resetFilters(schoolId: schoolId),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, VoidCallback onDeleted) {
    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: Chip(
        label: Text(label, style: const TextStyle(fontSize: 11)),
        deleteIcon: const Icon(Icons.close, size: 14),
        onDeleted: onDeleted,
        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
        visualDensity: VisualDensity.compact,
      ),
    );
  }

  Widget _buildBody(
    ThemeData theme,
    bool isDark,
    RequestComplaintProvider provider,
    String schoolId,
  ) {
    if (provider.isLoading && provider.items.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (provider.errorMessage != null && provider.items.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, size: 54, color: Colors.red),
              const SizedBox(height: 16),
              Text(
                provider.errorMessage!,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 14),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                icon: const Icon(Icons.refresh),
                label: const Text('Try Again'),
                onPressed: () {
                  provider.fetchRequestComplaints(
                    refresh: true,
                    schoolId: schoolId,
                  );
                },
              ),
            ],
          ),
        ),
      );
    }

    if (provider.items.isEmpty) {
      return Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 90,
                height: 90,
                decoration: BoxDecoration(
                  color: AppColors.primary.withAlpha(20),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.all_inbox_rounded,
                  size: 48,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'No Requests or Complaints Found',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Create a request or complaint to get started.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey.shade600,
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                icon: const Icon(Icons.add),
                label: const Text('Create New'),
                onPressed: () async {
                  final res = await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const CreateRequestComplaintScreen(),
                    ),
                  );
                  if (res == true && mounted) {
                    provider.fetchRequestComplaints(
                      refresh: true,
                      schoolId: schoolId,
                    );
                  }
                },
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 80),
      itemCount: provider.items.length + (provider.isLoadingMore ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == provider.items.length) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        final item = provider.items[index];
        return _buildItemCard(theme, isDark, item);
      },
    );
  }

  Widget _buildItemCard(
    ThemeData theme,
    bool isDark,
    RequestComplaintModel item,
  ) {
    Color typeColor =
        item.isRequest ? Colors.blue.shade700 : Colors.deepOrange.shade700;
    Color typeBg =
        item.isRequest ? Colors.blue.shade50 : Colors.deepOrange.shade50;
    if (isDark) typeBg = typeColor.withAlpha(45);

    Color statusColor;
    Color statusBg;
    switch (item.status) {
      case 'RESOLVED':
        statusColor = Colors.green.shade800;
        statusBg = isDark
            ? Colors.green.shade900.withAlpha(50)
            : Colors.green.shade50;
        break;
      case 'IN_PROGRESS':
        statusColor = Colors.blue.shade800;
        statusBg =
            isDark ? Colors.blue.shade900.withAlpha(50) : Colors.blue.shade50;
        break;
      case 'REJECTED':
        statusColor = Colors.red.shade800;
        statusBg =
            isDark ? Colors.red.shade900.withAlpha(50) : Colors.red.shade50;
        break;
      default:
        statusColor = Colors.orange.shade800;
        statusBg =
            isDark ? Colors.orange.shade900.withAlpha(50) : Colors.orange.shade50;
    }

    Color priorityColor;
    switch (item.priority) {
      case 'URGENT':
        priorityColor = Colors.red.shade700;
        break;
      case 'HIGH':
        priorityColor = Colors.orange.shade800;
        break;
      case 'MEDIUM':
        priorityColor = Colors.amber.shade800;
        break;
      default:
        priorityColor = Colors.teal.shade700;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(
          color: isDark ? Colors.white12 : Colors.grey.shade200,
        ),
      ),
      color: isDark ? const Color(0xFF1E232E) : Colors.white,
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => RequestDetailScreen(item: item),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Chips Row
              Row(
                children: [
                  // Type
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: typeBg,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      item.type,
                      style: TextStyle(
                        color: typeColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 11,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),

                  // Priority
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: priorityColor.withAlpha(25),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.flag, size: 10, color: priorityColor),
                        const SizedBox(width: 3),
                        Text(
                          item.priority,
                          style: TextStyle(
                            color: priorityColor,
                            fontWeight: FontWeight.bold,
                            fontSize: 10,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),

                  // Status
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: statusBg,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      item.status,
                      style: TextStyle(
                        color: statusColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 11,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),

              // Title
              Text(
                item.title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 6),

              // Description preview
              Text(
                item.description,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 13,
                  color: isDark ? Colors.grey.shade300 : Colors.grey.shade700,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 12),

              // Divider
              Divider(
                height: 1,
                color: isDark ? Colors.white12 : Colors.grey.shade200,
              ),
              const SizedBox(height: 10),

              // Sender / Recipient Info & Attachments & Date
              Row(
                children: [
                  // Category badge
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                    decoration: BoxDecoration(
                      color: theme.primaryColor.withAlpha(20),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      item.category,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: theme.primaryColor,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),

                  // Attachments indicator
                  if (item.attachments.isNotEmpty) ...[
                    Icon(
                      Icons.attach_file,
                      size: 14,
                      color: Colors.grey.shade600,
                    ),
                    Text(
                      '${item.attachments.length}',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    const SizedBox(width: 8),
                  ],

                  const Spacer(),

                  // Created Date
                  if (item.createdAt != null)
                    Text(
                      DateFormat('MMM dd, yyyy').format(item.createdAt!),
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey.shade500,
                      ),
                    ),
                ],
              ),

              const SizedBox(height: 6),
              // Sender / Recipient Names
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'From: ${item.sender?.name ?? 'Unknown'}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ),
                  if (item.recipient != null) ...[
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'To: ${item.recipient!.name}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.end,
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
