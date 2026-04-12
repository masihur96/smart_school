import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../providers/trash_restore_provider.dart';

class BackupScreen extends StatefulWidget {
  const BackupScreen({super.key});

  @override
  State<BackupScreen> createState() => _BackupScreenState();
}

class _BackupScreenState extends State<BackupScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  // Entity display meta
  static const List<Map<String, dynamic>> _entities = [
    {
      'key': 'user',
      'label': 'Users',
      'icon': Icons.people_alt_rounded,
      'color': Color(0xFF5C6BC0),
    },
    {
      'key': 'school',
      'label': 'Schools',
      'icon': Icons.account_balance_rounded,
      'color': Color(0xFF26A69A),
    },
    {
      'key': 'class',
      'label': 'Classes',
      'icon': Icons.class_rounded,
      'color': Color(0xFF42A5F5),
    },
    {
      'key': 'section',
      'label': 'Sections',
      'icon': Icons.view_week_rounded,
      'color': Color(0xFFAB47BC),
    },
    {
      'key': 'subject',
      'label': 'Subjects',
      'icon': Icons.book_rounded,
      'color': Color(0xFFEF5350),
    },
    {
      'key': 'pricing',
      'label': 'Pricing',
      'icon': Icons.monetization_on_rounded,
      'color': Color(0xFFFFB300),
    },
    {
      'key': 'subscription',
      'label': 'Subscriptions',
      'icon': Icons.subscriptions_rounded,
      'color': Color(0xFF26C6DA),
    },
    {
      'key': 'homework',
      'label': 'Homework',
      'icon': Icons.assignment_rounded,
      'color': Color(0xFF66BB6A),
    },
    {
      'key': 'attendance',
      'label': 'Attendance',
      'icon': Icons.fact_check_rounded,
      'color': Color(0xFFFF7043),
    },
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _entities.length + 1, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Only fetch if there's nothing yet loaded (avoid re-fetching on tab switch)
      final notifier = context.read<TrashRestoreNotifier>();
      if (notifier.totalDeleted == 0) {
        notifier.fetchAll();
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Color _entityColor(String key) {
    return (_entities.firstWhere(
          (e) => e['key'] == key,
          orElse: () => {'color': AppColors.primary},
        )['color'] as Color);
  }

  IconData _entityIcon(String key) {
    return (_entities.firstWhere(
          (e) => e['key'] == key,
          orElse: () => {'icon': Icons.delete_forever_rounded},
        )['icon'] as IconData);
  }

  @override
  Widget build(BuildContext context) {
    final notifier = context.watch<TrashRestoreNotifier>();
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      body: NestedScrollView(
        headerSliverBuilder: (ctx, innerBoxScrolled) => [
          _buildSliverAppBar(notifier),
        ],
        body: Column(
          children: [
            _buildTabBar(notifier),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildAllTab(notifier),
                  ..._entities.map(
                    (e) => _buildEntityTab(
                      notifier,
                      e['key'] as String,
                      e['color'] as Color,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }


  Widget _buildSliverAppBar(TrashRestoreNotifier notifier) {
    return SliverAppBar(
      expandedHeight: 180,
      pinned: true,
      backgroundColor: const Color(0xFF1B2559),
      iconTheme: const IconThemeData(color: Colors.white),
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF1B2559), Color(0xFF2D3A8C)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Icon(
                          Icons.restore_from_trash_rounded,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Trash & Restore',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            '${notifier.totalDeleted} deleted records found',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.7),
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                      const Spacer(),
                      _RefreshButton(onTap: () => notifier.fetchAll()),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _buildSearchBar(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      height: 44,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withOpacity(0.2)),
      ),
      child: TextField(
        controller: _searchController,
        style: const TextStyle(color: Colors.white, fontSize: 14),
        decoration: InputDecoration(
          hintText: 'Search deleted records…',
          hintStyle: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 14),
          prefixIcon: const Icon(Icons.search_rounded, color: Colors.white54, size: 20),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.close_rounded, color: Colors.white54, size: 18),
                  onPressed: () {
                    _searchController.clear();
                    setState(() => _searchQuery = '');
                  },
                )
              : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 12),
        ),
        onChanged: (v) => setState(() => _searchQuery = v.toLowerCase()),
      ),
    );
  }

  Widget _buildTabBar(TrashRestoreNotifier notifier) {
    return Container(
      color: const Color(0xFF1B2559),
      child: TabBar(
        controller: _tabController,
        isScrollable: true,
        indicatorColor: Colors.white,
        indicatorWeight: 3,
        labelColor: Colors.white,
        unselectedLabelColor: Colors.white54,
        labelStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
        unselectedLabelStyle: const TextStyle(fontSize: 12),
        tabAlignment: TabAlignment.start,
        tabs: [
          Tab(
            child: Row(
              children: [
                const Icon(Icons.all_inclusive_rounded, size: 16),
                const SizedBox(width: 6),
                Text('All (${notifier.totalDeleted})'),
              ],
            ),
          ),
          ..._entities.map((e) {
            final count = notifier.recordsFor(e['key'] as String).length;
            return Tab(
              child: Row(
                children: [
                  Icon(e['icon'] as IconData, size: 14),
                  const SizedBox(width: 5),
                  Text('${e['label']}${count > 0 ? ' ($count)' : ''}'),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  // ─── ALL TAB ──────────────────────────────────────────────────────────────
  Widget _buildAllTab(TrashRestoreNotifier notifier) {
    final all = _entities
        .expand((e) => notifier.recordsFor(e['key'] as String))
        .where((r) =>
            _searchQuery.isEmpty ||
            r.displayName.toLowerCase().contains(_searchQuery) ||
            r.entity.contains(_searchQuery))
        .toList();

    if (_entities.every((e) => notifier.isLoadingEntity(e['key'] as String))) {
      return const _LoadingView();
    }

    if (all.isEmpty) {
      return const _EmptyView(message: 'No deleted records found');
    }

    // Group by entity
    final grouped = <String, List<DeletedRecord>>{};
    for (final r in all) {
      grouped.putIfAbsent(r.entity, () => []).add(r);
    }

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      physics: const BouncingScrollPhysics(),
      children: grouped.entries.map((entry) {
        return _buildEntityGroup(notifier, entry.key, entry.value);
      }).toList(),
    );
  }

  Widget _buildEntityGroup(
    TrashRestoreNotifier notifier,
    String entity,
    List<DeletedRecord> records,
  ) {
    final color = _entityColor(entity);
    final icon = _entityIcon(entity);
    final label = _entities.firstWhere((e) => e['key'] == entity,
        orElse: () => {'label': entity})['label'] as String? ?? entity;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 12, bottom: 8),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 16),
              ),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${records.length}',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ),
            ],
          ),
        ),
        ...records.map(
          (r) => _RecordCard(
            record: r,
            color: color,
            icon: icon,
            onRestore: () => _confirmRestore(context, notifier, r),
          ),
        ),
        const SizedBox(height: 4),
      ],
    );
  }

  // ─── ENTITY-specific TAB ──────────────────────────────────────────────────
  Widget _buildEntityTab(
    TrashRestoreNotifier notifier,
    String entity,
    Color color,
  ) {
    if (notifier.isLoadingEntity(entity)) return const _LoadingView();

    final records = notifier
        .recordsFor(entity)
        .where((r) =>
            _searchQuery.isEmpty ||
            r.displayName.toLowerCase().contains(_searchQuery) ||
            (r.subtitle?.toLowerCase().contains(_searchQuery) ?? false))
        .toList();

    if (records.isEmpty) {
      return _EmptyView(
        message: 'No deleted records for this category',
        icon: _entityIcon(entity),
        color: color,
      );
    }

    final icon = _entityIcon(entity);
    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      physics: const BouncingScrollPhysics(),
      itemCount: records.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (ctx, i) => _RecordCard(
        record: records[i],
        color: color,
        icon: icon,
        onRestore: () => _confirmRestore(context, notifier, records[i]),
      ),
    );
  }

  // ─── CONFIRM + RESTORE ────────────────────────────────────────────────────
  Future<void> _confirmRestore(
    BuildContext ctx,
    TrashRestoreNotifier notifier,
    DeletedRecord record,
  ) async {
    final color = _entityColor(record.entity);
    final confirmed = await showDialog<bool>(
      context: ctx,
      builder: (dialogCtx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(Icons.restore_rounded, color: color, size: 22),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                'Restore Record',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Are you sure you want to restore:',
              style: TextStyle(color: Colors.grey[600], fontSize: 13),
            ),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.06),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: color.withOpacity(0.2)),
              ),
              child: Row(
                children: [
                  Icon(_entityIcon(record.entity), color: color, size: 18),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          record.displayName,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                        if (record.subtitle != null)
                          Text(
                            record.subtitle!,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'This will make the record active again in the system.',
              style: TextStyle(color: Colors.grey[500], fontSize: 12),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogCtx).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton.icon(
            onPressed: () => Navigator.of(dialogCtx).pop(true),
            icon: const Icon(Icons.restore_rounded, size: 16),
            label: const Text('Restore'),
            style: ElevatedButton.styleFrom(
              backgroundColor: color,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true && ctx.mounted) {
      final success = await notifier.restoreRecord(record);
      if (ctx.mounted) {
        ScaffoldMessenger.of(ctx).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(
                  success ? Icons.check_circle_rounded : Icons.error_rounded,
                  color: Colors.white,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    success
                        ? '${record.displayName} restored successfully!'
                        : notifier.error ?? 'Restore failed.',
                  ),
                ),
              ],
            ),
            backgroundColor: success ? const Color(0xFF2E7D32) : Colors.red[700],
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }
}

