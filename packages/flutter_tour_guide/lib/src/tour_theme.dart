import 'package:flutter/material.dart';

/// Visual configuration for the tour overlay.
///
/// Pass a [TourTheme] to [Tour.show] to match your app's brand.
/// All fields have sensible defaults so you can override only what you need.
class TourTheme {
  /// Colour used for the Next/Done button and step-progress dots.
  final Color accentColor;

  /// Opacity of the scrim that darkens the background. 0.0–1.0.
  final double scrimOpacity;

  /// Background colour of the tooltip card.
  final Color cardColor;

  /// Title text style.
  final TextStyle titleStyle;

  /// Body text style.
  final TextStyle bodyStyle;

  /// Step counter and "Skip tour" text style.
  final TextStyle captionStyle;

  /// Corner radius of the tooltip card.
  final double cardRadius;

  /// Corner radius of the spotlight cutout.
  final double spotlightRadius;

  /// Extra padding inflated around the target widget rect.
  final double spotlightPadding;

  const TourTheme({
    this.accentColor = const Color(0xFF00B140),
    this.scrimOpacity = 0.65,
    this.cardColor = const Color(0xFFFFFFFF),
    this.titleStyle = const TextStyle(
      fontSize: 15,
      fontWeight: FontWeight.w700,
      color: Color(0xFF131313),
    ),
    this.bodyStyle = const TextStyle(
      fontSize: 13,
      height: 1.4,
      color: Color(0xFF393939),
    ),
    this.captionStyle = const TextStyle(
      fontSize: 12,
      color: Color(0xFF727272),
    ),
    this.cardRadius = 14,
    this.spotlightRadius = 12,
    this.spotlightPadding = 8,
  });
}
