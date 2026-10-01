import json

en_file = 'lib/l10n/app_en.arb'
bn_file = 'lib/l10n/app_bn.arb'
login_file = 'lib/features/auth/presntation/views/login_screen.dart'
reg_file = 'lib/features/auth/presntation/views/register_screen.dart'

with open(en_file, 'r', encoding='utf-8') as f:
    en_data = json.load(f)
with open(bn_file, 'r', encoding='utf-8') as f:
    bn_data = json.load(f)

new_keys = {
    'pleaseEnterYourEmailOrPhoneNumber': ('Please enter your email or phone number', 'অনুগ্রহ করে আপনার ইমেল বা ফোন নম্বর লিখুন'),
    'pleaseEnterAValidEmailOrPhoneNumber': ('Please enter a valid email or phone number', 'অনুগ্রহ করে একটি বৈধ ইমেল বা ফোন নম্বর লিখুন'),
    'accountInactive': ('Account Inactive', 'অ্যাকাউন্ট নিষ্ক্রিয়'),
    'accountInactiveMessage': ('Your account is currently inactive. Please communicate with your principal or administrator for assistance.', 'আপনার অ্যাকাউন্ট বর্তমানে নিষ্ক্রিয়। সহায়তার জন্য অনুগ্রহ করে আপনার অধ্যক্ষ বা প্রশাসকের সাথে যোগাযোগ করুন।'),
    'schoolInactive': ('School Inactive', 'স্কুল নিষ্ক্রিয়'),
    'schoolInactiveMessage': ('Your school account is currently inactive. Please communicate with SchoolCare support for assistance.', 'আপনার স্কুল অ্যাকাউন্ট বর্তমানে নিষ্ক্রিয়। সহায়তার জন্য অনুগ্রহ করে স্কুলকেয়ার সাপোর্টের সাথে যোগাযোগ করুন।'),
    'biometricCredentialsExpired': ('Biometric credentials expired. Please log in manually.', 'বায়োমেট্রিক শংসাপত্রগুলির মেয়াদ শেষ হয়ে গেছে। অনুগ্রহ করে ম্যানুয়ালি লগ ইন করুন।'),
    'schoolcareDigitalCampus': ('SCHOOLCARE DIGITAL CAMPUS', 'স্কুলকেয়ার ডিজিটাল ক্যাম্পাস'),
    'welcomeBack': ('Welcome Back', 'স্বাগতম'),
    'signInToManageYourSchool': ('Sign in to manage your school and academic workspace.', 'আপনার স্কুল এবং একাডেমিক কাজের জায়গা পরিচালনা করতে সাইন ইন করুন।'),
    'emailOrPhoneNumber': ('Email or Phone Number', 'ইমেল বা ফোন নম্বর'),
    'dontHaveAnAccount': ("Don't have an account?", "কোনো অ্যাকাউন্ট নেই?"),
    'registerNow': ('Register Now', 'এখন নিবন্ধন করুন'),
    'alreadyRegistered': ('Already registered?', 'ইতিমধ্যে নিবন্ধিত?'),
}

for key, val in new_keys.items():
    if key not in en_data:
        en_data[key] = val[0]
        bn_data[key] = val[1]

with open(en_file, 'w', encoding='utf-8') as f:
    json.dump(en_data, f, ensure_ascii=False, indent=2)
with open(bn_file, 'w', encoding='utf-8') as f:
    json.dump(bn_data, f, ensure_ascii=False, indent=2)

def replace_in_file(filepath, replacements):
    with open(filepath, 'r', encoding='utf-8') as f:
        content = f.read()
    
    # make sure import exists
    import_stmt = "import 'package:smart_school/l10n/app_localizations.dart';\n"
    if 'app_localizations.dart' not in content:
        idx = content.find("import 'package:provider/provider.dart';")
        if idx != -1:
            idx = content.find('\n', idx)
            content = content[:idx+1] + import_stmt + content[idx+1:]
            
    for old, new in replacements:
        content = content.replace(old, new)
        
    with open(filepath, 'w', encoding='utf-8') as f:
        f.write(content)