// ─── REUSABLE WIDGETS ─────────────────────────────────────────────────────────

class _RecordCard extends StatelessWidget {
  final DeletedRecord record;
  final Color color;
  final IconData icon;
  final VoidCallback onRestore;

  const _RecordCard({
    required this.record,
    required this.color,
    required this.icon,
    required this.onRestore,
  });

  String _formatDate(String? raw) {
    if (raw == null) return '';
    try {
      final dt = DateTime.parse(raw).toLocal();
      final now = DateTime.now();
      final diff = now.difference(dt);
      if (diff.inDays == 0) return 'Today';
      if (diff.inDays == 1) return 'Yesterday';
      if (diff.inDays < 7) return '${diff.inDays} days ago';
      return '${dt.day}/${dt.month}/${dt.year}';
    } catch (_) {
      return raw.length > 10 ? raw.substring(0, 10) : raw;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: () {},
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Icon(icon, color: color, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      record.displayName,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (record.subtitle != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        record.subtitle!,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[500],
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    if (record.deletedAt != null) ...[
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            Icons.schedule_rounded,
                            size: 11,
                            color: Colors.red[300],
                          ),
                          const SizedBox(width: 3),
                          Text(
                            'Deleted ${_formatDate(record.deletedAt)}',
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.red[300],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: onRestore,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: color.withOpacity(0.25)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.restore_rounded, color: color, size: 14),
                      const SizedBox(width: 4),
                      Text(
                        'Restore',
                        style: TextStyle(
                          color: color,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LoadingView extends StatelessWidget {
  const _LoadingView();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
          ),
          SizedBox(height: 16),
          Text(
            'Loading deleted records…',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
          ),
        ],
      ),
    );
  }
}

class _EmptyView extends StatelessWidget {
  final String message;
  final IconData icon;
  final Color color;

  const _EmptyView({
    required this.message,
    this.icon = Icons.delete_sweep_rounded,
    this.color = AppColors.primary,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: color.withOpacity(0.08),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 48, color: color.withOpacity(0.5)),
            ),
            const SizedBox(height: 20),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[500],
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'All records are active — nothing to restore.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: Colors.grey[400]),
            ),
          ],
        ),
      ),
    );
  }
}

class _RefreshButton extends StatefulWidget {
  final VoidCallback onTap;
  const _RefreshButton({required this.onTap});

  @override
  State<_RefreshButton> createState() => _RefreshButtonState();
}

class _RefreshButtonState extends State<_RefreshButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _handleTap() {
    _ctrl.repeat();
    widget.onTap();
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) _ctrl.stop();
    });
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _handleTap,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: RotationTransition(
          turns: _ctrl,
          child: const Icon(Icons.refresh_rounded, color: Colors.white, size: 20),
        ),
      ),
    );
  }
}
