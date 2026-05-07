import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:smart_school/configs/route_generator.dart';
import 'package:smart_school/core/theme/app_colors.dart';
import 'package:smart_school/l10n/app_localizations.dart';
import 'package:smart_school/models/user_model.dart';

import '../../../auth/providers/auth_provider.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _isEditing = false;
  late TextEditingController _nameController;
  late TextEditingController _phoneController;

  @override
  void initState() {
    super.initState();
    final user = context.read<AuthNotifier>().user;
    _nameController = TextEditingController(text: user?.name);
    _phoneController = TextEditingController(text: user?.phone);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  void _handleUpdate() async {
    final auth = context.read<AuthNotifier>();
    final success = await auth.updateProfile(
      name: _nameController.text.trim(),
      phone: _phoneController.text.trim(),
    );

    if (success && mounted) {
      setState(() => _isEditing = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Profile updated successfully'),
          backgroundColor: Colors.green,
        ),
      );
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(auth.error ?? 'Failed to update profile'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthNotifier>();
    final user = authProvider.user;
    final l10n = AppLocalizations.of(context)!;

    if (user == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    // Format the creation date
    String memberSince = 'N/A';
    if (user.createdAt != null) {
      memberSince = DateFormat('MMMM dd, yyyy').format(user.createdAt!);
    }

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          _buildSliverAppBar(context, user, authProvider.isLoading),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 24),

                  // Status & Badge Section
                  _buildStatusSection(context, user),
                  const SizedBox(height: 32),

                  // Information Sections
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildSectionHeader(l10n.personalInformation),
                      TextButton.icon(
                        onPressed: () {
                          if (_isEditing) {
                            _handleUpdate();
                          } else {
                            setState(() => _isEditing = true);
                          }
                        },
                        icon: Icon(
                          _isEditing
                              ? Icons.check_circle_rounded
                              : Icons.edit_rounded,
                          size: 18,
                        ),
                        label: Text(_isEditing ? 'Save' : 'Edit'),
                        style: TextButton.styleFrom(
                          foregroundColor: _isEditing
                              ? Colors.green
                              : AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                  _buildInfoCard(context, [
                    _buildInfoTile(
                      context,
                      icon: Icons.person_outline_rounded,
                      label: 'Full Name',
                      value: user.name,
                      isEditable: true,
                      controller: _nameController,
                    ),
                    _buildInfoTile(
                      context,
                      icon: Icons.email_outlined,
                      label: 'Email Address',
                      value: user.email,
                      isCopyable: true,
                    ),
                    _buildInfoTile(
                      context,
                      icon: Icons.phone_android_rounded,
                      label: 'Phone Number',
                      value: user.phone ?? 'N/A',
                      isEditable: true,
                      controller: _phoneController,
                    ),
                  ]),

                  const SizedBox(height: 24),
                  _buildSectionHeader(l10n.organizationalDetails),
                  _buildInfoCard(context, [
                    _buildInfoTile(
                      context,
                      icon: Icons.school_outlined,
                      label: 'School Name',
                      value: user.school?.name ?? 'N/A',
                    ),
                    _buildInfoTile(
                      context,
                      icon: Icons.school_outlined,
                      label: 'School Email',
                      value: user.school?.email ?? 'N/A',
                      isCopyable: true,
                    ),
                    _buildInfoTile(
                      context,
                      icon: Icons.school_outlined,
                      label: 'School Phone',
                      value: user.school?.phone ?? 'N/A',
                      isCopyable: true,
                    ),
                    _buildInfoTile(
                      context,
                      icon: Icons.school_outlined,
                      label: 'School Address',
                      value: user.school?.address ?? 'N/A',
                    ),
                    _buildInfoTile(
                      context,
                      icon: Icons.admin_panel_settings_outlined,
                      label: 'Account Role',
                      value: user.role.name.toUpperCase(),
                    ),
                    if (user.rollNumber != null && user.rollNumber!.isNotEmpty)
                      _buildInfoTile(
                        context,
                        icon: Icons.format_list_numbered_rounded,
                        label: 'Roll Number',
                        value: user.rollNumber!,
                      ),
                    if (user.designation != null &&
                        user.designation!.isNotEmpty)
                      _buildInfoTile(
                        context,
                        icon: Icons.badge_outlined,
                        label: 'Designation',
                        value: user.designation!,
                      ),
                  ]),

                  const SizedBox(height: 24),
                  _buildSectionHeader(l10n.security),
                  _buildInfoCard(context, [
                    _buildInteractiveTile(
                      context,
                      icon: Icons.lock_reset_rounded,
                      label: l10n.changePassword,
                      subtitle: l10n.securityDescription,
                      onTap: () => Navigator.pushNamed(
                        context,
                        RouteGenerator.changePasswordRoute,
                      ),
                    ),
                  ]),

                  const SizedBox(height: 24),
                  _buildSectionHeader(l10n.accountMetadata),
                  _buildInfoCard(context, [
                    _buildInfoTile(
                      context,
                      icon: Icons.calendar_today_rounded,
                      label: l10n.memberSince,
                      value: memberSince,
                    ),
                  ]),
                  //
                  // const SizedBox(height: 32),
                  // _buildLogoutButton(context),
                  const SizedBox(height: 48),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSliverAppBar(BuildContext context, User user, bool isLoading) {
    print(user.role.name.toLowerCase());
    final theme = Theme.of(context);
    return SliverAppBar(
      expandedHeight: 240,
      pinned: true,
      stretch: true,
      backgroundColor: user.role.name.toLowerCase()=="admin"?AppColors.primaryAdmin: theme.primaryColor,
      foregroundColor: AppColors.white,
      flexibleSpace: FlexibleSpaceBar(
        stretchModes: const [StretchMode.zoomBackground],
        background:  Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(height: 40),
            Stack(
              children: [
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                  child: CircleAvatar(
                    radius: 50,
                    backgroundColor: theme.primaryColor.withOpacity(0.1),
                    child: Icon(
                      Icons.person,
                      size: 60,
                      color: theme.primaryColor,
                    ),
                  ),
                ),
                if (isLoading)
                  const Positioned.fill(
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              user.name,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              user.email,
              style: TextStyle(
                color: Colors.white.withOpacity(0.9),
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: Colors.grey[500],
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _buildInfoCard(BuildContext context, List<Widget> children) {
    return Card(child: Column(children: children));
  }

  Widget _buildInfoTile(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
    bool isCopyable = false,
    bool isEditable = false,
    TextEditingController? controller,
  }) {
    return Card(
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColor.withOpacity(0.08),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 20, color: Theme.of(context).primaryColor),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey[500],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                if (_isEditing && isEditable && controller != null)
                  TextField(
                    controller: controller,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1E293B),
                    ),
                    decoration: const InputDecoration(
                      isDense: true,
                      contentPadding: EdgeInsets.symmetric(vertical: 4),
                      border: InputBorder.none,
                    ),
                  )
                else
                  Text(
                    value,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
              ],
            ),
          ),
          if (isCopyable)
            IconButton(
              icon: Icon(Icons.copy_rounded, size: 18, color: Colors.grey[400]),
              onPressed: () {
                Clipboard.setData(ClipboardData(text: value));
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('$label copied to clipboard'),
                    duration: const Duration(seconds: 1),
                  ),
                );
              },
            ),
        ],
      ),
    );
  }

  Widget _buildInteractiveTile(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor.withOpacity(0.08),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                icon,
                size: 20,
                color: Theme.of(context).primaryColor,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1E293B),
                    ),
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              size: 20,
              color: Colors.grey[400],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusSection(BuildContext context, User user) {
    final bool isActive = user.isActive ?? false;
    final l10n = AppLocalizations.of(context)!;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: (isActive ? Colors.green : Colors.red).withOpacity(0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: (isActive ? Colors.green : Colors.red).withOpacity(0.1),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: isActive ? Colors.green : Colors.red,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 12),
          Text(
            isActive ? 'Account Active' : 'Account Inactive',
            style: TextStyle(
              color: isActive ? Colors.green[700] : Colors.red[700],
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
          const Spacer(),
          Text(
            l10n.verifiedUser,
            style: TextStyle(
              color: Colors.grey[500],
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLogoutButton(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: () => _showLogoutDialog(context),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.white,
          foregroundColor: Colors.red,
          elevation: 0,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: Color(0xFFFEE2E2), width: 1.5),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.logout_rounded, size: 20),
            SizedBox(width: 8),
            Text(
              l10n.signOut,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }

  void _showLogoutDialog(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(l10n.signOut),
        content: Text(l10n.signOutConfirmation),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              l10n.keepSignedIn,
              style: TextStyle(color: Colors.grey[600]),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              context.read<AuthNotifier>().logout();
            },
            child: Text(
              l10n.confirmSignOut,
              style: const TextStyle(
                color: Colors.red,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