# Note: Context for validators in StatefulWidgets is typically `context` if inside a State class, 
# wait, wait! The validators like `_validateEmailOrPhone` do NOT take a `BuildContext` parameter.
# Wait, `_validateEmailOrPhone` is a method inside `_LoginScreenState`. 
# Inside a State class, `context` is accessible as a property! So `AppLocalizations.of(context)!` is valid!

login_replacements = [
    ("'Please enter your email or phone number'", "AppLocalizations.of(context)!.pleaseEnterYourEmailOrPhoneNumber"),
    ("'Please enter a valid email address'", "AppLocalizations.of(context)!.pleaseEnterAValidEmailAddress"),
    ("'Please enter a valid phone number'", "AppLocalizations.of(context)!.pleaseEnterAValidPhoneNumber"),
    ("'Please enter a valid email or phone number'", "AppLocalizations.of(context)!.pleaseEnterAValidEmailOrPhoneNumber"),
    ("'Please enter your password'", "AppLocalizations.of(context)!.pleaseEnterYourPassword"),
    ("'Account Inactive'", "AppLocalizations.of(context)!.accountInactive"),
    ("'Your account is currently inactive. Please communicate with your principal or administrator for assistance.'", "AppLocalizations.of(context)!.accountInactiveMessage"),
    ("'School Inactive'", "AppLocalizations.of(context)!.schoolInactive"),
    ("'Your school account is currently inactive. Please communicate with SchoolCare support for assistance.'", "AppLocalizations.of(context)!.schoolInactiveMessage"),
    ("'Biometric credentials expired. Please log in manually.'", "AppLocalizations.of(context)!.biometricCredentialsExpired"),
    ("'SCHOOLCARE DIGITAL CAMPUS'", "AppLocalizations.of(context)!.schoolcareDigitalCampus"),
    ("'Welcome Back'", "AppLocalizations.of(context)!.welcomeBack"),
    ("'Sign in to manage your school and academic workspace.'", "AppLocalizations.of(context)!.signInToManageYourSchool"),
    ("'Email or Phone Number'", "AppLocalizations.of(context)!.emailOrPhoneNumber"),
    ("'Password'", "AppLocalizations.of(context)!.password"),
    ("'LOG IN'", "AppLocalizations.of(context)!.logIn.toUpperCase()"),
    ("\"Don't have an account?\"", "AppLocalizations.of(context)!.dontHaveAnAccount"),
    ("'Register Now'", "AppLocalizations.of(context)!.registerNow"),
    # Fix potential const text
    ("const Text(\n                            'SCHOOLCARE DIGITAL CAMPUS'", "Text(\n                            AppLocalizations.of(context)!.schoolcareDigitalCampus"),
    ("const Text(\n                          'Welcome Back'", "Text(\n                          AppLocalizations.of(context)!.welcomeBack"),
    ("const Text(\n                          'Sign in to manage your school and academic workspace.'", "Text(\n                          AppLocalizations.of(context)!.signInToManageYourSchool"),
    ("const Text(\n                          \"Don't have an account?\"", "Text(\n                          AppLocalizations.of(context)!.dontHaveAnAccount"),
    ("const Text(\n                            'Register Now'", "Text(\n                            AppLocalizations.of(context)!.registerNow"),
]

replace_in_file(login_file, login_replacements)

reg_replacements = [
    ('\"Already registered?\"', "AppLocalizations.of(context)!.alreadyRegistered"),
    ("const Text(\n                        \"Already registered?\"", "Text(\n                        AppLocalizations.of(context)!.alreadyRegistered"),
]

replace_in_file(reg_file, reg_replacements)

# Now just write a short python script to remove leftover const before Text widgets containing AppLocalizations
print("Done patching dart files.")
