import os

replacements = {
    'lib/features/teacher/screens/teacher_self_attendance_detail_screen.dart': [
        ("'Unknown'", "AppLocalizations.of(context)!.unknown")
    ],
    'lib/features/teacher/screens/teacher_dashboard_screen.dart': [
        ("'Unknown'", "AppLocalizations.of(context)!.unknown")
    ],
    'lib/features/teacher/screens/schedule_class_details.dart': [
        ("'No students found in\\n${classRoom.name}'", "AppLocalizations.of(context)!.noStudentsFoundIn(classRoom.name)")
    ],
    'lib/features/teacher/screens/teacher_exam_details_screen.dart': [
        ("Text('Class $c')", "Text(AppLocalizations.of(context)!.classWithParam(c.toString()))")
    ],
    'lib/features/teacher/screens/homework_details_screen.dart': [
        ("Text(isBulk ? 'Bulk Update' : 'Update')", "Text(isBulk ? AppLocalizations.of(context)!.bulkUpdate : AppLocalizations.of(context)!.update)")
    ]
}

for filepath, reps in replacements.items():
    with open(filepath, 'r', encoding='utf-8') as f:
        content = f.read()
    
    new_content = content
    for old, new in reps:
        new_content = new_content.replace(old, new)
        
    if new_content != content:
        # ensure import is present
        import_stmt = "import 'package:smart_school/l10n/app_localizations.dart';"
        if import_stmt not in new_content:
            first_import = new_content.find('import ')
            if first_import != -1:
                end_line = new_content.find('\n', first_import)
                new_content = new_content[:end_line+1] + import_stmt + '\n' + new_content[end_line+1:]
        
        with open(filepath, 'w', encoding='utf-8') as f:
            f.write(new_content)
        print(f'Replaced in {filepath}')
