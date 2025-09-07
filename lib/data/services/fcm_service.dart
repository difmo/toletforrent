import 'dart:io';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'notifications_service.dart';

/// TOP-LEVEL handler (must be top-level, not inside a class/file scope)
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // You cannot show local notif without initializing plugins in background isolate,
  // but often we keep it minimal or use headless logic.
}

class FcmService {
  FcmService._();
  static final FcmService I = FcmService._();

  final _messaging = FirebaseMessaging.instance;

  Future<void> init() async {
    // iOS permissions
    await _messaging.requestPermission();

    // Get FCM token
    final token = await _messaging.getToken();
    // TODO: Save token to Firestore under users/{uid}/tokens/{token} if logged in
    // or in users/{uid} field 'fcmTokens': FieldValue.arrayUnion([token])

    // Foreground messages
    FirebaseMessaging.onMessage.listen((RemoteMessage message) async {
      final ntf = message.notification;
      if (ntf != null) {
        await NotificationsService.I.showLocal(
          title: ntf.title ?? 'New message',
          body: ntf.body ?? '',
        );
      }
    });

    // App opened from terminated by tapping notification
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      // TODO: Navigate to proper screen based on message.data
    });

    // Background handler
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

    if (Platform.isAndroid) {
      // Android 13+ runtime permission (optionally handle with a dialog in UI)
    }
  }
}
