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
        )['color']
        as Color);
  }

  IconData _entityIcon(String key) {
    return (_entities.firstWhere(
          (e) => e['key'] == key,
          orElse: () => {'icon': Icons.delete_forever_rounded},
        )['icon']
        as IconData);
  }

  @override
  Widget build(BuildContext context) {
    final notifier = context.watch<TrashRestoreNotifier>();
    return Scaffold(
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
      expandedHeight: 200,
      pinned: true,
      stretch: true,
      backgroundColor: const Color(0xFF0F172A),
      iconTheme: const IconThemeData(color: Colors.white),
      flexibleSpace: FlexibleSpaceBar(
        stretchModes: const [
          StretchMode.blurBackground,
          StretchMode.zoomBackground,
        ],
        background: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF0F172A), Color(0xFF1E293B), Color(0xFF334155)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Stack(
            children: [
              // Decorative circles
              Positioned(
                top: -50,
                right: -50,
                child: Container(
                  width: 200,
                  height: 200,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.03),
                    shape: BoxShape.circle,
                  ),
                ),
              ),
              SafeArea(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.blueAccent.withOpacity(
                                          0.2,
                                        ),
                                        borderRadius: BorderRadius.circular(6),
                                        border: Border.all(
                                          color: Colors.blueAccent.withOpacity(
                                            0.3,
                                          ),
                                        ),
                                      ),
                                      child: const Text(
                                        'SUPER ADMIN',
                                        style: TextStyle(
                                          color: Colors.blueAccent,
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                          letterSpacing: 1.2,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                const Text(
                                  'System Trash',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 28,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: -0.5,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Manage and restore soft-deleted records',
                                  style: TextStyle(
                                    color: Colors.white.withOpacity(0.6),
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          _RefreshButton(
                            onTap: () => notifier.fetchAllFromTrash(),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      _buildSearchBar(),
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

  Widget _buildSearchBar() {
    return Container(
      height: 48,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.15)),
      ),
      child: TextField(
        controller: _searchController,
        style: const TextStyle(fontSize: 14),
        cursorColor: Colors.blueAccent,
        decoration: InputDecoration(
          hintText: 'Search records...',
          hintStyle: TextStyle(
            color: Colors.white.withOpacity(0.4),
            fontSize: 14,
          ),
          prefixIcon: Icon(
            Icons.search_rounded,
            color: Colors.white.withOpacity(0.5),
            size: 20,
          ),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  icon: const Icon(
                    Icons.cancel_rounded,
                    color: Colors.white54,
                    size: 20,
                  ),
                  onPressed: () {
                    _searchController.clear();
                    setState(() => _searchQuery = '');
                  },
                )
              : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 14),
        ),
        onChanged: (v) => setState(() => _searchQuery = v.toLowerCase()),
      ),
    );
  }

  Widget _buildTabBar(TrashRestoreNotifier notifier) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: const BoxDecoration(
        color: Color(0xFF0F172A),
        border: Border(bottom: BorderSide(color: Color(0xFF1E293B), width: 1)),
      ),
      child: TabBar(
        controller: _tabController,
        isScrollable: true,
        indicatorSize: TabBarIndicatorSize.label,
        indicator: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: Colors.blueAccent.withOpacity(0.15),
          border: Border.all(color: Colors.blueAccent.withOpacity(0.3)),
        ),
        labelColor: Colors.blueAccent,
        unselectedLabelColor: const Color(0xFF94A3B8),
        labelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
        unselectedLabelStyle: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w500,
        ),
        dividerColor: Colors.transparent,
        tabAlignment: TabAlignment.start,
        tabs: [
          _buildTabItem(
            'All',
            Icons.auto_awesome_rounded,
            notifier.totalDeleted,
          ),
          ..._entities.map((e) {
            final count = notifier.recordsFor(e['key'] as String).length;
            return _buildTabItem(
              e['label'] as String,
              e['icon'] as IconData,
              count,
            );
          }),
        ],
      ),
    );
  }

  Widget _buildTabItem(String label, IconData icon, int count) {
    return Tab(
      height: 40,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16),
          const SizedBox(width: 8),
          Text(label),
          if (count > 0) ...[
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                '$count',
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ─── ALL TAB ──────────────────────────────────────────────────────────────
  Widget _buildAllTab(TrashRestoreNotifier notifier) {
    if (notifier.isLoadingAll) return const _LoadingView();

    final all = _entities
        .expand((e) => notifier.recordsFor(e['key'] as String))
        .where(
          (r) =>
              _searchQuery.isEmpty ||
              r.displayName.toLowerCase().contains(_searchQuery) ||
              r.entity.contains(_searchQuery),
        )
        .toList();

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
    final label =
        _entities.firstWhere(
              (e) => e['key'] == entity,
              orElse: () => {'label': entity},
            )['label']
            as String? ??
        entity;

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
    if (notifier.isLoadingAll || notifier.isLoadingEntity(entity)) {
      return const _LoadingView();
    }

    final records = notifier
        .recordsFor(entity)
        .where(
          (r) =>
              _searchQuery.isEmpty ||
              r.displayName.toLowerCase().contains(_searchQuery) ||
              (r.subtitle?.toLowerCase().contains(_searchQuery) ?? false),
        )
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
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      physics: const BouncingScrollPhysics(),
      itemCount: records.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
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
            backgroundColor: success
                ? const Color(0xFF2E7D32)
                : Colors.red[700],
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
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
      if (diff.inDays == 0)
        return 'Today at ${dt.hour}:${dt.minute.toString().padLeft(2, '0')}';
      if (diff.inDays == 1) return 'Yesterday';
      if (diff.inDays < 7) return '${diff.inDays} days ago';
      return '${dt.day}/${dt.month}/${dt.year}';
    } catch (_) {
      return raw.length > 10 ? raw.substring(0, 10) : raw;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(icon, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      record.displayName,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,

                        letterSpacing: -0.2,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    if (record.subtitle != null)
                      Text(
                        record.subtitle!,
                        style: const TextStyle(
                          fontSize: 12,

                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Row(
                          children: [
                            const Icon(
                              Icons.delete_outline_rounded,
                              size: 10,
                              color: Color(0xFFF87171),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              _formatDate(record.deletedAt),
                              style: const TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFFF87171),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              _RestoreButton(onTap: onRestore, color: color),
            ],
          ),
        ),
      ),
    );
  }
}

class _RestoreButton extends StatelessWidget {
  final VoidCallback onTap;
  final Color color;

  const _RestoreButton({required this.onTap, required this.color});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: color.withOpacity(0.08),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: color.withOpacity(0.12)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.unarchive_rounded, color: color, size: 16),
              const SizedBox(width: 6),
              Text(
                'Restore',
                style: TextStyle(
                  color: color,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
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
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(
            width: 40,
            height: 40,
            child: CircularProgressIndicator(
              strokeWidth: 3,
              valueColor: AlwaysStoppedAnimation<Color>(Colors.blueAccent),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Synchronizing trash data...',
            style: TextStyle(
              color: const Color(0xFF64748B),
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
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
          child: const Icon(
            Icons.refresh_rounded,
            color: Colors.white,
            size: 20,
          ),
        ),
      ),
    );
  }
}
