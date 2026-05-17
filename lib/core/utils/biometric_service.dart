import 'package:local_auth/local_auth.dart';
import 'package:flutter/services.dart';

class BiometricService {
  final LocalAuthentication _auth = LocalAuthentication();

  /// Returns true if the device supports biometrics AND has credentials enrolled.
  Future<bool> isBiometricAvailable() async {
    try {
      final bool canAuthenticate =
          await _auth.canCheckBiometrics || await _auth.isDeviceSupported();
      if (!canAuthenticate) return false;

      // Also verify at least one biometric is actually enrolled
      final List<BiometricType> available = await _auth.getAvailableBiometrics();
      return available.isNotEmpty;
    } on PlatformException catch (e) {
      print('[BiometricService] isBiometricAvailable error: $e');
      return false;
    }
  }

  Future<List<BiometricType>> getAvailableBiometrics() async {
    try {
      return await _auth.getAvailableBiometrics();
    } on PlatformException catch (e) {
      print('[BiometricService] getAvailableBiometrics error: $e');
      return [];
    }
  }

  /// Authenticate the user with biometrics (or device PIN as fallback).
  ///
  /// Key fixes for the "first attempt fails" bug:
  /// - biometricOnly: false  → allows PIN fallback that some devices need on
  ///   the very first call to warm up the authentication session.
  /// - persistAcrossBackgrounding: true → keeps the prompt alive if the user
  ///   briefly switches away from the app during the auth dialog.
  /// - stopAuthentication() before each call → resets any hung session.
  Future<bool> authenticate() async {
    // Reset any previously hung authentication session
    try {
      await _auth.stopAuthentication();
    } catch (_) {}

    try {
      return await _auth.authenticate(
        localizedReason: 'Please authenticate to login to SchoolCare',
        biometricOnly: false,            // allow PIN fallback on first attempt
        sensitiveTransaction: false,
        persistAcrossBackgrounding: true, // keep dialog alive on app switch
      );
    } on PlatformException catch (e) {
      print('[BiometricService] authenticate error: $e');
      return false;
    }
  }
}
