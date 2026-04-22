import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../constants.dart';
import '../../shared/models/detection.dart';

/// Meta Instagram Graph API 클라이언트.
///
/// 실제 호출은 다음 엔드포인트를 사용한다.
///
/// * `GET /me` (graph.instagram.com) — 연결된 비즈니스 계정 정보 조회
/// * `GET /{ig-user-id}/media` — 본인이 업로드한 미디어 검증
/// * `GET /ig_hashtag_search` — 해시태그 ID 조회
/// * `GET /{hashtag-id}/recent_media` — 해시태그의 최신 공개 미디어 (24h)
/// * `GET /{ig-user-id}?fields=business_discovery.username(...)`
///   — 다른 비즈니스/크리에이터 계정의 공개 프로필 + 미디어 조회
///
/// 환경 변수(`META_USER_TOKEN`, `META_IG_USER_ID`)가 비어 있으면
/// `isConfigured == false` 가 되며, 모든 메서드는 미리 준비된 데모 데이터로
/// 응답한다. 따라서 토큰 없이도 UI 가 그대로 동작한다.
class InstagramApiService {
  InstagramApiService({Dio? dio, FlutterSecureStorage? storage})
      : _dio = dio ??
            Dio(
              BaseOptions(
                baseUrl: ApiConstants.instagramGraphBaseUrl,
                connectTimeout: const Duration(seconds: 10),
                receiveTimeout: const Duration(seconds: 10),
              ),
            ),
        _graphDio = Dio(
          BaseOptions(
            baseUrl: ApiConstants.facebookGraphBaseUrl,
            connectTimeout: const Duration(seconds: 10),
            receiveTimeout: const Duration(seconds: 10),
          ),
        ),
        _storage = storage ?? const FlutterSecureStorage();

  final Dio _dio; // graph.instagram.com (Instagram Login)
  final Dio _graphDio; // graph.facebook.com (해시태그/Business Discovery)
  final FlutterSecureStorage _storage;

  /// 컴파일 타임 또는 SecureStorage 에 저장된 토큰을 반환.
  Future<String?> _userToken() async {
    if (MetaEnv.userToken.isNotEmpty) return MetaEnv.userToken;
    return _storage.read(key: StorageKeys.metaUserToken);
  }

  Future<String?> _igUserId() async {
    if (MetaEnv.igUserId.isNotEmpty) return MetaEnv.igUserId;
    return _storage.read(key: StorageKeys.metaIgUserId);
  }

  /// 토큰이 없거나 자동 조회가 실패하면 데모 모드.
  Future<bool> get isConfigured async {
    final token = await _userToken();
    return token != null && token.isNotEmpty;
  }

  // ---------------------------------------------------------------------------
  // Public API
  // ---------------------------------------------------------------------------

  /// 연결 상태 조회 — 대시보드에서 "연결됨/데모" 뱃지를 그릴 때 사용.
  Future<InstagramConnectionStatus> fetchConnectionStatus() async {
    final token = await _userToken();
    if (token == null || token.isEmpty) {
      return const InstagramConnectionStatus.demo();
    }
    try {
      final res = await _dio.get(
        '/me',
        queryParameters: {
          'fields':
              'user_id,username,account_type,profile_picture_url,media_count',
          'access_token': token,
        },
      );
      final data = res.data is Map<String, dynamic>
          ? res.data as Map<String, dynamic>
          : <String, dynamic>{};
      return InstagramConnectionStatus(
        connected: true,
        username: data['username'] as String?,
        userId: (data['user_id'] ?? data['id'])?.toString(),
        accountType: data['account_type'] as String?,
        profilePictureUrl: data['profile_picture_url'] as String?,
        mediaCount: (data['media_count'] as num?)?.toInt(),
      );
    } on DioException catch (e) {
      return InstagramConnectionStatus(
        connected: false,
        error: _formatError(e),
      );
    }
  }

  /// 등록된 본인 IG 미디어 목록.
  Future<List<InstagramMedia>> fetchOwnMedia({int limit = 25}) async {
    final token = await _userToken();
    final igId = await _igUserId();
    if (token == null || token.isEmpty || igId == null || igId.isEmpty) {
      return _demoMedia();
    }
    try {
      final res = await _dio.get(
        '/$igId/media',
        queryParameters: {
          'fields':
              'id,media_type,media_url,thumbnail_url,permalink,caption,timestamp',
          'limit': limit,
          'access_token': token,
        },
      );
      final list = (res.data['data'] as List? ?? [])
          .map((e) => InstagramMedia.fromJson(e as Map<String, dynamic>))
          .toList();
      return list;
    } on DioException {
      return _demoMedia();
    }
  }

