import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

class SocialAuthResult {
  final String provider; // 'google' or 'apple'
  final String? idToken;
  final String? accessToken;
  final String? email;
  final String? name;
  final String? photoUrl;
  final String? appleAuthorizationCode;

  SocialAuthResult({
    required this.provider,
    this.idToken,
    this.accessToken,
    this.email,
    this.name,
    this.photoUrl,
    this.appleAuthorizationCode,
  });
}

class SocialAuthService {
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: ['email', 'profile'],
  );

  /// Perform Google / Gmail Login
  Future<SocialAuthResult?> signInWithGoogle() async {
    try {
      final GoogleSignInAccount? account = await _googleSignIn.signIn();
      if (account == null) return null; // User cancelled

      final GoogleSignInAuthentication auth = await account.authentication;

      return SocialAuthResult(
        provider: 'google',
        idToken: auth.idToken,
        accessToken: auth.accessToken,
        email: account.email,
        name: account.displayName,
        photoUrl: account.photoUrl,
      );
    } catch (e) {
      if (kDebugMode) {
        print('Google Sign-In Error: $e');
      }
      rethrow;
    }
  }

  /// Sign out from Google
  Future<void> signOutGoogle() async {
    try {
      if (await _googleSignIn.isSignedIn()) {
        await _googleSignIn.signOut();
      }
    } catch (_) {}
  }

  /// Perform Apple Login
  Future<SocialAuthResult?> signInWithApple() async {
    try {
      final isAvailable = await SignInWithApple.isAvailable();
      if (!isAvailable && !kIsWeb && !Platform.isIOS && !Platform.isMacOS) {
        throw Exception('Sign in with Apple is not available on this platform.');
      }

      final credential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
      );

      final String? name = (credential.givenName != null || credential.familyName != null)
          ? '${credential.givenName ?? ''} ${credential.familyName ?? ''}'.trim()
          : null;

      return SocialAuthResult(
        provider: 'apple',
        idToken: credential.identityToken,
        appleAuthorizationCode: credential.authorizationCode,
        email: credential.email,
        name: name,
      );
    } catch (e) {
      if (kDebugMode) {
        print('Apple Sign-In Error: $e');
      }
      rethrow;
    }
  }
}
