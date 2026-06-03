class ChatBootModel {
  ChatBootModel({
    required this.id,
    required this.object,
    required this.created,
    required this.model,
    required this.choices,
    required this.usage,
  });

  final String id;
  final String object;
  final int created;
  final String model;
  final List<Choice> choices;
  final Usage? usage;

  ChatBootModel copyWith({
    String? id,
    String? object,
    int? created,
    String? model,
    List<Choice>? choices,
    Usage? usage,
  }) {
    return ChatBootModel(
      id: id ?? this.id,
      object: object ?? this.object,
      created: created ?? this.created,
      model: model ?? this.model,
      choices: choices ?? this.choices,
      usage: usage ?? this.usage,
    );
  }

  factory ChatBootModel.fromJson(Map<String, dynamic> json){
    return ChatBootModel(
      id: json["id"] ?? "",
      object: json["object"] ?? "",
      created: json["created"] ?? 0,
      model: json["model"] ?? "",
      choices: json["choices"] == null ? [] : List<Choice>.from(json["choices"]!.map((x) => Choice.fromJson(x))),
      usage: json["usage"] == null ? null : Usage.fromJson(json["usage"]),
    );
  }

  Map<String, dynamic> toJson() => {
    "id": id,
    "object": object,
    "created": created,
    "model": model,
    "choices": choices.map((x) => x.toJson()).toList(),
    "usage": usage?.toJson(),
  };

  @override
  String toString(){
    return "$id, $object, $created, $model, $choices, $usage, ";
  }
}

class Choice {
  Choice({
    required this.index,
    required this.message,
    required this.finishReason,
  });

  final int index;
  final Message? message;
  final String finishReason;

  Choice copyWith({
    int? index,
    Message? message,
    String? finishReason,
  }) {
    return Choice(
      index: index ?? this.index,
      message: message ?? this.message,
      finishReason: finishReason ?? this.finishReason,
    );
  }

  factory Choice.fromJson(Map<String, dynamic> json){
    return Choice(
      index: json["index"] ?? 0,
      message: json["message"] == null ? null : Message.fromJson(json["message"]),
      finishReason: json["finish_reason"] ?? "",
    );
  }

  Map<String, dynamic> toJson() => {
    "index": index,
    "message": message?.toJson(),
    "finish_reason": finishReason,
  };

  @override
  String toString(){
    return "$index, $message, $finishReason, ";
  }
}

class Message {
  Message({
    required this.role,
    required this.toolCalls,
    required this.content,
  });

  final String role;
  final dynamic toolCalls;
  final String content;

  Message copyWith({
    String? role,
    dynamic toolCalls,
    String? content,
  }) {
    return Message(
      role: role ?? this.role,
      toolCalls: toolCalls ?? this.toolCalls,
      content: content ?? this.content,
    );
  }

  factory Message.fromJson(Map<String, dynamic> json){
    return Message(
      role: json["role"] ?? "",
      toolCalls: json["tool_calls"],
      content: json["content"] ?? "",
    );
  }

  Map<String, dynamic> toJson() => {
    "role": role,
    "tool_calls": toolCalls,
    "content": content,
  };

  @override
  String toString(){
    return "$role, $toolCalls, $content, ";
  }
}

class Usage {
  Usage({
    required this.promptTokens,
    required this.totalTokens,
    required this.completionTokens,
  });

  final int promptTokens;
  final int totalTokens;
  final int completionTokens;

  Usage copyWith({
    int? promptTokens,
    int? totalTokens,
    int? completionTokens,
  }) {
    return Usage(
      promptTokens: promptTokens ?? this.promptTokens,
      totalTokens: totalTokens ?? this.totalTokens,
      completionTokens: completionTokens ?? this.completionTokens,
    );
  }

  factory Usage.fromJson(Map<String, dynamic> json){
    return Usage(
      promptTokens: json["prompt_tokens"] ?? 0,
      totalTokens: json["total_tokens"] ?? 0,
      completionTokens: json["completion_tokens"] ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
    "prompt_tokens": promptTokens,
    "total_tokens": totalTokens,
    "completion_tokens": completionTokens,
  };

  @override
  String toString(){
    return "$promptTokens, $totalTokens, $completionTokens, ";
  }
}
