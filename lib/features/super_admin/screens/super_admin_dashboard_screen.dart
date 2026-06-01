import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:smart_school/core/theme/app_colors.dart';
import 'package:smart_school/core/widgets/app_drawer.dart';
import 'package:smart_school/core/widgets/notification_icon_button.dart';
import 'package:smart_school/features/auth/providers/auth_provider.dart';
import 'package:smart_school/features/profile/presentation/views/profile_screen.dart';
import 'package:smart_school/features/super_admin/providers/super_admin_dashboard_provider.dart';
import 'package:smart_school/features/super_admin/providers/super_admin_school_provider.dart';
import 'package:smart_school/features/super_admin/screens/backup_screen.dart';
import 'package:smart_school/features/super_admin/screens/pricing_school_screen.dart';
import 'package:smart_school/features/super_admin/screens/subscription_screen.dart';
import 'package:smart_school/features/super_admin/screens/super_admin_notification_sender_screen.dart';
import 'package:smart_school/features/super_admin/screens/super_admin_school_screen.dart';
import 'package:smart_school/features/super_admin/screens/system_status_screen.dart';
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

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<SuperAdminDashboardNotifier>().fetchDashboardData();
      context.read<SuperAdminSchoolNotifier>().fetchSchools();
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
        appBar: AppBar(
          title: Text(
            _getTitle(l10n),
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.white,
              fontSize: 18,
            ),
          ),
          elevation: 0,
          backgroundColor: AppColors.primaryDark,
          foregroundColor: Colors.white,
          iconTheme: const IconThemeData(color: Colors.white),
          actions: [
            NotificationIconButton(color: AppColors.primaryDark),
            IconButton(
              icon: const Icon(Icons.account_circle_outlined),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const ProfileScreen()),
                );
              },
            ),
            const SizedBox(width: 8),
          ],
        ),
        drawer: const AppDrawer(),
        body: IndexedStack(
          index: _selectedIndex,
          children: [
            _buildOverviewTab(user, l10n),

            SuperAdminSchoolScreen(),

            _buildSettingsTab(l10n),
          ],
        ),
        bottomNavigationBar: Container(
          decoration: BoxDecoration(
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.08),
                blurRadius: 10,
                offset: const Offset(0, -4),
              ),
            ],
          ),
          child: BottomNavigationBar(
            currentIndex: _selectedIndex,
            onTap: _onItemTapped,
            type: BottomNavigationBarType.fixed,
            selectedItemColor: AppColors.primaryDark,
            unselectedItemColor: Colors.grey.shade500,
            elevation: 0,
            selectedLabelStyle: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
            unselectedLabelStyle: const TextStyle(fontSize: 12),
            items: [
              BottomNavigationBarItem(
                icon: const Icon(Icons.dashboard_outlined),
                activeIcon: const Icon(Icons.dashboard),
                label: l10n.overview,
              ),
              BottomNavigationBarItem(
                icon: const Icon(Icons.business_rounded),
                activeIcon: const Icon(Icons.business),
                label: l10n.schools,
              ),
              BottomNavigationBarItem(
                icon: const Icon(Icons.settings_suggest_outlined),
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
          _buildModernHeader(user, l10n),
          Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSectionTitle(l10n.systemPerformance),
                const SizedBox(height: 16),
                _buildStatGrid(l10n),
                const SizedBox(height: 24),
                _buildSectionTitle(l10n.quickActions),
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

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        letterSpacing: 0.5,
      ),
    );
  }

  Widget _buildModernHeader(User? user, AppLocalizations l10n) {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        color: AppColors.primaryDark,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(32),
          bottomRight: Radius.circular(32),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 20,
            offset: Offset(0, 10),
          ),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(25, 20, 25, 30),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                ),
                child: const CircleAvatar(
                  radius: 30,
                  backgroundColor: Colors.white24,
                  child: Icon(
                    Icons.admin_panel_settings,
                    size: 40,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(width: 15),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.welcomeBack,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.9),
                        fontSize: 14,
                      ),
                    ),
                    Text(
                      user?.name ?? 'Super Admin',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                    ),
                    Text(
                      'System Administrator',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.8),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SystemStatusScreen()),
              );
            },
            child: Container(
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
          _buildGradientStatCard(
            l10n.totalSchools,
            '${data.totalSchools}',
            Icons.business,
            const [Color(0xFF3B82F6), Color(0xFF2563EB)], // Blue
          ),
          _buildGradientStatCard(
            l10n.totalStudents,
            '${data.totalStudents}',
            Icons.people,
            const [Color(0xFF8B5CF6), Color(0xFF6D28D9)], // Purple
          ),
          _buildGradientStatCard(
            l10n.totalTeachers,
            '${data.totalTeachers}',
            Icons.dns,
            const [Color(0xFF10B981), Color(0xFF059669)], // Green
          ),
          _buildGradientStatCard(
            l10n.activeSubscription,
            '${data.activeSubscriptions}',
            Icons.monetization_on,
            const [Color(0xFFF59E0B), Color(0xFFD97706)], // Orange
          ),
        ],
      ),
    );
  }

  Widget _buildGradientStatCard(
    String label,
    String value,
    IconData icon,
    List<Color> colors,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: colors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: colors.last.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, size: 24, color: Colors.white),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: Colors.white.withOpacity(0.9),
                ),
              ),
            ],
          ),
        ],
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
        crossAxisCount: 3,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 0.9,
        children: [
          _buildActionItem(l10n.schools, Icons.add_business_rounded, () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => SuperAdminSchoolScreen()),
            );
          }, Colors.blue),
          _buildActionItem(l10n.pricing, Icons.terminal_rounded, () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => PricingSchoolScreen()),
            );
          }, Colors.purple),
          _buildActionItem(l10n.subscription, Icons.podcasts_rounded, () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => SubscriptionScreen()),
            );
          }, Colors.green),
          _buildActionItem(l10n.backup, Icons.storage_rounded, () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => BackupScreen()),
            );
          }, Colors.orange),
          _buildActionItem('Announcement', Icons.campaign_rounded, () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const SuperAdminNotificationSenderScreen(),
              ),
            );
          }, Colors.red),
        ],
      ),
    );
  }

  Widget _buildActionItem(String title, IconData icon, VoidCallback onTap, Color iconColor) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: iconColor.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 28, color: iconColor),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  // --- SETTINGS TAB ---
  Widget _buildSettingsTab(AppLocalizations l10n) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
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
