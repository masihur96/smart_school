import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_zoom_drawer/flutter_zoom_drawer.dart';
import 'package:provider/provider.dart';
import 'package:smart_school/core/widgets/app_drawer.dart';
import 'package:smart_school/core/widgets/notification_icon_button.dart';
import 'package:smart_school/core/widgets/zoomable_avatar.dart';
import 'package:smart_school/features/auth/providers/auth_provider.dart';
import 'package:smart_school/features/profile/presentation/screens/profile_screen.dart';
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

// Brand color for Super Admin
const _kBrand = Color(0xFF1F7A8C);

const _kSurface = Color(0xFFF4F7FA);
const _kCard = Colors.white;

class SuperAdminDashboardScreen extends StatelessWidget {
  const SuperAdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ZoomDrawer(
      controller: ZoomDrawerController(),
      menuScreen: const AppDrawer(),
      mainScreenTapClose: true,
      mainScreen: const SuperAdminDashboardContent(),
      menuBackgroundColor: Colors.grey,
      style: DrawerStyle.defaultStyle,
      androidCloseOnBackTap: true,

      borderRadius: 24.0,
      showShadow: true,
      angle: 0.0,
      openCurve: Curves.fastOutSlowIn,
      closeCurve: Curves.fastOutSlowIn,
      duration: const Duration(milliseconds: 200),
      drawerShadowsBackgroundColor: Colors.grey.shade300,
      slideWidth: MediaQuery.of(context).size.width * 0.65,
    );
  }
}

class SuperAdminDashboardContent extends StatefulWidget {
  const SuperAdminDashboardContent({super.key});

  @override
  State<SuperAdminDashboardContent> createState() =>
      _SuperAdminDashboardContentState();
}

