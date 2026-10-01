import os
import re
import json

def to_camel_case(s):
    # Remove non-alphanumeric and split
    s = re.sub(r'[^a-zA-Z0-9]+', ' ', s).strip()
    parts = s.split()
    if not parts:
        return 'emptyString'
    return parts[0].lower() + ''.join(p.capitalize() for p in parts[1:])

en_arb_path = 'lib/l10n/app_en.arb'
bn_arb_path = 'lib/l10n/app_bn.arb'

with open(en_arb_path, 'r', encoding='utf-8') as f:
    en_data = json.load(f)
with open(bn_arb_path, 'r', encoding='utf-8') as f:
    bn_data = json.load(f)

# Find all dart files
dart_files = []
for root, _, files in os.walk('lib'):
    for file in files:
        if file.endswith('.dart'):
            dart_files.append(os.path.join(root, file))

# Regex to match Text('LiteralString'
# We'll only match single or double quotes without $ or \ inside
pattern = re.compile(r"Text\(\s*(['\"])([^$'\"]+)\1")

fixes_made = 0

for file_path in dart_files:
    with open(file_path, 'r', encoding='utf-8') as f:
        content = f.read()

    matches = pattern.findall(content)
    if not matches:
        continue

    new_content = content
    needs_import = False

    for quote, text in matches:
        # Ignore empty strings or very short things like punctuation
        if len(text.strip()) < 2:
            continue
            
        # Ignore if it looks like a date format or just numbers
        if re.match(r'^[0-9:\-\., /]+$', text):
            continue

        key = to_camel_case(text)
        
        # Make sure key is unique if there's a collision with different text
        original_key = key
        counter = 1
        while key in en_data and en_data[key] != text:
            key = f"{original_key}{counter}"
            counter += 1

        # Add to en
        en_data[key] = text
        # Add to bn if not exists (fallback to en)
        if key not in bn_data:
            bn_data[key] = text

        # Replace in dart file
        # We need to replace Text('text' with Text(AppLocalizations.of(context)!.key
        old_str = f"Text({quote}{text}{quote}"
        new_str = f"Text(AppLocalizations.of(context)!.{key}"
        if old_str in new_content:
            new_content = new_content.replace(old_str, new_str)
            needs_import = True
            fixes_made += 1

    if needs_import:
        # Check if import exists
        import_stmt = "import 'package:flutter_gen/gen_l10n/app_localizations.dart';"
        if import_stmt not in new_content:
            # Add after the first import, or at top
            first_import = new_content.find('import ')
            if first_import != -1:
                # Find end of that line
                end_line = new_content.find('\n', first_import)
                new_content = new_content[:end_line+1] + import_stmt + '\n' + new_content[end_line+1:]
            else:
                new_content = import_stmt + '\n' + new_content

        with open(file_path, 'w', encoding='utf-8') as f:
            f.write(new_content)

if fixes_made > 0:
    with open(en_arb_path, 'w', encoding='utf-8') as f:
        json.dump(en_data, f, ensure_ascii=False, indent=2)
    with open(bn_arb_path, 'w', encoding='utf-8') as f:
        json.dump(bn_data, f, ensure_ascii=False, indent=2)
    print(f"Fixed {fixes_made} hardcoded strings across dart files.")
else:
    print("No simple hardcoded strings found to fix.")