  /// 해시태그 ID 조회. 7일 동안 최대 30개의 고유 해시태그만 가능.
  Future<String?> resolveHashtagId(String hashtag) async {
    final token = await _userToken();
    final igId = await _igUserId();
    if (token == null || igId == null) return null;
    try {
      final res = await _graphDio.get(
        '/ig_hashtag_search',
        queryParameters: {
          'user_id': igId,
          'q': hashtag.replaceAll('#', ''),
          'access_token': token,
        },
      );
      final data = res.data['data'] as List? ?? [];
      if (data.isEmpty) return null;
      return data.first['id'] as String?;
    } on DioException {
      return null;
    }
  }

  /// 해시태그 기반 최근 공개 미디어 검색 (지난 24시간).
  Future<List<InstagramMedia>> searchRecentByHashtag(String hashtag) async {
    final token = await _userToken();
    final igId = await _igUserId();
    if (token == null || igId == null) return _demoMedia();
    final tagId = await resolveHashtagId(hashtag);
    if (tagId == null) return [];
    try {
      final res = await _graphDio.get(
        '/$tagId/recent_media',
        queryParameters: {
          'user_id': igId,
          'fields':
              'id,media_type,media_url,permalink,caption,like_count,timestamp',
          'access_token': token,
        },
      );
      return (res.data['data'] as List? ?? [])
          .map((e) => InstagramMedia.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException {
      return [];
    }
  }

  /// 다른 비즈니스/크리에이터 계정의 공개 프로필을 username 으로 조회.
  Future<InstagramBusinessProfile?> discoverBusinessByUsername(
    String username,
  ) async {
    final token = await _userToken();
    final igId = await _igUserId();
    if (token == null || igId == null) {
      return _demoBusinessProfile(username);
    }
    final cleaned = username.replaceAll('@', '');
    try {
      final res = await _graphDio.get(
        '/$igId',
        queryParameters: {
          'fields':
              'business_discovery.username($cleaned){id,username,followers_count,media_count,profile_picture_url,biography,media{id,media_type,media_url,permalink,caption,timestamp}}',
          'access_token': token,
        },
      );
      final bd = res.data['business_discovery'] as Map<String, dynamic>?;
      if (bd == null) return null;
      return InstagramBusinessProfile.fromJson(bd);
    } on DioException {
      return _demoBusinessProfile(username);
    }
  }

  /// 모니터링 키워드(해시태그) 리스트로 의심 사례를 모아서 Detection 객체로 변환.
  ///
  /// `originalPhotoIds` 가 주어지면 detection.originalPhotoId 에 매칭한다.
  Future<List<Detection>> scanForUnauthorizedUse({
    required List<String> hashtags,
    List<String> originalPhotoIds = const [],
  }) async {
    final configured = await isConfigured;
    if (!configured) {
      return _demoDetections();
    }
    final results = <Detection>[];
    for (final tag in hashtags) {
      final media = await searchRecentByHashtag(tag);
      for (final m in media) {
        if (m.permalink == null) continue;
        results.add(
          Detection(
            detectionId: 'ig_${m.id}',
            platform: 'instagram',
            foundUrl: m.permalink!,
            screenshotUrl: m.mediaUrl ?? m.thumbnailUrl,
            // 해시태그 매칭은 1차 신호이므로 보수적으로 0.72로 시작.
            similarity: 0.72,
            originalPhotoId:
                originalPhotoIds.isNotEmpty ? originalPhotoIds.first : null,
            detectedAt: m.timestamp ?? DateTime.now(),
            status: DetectionStatus.unread,
          ),
        );
      }
    }
    return results;
  }

  // ---------------------------------------------------------------------------
  // Demo data — 토큰 없을 때만 사용
  // ---------------------------------------------------------------------------

  List<InstagramMedia> _demoMedia() => [
        InstagramMedia(
          id: 'demo_ig_1',
          mediaType: 'IMAGE',
          mediaUrl:
              'https://images.unsplash.com/photo-1494790108377-be9c29b29330',
          permalink: 'https://www.instagram.com/p/demo_post_1/',
          caption: '데모용 게시물입니다. (API 키가 설정되지 않음)',
          timestamp: DateTime.now().subtract(const Duration(hours: 3)),
        ),
        InstagramMedia(
          id: 'demo_ig_2',
          mediaType: 'IMAGE',
          mediaUrl:
              'https://images.unsplash.com/photo-1438761681033-6461ffad8d80',
          permalink: 'https://www.instagram.com/p/demo_post_2/',
          caption: '#내사진 #프로필도용',
          timestamp: DateTime.now().subtract(const Duration(hours: 12)),
        ),
      ];

  InstagramBusinessProfile _demoBusinessProfile(String username) =>
      InstagramBusinessProfile(
        id: 'demo_${username.hashCode}',
        username: username,
        followersCount: 3200,
        mediaCount: 5,
        profilePictureUrl:
            'https://images.unsplash.com/photo-1438761681033-6461ffad8d80',
        biography: '데모 프로필 — 실제 API 토큰을 연결하면 라이브 데이터로 표시됩니다.',
        media: _demoMedia(),
      );

  List<Detection> _demoDetections() => [
        Detection(
          detectionId: 'ig_demo_1',
          platform: 'instagram',
          foundUrl: 'https://www.instagram.com/sooyoung_love/',
          screenshotUrl:
              'https://images.unsplash.com/photo-1494790108377-be9c29b29330',
          similarity: 0.94,
          originalPhotoId: null,
          detectedAt: DateTime.now().subtract(const Duration(hours: 2)),
          status: DetectionStatus.unread,
        ),
        Detection(
          detectionId: 'ig_demo_2',
          platform: 'instagram',
          foundUrl: 'https://www.instagram.com/hanna_style/',
          screenshotUrl:
              'https://images.unsplash.com/photo-1438761681033-6461ffad8d80',
          similarity: 0.88,
          originalPhotoId: null,
          detectedAt: DateTime.now().subtract(const Duration(hours: 9)),
          status: DetectionStatus.unread,
        ),
      ];

  String _formatError(DioException e) {
    final msg = e.response?.data is Map
        ? (e.response?.data['error']?['message'] as String?)
        : null;
    return msg ?? e.message ?? 'Instagram API 호출 실패';
  }
}

// ----------------------------- Models ---------------------------------------

class InstagramConnectionStatus {
  final bool connected;
  final String? username;
  final String? userId;
  final String? accountType;
  final String? profilePictureUrl;
  final int? mediaCount;
  final String? error;

  const InstagramConnectionStatus({
    required this.connected,
    this.username,
    this.userId,
    this.accountType,
    this.profilePictureUrl,
    this.mediaCount,
    this.error,
  });

  const InstagramConnectionStatus.demo()
      : connected = false,
        username = null,
        userId = null,
        accountType = null,
        profilePictureUrl = null,
        mediaCount = null,
        error = '데모 모드 (Meta 토큰 미설정)';

  bool get isDemo => !connected;
}

class InstagramMedia {
  final String id;
  final String mediaType; // IMAGE / VIDEO / CAROUSEL_ALBUM
  final String? mediaUrl;
  final String? thumbnailUrl;
  final String? permalink;
  final String? caption;
  final int? likeCount;
  final DateTime? timestamp;

  const InstagramMedia({
    required this.id,
    required this.mediaType,
    this.mediaUrl,
    this.thumbnailUrl,
    this.permalink,
    this.caption,
    this.likeCount,
    this.timestamp,
  });

  factory InstagramMedia.fromJson(Map<String, dynamic> json) => InstagramMedia(
        id: json['id'].toString(),
        mediaType: (json['media_type'] ?? 'IMAGE').toString(),
        mediaUrl: json['media_url'] as String?,
        thumbnailUrl: json['thumbnail_url'] as String?,
        permalink: json['permalink'] as String?,
        caption: json['caption'] as String?,
        likeCount: (json['like_count'] as num?)?.toInt(),
        timestamp: json['timestamp'] != null
            ? DateTime.tryParse(json['timestamp'] as String)
            : null,
      );
}

class InstagramBusinessProfile {
  final String id;
  final String username;
  final int? followersCount;
  final int? mediaCount;
  final String? profilePictureUrl;
  final String? biography;
  final List<InstagramMedia> media;

  const InstagramBusinessProfile({
    required this.id,
    required this.username,
    this.followersCount,
    this.mediaCount,
    this.profilePictureUrl,
    this.biography,
    this.media = const [],
  });

  factory InstagramBusinessProfile.fromJson(Map<String, dynamic> json) {
    final mediaList = ((json['media']?['data']) as List? ?? [])
        .map((e) => InstagramMedia.fromJson(e as Map<String, dynamic>))
        .toList();
    return InstagramBusinessProfile(
      id: json['id'].toString(),
      username: (json['username'] ?? '').toString(),
      followersCount: (json['followers_count'] as num?)?.toInt(),
      mediaCount: (json['media_count'] as num?)?.toInt(),
      profilePictureUrl: json['profile_picture_url'] as String?,
      biography: json['biography'] as String?,
      media: mediaList,
    );
  }
}

// ----------------------------- Providers ------------------------------------

final instagramApiServiceProvider = Provider<InstagramApiService>(
  (ref) => InstagramApiService(),
);

final instagramConnectionProvider =
    FutureProvider<InstagramConnectionStatus>((ref) async {
  return ref.watch(instagramApiServiceProvider).fetchConnectionStatus();
});
