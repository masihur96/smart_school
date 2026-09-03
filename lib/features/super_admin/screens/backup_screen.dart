import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';
import 'package:smart_school/l10n/app_localizations.dart';

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
    _tabController.addListener(() {
      // Clear selection when switching tabs
      final notifier = context.read<TrashRestoreNotifier>();
      if (notifier.selectionMode) {
        notifier.clearSelection();
      }
      setState(() {});
    });
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

  /// Returns the entity key for the currently selected tab (null = All tab).
  String? _currentEntityKey() {
    final idx = _tabController.index;
    if (idx == 0) return null;
    return _entities[idx - 1]['key'] as String;
  }

  @override
  Widget build(BuildContext context) {
    final notifier = context.watch<TrashRestoreNotifier>();
    return Scaffold(
      body: Stack(
        children: [
          NestedScrollView(
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
          // Floating bulk action bar
          if (notifier.selectionMode) _buildBulkActionBar(notifier),
        ],
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
      // Exit selection mode via back button override
      leading: notifier.selectionMode
          ? IconButton(
              icon: const Icon(Icons.close_rounded, color: Colors.white),
              onPressed: () => notifier.clearSelection(),
            )
          : null,
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
                                    SizedBox(width: 40),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 18,
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
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (_currentEntityKey() != null) ...[
                                GestureDetector(
                                  onTap: () {
                                    if (notifier.selectionMode) {
                                      notifier.clearSelection();
                                    } else {
                                      notifier.enterSelectionMode();
                                    }
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: notifier.selectionMode
                                          ? Colors.blueAccent.withOpacity(0.2)
                                          : Colors.white.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Icon(
                                      Icons.checklist_rounded,
                                      color: notifier.selectionMode
                                          ? Colors.blueAccent
                                          : Colors.white,
                                      size: 20,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                              ],
                              _RefreshButton(
                                onTap: () => notifier.fetchAllFromTrash(),
                              ),
                            ],
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
          hintStyle: TextStyle(fontSize: 14),
          prefixIcon: Icon(Icons.search_rounded, size: 20),
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
      padding: EdgeInsets.fromLTRB(
        16,
        12,
        16,
        notifier.selectionMode ? 120 : 12,
      ),
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
            isSelected: notifier.isSelected(r.id),
            selectionMode: notifier.selectionMode,
            onRestore: () => _confirmRestore(context, notifier, r),
            onDelete: () => _confirmPermanentDelete(context, notifier, r),
            onLongPress: () {
              if (!notifier.selectionMode) {
                notifier.enterSelectionMode(r.id);
              }
            },
            onTap: notifier.selectionMode
                ? () => notifier.toggleSelection(r.id)
                : null,
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

    // Bulk select header
    final allSelected = notifier.areAllSelected(records);

    return Column(
      children: [
        // Selection header — only shown when in selection mode
        AnimatedSize(
          duration: const Duration(milliseconds: 200),
          child: notifier.selectionMode
              ? _buildSelectionHeader(notifier, entity, records, allSelected)
              : const SizedBox.shrink(),
        ),
        Expanded(
          child: ListView.separated(
            padding: EdgeInsets.fromLTRB(
              16,
              16,
              16,
              notifier.selectionMode ? 120 : 16,
            ),
            physics: const BouncingScrollPhysics(),
            itemCount: records.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (ctx, i) => _RecordCard(
              record: records[i],
              color: color,
              icon: icon,
              isSelected: notifier.isSelected(records[i].id),
              selectionMode: notifier.selectionMode,
              onRestore: () => _confirmRestore(context, notifier, records[i]),
              onDelete: () =>
                  _confirmPermanentDelete(context, notifier, records[i]),
              onLongPress: () {
                if (!notifier.selectionMode) {
                  notifier.enterSelectionMode(records[i].id);
                }
              },
              onTap: notifier.selectionMode
                  ? () => notifier.toggleSelection(records[i].id)
                  : null,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSelectionHeader(
    TrashRestoreNotifier notifier,
    String entity,
    List<DeletedRecord> records,
    bool allSelected,
  ) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFEF4444).withOpacity(0.07),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFEF4444).withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Icon(
            Icons.checklist_rounded,
            size: 18,
            color: const Color(0xFFEF4444),
          ),
          const SizedBox(width: 8),
          Text(
            '${notifier.selectedCount} selected',
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: Color(0xFFEF4444),
            ),
          ),
          const Spacer(),
          GestureDetector(
            onTap: () {
              if (allSelected) {
                notifier.clearSelection();
                notifier.enterSelectionMode('');
                // Re-enter selection mode with empty set — keep bar visible
                // We just clear selection here; user can still long-press again
                notifier.clearSelection();
              } else {
                notifier.selectAllVisible(records);
              }
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: allSelected
                    ? const Color(0xFFEF4444).withOpacity(0.15)
                    : Colors.grey.withOpacity(0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                allSelected ? 'Deselect All' : 'Select All',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: allSelected
                      ? const Color(0xFFEF4444)
                      : Colors.grey[600],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── BULK ACTION BAR ──────────────────────────────────────────────────────
  Widget _buildBulkActionBar(TrashRestoreNotifier notifier) {
    final entityKey = _currentEntityKey();
    final safeEntityKey = entityKey ?? '';
    final isAllTab = entityKey == null;

    return Positioned(
      left: 0,
      right: 0,
      bottom: 0,
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        decoration: BoxDecoration(
          color: const Color(0xFF0F172A),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 24,
              offset: const Offset(0, -4),
            ),
          ],
          border: Border(
            top: BorderSide(color: Colors.white.withOpacity(0.06), width: 1),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Drag indicator
            Container(
              width: 36,
              height: 3,
              margin: const EdgeInsets.only(bottom: 10),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.15),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Row(
              children: [
                // Selection count badge
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.06),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.checklist_rounded,
                        size: 16,
                        color: Colors.white.withOpacity(0.7),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '${notifier.selectedCount} item${notifier.selectedCount == 1 ? '' : 's'}',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Colors.white.withOpacity(0.8),
                        ),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                // Cancel button
                IconButton(
                  icon: Icon(
                    Icons.close_rounded,
                    color: Colors.white.withOpacity(0.5),
                    size: 20,
                  ),
                  onPressed: () => notifier.clearSelection(),
                  tooltip: 'Cancel',
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                // Restore Selected
                if (!isAllTab)
                  Expanded(
                    child: _BulkActionButton(
                      label: 'Restore Selected',
                      icon: Icons.unarchive_rounded,
                      color: const Color(0xFF22C55E),
                      loading: notifier.restoring,
                      onTap: notifier.selectedCount == 0
                          ? null
                          : () => _confirmBulkRestore(
                              context,
                              notifier,
                              safeEntityKey,
                            ),
                    ),
                  ),
                if (!isAllTab) const SizedBox(width: 10),
                // Delete Selected
                Expanded(
                  child: _BulkActionButton(
                    label: 'Delete Forever',
                    icon: Icons.delete_forever_rounded,
                    color: const Color(0xFFEF4444),
                    loading: notifier.deleting,
                    onTap: notifier.selectedCount == 0 || isAllTab
                        ? null
                        : () => _confirmBulkDelete(
                            context,
                            notifier,
                            safeEntityKey,
                          ),
                  ),
                ),
              ],
            ),
            if (isAllTab)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  'Switch to a specific category tab to use bulk actions.',
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.white.withOpacity(0.4),
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
          ],
        ),
      ),
    );
  }

  // ─── CONFIRM RESTORE (single) ─────────────────────────────────────────────
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
            child: Text(AppLocalizations.of(context)!.cancel),
          ),
          ElevatedButton.icon(
            onPressed: () => Navigator.of(dialogCtx).pop(true),
            icon: const Icon(Icons.restore_rounded, size: 16),
            label: Text(AppLocalizations.of(context)!.restore),
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
          _buildSnackBar(
            success
                ? '${record.displayName} restored successfully!'
                : notifier.error ?? 'Restore failed.',
            success,
          ),
        );
      }
    }
  }

  // ─── CONFIRM PERMANENT DELETE (single) ───────────────────────────────────
  Future<void> _confirmPermanentDelete(
    BuildContext ctx,
    TrashRestoreNotifier notifier,
    DeletedRecord record,
  ) async {
    const dangerColor = Color(0xFFEF4444);
    final confirmed = await showDialog<bool>(
      context: ctx,
      builder: (dialogCtx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: dangerColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.delete_forever_rounded,
                color: dangerColor,
                size: 22,
              ),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                'Delete Permanently',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: dangerColor.withOpacity(0.06),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: dangerColor.withOpacity(0.2)),
              ),
              child: Row(
                children: [
                  Icon(
                    _entityIcon(record.entity),
                    color: dangerColor,
                    size: 18,
                  ),
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
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: dangerColor.withOpacity(0.05),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: dangerColor.withOpacity(0.15)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.warning_amber_rounded,
                    size: 16,
                    color: dangerColor,
                  ),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'This action cannot be undone. The record will be permanently removed from the database.',
                      style: TextStyle(
                        fontSize: 12,
                        color: dangerColor,
                        fontWeight: FontWeight.w600,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogCtx).pop(false),
            child: Text(AppLocalizations.of(context)!.cancel),
          ),
          ElevatedButton.icon(
            onPressed: () => Navigator.of(dialogCtx).pop(true),
            icon: const Icon(Icons.delete_forever_rounded, size: 16),
            label: const Text('Delete Forever'),
            style: ElevatedButton.styleFrom(
              backgroundColor: dangerColor,
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
      final success = await notifier.permanentDelete(record);
      if (ctx.mounted) {
        ScaffoldMessenger.of(ctx).showSnackBar(
          _buildSnackBar(
            success
                ? '${record.displayName} permanently deleted.'
                : notifier.error ?? 'Delete failed.',
            success,
            isDelete: true,
          ),
        );
      }
    }
  }

  // ─── CONFIRM BULK RESTORE ─────────────────────────────────────────────────
  Future<void> _confirmBulkRestore(
    BuildContext ctx,
    TrashRestoreNotifier notifier,
    String entity,
  ) async {
    final ids = notifier.selectedIds.toList();
    final count = ids.length;
    final entityLabel =
        _entities.firstWhere(
              (e) => e['key'] == entity,
              orElse: () => {'label': entity},
            )['label']
            as String;

    final color = _entityColor(entity);

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
              child: Icon(Icons.unarchive_rounded, color: color, size: 22),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                'Restore Records',
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
              'Restore $count $entityLabel record${count == 1 ? '' : 's'}?',
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Text(
              'Selected records will become active again in the system.',
              style: TextStyle(color: Colors.grey[500], fontSize: 12),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogCtx).pop(false),
            child: Text(AppLocalizations.of(context)!.cancel),
          ),
          ElevatedButton.icon(
            onPressed: () => Navigator.of(dialogCtx).pop(true),
            icon: const Icon(Icons.unarchive_rounded, size: 16),
            label: Text('Restore $count'),
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
      final result = await notifier.restoreSelected(entity, ids);
      if (ctx.mounted) {
        final msg = result.failed == 0
            ? '${result.succeeded} record${result.succeeded == 1 ? '' : 's'} restored successfully!'
            : '${result.succeeded} restored, ${result.failed} failed.';
        ScaffoldMessenger.of(
          ctx,
        ).showSnackBar(_buildSnackBar(msg, result.failed == 0));
      }
    }
  }

  // ─── CONFIRM BULK DELETE ──────────────────────────────────────────────────
  Future<void> _confirmBulkDelete(
    BuildContext ctx,
    TrashRestoreNotifier notifier,
    String entity,
  ) async {
    final ids = notifier.selectedIds.toList();
    final count = ids.length;
    const dangerColor = Color(0xFFEF4444);
    final entityLabel =
        _entities.firstWhere(
              (e) => e['key'] == entity,
              orElse: () => {'label': entity},
            )['label']
            as String;

    final confirmed = await showDialog<bool>(
      context: ctx,
      builder: (dialogCtx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: dangerColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.delete_forever_rounded,
                color: dangerColor,
                size: 22,
              ),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                'Delete Permanently',
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
              'You are about to permanently delete $count $entityLabel record${count == 1 ? '' : 's'}.',
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: dangerColor.withOpacity(0.05),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: dangerColor.withOpacity(0.2)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.warning_amber_rounded,
                    size: 16,
                    color: dangerColor,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: RichText(
                      text: const TextSpan(
                        style: TextStyle(fontSize: 12, height: 1.4),
                        children: [
                          TextSpan(
                            text: 'This action cannot be undone. ',
                            style: TextStyle(
                              fontWeight: FontWeight.w800,
                              color: dangerColor,
                            ),
                          ),
                          TextSpan(
                            text:
                                'All selected records will be permanently removed from the database.',
                            style: TextStyle(
                              color: dangerColor,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogCtx).pop(false),
            child: Text(AppLocalizations.of(context)!.cancel),
          ),
          ElevatedButton.icon(
            onPressed: () => Navigator.of(dialogCtx).pop(true),
            icon: const Icon(Icons.delete_forever_rounded, size: 16),
            label: Text('Delete $count Forever'),
            style: ElevatedButton.styleFrom(
              backgroundColor: dangerColor,
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
      final result = await notifier.permanentDeleteBulk(entity, ids);
      if (ctx.mounted) {
        final msg = result.failed == 0
            ? '${result.succeeded} record${result.succeeded == 1 ? '' : 's'} permanently deleted.'
            : '${result.succeeded} deleted, ${result.failed} failed.';
        ScaffoldMessenger.of(
          ctx,
        ).showSnackBar(_buildSnackBar(msg, result.failed == 0, isDelete: true));
      }
    }
  }

  SnackBar _buildSnackBar(
    String message,
    bool success, {
    bool isDelete = false,
  }) {
    final color = success
        ? (isDelete ? const Color(0xFFEF4444) : const Color(0xFF2E7D32))
        : Colors.red[700]!;
    final icon = success
        ? (isDelete ? Icons.delete_forever_rounded : Icons.check_circle_rounded)
        : Icons.error_rounded;
    return SnackBar(
      content: Row(
        children: [
          Icon(icon, color: Colors.white),
          const SizedBox(width: 8),
          Expanded(child: Text(message)),
        ],
      ),
      backgroundColor: color,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      duration: const Duration(seconds: 3),
    );
  }
}

// ─── REUSABLE WIDGETS ─────────────────────────────────────────────────────────

class _RecordCard extends StatelessWidget {
  final DeletedRecord record;
  final Color color;
  final IconData icon;
  final bool isSelected;
  final bool selectionMode;
  final VoidCallback onRestore;
  final VoidCallback onDelete;
  final VoidCallback onLongPress;
  final VoidCallback? onTap;

  const _RecordCard({
    required this.record,
    required this.color,
    required this.icon,
    required this.isSelected,
    required this.selectionMode,
    required this.onRestore,
    required this.onDelete,
    required this.onLongPress,
    this.onTap,
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
    const dangerColor = Color(0xFFEF4444);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        border: isSelected
            ? Border.all(color: dangerColor, width: 2)
            : Border.all(color: Colors.transparent, width: 2),
      ),
      child: Card(
        margin: EdgeInsets.zero,
        child: InkWell(
          onTap: onTap,
          onLongPress: onLongPress,
          borderRadius: BorderRadius.circular(20),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  // Checkbox overlay in selection mode
                  if (selectionMode) ...[
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      width: 24,
                      height: 24,
                      margin: const EdgeInsets.only(right: 12),
                      decoration: BoxDecoration(
                        color: isSelected ? dangerColor : Colors.transparent,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: isSelected
                              ? dangerColor
                              : Colors.grey.withOpacity(0.4),
                          width: 2,
                        ),
                      ),
                      child: isSelected
                          ? const Icon(
                              Icons.check_rounded,
                              size: 14,
                              color: Colors.white,
                            )
                          : null,
                    ),
                  ],
                  // Entity icon
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
                  ),
                  // Action buttons — hidden in selection mode
                  if (!selectionMode) ...[
                    const SizedBox(width: 8),
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        _RestoreButton(onTap: onRestore, color: color),
                        const SizedBox(height: 6),
                        _DeleteForeverButton(onTap: onDelete),
                      ],
                    ),
                  ],
                ],
              ),
            ),
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
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          decoration: BoxDecoration(
            color: color.withOpacity(0.08),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: color.withOpacity(0.12)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.unarchive_rounded, color: color, size: 14),
              const SizedBox(width: 5),
              Text(
                'Restore',
                style: TextStyle(
                  color: color,
                  fontSize: 12,
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

class _DeleteForeverButton extends StatelessWidget {
  final VoidCallback onTap;

  const _DeleteForeverButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    const dangerColor = Color(0xFFEF4444);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          decoration: BoxDecoration(
            color: dangerColor.withOpacity(0.07),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: dangerColor.withOpacity(0.15)),
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.delete_forever_rounded, color: dangerColor, size: 14),
              SizedBox(width: 5),
              Text(
                'Delete',
                style: TextStyle(
                  color: dangerColor,
                  fontSize: 12,
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

class _BulkActionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final bool loading;
  final VoidCallback? onTap;

  const _BulkActionButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.loading,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final disabled = onTap == null;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: disabled ? null : onTap,
        borderRadius: BorderRadius.circular(14),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(vertical: 13),
          decoration: BoxDecoration(
            color: disabled
                ? Colors.white.withOpacity(0.04)
                : color.withOpacity(0.15),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: disabled
                  ? Colors.white.withOpacity(0.06)
                  : color.withOpacity(0.3),
            ),
          ),
          child: loading
              ? Center(
                  child: SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(color),
                    ),
                  ),
                )
              : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      icon,
                      size: 16,
                      color: disabled ? Colors.white.withOpacity(0.25) : color,
                    ),
                    const SizedBox(width: 7),
                    Text(
                      label,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: disabled
                            ? Colors.white.withOpacity(0.25)
                            : color,
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
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: 6,
      itemBuilder: (context, index) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Shimmer.fromColors(
            baseColor: isDark ? Colors.grey[800]! : Colors.grey[300]!,
            highlightColor: isDark ? Colors.grey[700]! : Colors.grey[100]!,
            child: Container(
              height: 84,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
              ),
            ),
          ),
        );
      },
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
