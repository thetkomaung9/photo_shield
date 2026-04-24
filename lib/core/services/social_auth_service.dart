import 'dart:math';

import 'package:flutter/services.dart';
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_web_auth_2/flutter_web_auth_2.dart';
import 'package:flutter_naver_login/flutter_naver_login.dart';
import 'package:flutter_naver_login/interface/types/naver_login_status.dart';
import 'package:kakao_flutter_sdk/kakao_flutter_sdk.dart';

import '../../shared/models/social_connection.dart';
import '../../shared/models/social_platform.dart';
import '../constants.dart';
import 'api_service.dart';
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
    if (!await _hasLiveLoginSetup(platform)) {
      return _connectDemo(platform);
    }

    switch (platform) {
      case SocialPlatform.facebook:
        return _connectFacebook();
      case SocialPlatform.instagram:
        return _connectInstagram();
      case SocialPlatform.kakao:
        return _connectKakao();
      case SocialPlatform.naver:
        return _connectNaver();
    }
  }

  Future<SocialConnection> _connectDemo(SocialPlatform platform) async {
    final now = DateTime.now();
    final accountLabel = _defaultAccountLabel(platform, false);

    await _persistConnection(
      platform,
      accountLabel: accountLabel,
      connectedAt: now,
    );

    return SocialConnection(
      platform: platform,
      isConnected: true,
      isDemo: true,
      requiresConsoleSetup: true,
      accountLabel: accountLabel,
      connectedAt: now,
      lastSyncAt: now,
    );
  }

  Future<SocialConnection> _connectFacebook() async {
    final loginResult = await FacebookAuth.instance.login(
      permissions: const ['email', 'public_profile'],
    );
    if (loginResult.status != LoginStatus.success ||
        loginResult.accessToken == null) {
      throw StateError(loginResult.message ?? 'Facebook login failed');
    }

    final accessToken = loginResult.accessToken!;
    final userData = await FacebookAuth.instance.getUserData();
    final now = DateTime.now();
    final accountLabel =
        (userData['name'] ?? userData['email'] ?? 'Facebook account')
            .toString();

    await _storage.write(
      key: StorageKeys.metaUserToken,
      value: accessToken.tokenString,
    );
    await _persistConnection(
      SocialPlatform.facebook,
      accountLabel: accountLabel,
      connectedAt: now,
    );

    return SocialConnection(
      platform: SocialPlatform.facebook,
      isConnected: true,
      isDemo: false,
      requiresConsoleSetup: false,
      accountLabel: accountLabel,
      connectedAt: now,
      lastSyncAt: now,
    );
  }

  Future<SocialConnection> _connectInstagram() async {
    final authorizeUri = Uri.https('www.instagram.com', '/oauth/authorize', {
      'enable_fb_login': '0',
      'force_authentication': '1',
      'client_id': InstagramEnv.clientId,
      'redirect_uri': InstagramEnv.redirectUri,
      'response_type': 'code',
      'scope': 'user_profile,user_media',
      'state': _randomState(),
    });
    final callbackScheme = Uri.parse(InstagramEnv.redirectUri).scheme;
    final callbackResult = await FlutterWebAuth2.authenticate(
      url: authorizeUri.toString(),
      callbackUrlScheme: callbackScheme,
      options: const FlutterWebAuth2Options(preferEphemeral: true),
    );

    final code = Uri.parse(callbackResult).queryParameters['code'];
    if (code == null || code.isEmpty) {
      throw StateError('Instagram authorization code missing');
    }

    final exchangeResponse = await ApiService().dio.post(
      ApiConstants.resolveBackendUrl(ApiConstants.instagramAuthExchangePath),
      data: {
        'code': code,
        'redirectUri': InstagramEnv.redirectUri,
      },
    );
    final data = exchangeResponse.data is Map<String, dynamic>
        ? exchangeResponse.data as Map<String, dynamic>
        : <String, dynamic>{};
    final accessToken =
        data['accessToken']?.toString() ?? data['access_token']?.toString();
    if (accessToken == null || accessToken.isEmpty) {
      throw StateError('Instagram token exchange failed');
    }

    final now = DateTime.now();
    final accountLabel =
        (data['username'] ?? data['accountLabel'] ?? 'Instagram account')
            .toString();

    await _storage.write(
      key: StorageKeys.instagramAccessToken,
      value: accessToken,
    );
    await _storage.write(
      key: StorageKeys.metaIgUserId,
      value: data['userId']?.toString() ?? data['igUserId']?.toString(),
    );
    await _persistConnection(
      SocialPlatform.instagram,
      accountLabel: accountLabel,
      connectedAt: now,
    );

    return SocialConnection(
      platform: SocialPlatform.instagram,
      isConnected: true,
      isDemo: false,
      requiresConsoleSetup: false,
      accountLabel: accountLabel,
      connectedAt: now,
      lastSyncAt: now,
    );
  }

  Future<SocialConnection> _connectKakao() async {
    OAuthToken token;
    if (await isKakaoTalkInstalled()) {
      try {
        token = await UserApi.instance.loginWithKakaoTalk();
      } on PlatformException catch (error) {
        if (error.code == 'CANCELED') {
          rethrow;
        }
        token = await UserApi.instance.loginWithKakaoAccount();
      }
    } else {
      token = await UserApi.instance.loginWithKakaoAccount();
    }

    final user = await UserApi.instance.me();
    final now = DateTime.now();
    final accountLabel = user.kakaoAccount?.profile?.nickname ??
        user.kakaoAccount?.email ??
        'Kakao account';

    await _storage.write(
      key: StorageKeys.kakaoAccessToken,
      value: token.accessToken,
    );
    await _persistConnection(
      SocialPlatform.kakao,
      accountLabel: accountLabel,
      connectedAt: now,
    );

    return SocialConnection(
      platform: SocialPlatform.kakao,
      isConnected: true,
      isDemo: false,
      requiresConsoleSetup: false,
      accountLabel: accountLabel,
      connectedAt: now,
      lastSyncAt: now,
    );
  }

  Future<SocialConnection> _connectNaver() async {
    final result = await FlutterNaverLogin.logIn();
    if (result.status != NaverLoginStatus.loggedIn) {
      throw StateError(result.errorMessage ?? 'Naver login failed');
    }

    final token = await FlutterNaverLogin.getCurrentAccessToken();
    if (!token.isValid()) {
      throw StateError('Naver access token missing');
    }

    final account = result.account;
    final now = DateTime.now();
    final accountLabel = account?.name?.isNotEmpty == true
        ? account!.name!
        : (account?.nickname?.isNotEmpty == true
            ? account!.nickname!
            : 'Naver account');

    await _storage.write(
      key: StorageKeys.naverAccessToken,
      value: token.accessToken,
    );
    await _persistConnection(
      SocialPlatform.naver,
      accountLabel: accountLabel,
      connectedAt: now,
    );

    return SocialConnection(
      platform: SocialPlatform.naver,
      isConnected: true,
      isDemo: false,
      requiresConsoleSetup: false,
      accountLabel: accountLabel,
      connectedAt: now,
      lastSyncAt: now,
    );
  }

  Future<void> _persistConnection(
    SocialPlatform platform, {
    required String accountLabel,
    required DateTime connectedAt,
  }) async {
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
      value: connectedAt.toIso8601String(),
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
        return MetaEnv.appId.isNotEmpty;
      case SocialPlatform.instagram:
        return InstagramEnv.isConfigured;
      case SocialPlatform.kakao:
        return KakaoEnv.isConfigured;
      case SocialPlatform.naver:
        return NaverEnv.isConfigured;
    }
  }

  Future<bool> _hasLiveLoginSetup(SocialPlatform platform) {
    return _isLiveConfigured(platform);
  }

  String _randomState() {
    final random = Random.secure();
    const chars =
        '0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz';
    return List.generate(
      24,
      (_) => chars[random.nextInt(chars.length)],
    ).join();
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
