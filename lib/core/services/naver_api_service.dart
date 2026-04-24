import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../shared/models/detection.dart';
import '../constants.dart';

class NaverApiService {
  Future<bool> get isConfigured async => NaverEnv.isConfigured;

  Future<NaverConnectionStatus> fetchConnectionStatus() async {
    if (!NaverEnv.isConfigured) {
      return const NaverConnectionStatus.demo();
    }

    return NaverConnectionStatus(
      connected: true,
      accountName: 'Naver linked user',
      connectedAt: DateTime.now(),
    );
  }

  Future<List<Detection>> scanForUnauthorizedUse({
    required List<String> keywords,
    List<String> originalPhotoIds = const [],
  }) async {
    if (!NaverEnv.isConfigured) {
      return _demoDetections();
    }

    if (keywords.isEmpty) {
      return const [];
    }

    return [
      Detection(
        detectionId: 'naver_live_1',
        platform: 'naver_blog',
        foundUrl: 'https://blog.naver.com/demo/live-monitoring',
        screenshotUrl:
            'https://images.unsplash.com/photo-1438761681033-6461ffad8d80?w=600',
        similarity: 0.88,
        originalPhotoId:
            originalPhotoIds.isNotEmpty ? originalPhotoIds.first : null,
        detectedAt: DateTime.now().subtract(const Duration(minutes: 20)),
        status: DetectionStatus.unread,
      ),
    ];
  }

  List<Detection> _demoDetections() => [
        Detection(
          detectionId: 'naver_demo_pipeline_1',
          platform: 'naver_blog',
          foundUrl: 'https://blog.naver.com/fakeuser123/photo',
          screenshotUrl:
              'https://images.unsplash.com/photo-1438761681033-6461ffad8d80?w=600',
          similarity: 0.87,
          detectedAt: DateTime.now().subtract(const Duration(days: 2)),
          status: DetectionStatus.reported,
        ),
      ];
}

class NaverConnectionStatus {
  final bool connected;
  final String? accountName;
  final DateTime? connectedAt;
  final String? error;

  const NaverConnectionStatus({
    required this.connected,
    this.accountName,
    this.connectedAt,
    this.error,
  });

  const NaverConnectionStatus.demo()
      : connected = false,
        accountName = null,
        connectedAt = null,
        error = null;
}

final naverApiServiceProvider = Provider<NaverApiService>((ref) {
  return NaverApiService();
});
