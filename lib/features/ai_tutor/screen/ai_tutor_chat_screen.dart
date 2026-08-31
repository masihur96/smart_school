import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:smart_school/core/theme/app_colors.dart';
import 'package:smart_school/features/ai_tutor/model/chat_model.dart';
import 'package:smart_school/features/ai_tutor/service/chat_repository.dart';
import 'package:smart_school/l10n/app_localizations.dart';
import 'package:speech_to_text/speech_to_text.dart';

class ChatMessage {
  final String text;
  final bool isUser;
  bool isSpeaking;

  ChatMessage({
    required this.text,
    required this.isUser,
    this.isSpeaking = false,
  });
}

class AiTutorChatScreen extends StatefulWidget {
  const AiTutorChatScreen({super.key});

  @override
  State<AiTutorChatScreen> createState() => _AiTutorChatScreenState();
}

class _AiTutorChatScreenState extends State<AiTutorChatScreen> {
  final ChatRepository _chatRepository = ChatRepository();
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final SpeechToText _speechToText = SpeechToText();
  final FlutterTts _flutterTts = FlutterTts();

  final List<ChatMessage> messages = [];
  bool _isLoading = false;
  bool _isListening = false;
  bool _autoSpeak = true;

  bool _speechEnabled = false;

  @override
  void initState() {
    super.initState();
    _initializeSpeech();
    _flutterTts.setCompletionHandler(() {
      if (mounted) {
        setState(() {
          for (var msg in messages) {
            msg.isSpeaking = false;
          }
        });
      }
    });

    // Initializing the chatbot persona silently
    createChat(
      "Act as a friendly and professional assistant Tutor.",
      isInitial: true,
    );
  }

