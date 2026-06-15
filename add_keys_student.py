import json

def add_keys(file_path, new_keys):
    with open(file_path, 'r', encoding='utf-8') as f:
        data = json.load(f)
    data.update(new_keys)
    with open(file_path, 'w', encoding='utf-8') as f:
        json.dump(data, f, ensure_ascii=False, indent=2)

en_keys = {
    "searchByName": "Search by name",
    "status": "Status",
    "titleLabel": "Title",
    "messageLabel": "Message",
    "limitReached": "Limit Reached",
    "studentLimitReached": "You have reached your student limit ({count} / {max}).\n\nUpgrade your plan to add more students.",
    "@studentLimitReached": {
        "placeholders": {
            "count": {"type": "int"},
            "max": {"type": "int"}
        }
    },
    "upgradePlan": "Upgrade Plan"
}

bn_keys = {
    "searchByName": "নাম দিয়ে খুঁজুন",
    "status": "স্ট্যাটাস",
    "titleLabel": "শিরোনাম",
    "messageLabel": "বার্তা",
    "limitReached": "সীমা অতিক্রম করেছে",
    "studentLimitReached": "আপনি আপনার শিক্ষার্থীর সীমায় পৌঁছে গেছেন ({count} / {max})।\n\nআরও শিক্ষার্থী যোগ করতে আপনার প্ল্যান আপগ্রেড করুন।",
    "upgradePlan": "প্ল্যান আপগ্রেড করুন"
}

add_keys('lib/l10n/app_en.arb', en_keys)
add_keys('lib/l10n/app_bn.arb', bn_keys)
