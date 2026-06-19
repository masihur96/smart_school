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
      "model": "mistral-large-latest",
      "messages": [
        {"role": "user", "content": text},
      ],
    };

    // Request header
    dynamic header = {
      "Authorization": "Bearer A0b5MHGq230KVhrOvge4omud5BrvQemV",
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

        print(
          "Successfully Created: ${chatBootModel.choices.first.message!.content}",
        );
      } else {
        print("Failed to create notice: ${response.statusMessage}");
      }
    } catch (exception, stackTrace) {
      // Log exception and capture it using Sentry for error monitoring

      print("Exception: $exception");
      return data;
    }

    return chatBootModel;
  }
}
