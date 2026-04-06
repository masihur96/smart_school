import 'package:flutter/material.dart';
import 'package:teacher_app/core/theme.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Profile'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () {},
          )
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 32),
            const CircleAvatar(
              radius: 60,
              backgroundColor: AppColors.primary,
              child: Icon(Icons.person, size: 60, color: Colors.white),
            ),
            const SizedBox(height: 16),
            Text(
              'Mr. Masihur Rahman',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const Text(
              'Senior Mathematics Teacher',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 16),
            ),
            const SizedBox(height: 32),
            _buildInfoCard(context),
            const SizedBox(height: 24),
            _buildSettingsList(context),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: const Column(
        children: [
          _InfoRow(label: 'Email', value: 'masihur.teacher@school.com'),
          Divider(height: 32),
          _InfoRow(label: 'Employee ID', value: 'EDU-2024-001'),
          Divider(height: 32),
          _InfoRow(label: 'Department', value: 'Science & Mathematics'),
        ],
      ),
    );
  }

  Widget _buildSettingsList(BuildContext context) {
    return Column(
      children: [
        _buildSettingsItem(context, 'Account Settings', Icons.person_outline),
        _buildSettingsItem(context, 'Notifications', Icons.notifications_none),
        _buildSettingsItem(context, 'Attendance Reports', Icons.insert_chart_outlined_rounded),
        _buildSettingsItem(context, 'Help & Support', Icons.help_outline),
        _buildSettingsItem(context, 'Logout', Icons.logout, color: Colors.red),
      ],
    );
  }

  Widget _buildSettingsItem(BuildContext context, String title, IconData icon, {Color? color}) {
    return ListTile(
      leading: Icon(icon, color: color ?? AppColors.textPrimary),
      title: Text(title, style: TextStyle(color: color ?? AppColors.textPrimary, fontWeight: FontWeight.w500)),
      trailing: const Icon(Icons.chevron_right, size: 20),
      onTap: () {},
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(color: AppColors.textSecondary)),
        Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
      ],
    );
  }
}
