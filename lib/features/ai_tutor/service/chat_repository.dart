// Method to create a new notice
import 'dart:developer';

import 'package:smart_school/configs/network/data_provider.dart';
import 'package:smart_school/features/ai_tutor/model/chat_model.dart';

class ChatRepository {
  final DataProvider _dataProvider = DataProvider();
  Future<ChatBootModel?> createChat({required String text}) async {
    ChatBootModel? chatBootModel;

    // Prepare data for POST request
    dynamic data = {
      "model": "open-mistral-7b",
      "messages": [
        {"role": "user", "content": text},
      ],
    };

    // Request header
    dynamic header = {
      "Authorization": "Bearer nE7emk3UaZdiHf3hoAS0lhz4s6MG1WNV",
    };

    try {
      // Perform the POST request
      var response = await _dataProvider.performRequest(
        "POST",
        "https://api.mistral.ai/v1/chat/completions",
        data: data,
        header: header,
      );
      log("Create Notice status Code: ${response!.statusCode}");

      if (response.statusCode == 200) {
        var data = response.data;
        chatBootModel = ChatBootModel.fromJson(data);
      } else {
        log("Failed to create notice: ${response.statusMessage}");
      }
    } catch (exception, stackTrace) {
      // Log exception and capture it using Sentry for error monitoring

      log("Exception: $exception");
      return data;
    }

    return chatBootModel;
  }
}