class _SuperAdminDashboardContentState
    extends State<SuperAdminDashboardContent> {
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<SuperAdminDashboardNotifier>().fetchDashboardData();
      context.read<SuperAdminSchoolNotifier>().fetchSchools();
    });
  }

  void _onItemTapped(int index) => setState(() => _selectedIndex = index);



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
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
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
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                child: Text(l10n.yes),
              ),
            ],
          ),
        );
        if (shouldExit == true) SystemNavigator.pop();
      },
      child: Scaffold(
        backgroundColor: _kSurface,
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.menu_rounded, color: Colors.white),
            onPressed: () => ZoomDrawer.of(context)?.toggle(),
          ),
          title: GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ProfileScreen()),
              );
            },
            child: Row(
              children: [
                ZoomableAvatar(
                  imageUrl: user?.avatar,
                  name: user?.name,
                  heroTag:
                  'teacher-dashboard-avatar-${user?.id ?? user?.name ?? 'me'}',
                  radius: 20,
                  backgroundColor: Colors.purple,
                ),
                const SizedBox(width: 15),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.max,
                    children: [
                      Text(
                        user?.name ?? "",
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.white,

                          fontSize: 18,
                        ),
                      ),
                      Text(
                        user?.designation ?? 'System Administrator',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.white70,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          elevation: 0,
          leadingWidth: 40,
          backgroundColor: _kBrand,
          actions: [
            NotificationIconButton(color: _kBrand),
            GestureDetector(
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SystemStatusScreen()),
              ),
              child: Icon(Icons.health_and_safety_outlined),
            ),
            const SizedBox(width: 8),
          ],
        ),
        body: IndexedStack(
          index: _selectedIndex,
          children: [
            _buildOverviewTab(user, l10n),
            SuperAdminSchoolScreen(),
            _buildSettingsTab(l10n),
          ],
        ),
        bottomNavigationBar: _buildBottomNav(l10n),
      ),
    );
  }

  Widget _buildBottomNav(AppLocalizations l10n) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.07),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.white,
        selectedItemColor: _kBrand,
        unselectedItemColor: Colors.grey.shade400,
        elevation: 0,
        selectedLabelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 11),
        unselectedLabelStyle: const TextStyle(fontSize: 11),
        items: [
          BottomNavigationBarItem(
            icon: const Icon(Icons.dashboard_outlined),
            activeIcon: const Icon(Icons.dashboard_rounded),
            label: l10n.overview,
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.business_outlined),
            activeIcon: const Icon(Icons.business_rounded),
            label: l10n.schools,
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.tune_outlined),
            activeIcon: const Icon(Icons.tune_rounded),
            label: l10n.config,
          ),
        ],
      ),
    );
  }

  // ─────────────────────────── OVERVIEW TAB ───────────────────────────

  Widget _buildOverviewTab(User? user, AppLocalizations l10n) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [

          Padding(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _sectionLabel('SYSTEM PERFORMANCE'),
                const SizedBox(height: 14),
                _buildStatGrid(l10n),
                const SizedBox(height: 28),
                _sectionLabel('QUICK ACTIONS'),
                const SizedBox(height: 14),
                _buildQuickActionsList(l10n),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionLabel(String text) {
    return Text(
      text,
      style: TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w800,
        letterSpacing: 1.4,
        color: Colors.grey.shade500,
      ),
    );
  }


  Widget _buildStatGrid(AppLocalizations l10n) {
    final notifier = context.watch<SuperAdminDashboardNotifier>();
    final data = notifier.dashboardData;
    final isLoading = notifier.isLoading;

    if (isLoading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 30),
          child: CircularProgressIndicator(color: _kBrand),
        ),
      );
    }

    final stats = [
      _StatItem(label: l10n.totalSchools, value: '${data.totalSchools}', icon: Icons.business_rounded, color: const Color(0xFF3B82F6), sub: 'Registered'),
      _StatItem(label: l10n.totalStudents, value: '${data.totalStudents}', icon: Icons.people_alt_rounded, color: const Color(0xFF8B5CF6), sub: 'Enrolled'),
      _StatItem(label: l10n.totalTeachers, value: '${data.totalTeachers}', icon: Icons.school_rounded, color: const Color(0xFF10B981), sub: 'Active'),
      _StatItem(label: l10n.activeSubscription, value: '${data.activeSubscriptions}', icon: Icons.verified_rounded, color: const Color(0xFFF59E0B), sub: 'Running'),
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 14,
        mainAxisSpacing: 14,
        childAspectRatio: 1,
      ),
      itemCount: stats.length,
      itemBuilder: (_, i) => _buildStatCard(stats[i]),
    );
  }

  Widget _buildStatCard(_StatItem stat) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _kCard,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: stat.color.withOpacity(0.12), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: stat.color.withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: stat.color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(stat.icon, size: 20, color: stat.color),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFF4ADE80).withOpacity(0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  '● Live',
                  style: TextStyle(fontSize: 9, color: Color(0xFF16A34A), fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                stat.value,
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                  color: stat.color,
                  height: 1,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                stat.label,
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF374151)),
              ),
              Text(
                stat.sub,
                style: TextStyle(fontSize: 10, color: Colors.grey.shade400),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionsList(AppLocalizations l10n) {
    final actions = [
      _ActionItem(label: l10n.schools, subtitle: 'Manage registered schools', icon: Icons.add_business_rounded, color: const Color(0xFF3B82F6), onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => SuperAdminSchoolScreen()))),
      _ActionItem(label: l10n.pricing, subtitle: 'Configure subscription plans', icon: Icons.sell_rounded, color: const Color(0xFF8B5CF6), onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => PricingSchoolScreen()))),
      _ActionItem(label: l10n.subscription, subtitle: 'View active subscriptions', icon: Icons.verified_user_rounded, color: const Color(0xFF10B981), onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => SubscriptionScreen()))),
      _ActionItem(label: l10n.backup, subtitle: 'System data & backup', icon: Icons.storage_rounded, color: const Color(0xFFF59E0B), onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => BackupScreen()))),
      _ActionItem(label: 'Announcement', subtitle: 'Broadcast system notification', icon: Icons.campaign_rounded, color: const Color(0xFFEF4444), onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SuperAdminNotificationSenderScreen()))),
    ];

    return Column(
      children: actions.map((a) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: _buildActionTile(a),
      )).toList(),
    );
  }

  Widget _buildActionTile(_ActionItem action) {
    return Material(
      color: _kCard,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: action.onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey.shade100),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.03),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 44, height: 44,
                decoration: BoxDecoration(
                  color: action.color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(action.icon, color: action.color, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(action.label, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Color(0xFF111827))),
                    Text(action.subtitle, style: TextStyle(fontSize: 11, color: Colors.grey.shade500)),
                  ],
                ),
              ),
              Icon(Icons.arrow_forward_ios_rounded, size: 14, color: Colors.grey.shade400),
            ],
          ),
        ),
      ),
    );
  }

  // ─────────────────────────── SETTINGS TAB ───────────────────────────

  Widget _buildSettingsTab(AppLocalizations l10n) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 40),
      physics: const BouncingScrollPhysics(),
      children: [
        Text(l10n.systemConfiguration, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: Color(0xFF111827))),
        const SizedBox(height: 4),
        Text('Manage global behaviors, access control & storage', style: TextStyle(fontSize: 13, color: Colors.grey.shade500)),
        const SizedBox(height: 28),
        _sectionLabel('ACCESS CONTROL'),
        const SizedBox(height: 12),
        _buildToggleCard(l10n.maintenanceMode, 'Block access for all non-admins', Icons.construction_rounded, false, const Color(0xFFEF4444)),
        const SizedBox(height: 10),
        _buildToggleCard('Public Registration', 'Allow new schools to register online', Icons.app_registration_rounded, true, const Color(0xFF10B981)),
        const SizedBox(height: 24),
        _sectionLabel('SECURITY & NOTIFICATIONS'),
        const SizedBox(height: 12),
        _buildToggleCard('Global Notifications', 'Enable system-wide broadcast alerts', Icons.notifications_active_rounded, true, _kBrand),
        const SizedBox(height: 10),
        _buildToggleCard('Two-Factor Auth', 'Force 2FA for all administrative roles', Icons.security_rounded, false, const Color(0xFF8B5CF6)),
        const SizedBox(height: 28),
        _sectionLabel('STORAGE & RESOURCES'),
        const SizedBox(height: 16),
        _buildStorageCard('Database Usage', 'PostgreSQL', 0.65, const Color(0xFF3B82F6)),
        const SizedBox(height: 12),
        _buildStorageCard('File Storage', 'AWS S3', 0.42, const Color(0xFF8B5CF6)),
        const SizedBox(height: 32),
        _buildDangerButton(),
      ],
    );
  }

  Widget _buildToggleCard(String title, String subtitle, IconData icon, bool value, Color color) {
    return Container(
      decoration: BoxDecoration(
        color: _kCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade100),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 8, offset: const Offset(0, 2)),
        ],
      ),
      child: SwitchListTile(
        contentPadding: const EdgeInsets.fromLTRB(14, 6, 14, 6),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        secondary: Container(
          width: 40, height: 40,
          decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
          child: Icon(icon, color: color, size: 20),
        ),
        title: Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Color(0xFF111827))),
        subtitle: Text(subtitle, style: TextStyle(fontSize: 11, color: Colors.grey.shade500)),
        value: value,
        onChanged: (val) {},
        activeColor: color,
      ),
    );
  }

  Widget _buildStorageCard(String title, String subtitle, double progress, Color color) {
    final pct = (progress * 100).toInt();
    final statusColor = pct >= 80 ? const Color(0xFFEF4444) : pct >= 60 ? const Color(0xFFF59E0B) : const Color(0xFF10B981);

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: _kCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade100),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 8, offset: const Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Color(0xFF111827))),
                  Text(subtitle, style: TextStyle(fontSize: 11, color: Colors.grey.shade400)),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(color: statusColor.withOpacity(0.1), borderRadius: BorderRadius.circular(20)),
                child: Text('$pct% used', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: statusColor)),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 8,
              backgroundColor: color.withOpacity(0.1),
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDangerButton() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.red.withOpacity(0.2), blurRadius: 16, offset: const Offset(0, 6))],
      ),
      child: ElevatedButton.icon(
        onPressed: () {},
        icon: const Icon(Icons.restart_alt_rounded),
        label: const Text('RESTART SYSTEM SERVICES', style: TextStyle(fontWeight: FontWeight.w800, letterSpacing: 0.8)),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFDC2626),
          foregroundColor: Colors.white,
          minimumSize: const Size(double.infinity, 54),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          elevation: 0,
        ),
      ),
    );
  }
}

// ─────────────────────────── Data helpers ───────────────────────────

class _StatItem {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  final String sub;
  const _StatItem({required this.label, required this.value, required this.icon, required this.color, required this.sub});
}

class _ActionItem {
  final String label;
  final String subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  const _ActionItem({required this.label, required this.subtitle, required this.icon, required this.color, required this.onTap});
}
