import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../shared/models/detection.dart';
import '../constants.dart';

class KakaoApiService {
  Future<bool> get isConfigured async => KakaoEnv.isConfigured;

  Future<KakaoConnectionStatus> fetchConnectionStatus() async {
    if (!KakaoEnv.isConfigured) {
      return const KakaoConnectionStatus.demo();
    }

    return KakaoConnectionStatus(
      connected: true,
      nickname: 'Kakao linked user',
      connectedAt: DateTime.now(),
    );
  }

  Future<List<Detection>> scanForUnauthorizedUse({
    required List<String> keywords,
    List<String> originalPhotoIds = const [],
  }) async {
    if (!KakaoEnv.isConfigured) {
      return _demoDetections();
    }

    if (keywords.isEmpty) {
      return const [];
    }

    return [
      Detection(
        detectionId: 'kakao_live_1',
        platform: 'kakao_story',
        foundUrl: 'https://story.kakao.com/_demo/live-monitoring',
        screenshotUrl:
            'https://images.unsplash.com/photo-1531746020798-e6953c6e8e04?w=600',
        similarity: 0.84,
        originalPhotoId:
            originalPhotoIds.isNotEmpty ? originalPhotoIds.first : null,
        detectedAt: DateTime.now().subtract(const Duration(minutes: 45)),
        status: DetectionStatus.unread,
      ),
    ];
  }

  List<Detection> _demoDetections() => [
        Detection(
          detectionId: 'kakao_demo_pipeline_1',
          platform: 'kakao_story',
          foundUrl: 'https://story.kakao.com/_demo/9999',
          screenshotUrl:
              'https://images.unsplash.com/photo-1531746020798-e6953c6e8e04?w=600',
          similarity: 0.81,
          detectedAt: DateTime.now().subtract(const Duration(days: 1)),
          status: DetectionStatus.read,
        ),
      ];
}

class KakaoConnectionStatus {
  final bool connected;
  final String? nickname;
  final DateTime? connectedAt;
  final String? error;

  const KakaoConnectionStatus({
    required this.connected,
    this.nickname,
    this.connectedAt,
    this.error,
  });

  const KakaoConnectionStatus.demo()
      : connected = false,
        nickname = null,
        connectedAt = null,
        error = null;
}

final kakaoApiServiceProvider = Provider<KakaoApiService>((ref) {
  return KakaoApiService();
});
