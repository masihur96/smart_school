import json

bn_file = 'lib/l10n/app_bn.arb'

with open(bn_file, 'r', encoding='utf-8') as f:
    bn_data = json.load(f)

fixes = {
    'emailOrPhoneNumber': 'ইমেল বা ফোন নম্বর',
    'registerNow': 'এখন নিবন্ধন করুন',
    'createYourAdministratorAccountToRegisterAndManageYourInstitution': 'আপনার প্রতিষ্ঠান নিবন্ধন এবং পরিচালনা করতে আপনার প্রশাসক অ্যাকাউন্ট তৈরি করুন।',
    'continueToSchoolSetup': 'স্কুল সেটআপ চালিয়ে যান',
    'alreadyRegistered': 'ইতিমধ্যে নিবন্ধিত?',
    'logIn': 'লগ ইন',
    'principalRegistration': 'অধ্যক্ষ নিবন্ধন',
    'step1Of2PrincipalAccount': 'ধাপ ১ এর ২ • অধ্যক্ষ অ্যাকাউন্ট',
    'joinSchoolcare': 'স্কুলকেয়ার-এ যোগ দিন',
    'pleaseAcceptTheTermsConditionsAndPrivacyPolicyToProceed': 'এগিয়ে যেতে অনুগ্রহ করে শর্তাবলী এবং গোপনীয়তা নীতি গ্রহণ করুন।',
    'signInToManageYourSchoolAndAcademicWorkspace': 'আপনার স্কুল এবং একাডেমিক কাজের জায়গা পরিচালনা করতে সাইন ইন করুন।',
    'schoolcareDigitalCampus': 'স্কুলকেয়ার ডিজিটাল ক্যাম্পাস'
}

for k, v in fixes.items():
    if k in bn_data:
        bn_data[k] = v

with open(bn_file, 'w', encoding='utf-8') as f:
    json.dump(bn_data, f, ensure_ascii=False, indent=2)

print("Fixed translations in app_bn.arb")