  @override
  void dispose() {
    _flutterTts.stop();
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _initializeSpeech() async {
    _speechEnabled = await _speechToText.initialize(
      onStatus: (status) {
        debugPrint("Current status: $status");
        _onSpeechStatus(status);
      },
      onError: (error) {
        debugPrint('Speech recognition error: $error');
        _stopListening();
      },
    );
    await _flutterTts.setLanguage("bn-BD");
    await _flutterTts.setSpeechRate(0.5); // Adjust speech rate
    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _startListening() async {
    // Stop any ongoing TTS before listening
    await _stopSpeaking();

    try {
      // Re-initialize if not enabled (e.g. if permissions were just granted)
      if (!_speechEnabled) {
        _speechEnabled = await _speechToText.initialize(
          onStatus: (status) {
            debugPrint("Current status: $status");
            _onSpeechStatus(status);
          },
          onError: (error) {
            debugPrint('Speech recognition error: $error');
            _stopListening();
          },
        );
      }

      if (_speechEnabled) {
        setState(() => _isListening = true);

        await _speechToText.listen(
          onResult: (result) {
            setState(() {
              _controller.text = result.recognizedWords;
            });
          },
          listenFor: const Duration(seconds: 30),
          pauseFor: const Duration(seconds: 3),
          localeId: 'bn_BD',
        );
      } else {
        debugPrint('Speech recognition not available');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Speech recognition is not available on this device.',
              ),
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('Error initializing speech recognition: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error initializing speech recognition: $e')),
        );
      }
    }
  }

  void _onSpeechStatus(String status) {
    debugPrint("Speech status: $status");

    if (status.toLowerCase().contains('done') ||
        status.toLowerCase().contains('notlistening')) {
      if (_isListening) {
        _stopListening();

        // Automatically send the message when speech recognition is done
        Future.delayed(const Duration(milliseconds: 300), () {
          if (_controller.text.trim().isNotEmpty) {
            _onSendPressed();
          }
        });
      }
    }
  }

  Future<void> _stopListening() async {
    if (_isListening) {
      await _speechToText.stop();
      if (mounted) {
        setState(() => _isListening = false);
      }
    }
  }

  Future<void> _speak(ChatMessage message) async {
    await _stopSpeaking(); // Stop any current speech

    setState(() {
      message.isSpeaking = true;
    });

    // Clean text to remove markdown and emojis for better human-like speech
    String cleanText = message.text.replaceAll(RegExp(r'[*#_~`]'), '');
    cleanText = cleanText.replaceAll(
        RegExp(
            r'[\u{1F600}-\u{1F64F}\u{1F300}-\u{1F5FF}\u{1F680}-\u{1F6FF}\u{1F900}-\u{1F9FF}\u{2600}-\u{26FF}\u{2700}-\u{27BF}]',
            unicode: true),
        '');

    var result = await _flutterTts.speak(cleanText);
    if (result == 0) {
      // If speech failed to start immediately
      setState(() {
        message.isSpeaking = false;
      });
    }
  }

  Future<void> _stopSpeaking() async {
    await _flutterTts.stop();
    setState(() {
      for (var msg in messages) {
        msg.isSpeaking = false;
      }
    });
  }

  void createChat(String text, {bool isInitial = false}) async {
    if (!isInitial) {
      setState(() {
        _isLoading = true;
        messages.add(ChatMessage(text: text, isUser: true));
      });
    } else {
      setState(() {
        _isLoading = true;
      });
    }
    _scrollToBottom();

    // Stop speaking when user sends a new message
    await _stopSpeaking();

String prompt =
        """
You are a friendly AI Tutor for school and college students.

Instructions:
- Always answer in Bengali.
- Explain topics in very simple language.
- Use real-life examples.
- Teach step-by-step.
- If the answer contains calculations, show all steps.
- If the student makes a mistake, politely correct it.
- At the end, provide a short summary.
- Do NOT use emojis, markdown formatting (like ** for bold or # for headings), or special symbols. Respond with clean plain text only.

Student Question:
$text
""";

    ChatBootModel? chatBootModelData = await _chatRepository.createChat(
      text: prompt,
    );

    if (mounted) {
      if (chatBootModelData != null && chatBootModelData.choices.isNotEmpty) {
        String botResponse =
            chatBootModelData.choices.first.message?.content ??
            "দুঃখিত, আমি বুঝতে পারিনি।";
        ChatMessage botMessage = ChatMessage(text: botResponse, isUser: false);

        setState(() {
          messages.add(botMessage);
          _isLoading = false;
        });

        _scrollToBottom();

        if (_autoSpeak) {
          _speak(botMessage);
        }
      } else {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to get a response. Please try again.'),
          ),
        );
      }
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _retryLastMessage() async {
    if (messages.isNotEmpty) {
      // Find the last user message
      var userMessages = messages.where((msg) => msg.isUser).toList();
      if (userMessages.isNotEmpty) {
        String lastUserMessageText = userMessages.last.text;

        // Clear the last bot response if it's the very last message in the list
        if (!messages.last.isUser) {
          setState(() {
            messages.removeLast();
          });
        }
        createChat(lastUserMessageText);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(
        elevation: 0,

        backgroundColor: AppColors.primaryTeacher,
        foregroundColor: AppColors.white,
        leading: BackButton(color: AppColors.white),
        title: Row(
          children: [
            CircleAvatar(
              backgroundColor: Theme.of(context).primaryColor.withOpacity(0.1),
              child: Icon(Icons.school, color: AppColors.white),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "AI Tutor",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                      color: AppColors.white,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    "Online",
                    style: TextStyle(color: AppColors.white, fontSize: 12),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          Row(
            children: [
              Icon(
                _autoSpeak ? Icons.volume_up : Icons.volume_off,
                size: 20,
                color: _autoSpeak ? AppColors.white : Colors.grey,
              ),
              Switch(
                value: _autoSpeak,
                onChanged: (value) {
                  setState(() {
                    _autoSpeak = value;
                  });
                  if (!value) _stopSpeaking();
                },
                activeColor: AppColors.white,
              ),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _isLoading ? null : _retryLastMessage,
            tooltip: 'Retry last message',
            color: AppColors.white,
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              itemCount: messages.length,
              itemBuilder: (context, index) {
                final message = messages[index];
                return _buildMessageBubble(message: message);
              },
            ),
          ),
          if (_isLoading) _buildTypingIndicator(),
          _buildMessageInput(),
        ],
      ),
    );
  }

  Widget _buildTypingIndicator() {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(left: 16, bottom: 8),
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
            bottomRight: Radius.circular(20),
            bottomLeft: Radius.circular(4),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 5,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 40,
              height: 20,
              child: Center(
                child: LinearProgressIndicator(
                  backgroundColor: Colors.grey[200],
                  valueColor: AlwaysStoppedAnimation<Color>(
                    Theme.of(context).primaryColor,
                  ),
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageInput() {
    return Container(
      decoration: const BoxDecoration(
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 10,
            offset: Offset(0, -2),
          ),
        ],
      ),
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 12,
        bottom: 12 + MediaQuery.of(context).padding.bottom,
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: () async {
              if (_isListening) {
                await _stopListening();
              } else {
                await _startListening();
              }
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: _isListening
                    ? Colors.red.withOpacity(0.1)
                    : Colors.grey[100],
                shape: BoxShape.circle,
              ),
              child: Icon(
                _isListening ? Icons.mic : Icons.mic_none,
                color: _isListening ? Colors.red : Colors.grey[700],
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              controller: _controller,
              textCapitalization: TextCapitalization.sentences,
              decoration: InputDecoration(
                hintText: _isListening ? "Listening..." : "Type a message...",
                hintStyle: TextStyle(color: Colors.grey[400]),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Colors.grey[100],
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
              ),
              onSubmitted: (_) => _onSendPressed(),
            ),
          ),
          const SizedBox(width: 8),
          Container(
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColor,
              shape: BoxShape.circle,
            ),
            child: IconButton(
              icon: const Icon(Icons.send, color: Colors.white, size: 20),
              onPressed: _isLoading ? null : _onSendPressed,
            ),
          ),
        ],
      ),
    );
  }

  void _onSendPressed() {
    final text = _controller.text.trim();
    if (text.isNotEmpty) {
      createChat(text);
      _controller.clear();
      _stopListening(); // Stop listening if user manually sends
    }
  }

  Widget _buildMessageBubble({required ChatMessage message}) {
    bool isUser = message.isUser;
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        margin: const EdgeInsets.symmetric(vertical: 6),
        decoration: BoxDecoration(
          color: isUser ? Theme.of(context).primaryColor : Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(20),
            topRight: const Radius.circular(20),
            bottomLeft: isUser
                ? const Radius.circular(20)
                : const Radius.circular(4),
            bottomRight: isUser
                ? const Radius.circular(4)
                : const Radius.circular(20),
          ),
          boxShadow: [
            if (!isUser)
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 5,
                offset: const Offset(0, 2),
              ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Flexible(
                  child: Text(
                    message.text,
                    style: TextStyle(
                      fontSize: 15,
                      height: 1.4,
                      color: isUser ? Colors.white : Colors.black87,
                    ),
                  ),
                ),
                if (!isUser) ...[
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: () {
                      if (message.isSpeaking) {
                        _stopSpeaking();
                      } else {
                        _speak(message);
                      }
                    },
                    child: Icon(
                      message.isSpeaking
                          ? Icons.stop_circle_outlined
                          : Icons.volume_up_outlined,
                      size: 20,
                      color: message.isSpeaking
                          ? Theme.of(context).primaryColor
                          : Colors.grey[500],
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}
