import 'package:flutter/material.dart';
import 'package:marquee/marquee.dart';
import 'package:flutter_tts/flutter_tts.dart';

class MarqueeNotice extends StatefulWidget {
  final String? customText;
  final Color? color;

  const MarqueeNotice({super.key, this.customText, required this.color});

  @override
  State<MarqueeNotice> createState() => _MarqueeNoticeState();
}

class _MarqueeNoticeState extends State<MarqueeNotice> {
  final FlutterTts _flutterTts = FlutterTts();
  bool _isPlaying = false;

  @override
  void initState() {
    super.initState();
    _initTts();
  }

  void _initTts() {
    _flutterTts.setStartHandler(() {
      if (mounted) {
        setState(() {
          _isPlaying = true;
        });
      }
    });

    _flutterTts.setCompletionHandler(() {
      if (mounted) {
        setState(() {
          _isPlaying = false;
        });
      }
    });

    _flutterTts.setErrorHandler((msg) {
      if (mounted) {
        setState(() {
          _isPlaying = false;
        });
      }
    });
  }

  @override
  void dispose() {
    _flutterTts.stop();
    super.dispose();
  }

  Future<void> _speak(String text) async {
    if (_isPlaying) {
      await _flutterTts.stop();
      if (mounted) {
        setState(() {
          _isPlaying = false;
        });
      }
      return;
    }

    // Detect language (Bangla Unicode range: 0980-09FF)
    bool isBangla = RegExp(r'[\u0980-\u09FF]').hasMatch(text);
    if (isBangla) {
      await _flutterTts.setLanguage("bn-BD");
    } else {
      await _flutterTts.setLanguage("en-US");
    }

    await _flutterTts.setPitch(1.0);
    await _flutterTts.setSpeechRate(0.5);
    await _flutterTts.speak(text);
  }

  @override
  Widget build(BuildContext context) {
    final String text = widget.customText ?? 'Welcome to Smart School! Stay tuned for the latest updates and announcements.';
    
    return Container(
      height: 44,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(
          color: widget.color!.withValues(alpha: 0.5),
          width: 2,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Row(
          children: [
            GestureDetector(
              onTap: () => _speak(text),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                padding: const EdgeInsets.symmetric(horizontal: 12),
                height: double.infinity,
                decoration: BoxDecoration(
                  color: _isPlaying ? Colors.redAccent : widget.color,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(10),
                    bottomLeft: Radius.circular(10),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      _isPlaying ? Icons.stop_rounded : Icons.campaign_rounded,
                      color: Colors.white, 
                      size: 20
                    ),
                    const SizedBox(width: 4),
                  ],
                ),
              ),
            ),
            Expanded(
              child: Marquee(
                text: text,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
                scrollAxis: Axis.horizontal,
                crossAxisAlignment: CrossAxisAlignment.center,
                blankSpace: 100.0,
                velocity: 30.0,
                pauseAfterRound: const Duration(seconds: 2),
                accelerationDuration: const Duration(seconds: 1),
                accelerationCurve: Curves.linear,
                decelerationDuration: const Duration(milliseconds: 500),
                decelerationCurve: Curves.easeOut,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

