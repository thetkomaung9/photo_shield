import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
// import 'package:firebase_core/firebase_core.dart';
// import 'package:firebase_messaging/firebase_messaging.dart';
import 'app.dart';
// import 'core/services/push_notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // TODO: Firebase 설정 후 활성화
  // Firebase 초기화 - google-services.json 필요
  // await Firebase.initializeApp();
  // FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
  // await PushNotificationService().initialize();

  runApp(const ProviderScope(child: PhotoShieldApp()));
}
