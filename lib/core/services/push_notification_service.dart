import 'package:flutter_riverpod/flutter_riverpod.dart';

/// 푸시 알림 서비스 (Firebase 설정 전 스텁)
/// Firebase 설정 후 firebase_messaging, flutter_local_notifications 활성화 필요
class PushNotificationService {
  static final PushNotificationService _instance =
      PushNotificationService._internal();
  factory PushNotificationService() => _instance;
  PushNotificationService._internal();

  /// 초기화 (Firebase 설정 후 구현)
  Future<void> initialize() async {
    // TODO: Firebase 설정 후 활성화
    // await _requestPermission();
    // await _initLocalNotifications();
    // final token = await getToken();
    // if (token != null) await _saveTokenToServer(token);
  }

  /// FCM 토큰 가져오기 (Firebase 설정 후 구현)
  Future<String?> getToken() async => null;

  /// 특정 토픽 구독
  Future<void> subscribeToTopic(String topic) async {}

  /// 토픽 구독 해제
  Future<void> unsubscribeFromTopic(String topic) async {}
}

/// Provider
final pushNotificationServiceProvider =
    Provider<PushNotificationService>((ref) {
  return PushNotificationService();
});
