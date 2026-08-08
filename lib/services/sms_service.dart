import 'package:dio/dio.dart';
import 'dart:developer';

class SmsService {
  // TODO: Replace with your actual MiMSMS credentials
  static const String _apiKey = "YOUR_API_KEY";
  static const String _userName = "your@email.com";
  static const String _senderName = "YourSenderID";

  Future<bool> sendBulkSms(List<String> phoneNumbers, String message) async {
    if (phoneNumbers.isEmpty || message.isEmpty) return false;

    try {
      final dio = Dio();
      final response = await dio.post(
        'https://api.mimsms.com/api/V2/OneToMany',
        data: {
          "apiKey": _apiKey,
          "userName": _userName,
          "senderName": _senderName,
          "message": message,
          "smsData": phoneNumbers.map((num) => {"mobNumber": num}).toList(),
        },
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        log('Bulk SMS sent successfully: ${response.data}');
        return true;
      } else {
        log('Failed to send Bulk SMS: ${response.statusCode} - ${response.data}');
        return false;
      }
    } catch (e) {
      log("SMS Send Error: $e");
      return false;
    }
  }
}
