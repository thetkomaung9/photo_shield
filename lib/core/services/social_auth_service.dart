import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../shared/models/social_connection.dart';
import '../../shared/models/social_platform.dart';
import '../constants.dart';
import 'facebook_api_service.dart';
import 'instagram_api_service.dart';
import 'kakao_api_service.dart';
import 'naver_api_service.dart';

class SocialAuthService {
  SocialAuthService({
    required FacebookApiService facebookApiService,
    required InstagramApiService instagramApiService,
    required KakaoApiService kakaoApiService,
    required NaverApiService naverApiService,
    FlutterSecureStorage? storage,
  })  : _facebookApiService = facebookApiService,
        _instagramApiService = instagramApiService,
        _kakaoApiService = kakaoApiService,
        _naverApiService = naverApiService,
        _storage = storage ?? const FlutterSecureStorage();

  final FacebookApiService _facebookApiService;
  final InstagramApiService _instagramApiService;
  final KakaoApiService _kakaoApiService;
  final NaverApiService _naverApiService;
  final FlutterSecureStorage _storage;

  Future<List<SocialConnection>> loadConnections() async {
    final facebookStatus = await _facebookApiService.fetchConnectionStatus();
    final instagramStatus = await _instagramApiService.fetchConnectionStatus();
    final kakaoStatus = await _kakaoApiService.fetchConnectionStatus();
    final naverStatus = await _naverApiService.fetchConnectionStatus();

    return [
      await _buildConnection(
        SocialPlatform.facebook,
        liveConnected: facebookStatus.connected,
        accountLabel: facebookStatus.userId ?? facebookStatus.appId,
        lastSyncAt: facebookStatus.expiresAt,
      ),
      await _buildConnection(
        SocialPlatform.instagram,
        liveConnected: instagramStatus.connected,
        accountLabel: instagramStatus.username,
        lastSyncAt: DateTime.now(),
      ),
      await _buildConnection(
        SocialPlatform.kakao,
        liveConnected: kakaoStatus.connected,
        accountLabel: kakaoStatus.nickname,
        lastSyncAt: kakaoStatus.connectedAt,
      ),
      await _buildConnection(
        SocialPlatform.naver,
        liveConnected: naverStatus.connected,
        accountLabel: naverStatus.accountName,
        lastSyncAt: naverStatus.connectedAt,
      ),
    ];
  }

  Future<SocialConnection> connect(SocialPlatform platform) async {
    final now = DateTime.now();
    final liveConfigured = await _isLiveConfigured(platform);
    final accountLabel = _defaultAccountLabel(platform, liveConfigured);

    await _storage.write(
      key: StorageKeys.socialConnected(platform.id),
      value: 'true',
    );
    await _storage.write(
      key: StorageKeys.socialAccountLabel(platform.id),
      value: accountLabel,
    );
    await _storage.write(
      key: StorageKeys.socialConnectedAt(platform.id),
      value: now.toIso8601String(),
    );

    return SocialConnection(
      platform: platform,
      isConnected: true,
      isDemo: !liveConfigured,
      requiresConsoleSetup: !liveConfigured,
      accountLabel: accountLabel,
      connectedAt: now,
      lastSyncAt: now,
    );
  }

  Future<void> disconnect(SocialPlatform platform) async {
    await _storage.delete(key: StorageKeys.socialConnected(platform.id));
    await _storage.delete(key: StorageKeys.socialAccountLabel(platform.id));
    await _storage.delete(key: StorageKeys.socialConnectedAt(platform.id));
  }

  Future<SocialConnection> _buildConnection(
    SocialPlatform platform, {
    required bool liveConnected,
    required String? accountLabel,
    DateTime? lastSyncAt,
  }) async {
    final persisted =
        await _storage.read(key: StorageKeys.socialConnected(platform.id));
    final persistedAt =
        await _storage.read(key: StorageKeys.socialConnectedAt(platform.id));
    final persistedLabel =
        await _storage.read(key: StorageKeys.socialAccountLabel(platform.id));
    final connectedAt =
        persistedAt == null ? null : DateTime.tryParse(persistedAt);
    final isConnected = liveConnected || persisted == 'true';

    if (!isConnected) {
      return SocialConnection(
        platform: platform,
        isConnected: false,
        isDemo: true,
        requiresConsoleSetup: true,
      );
    }

    return SocialConnection(
      platform: platform,
      isConnected: true,
      isDemo: !liveConnected,
      requiresConsoleSetup: !liveConnected,
      accountLabel: accountLabel ??
          persistedLabel ??
          _defaultAccountLabel(platform, liveConnected),
      connectedAt: connectedAt,
      lastSyncAt: lastSyncAt ?? connectedAt,
    );
  }

  Future<bool> _isLiveConfigured(SocialPlatform platform) async {
    switch (platform) {
      case SocialPlatform.facebook:
        return _facebookApiService.isConfigured;
      case SocialPlatform.instagram:
        return _instagramApiService.isConfigured;
      case SocialPlatform.kakao:
        return _kakaoApiService.isConfigured;
      case SocialPlatform.naver:
        return _naverApiService.isConfigured;
    }
  }

  String _defaultAccountLabel(SocialPlatform platform, bool liveConfigured) {
    final suffix = liveConfigured ? 'Live account' : 'Demo account';
    switch (platform) {
      case SocialPlatform.facebook:
        return 'Facebook $suffix';
      case SocialPlatform.instagram:
        return 'Instagram $suffix';
      case SocialPlatform.kakao:
        return 'Kakao $suffix';
      case SocialPlatform.naver:
        return 'Naver $suffix';
    }
  }
}

final socialAuthServiceProvider = Provider<SocialAuthService>((ref) {
  return SocialAuthService(
    facebookApiService: ref.watch(facebookApiServiceProvider),
    instagramApiService: ref.watch(instagramApiServiceProvider),
    kakaoApiService: ref.watch(kakaoApiServiceProvider),
    naverApiService: ref.watch(naverApiServiceProvider),
  );
});

final socialConnectionsProvider = FutureProvider<List<SocialConnection>>((ref) {
  return ref.watch(socialAuthServiceProvider).loadConnections();
});
