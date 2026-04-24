import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kakao_flutter_sdk_common/kakao_flutter_sdk_common.dart';

import 'app.dart';
import 'core/constants.dart';
import 'core/services/push_notification_service.dart';
import 'firebase_options.dart';

/// Background message handler for Firebase Messaging
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  final firebaseOptions = DefaultFirebaseOptions.currentPlatform;
  if (firebaseOptions == null) {
    return;
  }

  await Firebase.initializeApp(options: firebaseOptions);
  await PushNotificationService().handleBackgroundMessage(message);
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (KakaoEnv.isConfigured) {
    await KakaoSdk.init(
      nativeAppKey: KakaoEnv.nativeAppKey,
      customScheme: KakaoEnv.callbackScheme,
    );
  }

  // Initialize Firebase with error handling
  try {
    final firebaseOptions = DefaultFirebaseOptions.currentPlatform;
    if (firebaseOptions != null) {
      await Firebase.initializeApp(
        options: firebaseOptions,
      );

      // Set up background message handler
      FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

      // Initialize push notification service
      await PushNotificationService().initialize();
    } else {
      debugPrint('Firebase not configured for this platform');
    }
  } catch (e) {
    debugPrint('Firebase initialization failed: $e');
    // Continue anyway - Firebase is not critical for app functionality
  }

  runApp(const ProviderScope(child: PhotoShieldApp()));
}
