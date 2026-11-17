import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_tour_guide/src/tour_overlay.dart';
import 'package:flutter_tour_guide/src/tour_step.dart';
import 'package:flutter_tour_guide/src/tour_theme.dart';
import 'package:shared_preferences/shared_preferences.dart';

export 'tour_step.dart';
export 'tour_theme.dart';

/// Entry point for the Spotlight Tour system.
class Tour {
  Tour._();

  static const String _prefix = 'spotlight_tour_v1_';

  /// Show the tour for [id] if it hasn't been seen yet.
  ///
  /// - [id] — unique key used for SharedPreferences persistence.
  /// - [steps] — ordered list of [TourStep]s to walk through.
  /// - [theme] — optional visual config. Defaults to a neutral green theme.
  /// - [force] — set `true` to show even if already seen (e.g. restart button).
  /// - [onEnd] — called after every tour ending (skip or complete).
  ///             Use it to restore navigation state.
  /// - [onSkip] — called only when the user taps "Skip tour".
  static Future<void> show({
    required BuildContext context,
    required String id,
    required List<TourStep> steps,
    TourTheme theme = const TourTheme(),
    bool force = false,
    Future<void> Function()? onEnd,
    Future<void> Function()? onSkip,
  }) async {
    if (steps.isEmpty) return;

    final prefs = await SharedPreferences.getInstance();
    final key = '$_prefix$id';

    if (!force && (prefs.getBool(key) ?? false)) return;
    if (!context.mounted) return;

    final completer = Completer<void>();

    late OverlayEntry entry;
    entry = OverlayEntry(
      builder: (_) => TourOverlay(
        steps: steps,
        theme: theme,
        onSkip: onSkip == null ? null : () => onSkip(),
        onDone: () async {
          entry.remove();
          await prefs.setBool(key, true);
          await onEnd?.call();
          if (!completer.isCompleted) completer.complete();
        },
      ),
    );

    Overlay.of(context).insert(entry);
    return completer.future;
  }

  /// Mark a specific tour as unseen so it will show again next visit.
  static Future<void> reset(String id) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('$_prefix$id');
  }

  /// Reset every tour in the app.
  static Future<void> resetAll() async {
    final prefs = await SharedPreferences.getInstance();
    final keys = prefs.getKeys().where((k) => k.startsWith(_prefix)).toList();
    for (final k in keys) {
      await prefs.remove(k);
    }
  }
}
