import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:smart_school/features/auth/providers/auth_provider.dart';
import 'package:smart_school/core/widgets/app_drawer.dart';

class SuperAdminDashboardScreen extends StatefulWidget {
  const SuperAdminDashboardScreen({super.key});

  @override
  State<SuperAdminDashboardScreen> createState() => _SuperAdminDashboardScreenState();
}

class _SuperAdminDashboardScreenState extends State<SuperAdminDashboardScreen> {
  int _selectedIndex = 0;

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  String _getTitle() {
    switch (_selectedIndex) {
      case 0: return 'System Overview';
      case 1: return 'School Management';
      case 2: return 'System Config';
      default: return 'Super Admin';
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthNotifier>().user;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: Text(_getTitle()),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      drawer: const AppDrawer(),
      body: IndexedStack(
        index: _selectedIndex,
        children: [
          _buildOverviewTab(user),
          _buildSchoolsTab(),
          _buildSettingsTab(),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        selectedItemColor: Colors.deepPurple,
        unselectedItemColor: Colors.grey,
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.dashboard), label: 'Overview'),
          BottomNavigationBarItem(icon: Icon(Icons.business), label: 'Schools'),
          BottomNavigationBarItem(icon: Icon(Icons.settings_suggest), label: 'Config'),
        ],
      ),
    );
  }

  // --- OVERVIEW TAB ---
  Widget _buildOverviewTab(user) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildWelcomeHeader(user?.name ?? 'Super Admin'),
          const SizedBox(height: 24),
          _buildStatGrid(),
          const SizedBox(height: 32),
          const Text(
            'Recent System Alerts',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          _buildAlertTile('New School Signed Up: Bright Future Academy', '2 mins ago', Icons.add_business, Colors.green),
          _buildAlertTile('System Maintenance scheduled for midnight', '1 hour ago', Icons.warning_amber, Colors.orange),
          _buildAlertTile('High server load detected on US-East-1', '3 hours ago', Icons.speed, Colors.red),
        ],
      ),
    );
  }

  Widget _buildWelcomeHeader(String name) {
    return Row(
      children: [
        CircleAvatar(
          radius: 30,
          backgroundColor: Colors.deepPurple.withOpacity(0.1),
          child: Text(name[0], style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.deepPurple)),
        ),
        const SizedBox(width: 16),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Welcome,', style: TextStyle(color: Colors.grey[600], fontSize: 14)),
            Text(name, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
          ],
        ),
      ],
    );
  }

  Widget _buildStatGrid() {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      childAspectRatio: 1.4,
      children: [
        _buildStatCard('Schools', '42', Icons.business, Colors.blue),
        _buildStatCard('Active Users', '8.4k', Icons.people, Colors.green),
        _buildStatCard('Server Status', 'Healthy', Icons.dns, Colors.teal),
        _buildStatCard('Daily Rev', '\$1.2k', Icons.monetization_on, Colors.deepPurple),
      ],
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 24),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[500])),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildAlertTile(String title, String time, IconData icon, Color color) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ListTile(
        leading: Icon(icon, color: color),
        title: Text(title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
        subtitle: Text(time, style: const TextStyle(fontSize: 11)),
        trailing: const Icon(Icons.chevron_right, size: 16),
        onTap: () {},
      ),
    );
  }

  // --- SCHOOLS TAB ---
  Widget _buildSchoolsTab() {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Managed Schools', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            ElevatedButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.add, size: 18),
              label: const Text('New School'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.deepPurple,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        _buildSchoolCard('Global International School', 'Active', '1240 Students', 'Premium Plan'),
        _buildSchoolCard('St. Mary High School', 'Active', '850 Students', 'Basic Plan'),
        _buildSchoolCard('Lakeside Academy', 'Suspended', '0 Students', 'Trial Expired'),
        _buildSchoolCard('Oakwood Montessori', 'Trial', '120 Students', 'Free Trial'),
      ],
    );
  }

  Widget _buildSchoolCard(String name, String status, String students, String plan) {
    final statusColor = status == 'Active' ? Colors.green : (status == 'Suspended' ? Colors.red : Colors.orange);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.withOpacity(0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(name, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(color: statusColor.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                child: Text(status, style: TextStyle(color: statusColor, fontSize: 10, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _buildSmallInfo(Icons.people, students),
              const SizedBox(width: 16),
              _buildSmallInfo(Icons.credit_card, plan),
            ],
          ),
          const Divider(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(onPressed: () {}, child: const Text('View Analytics')),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: () {},
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.grey[100],
                  foregroundColor: Colors.black87,
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                child: const Text('Manage'),
              ),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildSmallInfo(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 14, color: Colors.grey[600]),
        const SizedBox(width: 4),
        Text(text, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
      ],
    );
  }

  // --- SETTINGS TAB ---
  Widget _buildSettingsTab() {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        const Text('System Configuration', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        const SizedBox(height: 20),
        _buildSettingToggle('Maintenance Mode', 'Block access for all non-admins', false),
        _buildSettingToggle('Public Registration', 'Allow new schools to register online', true),
        _buildSettingToggle('Global Notifications', 'Enable system-wide broadcast alerts', true),
        _buildSettingToggle('Two-Factor Auth', 'Force 2FA for all administrative roles', false),
        const SizedBox(height: 24),
        const Text('Storage \u0026 Resources', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 16),
        _buildStorageInfo('Database Usage', 0.65),
        const SizedBox(height: 16),
        _buildStorageInfo('File Storage (S3)', 0.42),
        const SizedBox(height: 32),
        ElevatedButton(
          onPressed: () {},
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.redAccent,
            foregroundColor: Colors.white,
            minimumSize: const Size(double.infinity, 50),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          child: const Text('RESTART SYSTEM SERVICES'),
        ),
      ],
    );
  }

  Widget _buildSettingToggle(String title, String subtitle, bool value) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: SwitchListTile(
        title: Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
        subtitle: Text(subtitle, style: const TextStyle(fontSize: 12)),
        value: value,
        onChanged: (val) {},
        activeColor: Colors.deepPurple,
      ),
    );
  }

  Widget _buildStorageInfo(String title, double progress) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(title, style: const TextStyle(fontSize: 14)),
            Text('${(progress * 100).toInt()}%', style: const TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
        const SizedBox(height: 8),
        LinearProgressIndicator(
          value: progress,
          backgroundColor: Colors.grey[200],
          valueColor: AlwaysStoppedAnimation<Color>(progress > 0.8 ? Colors.red : Colors.blue),
          minHeight: 8,
        ),
      ],
    );
  }
}
