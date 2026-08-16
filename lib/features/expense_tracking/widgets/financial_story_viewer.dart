import 'dart:async';
import 'package:flutter/material.dart';
import '../models/financial_story_model.dart';

class FinancialStoryViewer extends StatefulWidget {
  final List<FinancialStory> stories;
  final int initialStoryIndex;
  final Function(String storyId)? onStoryViewed;

  const FinancialStoryViewer({
    super.key,
    required this.stories,
    this.initialStoryIndex = 0,
    this.onStoryViewed,
  });

  @override
  State<FinancialStoryViewer> createState() => _FinancialStoryViewerState();
}

class _FinancialStoryViewerState extends State<FinancialStoryViewer>
    with SingleTickerProviderStateMixin {
  late int _currentStoryIndex;
  late int _currentSlideIndex;
  late AnimationController _progressController;
  Timer? _resumeTimer;
  bool _isPaused = false;

  static const Duration _slideDuration = Duration(seconds: 5);

  @override
  void initState() {
    super.initState();
    _currentStoryIndex = widget.initialStoryIndex;
    _currentSlideIndex = 0;

    _progressController = AnimationController(
      vsync: this,
      duration: _slideDuration,
    );

    _progressController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _nextSlide();
      }
    });

    _markCurrentStoryViewed();
    _startSlide();
  }

  void _markCurrentStoryViewed() {
    if (_currentStoryIndex < widget.stories.length) {
      final story = widget.stories[_currentStoryIndex];
      widget.onStoryViewed?.call(story.id);
    }
  }

  void _startSlide() {
    _progressController.reset();
    _progressController.forward();
  }

  void _nextSlide() {
    final story = widget.stories[_currentStoryIndex];
    if (_currentSlideIndex < story.slides.length - 1) {
      setState(() {
        _currentSlideIndex++;
      });
      _startSlide();
    } else {
      // Go to next story if available
      if (_currentStoryIndex < widget.stories.length - 1) {
        setState(() {
          _currentStoryIndex++;
          _currentSlideIndex = 0;
        });
        _markCurrentStoryViewed();
        _startSlide();
      } else {
        // End of all stories
        Navigator.of(context).pop();
      }
    }
  }

  void _previousSlide() {
    if (_currentSlideIndex > 0) {
      setState(() {
        _currentSlideIndex--;
      });
      _startSlide();
    } else {
      // Go to previous story if available
      if (_currentStoryIndex > 0) {
        setState(() {
          _currentStoryIndex--;
          _currentSlideIndex = widget.stories[_currentStoryIndex].slides.length - 1;
        });
        _startSlide();
      } else {
        _startSlide();
      }
    }
  }

  void _pause() {
    if (!_isPaused) {
      _isPaused = true;
      _progressController.stop();
    }
  }

  void _resume() {
    if (_isPaused) {
      _isPaused = false;
      _progressController.forward();
    }
  }

  @override
  void dispose() {
    _resumeTimer?.cancel();
    _progressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.stories.isEmpty) {
      return const SizedBox.shrink();
    }

    final story = widget.stories[_currentStoryIndex];
    final slide = story.slides[_currentSlideIndex];
    final bgGradients = story.gradientColors;

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: GestureDetector(
          onTapDown: (details) {
            final screenWidth = MediaQuery.of(context).size.width;
            if (details.globalPosition.dx < screenWidth * 0.3) {
              _previousSlide();
            } else {
              _nextSlide();
            }
          },
          onLongPressStart: (_) => _pause(),
          onLongPressEnd: (_) => _resume(),
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  bgGradients.first.withOpacity(0.95),
                  bgGradients.last,
                  const Color(0xFF0F172A),
                ],
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Story Progress Bars
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Row(
                    children: List.generate(story.slides.length, (index) {
                      return Expanded(
                        child: Container(
                          margin: const EdgeInsets.symmetric(horizontal: 2.5),
                          height: 3.5,
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(2),
                            child: _buildProgressIndicator(index),
                          ),
                        ),
                      );
                    }),
                  ),
                ),

                // Top Header Info Bar
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white.withOpacity(0.4)),
                        ),
                        child: Icon(story.icon, color: Colors.white, size: 20),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              story.title,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            Text(
                              story.subtitle,
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.8),
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close_rounded, color: Colors.white, size: 26),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // Main Slide Card Body
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20.0),
                    child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Badge Pill
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: slide.badgeColor.withOpacity(0.25),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: slide.badgeColor.withOpacity(0.8),
                                width: 1.2,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(slide.icon, color: Colors.white, size: 16),
                                const SizedBox(width: 6),
                                Text(
                                  slide.badge,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 16),

                          // Highlight Value
                          Text(
                            slide.highlightValue,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 34,
                              fontWeight: FontWeight.w900,
                              letterSpacing: -0.5,
                            ),
                          ),

                          const SizedBox(height: 4),

                          // Slide Title & Subtitle
                          Text(
                            slide.title,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            slide.subtitle,
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.85),
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),

                          const SizedBox(height: 18),

                          // Description Box
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: Colors.white.withOpacity(0.2)),
                            ),
                            child: Text(
                              slide.description,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 14.5,
                                height: 1.45,
                              ),
                            ),
                          ),

                          const SizedBox(height: 16),

                          // Bullet points
                          if (slide.bulletPoints.isNotEmpty) ...[
                            ...slide.bulletPoints.map((point) {
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 8.0),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Container(
                                      margin: const EdgeInsets.only(top: 4),
                                      padding: const EdgeInsets.all(3),
                                      decoration: BoxDecoration(
                                        color: Colors.white.withOpacity(0.25),
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(
                                        Icons.check,
                                        size: 12,
                                        color: Colors.white,
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Text(
                                        point,
                                        style: TextStyle(
                                          color: Colors.white.withOpacity(0.95),
                                          fontSize: 13.5,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }),
                            const SizedBox(height: 12),
                          ],

                          // Footer Note Card
                          if (slide.footerNote != null)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                              decoration: BoxDecoration(
                                color: Colors.black.withOpacity(0.25),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.white.withOpacity(0.15)),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.info_outline, color: Colors.amberAccent, size: 18),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      slide.footerNote!,
                                      style: const TextStyle(
                                        color: Colors.white70,
                                        fontSize: 12.5,
                                        fontStyle: FontStyle.italic,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),

                          const SizedBox(height: 24),
                        ],
                      ),
                    ),
                  ),
                ),

                // Bottom Action & Hints
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Tap left/right to navigate • Hold to pause',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.6),
                          fontSize: 11,
                        ),
                      ),
                      TextButton.icon(
                        onPressed: _nextSlide,
                        icon: const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white, size: 14),
                        label: const Text(
                          'Next',
                          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                        ),
                        style: TextButton.styleFrom(
                          backgroundColor: Colors.white.withOpacity(0.18),
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProgressIndicator(int index) {
    if (index < _currentSlideIndex) {
      return Container(color: Colors.white);
    } else if (index == _currentSlideIndex) {
      return AnimatedBuilder(
        animation: _progressController,
        builder: (context, child) {
          return LinearProgressIndicator(
            value: _progressController.value,
            backgroundColor: Colors.white.withOpacity(0.3),
            valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
          );
        },
      );
    } else {
      return Container(color: Colors.white.withOpacity(0.3));
    }
  }
}
