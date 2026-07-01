import 'package:flutter/foundation.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:go_router/go_router.dart';

/// Set by [App] once the GoRouter exists, so notification taps can navigate.
GoRouter? notificationRouter;

/// Handles FCM setup: permission, token retrieval/refresh, and tap navigation.
///
/// Android-only: [Firebase.initializeApp] reads `android/app/google-services.json`
/// (configured via the Google Services Gradle plugin), so no generated
/// `firebase_options.dart` is required.
class NotificationService {
  // Resolved lazily so `.instance` is only accessed after [Firebase.initializeApp].
  FirebaseMessaging get _messaging => FirebaseMessaging.instance;

  /// Initialize Firebase, request permission, register the token via [onToken]
  /// and keep it in sync on refresh. Failures are swallowed (push is non-critical).
  Future<void> initialize({
    required Future<void> Function(String token) onToken,
  }) async {
    try {
      await Firebase.initializeApp();

      await _messaging.requestPermission();

      final token = await _messaging.getToken();
      if (token != null) {
        await onToken(token);
      }

      _messaging.onTokenRefresh.listen((newToken) {
        onToken(newToken).catchError(
          (e) => debugPrint('Failed to re-register FCM token: $e'),
        );
      });

      // Navigate to the portfolio when the user taps the notification.
      FirebaseMessaging.onMessageOpenedApp.listen(_handleTap);
      final initial = await _messaging.getInitialMessage();
      if (initial != null) {
        _handleTap(initial);
      }
    } catch (e) {
      debugPrint('NotificationService init failed: $e');
    }
  }

  void _handleTap(RemoteMessage message) {
    notificationRouter?.go('/portfolio');
  }
}
