import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:smart_school/features/ai_tutor/model/chat_model.dart';
import 'package:smart_school/features/ai_tutor/service/chat_repository.dart';
import 'package:smart_school/l10n/app_localizations.dart';
import 'package:speech_to_text/speech_to_text.dart';



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

  final List<String> messages = [];
  bool _isLoading = false;
  bool _isListening = false;

  @override
  void initState() {
    super.initState();
    _initializeSpeech();
    createChat("Act as an assistant doctor. ${_controller.text}");
  }

  Future<void> _initializeSpeech() async {
    await _speechToText.initialize();
    await _flutterTts.setLanguage("bn-BD");
    // Set Bengali language
    await _flutterTts.setSpeechRate(0.5); // Adjust speech rate
  }

  Future<void> _startListening() async {
    try {
      bool available = await _speechToText.initialize(
        onStatus: (status) {
          debugPrint("Current status: $status");
          _onSpeechStatus(status);
        },
        onError: (error) {
          debugPrint('Speech recognition error: $error');
          _stopListening();
        },
      );

      if (available) {
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
      }
    } catch (e) {
      debugPrint('Error initializing speech recognition: $e');
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
      setState(() => _isListening = false);
    }
  }

  Future<void> _speak(String text) async {
    await _flutterTts.speak(text);
  }

  createChat(String text) async {
    setState(() {
      _isLoading = true;
      messages.add("👤 আপনি: $text");
    });

    String prompt = """
You are a friendly AI Tutor for school and college students.

Instructions:
- Always answer in Bengali.
- Explain topics in very simple language.
- Use real-life examples.
- Teach step-by-step.
- If the answer contains calculations, show all steps.
- If the student makes a mistake, politely correct it.
- At the end, provide a short summary.

Student Question:
$text
""";
    _scrollToBottom();
    ChatBootModel? chatBootModelData =
    await _chatRepository.createChat(text: prompt);
    if (chatBootModelData != null) {
      setState(() {
        messages.add(
            "🤖 ডাক্তার: ${chatBootModelData.choices.first.message?.content}");
      });
      _scrollToBottom();
    }

    setState(() {
      _isLoading = false;
    });
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

  // Add retry functionality
  Future<void> _retryLastMessage() async {
    if (messages.isNotEmpty) {
      // Get the last user message
      String lastUserMessage = messages
          .where((msg) => msg.startsWith("👤"))
          .last
          .replaceFirst("👤 আপনি: ", "");

      // Clear the last bot response if it exists
      if (messages.last.startsWith("🤖")) {
        messages.removeLast();
      }

      // Retry the last message
      createChat(lastUserMessage);
    }
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).primaryColor,
        title: Text(localizations?.teachers??"AI Tutor"),
        actions: [
          // Add retry button in app bar
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _isLoading ? null : _retryLastMessage,
            tooltip: 'Retry last message',
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
              child: ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                itemCount: messages.length > 1 ? messages.length - 1 : 0,
                itemBuilder: (context, index) {
                  final textMessage = messages[index + 1]; // Skip the first item
                  final isUser = textMessage.startsWith("👤");
                  return _buildMessageBubble(
                    text: textMessage,
                    isUser: isUser,
                  );
                },
              )),
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.only(bottom: 8),
              child: CircularProgressIndicator(),
            ),
          _buildMessageInput(),
        ],
      ),
    );
  }

  Widget _buildMessageInput() {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, -2))
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          IconButton(
            icon: Icon(
              _isListening ? Icons.mic : Icons.mic_none,
              color: _isListening ? Colors.red : Colors.grey,
            ),
            onPressed: () async {
              if (_isListening) {
                await _stopListening();
              } else {
                await _startListening();
              }

              setState(() {
                _isListening = !_isListening;
              });
            },
          ),
          Expanded(
            child: TextField(
              controller: _controller,
              decoration: InputDecoration(
                hintText: "Type a message...",
                hintStyle: TextStyle(color: Colors.grey[400]),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Colors.grey[100],
                contentPadding:
                const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
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
              icon: const Icon(Icons.send, color: Colors.white),
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
    }
  }

  Widget _buildMessageBubble({required String text, required bool isUser}) {
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints:
        BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        margin: const EdgeInsets.symmetric(vertical: 4),
        decoration: BoxDecoration(
          color: isUser ? Colors.blue : Colors.grey[200],
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Expanded(
              child: Text(
                text,
                style: TextStyle(
                  fontSize: 16,
                  color: isUser ? Colors.white : Colors.black87,
                ),
              ),
            ),
            if (!isUser)
              IconButton(
                icon: const Icon(Icons.volume_up, size: 20),
                onPressed: () => _speak(text.replaceFirst("🤖 ডাক্তার: ", "")),
                color: isUser ? Colors.white : Colors.blue,
              ),
          ],
        ),
      ),
    );
  }
}
