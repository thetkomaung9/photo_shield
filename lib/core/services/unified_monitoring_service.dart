import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../shared/models/detection.dart';
import '../../shared/models/notification_item.dart';
import '../../shared/models/social_connection.dart';
import '../../shared/models/social_platform.dart';
import '../constants.dart';
import 'facebook_api_service.dart';
import 'instagram_api_service.dart';
import 'kakao_api_service.dart';
import 'mock_data.dart';
import 'naver_api_service.dart';
import 'social_auth_service.dart';

class MonitoringPlatformSummary {
  final SocialPlatform platform;
  final bool isConnected;
  final bool isDemo;
  final int alertCount;

  const MonitoringPlatformSummary({
    required this.platform,
    required this.isConnected,
    required this.isDemo,
    required this.alertCount,
  });

  bool get isSafe => alertCount == 0;
}

class MonitoringSnapshot {
  final List<Detection> detections;
  final List<NotificationItem> generatedNotifications;
  final List<MonitoringPlatformSummary> platforms;
  final DateTime generatedAt;

  const MonitoringSnapshot({
    required this.detections,
    required this.generatedNotifications,
    required this.platforms,
    required this.generatedAt,
  });
}

class UnifiedMonitoringService {
  UnifiedMonitoringService({
    required FacebookApiService facebookApiService,
    required InstagramApiService instagramApiService,
    required KakaoApiService kakaoApiService,
    required NaverApiService naverApiService,
    required SocialAuthService socialAuthService,
  })  : _facebookApiService = facebookApiService,
        _instagramApiService = instagramApiService,
        _kakaoApiService = kakaoApiService,
        _naverApiService = naverApiService,
        _socialAuthService = socialAuthService;

  final FacebookApiService _facebookApiService;
  final InstagramApiService _instagramApiService;
  final KakaoApiService _kakaoApiService;
  final NaverApiService _naverApiService;
  final SocialAuthService _socialAuthService;

  Future<MonitoringSnapshot> buildSnapshot() async {
    final detections = <Detection>[...MockData.detections];
    final keywords = MonitoringEnv.keywords
        .split(',')
        .map((value) => value.trim())
        .where((value) => value.isNotEmpty)
        .toList();
    final suspectPages = MonitoringEnv.facebookSuspectPages
        .split(',')
        .map((value) => value.trim())
        .where((value) => value.isNotEmpty)
        .toList();

    if (await _instagramApiService.isConfigured) {
      detections.addAll(
        await _instagramApiService.scanForUnauthorizedUse(
          hashtags: keywords.isEmpty ? const ['내사진'] : keywords,
        ),
      );
    }
    if (await _facebookApiService.isConfigured) {
      detections.addAll(
        await _facebookApiService.scanForUnauthorizedUse(
          suspectPageIds: suspectPages,
        ),
      );
    }
    detections.addAll(
      await _kakaoApiService.scanForUnauthorizedUse(keywords: keywords),
    );
    detections.addAll(
      await _naverApiService.scanForUnauthorizedUse(keywords: keywords),
    );

    final merged = <String, Detection>{};
    for (final detection in detections) {
      merged[detection.detectionId] = detection;
    }

    final sortedDetections = merged.values.toList()
      ..sort((a, b) => b.detectedAt.compareTo(a.detectedAt));

    final connections = await _socialAuthService.loadConnections();

    return MonitoringSnapshot(
      detections: sortedDetections,
      generatedNotifications: _buildNotifications(sortedDetections),
      platforms: _buildPlatformSummaries(sortedDetections, connections),
      generatedAt: DateTime.now(),
    );
  }

  List<NotificationItem> _buildNotifications(List<Detection> detections) {
    final items = <NotificationItem>[];
    for (final detection in detections) {
      if (detection.similarity < 0.8) continue;
      items.add(
        NotificationItem(
          notificationId: 'monitor_${detection.detectionId}',
          type: detection.similarity >= 0.9 ? 'danger' : 'info',
          message:
              '${detection.platform} monitoring detected a suspicious match (${(detection.similarity * 100).round()}%)',
          detectionId: detection.detectionId,
          isRead: detection.status != DetectionStatus.unread,
          createdAt: detection.detectedAt,
        ),
      );
    }
    return items;
  }

  List<MonitoringPlatformSummary> _buildPlatformSummaries(
    List<Detection> detections,
    List<SocialConnection> connections,
  ) {
    return SocialPlatform.values.map((platform) {
      final connection = connections.firstWhere(
        (candidate) => candidate.platform == platform,
        orElse: () => SocialConnection.disconnected(platform),
      );
      final alertCount = detections.where((detection) {
        return detection.platform == platform.platformId ||
            (platform == SocialPlatform.naver &&
                detection.platform == 'naver_blog');
      }).length;

      return MonitoringPlatformSummary(
        platform: platform,
        isConnected: connection.isConnected,
        isDemo: connection.isDemo,
        alertCount: alertCount,
      );
    }).toList();
  }
}

final unifiedMonitoringServiceProvider =
    Provider<UnifiedMonitoringService>((ref) {
  return UnifiedMonitoringService(
    facebookApiService: ref.watch(facebookApiServiceProvider),
    instagramApiService: ref.watch(instagramApiServiceProvider),
    kakaoApiService: ref.watch(kakaoApiServiceProvider),
    naverApiService: ref.watch(naverApiServiceProvider),
    socialAuthService: ref.watch(socialAuthServiceProvider),
  );
});

final monitoringSnapshotProvider = FutureProvider<MonitoringSnapshot>((ref) {
  return ref.watch(unifiedMonitoringServiceProvider).buildSnapshot();
});
