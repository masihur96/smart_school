import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:smart_school/configs/route_generator.dart';
import 'package:smart_school/features/admin/providers/settings_provider.dart';
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

    return Scaffold(
      appBar: AppBar(title: Text(l10n.settingManagement)),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          // Theme Section
          _buildSectionHeader(l10n.theme, theme),
          _buildSettingTile(
            icon: settings.themeMode == ThemeMode.dark
                ? Icons.dark_mode
                : Icons.light_mode,
            title: "l10n.",
            theme: theme,
            trailing: Switch(
              value: settings.themeMode == ThemeMode.dark,
              onChanged: (value) {
                settings.setThemeMode(value ? ThemeMode.dark : ThemeMode.light);
              },
            ),
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
          const SizedBox(height: 32),

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
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: Icon(icon, color: theme.colorScheme.onSurfaceVariant),
        title: Text(title, style: theme.textTheme.titleMedium),
        subtitle: subtitle != null ? Text(subtitle) : null,
        trailing:
            trailing ?? (isAction ? const Icon(Icons.chevron_right) : null),
        onTap: onTap,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}
