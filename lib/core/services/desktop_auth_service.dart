import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:googleapis/drive/v3.dart' as drive;
import 'package:googleapis_auth/auth_io.dart' as auth;
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';

/// Desktop OAuth service using googleapis_auth for installed app flow.
///
/// On macOS, google_sign_in doesn't have a native implementation.
/// Instead, we use googleapis_auth's `clientViaUserConsent()` which:
///   1. Opens the default browser for Google OAuth consent
///   2. Spins up a tiny local HTTP server to capture the redirect
///   3. Returns an authenticated HTTP client
///
/// To set up:
///   1. Go to Google Cloud Console → APIs & Services → Credentials
///   2. Create an OAuth 2.0 Client ID of type "Desktop"
///   3. Copy the client ID and secret into [_desktopClientId] below
///   4. Ensure Drive API is enabled for the project
class DesktopAuthService {
  // ---- CONFIGURATION ----
  // Replace with your own Desktop OAuth Client ID from Google Cloud Console.
  // Project: rig-ledger-b0765 (project number 91755183896)
  // Type: Desktop application
  static const String _clientId =
      '91755183896-REPLACE_WITH_DESKTOP_CLIENT_ID.apps.googleusercontent.com';
  static const String _clientSecret = 'REPLACE_WITH_DESKTOP_SECRET';

  static final auth.ClientId _desktopClientId =
      auth.ClientId(_clientId, _clientSecret);

  static const List<String> _scopes = [
    drive.DriveApi.driveFileScope,
  ];

  static auth.AutoRefreshingAuthClient? _authClient;
  static String? _userEmail;

  /// Whether the user is signed in on desktop.
  static bool get isSignedIn => _authClient != null;

  /// The email of the signed-in user (may be null if not fetched).
  static String? get userEmail => _userEmail;

  /// The authenticated HTTP client for googleapis.
  static http.Client? get httpClient => _authClient;

  /// Sign in on desktop.
  ///
  /// Opens the default browser for Google OAuth consent.
  /// Returns (success, errorMessage).
  static Future<(bool, String?)> signIn() async {
    try {
      _authClient = await auth.clientViaUserConsent(
        _desktopClientId,
        _scopes,
        _openUrl,
      );

      // Fetch user email from the userinfo endpoint
      await _fetchUserEmail();

      return (true, null);
    } on auth.UserConsentException catch (e) {
      debugPrint('Desktop OAuth user consent error: $e');
      return (false, 'Sign-in was cancelled or denied');
    } on auth.ServerRequestFailedException catch (e) {
      debugPrint('Desktop OAuth server error: $e');
      return (false, 'OAuth server error: $e');
    } catch (e) {
      debugPrint('Desktop OAuth error: $e');
      return (false, 'Failed to sign in: $e');
    }
  }

  /// Attempt silent sign-in by checking for saved credentials.
  /// Currently not persistent — always returns false.
  /// A future enhancement could save refresh tokens to Hive.
  static Future<bool> trySignInSilently() async {
    // No persistent token storage yet; require interactive sign-in.
    return false;
  }

  /// Sign out and clean up.
  static Future<void> signOut() async {
    _authClient?.close();
    _authClient = null;
    _userEmail = null;
  }

  /// Open a URL in the default browser.
  static Future<void> _openUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      // Fallback: try direct Process.start on macOS
      if (Platform.isMacOS) {
        await Process.start('open', [url]);
      }
    }
  }

  /// Fetch the email of the signed-in user using the people/userinfo API.
  static Future<void> _fetchUserEmail() async {
    if (_authClient == null) return;
    try {
      final response = await _authClient!
          .get(Uri.parse('https://www.googleapis.com/oauth2/v2/userinfo'));
      if (response.statusCode == 200) {
        // Simple parse — avoid adding another dependency just for this
        final body = response.body;
        final emailMatch = RegExp(r'"email"\s*:\s*"([^"]+)"').firstMatch(body);
        if (emailMatch != null) {
          _userEmail = emailMatch.group(1);
        }
      }
    } catch (e) {
      debugPrint('Failed to fetch user email: $e');
    }
  }
}
