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

      // Verify at least one biometric is enrolled
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
  /// - biometricOnly: false  → allows PIN fallback so first-attempt works on
  ///   devices that need it to warm up the authentication session.
  /// - persistAcrossBackgrounding: true → keeps the prompt alive if user
  ///   briefly switches away during the auth dialog.
  Future<bool> authenticate() async {
    try {
      return await _auth.authenticate(
        localizedReason: 'Please authenticate to login to SchoolCare',
        biometricOnly: false,
        sensitiveTransaction: false,
        persistAcrossBackgrounding: true,
      );
    } on PlatformException catch (e) {
      print('[BiometricService] authenticate error: $e');
      return false;
    }
  }
}
