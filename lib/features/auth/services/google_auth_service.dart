import 'dart:developer';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/services.dart';
import 'package:google_sign_in/google_sign_in.dart';

class GoogleAuthService {
  static const String webClientId =
      '2512295449-u3jekrd8fifsb41fpjlap831vgf1qrh4.apps.googleusercontent.com';

  static bool _isInitialized = false;

  /// Ensures GoogleSignIn is initialized with the serverClientId from Firebase.
  static Future<void> initialize() async {
    if (_isInitialized) return;
    try {
      await GoogleSignIn.instance.initialize(
        serverClientId: webClientId,
      );
      _isInitialized = true;
    } catch (e) {
      log('GoogleSignIn initialization error: $e');
    }
  }

  /// Triggers Google Sign In flow and signs into Firebase.
  /// Returns [UserCredential] if successful, or `null` if cancelled by the user.
  static Future<UserCredential?> signInWithGoogle() async {
    try {
      await initialize();

      final GoogleSignInAccount googleUser =
          await GoogleSignIn.instance.authenticate();

      final GoogleSignInAuthentication googleAuth = googleUser.authentication;

      if (googleAuth.idToken == null) {
        throw Exception('Failed to obtain Google ID token.');
      }

      final OAuthCredential credential = GoogleAuthProvider.credential(
        idToken: googleAuth.idToken,
      );

      final UserCredential userCredential =
          await FirebaseAuth.instance.signInWithCredential(credential);

      return userCredential;
    } on PlatformException catch (e) {
      // User cancelled or closed the sign-in modal/sheet
      if (e.code == 'sign_in_canceled' ||
          e.code == 'canceled' ||
          e.code == '12501') {
        log('Google Sign-In cancelled: ${e.message}');
        return null;
      }
      log('PlatformException during Google Sign-In: $e');
      rethrow;
    } catch (e) {
      // Check if exception message indicates user cancellation
      final errStr = e.toString().toLowerCase();
      if (errStr.contains('cancel') || errStr.contains('12501')) {
        log('Google Sign-In cancelled: $e');
        return null;
      }
      log('Error during Google Sign-In: $e');
      rethrow;
    }
  }

  /// Signs out from both Firebase Auth and GoogleSignIn.
  static Future<void> signOut() async {
    try {
      await FirebaseAuth.instance.signOut();
    } catch (e) {
      log('FirebaseAuth signOut error: $e');
    }
    try {
      await GoogleSignIn.instance.signOut();
    } catch (e) {
      log('GoogleSignIn signOut error: $e');
    }
  }
}
