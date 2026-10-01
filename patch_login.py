import os

filepath = 'lib/features/auth/presntation/views/login_screen.dart'
with open(filepath, 'r', encoding='utf-8') as f:
    content = f.read()

import_stmt = "import 'package:smart_school/features/admin/providers/settings_provider.dart';\n"
if 'settings_provider.dart' not in content:
    idx = content.find("import 'package:provider/provider.dart';")
    if idx != -1:
        idx = content.find('\n', idx)
        content = content[:idx+1] + import_stmt + content[idx+1:]

func = """
  Widget _buildLanguageDropdown(bool isDark) {
    final settings = context.watch<SettingsProvider>();
    return PopupMenuButton<String>(
      icon: Icon(Icons.language, color: isDark ? Colors.white : Colors.black87),
      onSelected: (String langCode) {
        settings.setLocale(Locale(langCode));
      },
      itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
        const PopupMenuItem<String>(
          value: 'en',
          child: Text('English'),
        ),
        const PopupMenuItem<String>(
          value: 'bn',
          child: Text('বাংলা'),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
"""
content = content.replace('  @override\n  Widget build(BuildContext context) {', func)

old_body = "      body: SafeArea(\n        child: Center("
new_body = "      body: SafeArea(\n        child: Stack(\n          children: [\n            Center("
content = content.replace(old_body, new_body)

old_end = "            ),\n          ),\n        ),\n      ),\n    );\n  }\n}"
new_end = "            ),\n          ),\n            ),\n            Positioned(\n              top: 8,\n              right: 8,\n              child: _buildLanguageDropdown(isDark),\n            ),\n          ],\n        ),\n      ),\n    );\n  }\n}"

content = content.replace(old_end, new_end)

with open(filepath, 'w', encoding='utf-8') as f:
    f.write(content)
print('Login screen patched')
