import json

def add_keys(file_path, new_keys):
    with open(file_path, 'r', encoding='utf-8') as f:
        data = json.load(f)
    data.update(new_keys)
    with open(file_path, 'w', encoding='utf-8') as f:
        json.dump(data, f, ensure_ascii=False, indent=2)

en_keys = {
    "publishStatus": "Publish Status",
    "publishedOption": "Published",
    "unpublishedOption": "Unpublished",
    "noExamsFound": "No exams found",
    "assignmentCountLabel": "{count} Assignment(s)",
    "@assignmentCountLabel": {
        "placeholders": {
            "count": {"type": "int"}
        }
    },
    "egLabel": "e.g."
}

bn_keys = {
    "publishStatus": "প্রকাশের অবস্থা",
    "publishedOption": "প্রকাশিত",
    "unpublishedOption": "অপ্রকাশিত",
    "noExamsFound": "কোন পরীক্ষা পাওয়া যায়নি",
    "assignmentCountLabel": "{count} টি অ্যাসাইনমেন্ট",
    "egLabel": "যেমন"
}

add_keys('lib/l10n/app_en.arb', en_keys)
add_keys('lib/l10n/app_bn.arb', bn_keys)
