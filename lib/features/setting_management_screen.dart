import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:smart_school/configs/route_generator.dart';
import 'package:smart_school/features/admin/providers/settings_provider.dart';
import 'package:smart_school/features/auth/providers/auth_provider.dart';
import 'package:smart_school/features/admin/screens/admin_pricing_plan_screen.dart';
import 'package:smart_school/models/user_model.dart';
import 'package:smart_school/l10n/app_localizations.dart';

class SettingManagementScreen extends StatefulWidget {
  const SettingManagementScreen({super.key});

  @override
  State<SettingManagementScreen> createState() =>
      _SettingManagementScreenState();
}

class _SettingManagementScreenState extends State<SettingManagementScreen> {
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    final settings = context.watch<SettingsProvider>();
    final authNotifier = context.watch<AuthNotifier>();

    return Scaffold(
      appBar: AppBar(title: Text(l10n.settingManagement)),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          // Theme Section
          _buildSectionHeader(l10n.theme, theme),
          _buildSettingTile(
            icon: _getThemeIcon(settings.themeMode),
            title: l10n.theme,
            subtitle: _getThemeName(settings.themeMode, l10n),
            theme: theme,
            onTap: () => _showThemePicker(context, settings, l10n),
          ),
          const SizedBox(height: 24),

          // Language Section
          _buildSectionHeader(l10n.language, theme),
          _buildSettingTile(
            icon: Icons.language,
            title: "English / বাংলা",
            subtitle: settings.locale.languageCode == 'en'
                ? 'English'
                : 'বাংলা',
            theme: theme,
            onTap: () {
              final newLocale = settings.locale.languageCode == 'en'
                  ? const Locale('bn')
                  : const Locale('en');
              settings.setLocale(newLocale);
            },
          ),
          const SizedBox(height: 24),

          // Notifications Section
          _buildSectionHeader(l10n.notifications, theme),
          _buildSettingTile(
            icon: Icons.assignment_outlined,
            title: l10n.homework,
            theme: theme,
            trailing: Switch(
              value: settings.isHomeworkNotifyEnabled,
              onChanged: (value) {
                settings.setHomeworkNotify(value);
              },
            ),
          ),
          _buildSettingTile(
            icon: Icons.how_to_reg_outlined,
            title: l10n.attendance,
            theme: theme,
            trailing: Switch(
              value: settings.isAttendanceNotifyEnabled,
              onChanged: (value) {
                settings.setAttendanceNotify(value);
              },
            ),
          ),
          const SizedBox(height: 24),

          // Security Section
          _buildSectionHeader(l10n.security, theme),
          _buildSettingTile(
            icon: Icons.lock_outline,
            title: l10n.changePassword,
            onTap: () => Navigator.pushNamed(
              context,
              RouteGenerator.changePasswordRoute,
            ),
            theme: theme,
            isAction: true,
          ),
          const SizedBox(height: 24),

          // Admin Subscription Section
          if (authNotifier.user?.role == UserRole.admin) ...[
            _buildSectionHeader(l10n.systemSubscription, theme),
            _buildSettingTile(
              icon: Icons.card_membership,
              title: l10n.subscriptionDetails,
              subtitle: l10n.systemPlanManagement,
              theme: theme,
              isAction: true,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const AdminPricingPlanScreen(),
                  ),
                );
              },
            ),
            const SizedBox(height: 32),
          ],

          // Logout Button
          // ElevatedButton.icon(
          //   onPressed: () => authNotifier.logout(),
          //   icon: const Icon(Icons.logout),
          //   label: Text(l10n.logout),
          //   style: ElevatedButton.styleFrom(
          //     backgroundColor: theme.colorScheme.errorContainer,
          //     foregroundColor: theme.colorScheme.error,
          //   ),
          // ),
        ],
      ),
    );
  }

  IconData _getThemeIcon(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.light:
        return Icons.light_mode;
      case ThemeMode.dark:
        return Icons.dark_mode;
      case ThemeMode.system:
        return Icons.brightness_auto;
    }
  }

  String _getThemeName(ThemeMode mode, AppLocalizations l10n) {
    switch (mode) {
      case ThemeMode.light:
        return l10n.lightMode;
      case ThemeMode.dark:
        return l10n.darkMode;
      case ThemeMode.system:
        return l10n.systemDefault;
    }
  }

  void _showThemePicker(
    BuildContext context,
    SettingsProvider settings,
    AppLocalizations l10n,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.theme),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildThemeOption(
              context,
              ThemeMode.light,
              l10n.lightMode,
              Icons.light_mode,
              settings,
            ),
            _buildThemeOption(
              context,
              ThemeMode.dark,
              l10n.darkMode,
              Icons.dark_mode,
              settings,
            ),
            _buildThemeOption(
              context,
              ThemeMode.system,
              l10n.systemDefault,
              Icons.brightness_auto,
              settings,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildThemeOption(
    BuildContext context,
    ThemeMode mode,
    String title,
    IconData icon,
    SettingsProvider settings,
  ) {
    return ListTile(
      leading: Icon(icon),
      title: Text(title),
      trailing: settings.themeMode == mode
          ? Icon(Icons.check, color: Theme.of(context).colorScheme.primary)
          : null,
      onTap: () {
        settings.setThemeMode(mode);
        Navigator.pop(context);
      },
    );
  }

  Widget _buildSectionHeader(String title, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(
        title.toUpperCase(),
        style: theme.textTheme.labelLarge?.copyWith(
          color: theme.colorScheme.primary,
          letterSpacing: 1.2,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildSettingTile({
    required IconData icon,
    required String title,
    String? subtitle,
    VoidCallback? onTap,
    required ThemeData theme,
    bool isAction = false,
    Widget? trailing,
  }) {
    return Card(
      child: ListTile(
        leading: Icon(icon, color: theme.colorScheme.onSurfaceVariant),
        title: Text(title, style: theme.textTheme.titleMedium),
        subtitle: subtitle != null ? Text(subtitle) : null,
        trailing:
            trailing ?? (isAction ? const Icon(Icons.chevron_right) : null),
        onTap: onTap,
      ),
    );
  }
}
