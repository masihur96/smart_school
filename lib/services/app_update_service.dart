import 'dart:developer';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:in_app_update/in_app_update.dart';

/// Service responsible for managing in-app update flows via Google Play Core API.
///
/// Supports two update modes:
/// - **Immediate**: A full-screen, blocking experience for critical updates.
/// - **Flexible**: Background download with a user prompt to restart, for
///   non-critical updates.
///
/// Note: In-app updates only work on Android devices with a signed APK/AAB
/// distributed through the Google Play Store (including Internal Testing tracks).
/// They will silently no-op on debug builds or non-Play distributions.
class AppUpdateService {
  AppUpdateService._();

  static final AppUpdateService instance = AppUpdateService._();

  AppUpdateInfo? _cachedUpdateInfo;

  /// Checks if an update is available via Google Play.
  ///
  /// Returns [AppUpdateInfo] on success, or `null` if the check fails
  /// (e.g., not on Play Store, no internet, etc.).
  Future<AppUpdateInfo?> checkForUpdate() async {
    try {
      final info = await InAppUpdate.checkForUpdate();
      _cachedUpdateInfo = info;
      log('[AppUpdateService] Update availability: ${info.updateAvailability}');
      return info;
    } catch (e) {
      // Expected to throw on non-Play builds or sideloaded APKs.
      log('[AppUpdateService] checkForUpdate failed (expected on debug/sideloaded): $e');
      return null;
    }
  }

  /// Returns `true` if an update is available based on the cached info.
  bool get isUpdateAvailable =>
      _cachedUpdateInfo?.updateAvailability ==
      UpdateAvailability.updateAvailable;

  /// Triggers an **immediate** (blocking, full-screen) update.
  ///
  /// Prefer this for critical security or stability patches.
  /// The user must complete the update before they can proceed.
  ///
  /// Returns `true` if the update completed successfully.
  Future<bool> performImmediateUpdate() async {
    try {
      final result = await InAppUpdate.performImmediateUpdate();
      log('[AppUpdateService] Immediate update result: $result');
      return result == AppUpdateResult.success;
    } catch (e) {
      log('[AppUpdateService] Immediate update failed: $e');
      return false;
    }
  }

  /// Triggers a **flexible** (background) update.
  ///
  /// The update downloads in the background. Once complete, call
  /// [completeFlexibleUpdate] to prompt the user to restart.
  ///
  /// Returns `true` if the update started (or was already downloaded).
  Future<bool> startFlexibleUpdate() async {
    try {
      final result = await InAppUpdate.startFlexibleUpdate();
      log('[AppUpdateService] Flexible update start result: $result');
      return result == AppUpdateResult.success;
    } catch (e) {
      log('[AppUpdateService] Flexible update start failed: $e');
      return false;
    }
  }

  /// Completes a downloaded flexible update by restarting the app.
  ///
  /// Should be called after [startFlexibleUpdate] succeeds, typically from
  /// a SnackBar action or similar user-facing prompt.
  Future<void> completeFlexibleUpdate() async {
    try {
      await InAppUpdate.completeFlexibleUpdate();
      log('[AppUpdateService] Flexible update completed — app will restart.');
    } catch (e) {
      log('[AppUpdateService] Flexible update completion failed: $e');
    }
  }

  /// Checks for an update and handles it using the recommended strategy:
  ///
  /// - **Immediate update** → if `updatePriority >= 4` (high priority, as set
  ///   in Play Console) or if `clientVersionStalenessDays >= staleDaysThreshold`.
  /// - **Flexible update** → for all other available updates.
  ///
  /// [context] is used to display a SnackBar for the flexible update prompt.
  /// [staleDaysThreshold] defines how many days since the update was published
  /// before it is treated as an immediate update (default: 5 days).
  ///
  /// Returns `true` if any update flow was initiated.
  Future<bool> checkAndHandleUpdate(
    BuildContext context, {
    int staleDaysThreshold = 5,
  }) async {
    // In-app updates are Android-only.
    if (!defaultTargetPlatform.isAndroid) return false;

    final info = await checkForUpdate();
    if (info == null) return false;

    if (info.updateAvailability != UpdateAvailability.updateAvailable) {
      return false;
    }

    final isHighPriority = info.updatePriority >= 4;
    final isStale =
        (info.clientVersionStalenessDays ?? 0) >= staleDaysThreshold;

    if (isHighPriority || isStale) {
      // Immediate update — blocks the user until the update is applied.
      return await performImmediateUpdate();
    } else {
      // Flexible update — download in background, prompt to restart.
      final started = await startFlexibleUpdate();
      if (started && context.mounted) {
        _showFlexibleUpdateSnackBar(context);
      }
      return started;
    }
  }

  /// Shows a persistent [SnackBar] informing the user that an update has
  /// been downloaded and is ready to install.
  void _showFlexibleUpdateSnackBar(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text(
          '🎉 A new update has been downloaded.',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: const Color(0xFF1A73E8),
        duration: const Duration(seconds: 10),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
        action: SnackBarAction(
          label: 'RESTART',
          textColor: Colors.amberAccent,
          onPressed: completeFlexibleUpdate,
        ),
      ),
    );
  }
}

/// Extension to check platform without importing dart:io directly.
extension on TargetPlatform {
  bool get isAndroid => this == TargetPlatform.android;
}
