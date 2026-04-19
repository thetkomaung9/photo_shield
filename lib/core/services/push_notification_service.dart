import 'dart:io';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Firebase Cloud Messaging 기반 푸시 알림 서비스
class PushNotificationService {
  static final PushNotificationService _instance =
      PushNotificationService._internal();
  factory PushNotificationService() => _instance;
  PushNotificationService._internal();

  final _messaging = FirebaseMessaging.instance;
  final _localNotifications = FlutterLocalNotificationsPlugin();

  /// 알림 채널 (Android)
  static const _androidChannel = AndroidNotificationChannel(
    'photoshield_alerts',
    '탐지 알림',
    description: '이미지 도용 탐지 알림',
    importance: Importance.high,
  );

  /// 초기화
  Future<void> initialize() async {
    // 권한 요청
    await _requestPermission();

    // 로컬 알림 설정
    await _initLocalNotifications();

    // FCM 토큰 가져오기
    final token = await _messaging.getToken();
    if (token != null) {
      await _saveTokenToServer(token);
    }

    // 토큰 갱신 시 서버 업데이트
    _messaging.onTokenRefresh.listen(_saveTokenToServer);

    // 포그라운드 메시지 핸들러
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

    // 백그라운드 메시지 탭 핸들러
    FirebaseMessaging.onMessageOpenedApp.listen(_handleMessageOpenedApp);

    // 앱이 종료 상태에서 알림으로 실행된 경우
    final initialMessage = await _messaging.getInitialMessage();
    if (initialMessage != null) {
      _handleMessageOpenedApp(initialMessage);
    }
  }

  Future<void> _requestPermission() async {
    final settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      print('푸시 알림 권한 허용됨');
    } else if (settings.authorizationStatus ==
        AuthorizationStatus.provisional) {
      print('푸시 알림 임시 권한 허용됨');
    } else {
      print('푸시 알림 권한 거부됨');
    }
  }

  Future<void> _initLocalNotifications() async {
    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    await _localNotifications.initialize(
      const InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
      ),
      onDidReceiveNotificationResponse: _onNotificationTap,
    );

    // Android 알림 채널 생성
    if (Platform.isAndroid) {
      await _localNotifications
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(_androidChannel);
    }
  }

  Future<void> _saveTokenToServer(String token) async {
    // TODO: FastAPI 서버에 FCM 토큰 전송
    // await ApiService().dio.post('/users/fcm-token', data: {'token': token});
    print('FCM Token: $token');
  }

  void _handleForegroundMessage(RemoteMessage message) {
    final notification = message.notification;
    if (notification == null) return;

    // 로컬 알림 표시
    _localNotifications.show(
      notification.hashCode,
      notification.title ?? '탐지 알림',
      notification.body ?? '새로운 탐지 결과가 있습니다.',
      NotificationDetails(
        android: AndroidNotificationDetails(
          _androidChannel.id,
          _androidChannel.name,
          channelDescription: _androidChannel.description,
          icon: '@mipmap/ic_launcher',
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
      payload: message.data['detection_id'],
    );
  }

  void _handleMessageOpenedApp(RemoteMessage message) {
    final detectionId = message.data['detection_id'];
    if (detectionId != null) {
      // TODO: GoRouter로 탐지 상세 화면 이동
      // routerProvider.go('/detections/$detectionId');
      print('알림 탭: 탐지 ID $detectionId');
    }
  }

  void _onNotificationTap(NotificationResponse response) {
    final detectionId = response.payload;
    if (detectionId != null) {
      // TODO: GoRouter로 탐지 상세 화면 이동
      print('로컬 알림 탭: 탐지 ID $detectionId');
    }
  }

  /// FCM 토큰 가져오기
  Future<String?> getToken() => _messaging.getToken();

  /// 특정 토픽 구독 (예: 새로운 기능 알림)
  Future<void> subscribeToTopic(String topic) async {
    await _messaging.subscribeToTopic(topic);
  }

  /// 토픽 구독 해제
  Future<void> unsubscribeFromTopic(String topic) async {
    await _messaging.unsubscribeFromTopic(topic);
  }
}

/// 백그라운드 메시지 핸들러 (main.dart에서 등록 필요)
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  print('백그라운드 메시지 수신: ${message.messageId}');
}

/// Provider
final pushNotificationServiceProvider = Provider<PushNotificationService>((ref) {
  return PushNotificationService();
});
