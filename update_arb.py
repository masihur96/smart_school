import json

def update_arb(file_path, new_keys):
    with open(file_path, 'r', encoding='utf-8') as f:
        data = json.load(f)
    
    data.update(new_keys)
    
    with open(file_path, 'w', encoding='utf-8') as f:
        json.dump(data, f, indent=2, ensure_ascii=False)

en_keys = {
  "paymentDetails": "Payment Details",
  "paymentInstructions": "Please pay {amount} using one of the methods below. Then enter your Transaction ID to submit the request.",
  "@paymentInstructions": {
    "placeholders": {
      "amount": {
        "type": "String"
      }
    }
  },
  "selectPaymentMethod": "Select Payment Method",
  "sendMoneyTo": "Send Money To ({method})",
  "@sendMoneyTo": {
    "placeholders": {
      "method": {
        "type": "String"
      }
    }
  },
  "amount": "Amount",
  "transactionId": "Transaction ID",
  "enterTransactionId": "Enter Transaction ID",
  "pleaseEnterTransactionId": "Please enter Transaction ID",
  "submitPayment": "Submit Payment",
  "paymentSubmittedSuccessfully": "Payment submitted successfully!"
}

bn_keys = {
  "paymentDetails": "পেমেন্ট বিস্তারিত",
  "paymentInstructions": "দয়া করে নিচের যেকোনো একটি মাধ্যম ব্যবহার করে {amount} প্রদান করুন। তারপর অনুরোধটি জমা দিতে আপনার ট্রানজ্যাকশন আইডি লিখুন।",
  "@paymentInstructions": {
    "placeholders": {
      "amount": {
        "type": "String"
      }
    }
  },
  "selectPaymentMethod": "পেমেন্ট মাধ্যম নির্বাচন করুন",
  "sendMoneyTo": "টাকা পাঠান ({method})",
  "@sendMoneyTo": {
    "placeholders": {
      "method": {
        "type": "String"
      }
    }
  },
  "amount": "পরিমাণ",
  "transactionId": "ট্রানজ্যাকশন আইডি",
  "enterTransactionId": "ট্রানজ্যাকশন আইডি লিখুন",
  "pleaseEnterTransactionId": "দয়া করে ট্রানজ্যাকশন আইডি লিখুন",
  "submitPayment": "পেমেন্ট জমা দিন",
  "paymentSubmittedSuccessfully": "পেমেন্ট সফলভাবে জমা দেওয়া হয়েছে!"
}

update_arb('lib/l10n/app_en.arb', en_keys)
update_arb('lib/l10n/app_bn.arb', bn_keys)
