import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:smart_school/core/theme/app_colors.dart';
import 'package:smart_school/core/widgets/app_drawer.dart';
import 'package:smart_school/core/widgets/notification_icon_button.dart';
import 'package:smart_school/features/auth/providers/auth_provider.dart';
import 'package:smart_school/features/super_admin/providers/super_admin_dashboard_provider.dart';
import 'package:smart_school/features/super_admin/screens/backup_screen.dart';
import 'package:smart_school/features/super_admin/screens/pricing_school_screen.dart';
import 'package:smart_school/features/super_admin/screens/subscription_screen.dart';
import 'package:smart_school/features/super_admin/screens/super_admin_school_screen.dart';
import 'package:smart_school/l10n/app_localizations.dart';
import 'package:smart_school/models/user_model.dart';

class SuperAdminDashboardScreen extends StatefulWidget {
  const SuperAdminDashboardScreen({super.key});

  @override
  State<SuperAdminDashboardScreen> createState() =>
      _SuperAdminDashboardScreenState();
}

class _SuperAdminDashboardScreenState extends State<SuperAdminDashboardScreen> {
  int _selectedIndex = 0;

  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<SuperAdminDashboardNotifier>().fetchDashboardData();
    });
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  String _getTitle(AppLocalizations l10n) {
    switch (_selectedIndex) {
      case 0:
        return l10n.systemOverview;
      case 1:
        return l10n.schoolManagement;
      case 2:
        return l10n.systemConfig;
      default:
        return l10n.superAdmin;
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthNotifier>().user;

    final l10n = AppLocalizations.of(context)!;
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, dynamic result) async {
        if (didPop) return;
        final shouldExit = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: Text(l10n.exitApp),
            content: Text(l10n.exitAppConfirmation),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: Text(l10n.no),
              ),
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                ),
                child: Text(l10n.yes),
              ),
            ],
          ),
        );
        if (shouldExit == true) {
          SystemNavigator.pop();
        }
      },
      child: Scaffold(
        extendBodyBehindAppBar: true,
        appBar: AppBar(
          title: Text(
            _getTitle(l10n),
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          foregroundColor: AppColors.white,
          backgroundColor: Colors.transparent,
          elevation: 0,
          actions: [const NotificationIconButton(color: Colors.white)],
        ),
        drawer: const AppDrawer(),
        body: IndexedStack(
          index: _selectedIndex,
          children: [
            _buildOverviewTab(user, l10n),
            _buildSchoolsTab(l10n),
            _buildSettingsTab(l10n),
          ],
        ),
        bottomNavigationBar: Container(
          decoration: BoxDecoration(
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          child: BottomNavigationBar(
            currentIndex: _selectedIndex,
            onTap: _onItemTapped,
            selectedItemColor: AppColors.primary,
            unselectedItemColor: Colors.grey,
            type: BottomNavigationBarType.fixed,
            backgroundColor: Colors.white,
            elevation: 0,
            items: [
              BottomNavigationBarItem(
                icon: const Icon(Icons.dashboard_rounded),
                activeIcon: const Icon(Icons.dashboard),
                label: l10n.overview,
              ),
              BottomNavigationBarItem(
                icon: const Icon(Icons.business_rounded),
                activeIcon: const Icon(Icons.business),
                label: l10n.schools,
              ),
              BottomNavigationBarItem(
                icon: const Icon(Icons.settings_suggest_rounded),
                activeIcon: const Icon(Icons.settings_suggest),
                label: l10n.config,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // --- OVERVIEW TAB ---
  Widget _buildOverviewTab(user, AppLocalizations l10n) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(user, l10n),
          Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.systemPerformance,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                _buildStatGrid(l10n),
                const SizedBox(height: 16),
                Text(
                  l10n.quickActions,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                _buildQuickActionsGrid(l10n),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(User? user, AppLocalizations l10n) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(24, 80, 24, 40),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.primaryDark, Color(0xFF3F51B5)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(36),
          bottomRight: Radius.circular(36),
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryDark.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(height: 40),
                  Text(
                    '${l10n.welcomeBack}, ${user?.name ?? 'Admin'}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.white.withOpacity(0.3),
                    width: 2,
                  ),
                ),
                child: const CircleAvatar(
                  radius: 24,
                  backgroundColor: Colors.white24,
                  child: Icon(
                    Icons.admin_panel_settings,
                    color: Colors.white,
                    size: 28,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                const Icon(Icons.lens, color: Colors.greenAccent, size: 12),
                const SizedBox(width: 8),
                Text(
                  l10n.systemStatusHealthy,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
                const Spacer(),
                const Icon(Icons.sync, color: Colors.white70, size: 16),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatGrid(AppLocalizations l10n) {
    final dashboardNotifier = context.watch<SuperAdminDashboardNotifier>();
    final data = dashboardNotifier.dashboardData;
    final isLoading = dashboardNotifier.isLoading;

    if (isLoading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(20.0),
          child: CircularProgressIndicator(),
        ),
      );
    }

    return MediaQuery.removePadding(
      context: context,
      removeTop: true,
      child: GridView.count(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        crossAxisCount: 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 1.3,
        children: [
          _buildStatCard(
            l10n.totalSchools,
            '${data.totalSchools}',
            Icons.business,
          ),
          _buildStatCard(
            l10n.totalStudents,
            '${data.totalStudents}',
            Icons.people,
          ),
          _buildStatCard(
            l10n.totalTeachers,
            '${data.totalTeachers}',
            Icons.dns,
          ),
          _buildStatCard(
            l10n.activeSubscription,
            '${data.activeSubscriptions}',
            Icons.monetization_on,
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white30,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, size: 22),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  label,
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActionsGrid(AppLocalizations l10n) {
    return MediaQuery.removePadding(
      context: context,
      removeTop: true,
      child: GridView.count(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        crossAxisCount: 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 1.6,
        children: [
          _buildActionItem(l10n.schools, Icons.add_business_rounded, () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => SuperAdminSchoolScreen()),
            );
          }),
          _buildActionItem(l10n.pricing, Icons.terminal_rounded, () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => PricingSchoolScreen()),
            );
          }),
          _buildActionItem(l10n.subscription, Icons.podcasts_rounded, () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => SubscriptionScreen()),
            );
          }),
          _buildActionItem(l10n.backup, Icons.storage_rounded, () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => BackupScreen()),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildActionItem(String title, IconData icon, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Card(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 20),
            const SizedBox(width: 8),
            Text(
              title,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAlertTile(
    String title,
    String time,
    IconData icon,
    Color color,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color.withOpacity(0.8), color],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.2),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: Colors.white, size: 20),
        ),
        title: Text(
          title,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        subtitle: Text(
          time,
          style: TextStyle(fontSize: 11, color: Colors.white.withOpacity(0.8)),
        ),
        trailing: const Icon(
          Icons.arrow_forward_ios_rounded,
          color: Colors.white70,
          size: 14,
        ),
        onTap: () {},
      ),
    );
  }

  // --- SCHOOLS TAB ---
  Widget _buildSchoolsTab(AppLocalizations l10n) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 100, 20, 20),
      physics: const BouncingScrollPhysics(),
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              l10n.managedSchools,
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            Container(
              decoration: BoxDecoration(
                boxShadow: [
                  BoxShadow(blurRadius: 10, offset: const Offset(0, 4)),
                ],
              ),
              child: ElevatedButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.add_rounded, size: 20),
                label: Text(l10n.addNew),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  elevation: 0,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Text(
          'Oversee operations for ${42} educational institutions',
          style: TextStyle(fontSize: 13),
        ),
        const SizedBox(height: 24),
        _buildSchoolCard(
          'Global International School',
          'Active',
          '1240 Students',
          'Premium Plan',
          l10n,
        ),
        _buildSchoolCard(
          'St. Mary High School',
          'Active',
          '850 Students',
          'Basic Plan',
          l10n,
        ),
        _buildSchoolCard(
          'Lakeside Academy',
          'Suspended',
          '0 Students',
          'Trial Expired',
          l10n,
        ),
        _buildSchoolCard(
          'Oakwood Montessori',
          'Trial',
          '120 Students',
          'Free Trial',
          l10n,
        ),
      ],
    );
  }

  Widget _buildSchoolCard(
    String name,
    String status,
    String students,
    String plan,
    AppLocalizations l10n,
  ) {
    final statusColor = status == 'Active'
        ? Colors.green
        : (status == 'Suspended' ? Colors.red : Colors.orange);

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
                      child: Text(
                        name,
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: statusColor.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        status.toUpperCase(),
                        style: TextStyle(
                          color: statusColor,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    _buildSmallInfo(Icons.people_alt_rounded, students),
                    const SizedBox(width: 20),
                    _buildSmallInfo(Icons.wallet_rounded, plan),
                  ],
                ),
              ],
            ),
          ),
          Divider(),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.bar_chart_rounded, size: 18),
                label: Text(
                  l10n.analytics,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: () {},
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,

                  elevation: 0,
                  side: BorderSide(color: Colors.grey.shade300),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                  minimumSize: const Size(0, 0),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  l10n.manage,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSmallInfo(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 14),
        const SizedBox(width: 4),
        Text(text, style: TextStyle(fontSize: 12)),
      ],
    );
  }

  // --- SETTINGS TAB ---
  Widget _buildSettingsTab(AppLocalizations l10n) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 100, 20, 20),
      physics: const BouncingScrollPhysics(),
      children: [
        Text(
          l10n.systemConfiguration,
          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Text(
          'Manage global application behaviors and security',
          style: TextStyle(fontSize: 13),
        ),
        const SizedBox(height: 24),
        _buildSettingsGroup('Access Control', [
          _buildSettingToggle(
            l10n.maintenanceMode,
            'Block access for all non-admins',
            false,
          ),
          _buildSettingToggle(
            'Public Registration',
            'Allow new schools to register online',
            true,
          ),
        ]),
        const SizedBox(height: 24),
        _buildSettingsGroup('Security \u0026 Notifications', [
          _buildSettingToggle(
            'Global Notifications',
            'Enable system-wide broadcast alerts',
            true,
          ),
          _buildSettingToggle(
            'Two-Factor Auth',
            'Force 2FA for all administrative roles',
            false,
          ),
        ]),
        const SizedBox(height: 32),
        const Text(
          'Storage \u0026 Resources',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 20),
        _buildStorageInfo('Database Usage (PostgreSQL)', 0.65, Colors.blue),
        const SizedBox(height: 20),
        _buildStorageInfo('File Storage (AWS S3)', 0.42, Colors.purple),
        const SizedBox(height: 48),
        Container(
          decoration: BoxDecoration(
            boxShadow: [
              BoxShadow(
                color: Colors.red.withOpacity(0.2),
                blurRadius: 15,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: ElevatedButton(
            onPressed: () {},
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade600,
              foregroundColor: Colors.white,
              minimumSize: const Size(double.infinity, 56),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              elevation: 0,
            ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.refresh_rounded),
                SizedBox(width: 8),
                Text(
                  'RESTART SYSTEM SERVICES',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 20),
      ],
    );
  }

  Widget _buildSettingsGroup(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 12),
          child: Text(
            title.toUpperCase(),
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,

              letterSpacing: 1.1,
            ),
          ),
        ),
        ...children,
      ],
    );
  }

  Widget _buildSettingToggle(String title, String subtitle, bool value) {
    return Card(
      child: SwitchListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
        title: Text(
          title,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        subtitle: Text(subtitle, style: TextStyle(fontSize: 12)),
        value: value,
        onChanged: (val) {},
        activeColor: AppColors.primary,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      ),
    );
  }

  Widget _buildStorageInfo(String title, double progress, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              title,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
            ),
            Text(
              '${(progress * 100).toInt()}%',
              style: TextStyle(fontWeight: FontWeight.bold, color: color),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Stack(
          children: [
            Container(
              height: 10,
              width: double.infinity,
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            FractionallySizedBox(
              widthFactor: progress,
              child: Container(
                height: 10,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [color.withOpacity(0.7), color],
                  ),
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: [
                    BoxShadow(
                      color: color.withOpacity(0.3),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
