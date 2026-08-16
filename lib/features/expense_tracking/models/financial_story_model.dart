import 'package:flutter/material.dart';

class StorySlide {
  final String title;
  final String highlightValue;
  final String subtitle;
  final String description;
  final List<String> bulletPoints;
  final String badge;
  final Color badgeColor;
  final IconData icon;
  final String? footerNote;

  StorySlide({
    required this.title,
    required this.highlightValue,
    required this.subtitle,
    required this.description,
    this.bulletPoints = const [],
    required this.badge,
    required this.badgeColor,
    required this.icon,
    this.footerNote,
  });
}

class FinancialStory {
  final String id;
  final String title;
  final String subtitle;
  final IconData icon;
  final List<Color> gradientColors;
  final List<StorySlide> slides;
  bool isViewed;

  FinancialStory({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.gradientColors,
    required this.slides,
    this.isViewed = false,
  });

  FinancialStory copyWith({
    String? id,
    String? title,
    String? subtitle,
    IconData? icon,
    List<Color>? gradientColors,
    List<StorySlide>? slides,
    bool? isViewed,
  }) {
    return FinancialStory(
      id: id ?? this.id,
      title: title ?? this.title,
      subtitle: subtitle ?? this.subtitle,
      icon: icon ?? this.icon,
      gradientColors: gradientColors ?? this.gradientColors,
      slides: slides ?? this.slides,
      isViewed: isViewed ?? this.isViewed,
    );
  }
}
