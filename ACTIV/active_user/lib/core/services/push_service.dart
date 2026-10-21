import 'dart:io' show Platform;

import 'package:activ_user_app/core/network/activ_api_client.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

/// Wraps Firebase Cloud Messaging for the ACTIV user app.
///
/// The ACTIV host owns the Firebase project and drops [google-services.json]
/// into android/app before enabling push. Until then the service is a safe
/// no-op so the app still builds and runs. When the file is present the token
/// is registered with the backend `POST /devices` endpoint automatically.
class PushService {
  PushService._();

  static final instance = PushService._();

  bool _enabled = false;
  String? _token;

  bool get isEnabled => _enabled;

  /// Invoked on notification tap while the app is in foreground/background.
  /// Data payload (e.g. `{"type": "booking"}`) can be routed by the caller.
  void Function(Map<String, dynamic> data)? onNotificationTap;

  /// Initializes Firebase Messaging. Safe to call more than once.
  Future<void> init() async {
    if (_enabled) return;
    if (kIsWeb) return;
    if (!Platform.isAndroid && !Platform.isIOS) return;

    try {
      await FirebaseMessaging.instance.requestPermission();
      _enabled = true;

      FirebaseMessaging.instance.setForegroundNotificationPresentationOptions(
        alert: true,
        badge: true,
        sound: true,
      );

      // Foreground messages: route via the tap handler so the app can
      // navigate, ignoring silent/remote-only payloads.
      FirebaseMessaging.onMessage.listen((message) {
        final data = _data(message);
        if (data.isNotEmpty) onNotificationTap?.call(data);
      });
      FirebaseMessaging.onMessageOpenedApp.listen(_handleOpened);
      FirebaseMessaging.instance.getInitialMessage().then((message) {
        if (message != null) _handleOpened(message);
      });

      await _sync();
    } catch (_) {
      // Firebase not configured (missing google-services.json) or the
      // platform channel is unavailable on this test build.
      _enabled = false;
    }
  }

  Future<void> _handleOpened(RemoteMessage? message) async {
    if (message == null) return;
    final data = _data(message);
    if (data.isNotEmpty) onNotificationTap?.call(data);
  }

  /// Registers (or refreshes) the push token on the backend.
  Future<void> sync() async {
    if (!_enabled) return;
    await _sync();
  }

  Future<void> _sync() async {
    try {
      final token = await FirebaseMessaging.instance.getToken();
      if (token == null) return;
      _token = token;
      await ActivApiClient.instance.registerDevice(
        platform: Platform.isIOS ? 'ios' : 'android',
        token: token,
      );
    } catch (_) {
      // Backend offline or session expired; token will sync on next app start.
    }
  }

  /// Removes the device from the backend on logout.
  Future<void> unregister() async {
    if (!_enabled || _token == null) return;
    try {
      await ActivApiClient.instance.unregisterDevice(_token!);
    } catch (_) {
      // Best effort.
    }
    _token = null;
  }

  Map<String, dynamic> _data(RemoteMessage message) {
    return Map<String, dynamic>.from(message.data);
  }
}