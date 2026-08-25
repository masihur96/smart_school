import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:smart_school/core/utils/image_compress_utils.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:smart_school/configs/route_generator.dart';
import 'package:smart_school/core/theme/app_colors.dart';
import 'package:smart_school/l10n/app_localizations.dart';
import 'package:smart_school/models/user_model.dart';

import '../../../auth/providers/auth_provider.dart';
import 'package:cached_network_image/cached_network_image.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _isEditing = false;
  late TextEditingController _nameController;
  late TextEditingController _phoneController;
  
  bool _isEditingSchool = false;
  late TextEditingController _schoolNameController;
  late TextEditingController _schoolPhoneController;
  late TextEditingController _schoolAddressController;
  
  File? _imageFile;

  @override
  void initState() {
    super.initState();
    final user = context.read<AuthNotifier>().user;
    _nameController = TextEditingController(text: user?.name);
    _phoneController = TextEditingController(text: user?.phone);
    
    _schoolNameController = TextEditingController(text: user?.school?.name);
    _schoolPhoneController = TextEditingController(text: user?.school?.phone);
    _schoolAddressController = TextEditingController(text: user?.school?.address);

    // Fetch admins for the organization section
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AuthNotifier>().fetchAdmins();
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _schoolNameController.dispose();
    _schoolPhoneController.dispose();
    _schoolAddressController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: Text(AppLocalizations.of(context)!.galleryOption),
              onTap: () => Navigator.pop(context, ImageSource.gallery),
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: Text(AppLocalizations.of(context)!.cameraOption),
              onTap: () => Navigator.pop(context, ImageSource.camera),
            ),
          ],
        ),
      ),
    );

    if (source != null) {
      final pickedFile = await picker.pickImage(
        source: source,
        imageQuality: 85,
      );
      if (pickedFile != null) {
        // Compress to under 50 KB before upload
        final File compressed = await ImageCompressUtils.compressToUnder50KB(
          File(pickedFile.path),
        );
        setState(() {
          _imageFile = compressed;
        });

        final auth = context.read<AuthNotifier>();
        final success = await auth.uploadProfileImage(compressed);

        if (success && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(AppLocalizations.of(context)!.profileImageUpdated),
              backgroundColor: Colors.green,
            ),
          );
        } else if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(auth.error ?? 'Failed to update profile image'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  Future<void> _pickSchoolImage() async {
    final picker = ImagePicker();
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: Text(AppLocalizations.of(context)!.galleryOption),
              onTap: () => Navigator.pop(context, ImageSource.gallery),
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: Text(AppLocalizations.of(context)!.cameraOption),
              onTap: () => Navigator.pop(context, ImageSource.camera),
            ),
          ],
        ),
      ),
    );

    if (source != null) {
      final pickedFile = await picker.pickImage(
        source: source,
        imageQuality: 85,
      );
      if (pickedFile != null) {
        // Compress to under 50 KB before upload
        final File compressed = await ImageCompressUtils.compressToUnder50KB(
          File(pickedFile.path),
        );
        final auth = context.read<AuthNotifier>();
        final success = await auth.uploadSchoolProfileImage(compressed);

        if (success && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('School avatar updated successfully'),
              backgroundColor: Colors.green,
            ),
          );
        } else if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(auth.error ?? 'Failed to update school avatar'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
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
        SnackBar(
          content: Text(AppLocalizations.of(context)!.profileUpdated),
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

  void _handleSchoolUpdate() async {
    final auth = context.read<AuthNotifier>();
    final success = await auth.updateSchoolProfile(
      name: _schoolNameController.text.trim(),
      address: _schoolAddressController.text.trim(),
      avatar: auth.user?.school?.avatar,
    );

    if (success && mounted) {
      setState(() => _isEditingSchool = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('School profile updated successfully'),
          backgroundColor: Colors.green,
        ),
      );
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(auth.error ?? 'Failed to update school profile'),
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
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildSectionHeader(l10n.organizationalDetails),
                      if (user.role == UserRole.admin)
                        TextButton.icon(
                          onPressed: () {
                            if (_isEditingSchool) {
                              _handleSchoolUpdate();
                            } else {
                              setState(() => _isEditingSchool = true);
                            }
                          },
                          icon: Icon(
                            _isEditingSchool
                                ? Icons.check_circle_rounded
                                : Icons.edit_rounded,
                            size: 18,
                          ),
                          label: Text(_isEditingSchool ? 'Save' : 'Edit'),
                          style: TextButton.styleFrom(
                            foregroundColor: _isEditingSchool
                                ? Colors.green
                                : AppColors.primary,
                          ),
                        ),
                    ],
                  ),
                  _buildInfoCard(context, [
                    _buildInfoTile(
                      context,
                      icon: Icons.school_outlined,
                      label: 'School Name',
                      value: user.school?.name ?? 'N/A',
                      isEditable: true,
                      useSchoolEditState: true,
                      controller: _schoolNameController,
                      avatarUrl: user.school?.avatar.isNotEmpty == true 
                          ? user.school!.avatar 
                          : null,
                      onAvatarTap: _isEditingSchool ? _pickSchoolImage : null,
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
                      isEditable: true,
                      useSchoolEditState: true,
                      controller: _schoolAddressController,
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

                  // const SizedBox(height: 24),
                  // _buildSectionHeader(l10n.security),
                  // _buildInfoCard(context, [
                  //   _buildInteractiveTile(
                  //     context,
                  //     icon: Icons.lock_reset_rounded,
                  //     label: l10n.changePassword,
                  //     subtitle: l10n.securityDescription,
                  //     onTap: () => Navigator.pushNamed(
                  //       context,
                  //       RouteGenerator.changePasswordRoute,
                  //     ),
                  //   ),
                  // ]),

                  const SizedBox(height: 24),
                  _buildSectionHeader('Organization Admins'),
                  _buildAdminsSection(context, authProvider),

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

                  // Admin-only: Danger Zone
                  if (user.role == UserRole.admin) ...
                  [
                    const SizedBox(height: 24),
                    _buildSectionHeader('Danger Zone'),
                    _buildDangerCard(context),
                  ],
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
    final theme = Theme.of(context);
    return SliverAppBar(
      expandedHeight: 240,
      pinned: true,
      stretch: true,
      backgroundColor: user.role.name.toLowerCase() == "admin"
          ? AppColors.primaryAdmin
          : user.role.name.toLowerCase() == "teacher"
          ? AppColors.primaryTeacher
          : user.role.name.toLowerCase() == "student"
          ? AppColors.primaryStudent
          : theme.primaryColor,
      foregroundColor: AppColors.white,
      flexibleSpace: FlexibleSpaceBar(
        stretchModes: const [StretchMode.zoomBackground],
        background: Column(
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
                  child: GestureDetector(
                    onTap: () {

                    },
                    child: CircleAvatar(
                      radius: 50,
                      backgroundColor: theme.primaryColor.withOpacity(0.1),
                      backgroundImage: _imageFile != null
                          ? FileImage(_imageFile!)
                          : (user.avatar != null
                                    ? CachedNetworkImageProvider(
                                        user.avatar!,
                                        cacheKey: user.avatar!.split('?').first,
                                      )
                                    : null)
                                as ImageProvider?,
                      child: (_imageFile == null && user.avatar == null)
                          ? Icon(
                              Icons.person,
                              size: 60,
                              color: theme.primaryColor,
                            )
                          : null,
                    ),
                  ),
                ),
                if (user.role == UserRole.admin)
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: GestureDetector(
                      onTap: _pickImage,
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: theme.primaryColor,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                        child: const Icon(
                          Icons.camera_alt,
                          color: Colors.white,
                          size: 16,
                        ),
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
    bool useSchoolEditState = false,
    TextEditingController? controller,
    String? avatarUrl,
    VoidCallback? onAvatarTap,
  }) {
    return Card(
      child: Row(
        children: [
          GestureDetector(
            onTap: onAvatarTap,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  padding: avatarUrl != null ? EdgeInsets.zero : const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Theme.of(context).primaryColor.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: avatarUrl != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: Image.network(
                            avatarUrl,
                            width: 36,
                            height: 36,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Padding(
                              padding: const EdgeInsets.all(8),
                              child: Icon(icon, size: 20),
                            ),
                          ),
                        )
                      : Icon(icon, size: 20),
                ),
                if (onAvatarTap != null)
                  Positioned(
                    bottom: -4,
                    right: -4,
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        color: Theme.of(context).primaryColor,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 1.5),
                      ),
                      child: const Icon(
                        Icons.camera_alt,
                        size: 10,
                        color: Colors.white,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500),
                ),
                if ((useSchoolEditState ? _isEditingSchool : _isEditing) && isEditable && controller != null)
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
                    content: Text(AppLocalizations.of(context)!.copiedToClipboard(label)),
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
              child: Icon(icon, size: 20),
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

  Widget _buildAdminsSection(BuildContext context, AuthNotifier authProvider) {
    if (authProvider.isLoadingAdmins) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Center(child: CircularProgressIndicator()),
        ),
      );
    }

    final admins = authProvider.admins;

    if (admins.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Icon(Icons.admin_panel_settings_outlined, color: Colors.grey[400], size: 20),
              const SizedBox(width: 12),
              Text(
                'No admins found',
                style: TextStyle(color: Colors.grey[500], fontSize: 14),
              ),
            ],
          ),
        ),
      );
    }

    final isCurrentUserAdmin = authProvider.user?.role == UserRole.admin;

    return Card(
      child: Column(
        children: admins
            .map((admin) => _buildAdminTile(context, admin, isCurrentUserAdmin))
            .toList(),
      ),
    );
  }

  Widget _buildAdminTile(BuildContext context, User admin, bool canChangeRole) {
    final bool isActive = admin.isActive ?? false;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          // Avatar
          CircleAvatar(
            radius: 22,
            backgroundColor: AppColors.primary.withOpacity(0.1),
            backgroundImage: (admin.avatar != null && admin.avatar!.isNotEmpty)
                ? CachedNetworkImageProvider(
                    admin.avatar!,
                    cacheKey: admin.avatar!.split('?').first,
                  )
                : null,
            child: (admin.avatar == null || admin.avatar!.isEmpty)
                ? Text(
                    admin.name.isNotEmpty ? admin.name[0].toUpperCase() : '?',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                      fontSize: 16,
                    ),
                  )
                : null,
          ),
          const SizedBox(width: 12),
          // Name & email
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  admin.name,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  admin.email,
                  style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          // Active badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: (isActive ? Colors.green : Colors.red).withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              isActive ? 'Active' : 'Inactive',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: isActive ? Colors.green[700] : Colors.red[700],
              ),
            ),
          ),
          // Change role button (admin only)
          if (canChangeRole) ...[
            const SizedBox(width: 4),
            Tooltip(
              message: 'Change to Teacher',
              child: IconButton(
                icon: const Icon(Icons.swap_horiz_rounded, size: 20),
                color: Colors.orange,
                onPressed: () => _showChangeRoleDialog(context, admin),
              ),
            ),
          ],
        ],
      ),
    );
  }

  void _showChangeRoleDialog(BuildContext context, User admin) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: const [
            Icon(Icons.swap_horiz_rounded, color: Colors.orange, size: 24),
            SizedBox(width: 8),
            Text(
              'Change Role',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        content: RichText(
          text: TextSpan(
            style: const TextStyle(fontSize: 14, color: Colors.black87, height: 1.5),
            children: [
              const TextSpan(text: 'Change '),
              TextSpan(
                text: admin.name,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const TextSpan(
                text: '\'s role from ',
              ),
              const TextSpan(
                text: 'Admin',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.deepPurple,
                ),
              ),
              const TextSpan(text: ' to '),
              const TextSpan(
                text: 'Teacher',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.orange,
                ),
              ),
              const TextSpan(text: '?\n\nThis will remove their admin privileges.'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancel', style: TextStyle(color: Colors.grey[600])),
          ),
          ElevatedButton.icon(
            icon: const Icon(Icons.check_rounded, size: 18),
            label: const Text('Confirm'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            onPressed: () async {
              Navigator.pop(ctx);
              final auth = context.read<AuthNotifier>();
              final messenger = ScaffoldMessenger.of(context);
              final success = await auth.changeUserRole(admin.id, 'teacher');
              if (mounted) {
                messenger.showSnackBar(
                  SnackBar(
                    content: Text(
                      success
                          ? '${admin.name} is now a Teacher'
                          : auth.error ?? 'Failed to change role',
                    ),
                    backgroundColor: success ? Colors.green : Colors.red,
                  ),
                );
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildDangerCard(BuildContext context) {
    return Card(
      color: Colors.red.shade50,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.red.shade200, width: 1),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _showDeleteAccountDialog(context),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.delete_forever_rounded,
                  size: 22,
                  color: Colors.red,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Delete Account',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: Colors.red,
                      ),
                    ),
                    Text(
                      'Permanently remove your account and all data.',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.red.shade400,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                size: 20,
                color: Colors.red.shade300,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showDeleteAccountDialog(BuildContext context) {
    final confirmController = TextEditingController();
    bool confirmed = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) {
          return AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            title: Row(
              children: const [
                Icon(Icons.warning_amber_rounded, color: Colors.red, size: 26),
                SizedBox(width: 8),
                Text(
                  'Delete Account',
                  style: TextStyle(
                    color: Colors.red,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'This action is permanent and cannot be undone. '
                  'All your data will be deleted from our servers.',
                  style: TextStyle(fontSize: 14),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Type DELETE to confirm:',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: confirmController,
                  onChanged: (v) =>
                      setModalState(() => confirmed = v.trim() == 'DELETE'),
                  decoration: InputDecoration(
                    hintText: 'DELETE',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(
                        color: Colors.red,
                        width: 1.5,
                      ),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: Text(
                  'Cancel',
                  style: TextStyle(color: Colors.grey[600]),
                ),
              ),
              ElevatedButton(
                onPressed: confirmed
                    ? () async {
                        Navigator.pop(ctx);
                        final auth = context.read<AuthNotifier>();
                        final success = await auth.deleteAccount();
                        if (!success && mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                auth.error ?? 'Failed to delete account',
                              ),
                              backgroundColor: Colors.red,
                            ),
                          );
                        }
                      }
                    : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: Colors.red.shade100,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: const Text(
                  'Delete Account',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ],
          );
        },
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
