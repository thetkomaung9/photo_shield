import '../../shared/models/detection.dart';
import '../../shared/models/notification_item.dart';
import '../../shared/models/photo.dart';
import '../../shared/models/user.dart';

/// 데모 모드에서 모든 화면을 채우기 위한 정적 데이터 소스.
///
/// 실 백엔드(`https://api.photoshield.kr/v1`) 가 존재하지 않기 때문에
/// `photoProvider`, `detectionProvider`, `notificationProvider` 는 모두
/// 이 클래스에서 데이터를 읽어 즉시 성공 상태로 응답한다.
/// Meta(Facebook/Instagram) Graph API 토큰이 설정되어 있으면 그쪽 결과를
/// 추가로 합쳐서 보여주지만, 토큰이 없어도 앱은 완벽하게 동작한다.
class MockData {
  MockData._();

  // ──────────────────────────────────────────────────────────────
  // User
  // ──────────────────────────────────────────────────────────────
  static User get currentUser => User(
        userId: 'demo_user_1',
        name: '사용자',
        email: 'user@photoshield.kr',
        notificationEnabled: true,
        createdAt: DateTime.now().subtract(const Duration(days: 32)),
      );

  // ──────────────────────────────────────────────────────────────
  // Photos
  // ──────────────────────────────────────────────────────────────
  static List<Photo> get photos => [
        Photo(
          photoId: 'photo_demo_1',
          thumbnailUrl:
              'https://images.unsplash.com/photo-1494790108377-be9c29b29330?w=400',
          registeredAt: DateTime.now().subtract(const Duration(days: 14)),
          status: 'monitoring',
        ),
        Photo(
          photoId: 'photo_demo_2',
          thumbnailUrl:
              'https://images.unsplash.com/photo-1438761681033-6461ffad8d80?w=400',
          registeredAt: DateTime.now().subtract(const Duration(days: 7)),
          status: 'monitoring',
        ),
        Photo(
          photoId: 'photo_demo_3',
          thumbnailUrl:
              'https://images.unsplash.com/photo-1531746020798-e6953c6e8e04?w=400',
          registeredAt: DateTime.now().subtract(const Duration(days: 2)),
          status: 'learning',
        ),
      ];

  // ──────────────────────────────────────────────────────────────
  // Detections
  // ──────────────────────────────────────────────────────────────
  static List<Detection> get detections => [
        Detection(
          detectionId: 'detection_demo_1',
          platform: 'instagram',
          foundUrl: 'https://www.instagram.com/sooyoung_love/',
          screenshotUrl:
              'https://images.unsplash.com/photo-1494790108377-be9c29b29330?w=600',
          similarity: 0.947,
          originalPhotoId: 'photo_demo_1',
          detectedAt: DateTime.now().subtract(const Duration(hours: 3)),
          status: DetectionStatus.unread,
        ),
        Detection(
          detectionId: 'detection_demo_2',
          platform: 'naver_blog',
          foundUrl: 'https://blog.naver.com/fakeuser123/photo',
          screenshotUrl:
              'https://images.unsplash.com/photo-1438761681033-6461ffad8d80?w=600',
          similarity: 0.873,
          originalPhotoId: 'photo_demo_2',
          detectedAt: DateTime.now().subtract(const Duration(days: 4)),
          status: DetectionStatus.reported,
          reportUrl: 'https://example.com/report/2.pdf',
        ),
        Detection(
          detectionId: 'detection_demo_3',
          platform: 'kakao_story',
          foundUrl: 'https://story.kakao.com/_demo/9999',
          screenshotUrl:
              'https://images.unsplash.com/photo-1531746020798-e6953c6e8e04?w=600',
          similarity: 0.812,
          originalPhotoId: 'photo_demo_3',
          detectedAt: DateTime.now().subtract(const Duration(days: 9)),
          status: DetectionStatus.read,
        ),
      ];

  static Detection? findDetection(String id) {
    for (final d in detections) {
      if (d.detectionId == id) return d;
    }
    return null;
  }

  // ──────────────────────────────────────────────────────────────
  // Notifications
  // ──────────────────────────────────────────────────────────────
  static List<NotificationItem> get notifications => [
        NotificationItem(
          notificationId: 'notif_demo_1',
          type: 'danger',
          message: '인스타그램에서 무단 도용 의심 사례가 발견되었습니다. (SooYoung_Love)',
          detectionId: 'detection_demo_1',
          isRead: false,
          createdAt: DateTime.now().subtract(const Duration(hours: 3)),
        ),
        NotificationItem(
          notificationId: 'notif_demo_2',
          type: 'safe',
          message: '오늘의 정기 검사가 완료되었습니다. 새로운 위협은 발견되지 않았습니다.',
          isRead: false,
          createdAt: DateTime.now().subtract(const Duration(hours: 12)),
        ),
        NotificationItem(
          notificationId: 'notif_demo_3',
          type: 'info',
          message: '네이버 블로그 도용 신고가 접수되어 처리 중입니다.',
          detectionId: 'detection_demo_2',
          isRead: true,
          createdAt: DateTime.now().subtract(const Duration(days: 4)),
        ),
      ];

  // ──────────────────────────────────────────────────────────────
  // Platform statuses (used by home dashboard)
  // ──────────────────────────────────────────────────────────────
  static const List<PlatformStatus> platforms = [
    PlatformStatus(
      id: 'instagram',
      name: '인스타그램',
      status: '안전함',
      isSafe: true,
    ),
    PlatformStatus(
      id: 'kakao_story',
      name: '카카오스토리',
      status: '안전함',
      isSafe: true,
    ),
    PlatformStatus(
      id: 'naver',
      name: '네이버',
      status: '안전함',
      isSafe: true,
    ),
  ];

  /// 마지막 정기 검사 시각 (홈 화면 "최근 검사" 카드용).
  static DateTime get lastScanAt =>
      DateTime.now().subtract(const Duration(days: 2));

  /// 전체 보호 상태 — 데모에서는 항상 안전.
  static bool get isSafe => true;
}

class PlatformStatus {
  final String id;
  final String name;
  final String status;
  final bool isSafe;

  const PlatformStatus({
    required this.id,
    required this.name,
    required this.status,
    required this.isSafe,
  });
}
