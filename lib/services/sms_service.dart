import 'dart:developer';

import 'package:dio/dio.dart';

class SmsService {
  // TODO: Replace with your actual MiMSMS credentials
  static const String _apiKey = "C55AX924Q4H13M3";
  static const String _userName = "masihur96@gmail.com";
  static const String _senderName = "8809617634017";

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
        final responseData = response.data;
        if (responseData != null &&
            responseData is Map &&
            responseData['statusCode'] != 200) {
          log(
            'API Error: ${responseData['status'] ?? 'Unknown Error'} - $responseData',
          );
          return false;
        }
        log('Bulk SMS sent successfully: ${response.data}');
        return true;
      } else {
        log(
          'Failed to send Bulk SMS: ${response.statusCode} - ${response.data}',
        );
        return false;
      }
    } catch (e) {
      log("SMS Send Error: $e");
      return false;
    }
  }
}
