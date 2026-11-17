import 'package:flutter/material.dart';

/// A single step in a [Tour].
class TourStep {
  /// The widget to spotlight. Attach this key to the target widget.
  final GlobalKey targetKey;

  /// Short headline shown in the tooltip card.
  final String title;

  /// Explatory text shown below the title.
  final String body;

  /// Extra space inflated around the highlighted widget rect.
  /// Overrides [TourTheme.spotlightPadding] for this step if set.
  final double? padding;

  /// Corner radius of the spotlight cutout.
  /// Overrides [TourTheme.spotlightRadius] for this step if set.
  final double? radius;

  /// Optional async action run *before* this step is shown.
  ///
  /// Use it to switch tabs, navigate to a page, or do any async work that
  /// must complete before the target widget is in the tree.
  ///
  /// ```dart
  /// onBefore: () async {
  ///   tabController.animateTo(2);
  ///   await Future.delayed(const Duration(milliseconds: 350));
  /// }
  /// ```
  final Future<void> Function()? onBefore;

  const TourStep({
    required this.targetKey,
    required this.title,
    required this.body,
    this.padding,
    this.radius,
    this.onBefore,
  });
}
